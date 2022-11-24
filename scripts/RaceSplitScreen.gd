extends Node

class CheckpointState:
	var count := 0
	var done : Array
	func reset(cp_count : int) -> void:
		count = 0
		done.resize(cp_count)
		done.fill(false)

const CarDrift = preload("res://scenes/CarDrift.tscn")
const RecordDataBase = preload("res://scripts/RecordDataBase.gd")

signal scores_changed(scores)
signal checkpoints_changed(current, total)

enum State { RaceStarting, Countdown, Racing, RaceTerminated }


var players := []
var ghosts := []
var checkpoints : Array # CheckpointState
var scores : Array
var lap_stamps : Array
var max_score := 3
var state : int = State.RaceStarting
var elapsed_physics_frame := 0

var cameras : Array = []
var viewports : Array
var map : RaceMap
var hud : HUD

onready var end_score_overlay := $CanvasLayer/EndScoreOverlay
onready var pause_overlay := $CanvasLayer/PauseOverlay
onready var world := $World

func _ready():
	var _e : int # Error
	
	# Load layout for given player count
	match Global.player_count:
		1:
			_load_viewports_and_hud(
				"res://scenes/UI/SingleViewport.tscn",
				"res://scenes/UI/SingleHUD.tscn")
		2, _:
			_load_viewports_and_hud(
				"res://scenes/UI/DoubleViewport.tscn",
				"res://scenes/UI/DoubleHUD.tscn")
	
	# Setup viewports, world and cameras
	world.get_parent().remove_child(world)
	viewports.front().add_child(world)
	for v in viewports:
		v.world_2d = viewports.front().world_2d
		cameras.append(v.get_child(0))

	# Race Map
	var map_resource := load(Global.race_map_scene_name)
	map = map_resource.instance()
	map.translate(Vector2(-125, -125))
	map.rotation = -45 # radians!!!
	world.add_child(map)
	var auto_grass : AutoGrass = world.get_node("AutoGrass")
	auto_grass.set_rect(map.tile_map.get_used_rect().grow(5), Global.race_map_scene_name.hash())
	auto_grass.transform = map.transform
	_e = map.connect("checkpoint_area_entered", self, "_on_RaceMap_checkpoint_area_entered")
	_e = map.connect("start_area_entered", self, "_on_RaceMap_start_area_entered")
	
	# Player's Car
	for player_id in range(Global.player_count):
		var player := CarDrift.instance()
		player.player_id = player_id
		player.color = Global.player_colors[player_id]
		world.add_child(player)
		players.append(player)
		# remote camera
		var remote_transform := RemoteTransform2D.new()
		remote_transform.remote_path = cameras[player_id].get_path()
		players[player_id].add_child(remote_transform)
		# Player data
		scores.append(0)
		checkpoints.append(CheckpointState.new())
		lap_stamps.append(Array())
	
	# Ghost cars
	if Global.player_count == 1:
		var info : MapsList.MapInfo = Global.maps_info.get(Global.race_map_scene_name)
		var progression : MapsList.MapProgression = Global.maps_progression.get(Global.race_map_scene_name)
		if info != null:
			var completed = info.medals_completed(progression)
			for m in range(MapsList.MapInfo.Medal.COUNT):
				if m == MapsList.MapInfo.Medal.AUTHOR and not completed[MapsList.MapInfo.Medal.GOLD]:
					continue
				var medal : RecordDataBase.Record = info.target_medals[m]
				if medal == null or medal.path.empty():
					continue
				var ghost := CarDrift.instance()
				ghost.color = Global.medal_colors[m]
				ghost.is_ghost = true
				ghost.load_record(medal.path)
				world.add_child(ghost)
				ghosts.append(ghost)
		if progression != null:
			var ghost := CarDrift.instance()
			ghost.color = Global.player_colors[1]
			ghost.is_ghost = true
			ghost.load_record(progression.best_record.path)
			world.add_child(ghost)
			ghosts.append(ghost)
	
	# UI
	hud.get_elapsed_time_func = funcref(self, "_get_elapsed_time")
	_e = connect("checkpoints_changed", hud, "_on_checkpoints_changed")
	_e = connect("scores_changed", hud, "_on_scores_changed")
	pause_overlay.exit_to_menu_func = funcref(self, "_exit_to_menu")
	pause_overlay.reset_race_func = funcref(self, "_reset_race")
	end_score_overlay.exit_to_menu_func = funcref(self, "_exit_to_menu")
	end_score_overlay.reset_race_func = funcref(self, "_reset_race")
	end_score_overlay.score_table.player_count = Global.player_count
	match Global.player_count:
		1:
			end_score_overlay.score_table.row_mask = ScoreTable.RowMask.LAP_TIMES
			end_score_overlay.score_table.row_mask |= ScoreTable.RowMask.RACE_TIME
			end_score_overlay.score_table.row_mask |= ScoreTable.RowMask.MEDALS
		_:
			end_score_overlay.score_table.row_mask = ScoreTable.RowMask.PLAYER_NAME
			end_score_overlay.score_table.row_mask |= ScoreTable.RowMask.BEST_LAP_TIME
			end_score_overlay.score_table.row_mask |= ScoreTable.RowMask.RACE_TIME
			end_score_overlay.score_table.row_mask |= ScoreTable.RowMask.RANK
	SoundUI.connect_buttons(pause_overlay)
	
	# Start race logic
	initialize_race()

func _load_viewports_and_hud(game_viewport_path : String, hud_path : String):
	var game_viewport_scene : GameViewports = load(game_viewport_path).instance()
	add_child(game_viewport_scene)
	move_child(game_viewport_scene, 0)
	viewports = game_viewport_scene.get_viewports()
	
	hud = load(hud_path).instance()
	$CanvasLayer.add_child(hud)
	$CanvasLayer.move_child(hud, 0)

func _physics_process(_delta : float) -> void:
	if state == State.Racing:
		elapsed_physics_frame += 1

func initialize_race() -> void:
	for player_id in range(Global.player_count):
		players[player_id].reset(map.get_player_spawn(player_id))
		if Global.player_count == 1:
			players[player_id].enable_recording()
		scores[player_id] = 0
		checkpoints[player_id].reset(map.get_checkpoint_count())
	emit_signal("scores_changed", scores)
	emit_signal("checkpoints_changed", _make_checkpoint_count_array(), map.get_checkpoint_count())
	
	for g in ghosts:
		g.reset(map.get_player_spawn(0))
	
	$CountdownPlayer.play("RESET")
	elapsed_physics_frame = 0
	
	$ScreenFadeInOut.fade_in()
	yield($ScreenFadeInOut, "animation_finished")
	
	pause_overlay.allow_pause = true
	
	state = State.Countdown
	play_countdown()

func play_countdown() -> void:
	$CountdownPlayer.play("countdown")
	$CountdownPlayer.queue("post_countdown")
	$CountdownPlayer.queue("RESET")
	var _e := $CountdownPlayer.connect(
		"animation_changed", self, "_on_countdown_animation_changed", [], CONNECT_ONESHOT)

func _on_countdown_animation_changed(_old : String, _new : String) -> void:
	start_race()

func start_race() -> void:
	for p in players:
		p.activate()
	for g in ghosts:
		g.activate(true)
	state = State.Racing
	elapsed_physics_frame = 0

func _compare_times(a, b):
	return a.time < b.time

func end_race() -> void:
	state = State.RaceTerminated
	$CountdownPlayer.play("end_race")
	$CountdownPlayer.queue("RESET")
	yield($CountdownPlayer, "animation_finished")
	
	# Generate score table data
	var times := Array()
	for player_id in range(Global.player_count):
		var total := 0
		for t in lap_stamps[player_id]:
			total += t
		times.append({time=total, player_id=player_id})
	times.sort_custom(self, "_compare_times")
	var ranks := Array()
	ranks.resize(Global.player_count)
	for r in range(Global.player_count):
		var rank := r
		if r > 0 and times[r - 1].time == times[r].time:
			rank = ranks[times[r - 1].player_id]
		ranks[times[r].player_id] = rank + 1
	
	
	for player_id in range(Global.player_count):
		var data := ScoreTable.PlayerData.new()
		data.player_id = player_id
		data.player_name = "Player " + [
			"One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight",
			str(player_id+1)][min(player_id, 8)]
		data.lap_times = Array()
		var prev := 0
		for t in lap_stamps[player_id]:
			data.lap_times.append(t - prev)
			prev = t
		data.rank = ranks[player_id]
		if Global.player_count == 1:
			var info : MapsList.MapInfo = Global.maps_info.get(Global.race_map_scene_name)
			var progression : MapsList.MapProgression = Global.maps_progression.get(Global.race_map_scene_name)
			if info != null and progression != null:
				data.medals = info.medals_completed(progression)
				data.show_author_medal = data.medals[MapsList.MapInfo.Medal.AUTHOR]
		end_score_overlay.score_table.set_player_data(data)
	
	pause_overlay.allow_pause = false
	end_score_overlay.show()

func _reset_race() -> void:
	$ScreenFadeInOut.fade_out()
	yield($ScreenFadeInOut, "animation_finished")
	
	Global.change_scene_to_race()

func _exit_to_menu() -> void:
	$ScreenFadeInOut.fade_out()
	yield($ScreenFadeInOut, "animation_finished")
	
	Global.change_scene_to_main_menu()

func _on_RaceMap_checkpoint_area_entered(checkpoint_id, body):
	if state != State.Racing:
		return
	
	var player_id := players.find(body)
	if player_id == -1:
		printerr("Body is not a player")
		return

	if scores[player_id] >= max_score:
		return

	var checkpoint : CheckpointState = checkpoints[player_id]

	if not checkpoint.done[checkpoint_id]:
		checkpoint.done[checkpoint_id] = true
		checkpoint.count += 1
		(players[player_id] as CarDrift).save_reset_position()
		$CheckpointPlayer.play()
		emit_signal("checkpoints_changed", _make_checkpoint_count_array(), map.get_checkpoint_count())

func _on_RaceMap_start_area_entered(body):
	if state != State.Racing:
		return
	
	var player_id := players.find(body)
	if player_id == -1:
		printerr("Body is not a player")
		return
	
	var player : CarDrift = players[player_id]
	var checkpoint : CheckpointState = checkpoints[player_id]
	
	if checkpoint.count == map.get_checkpoint_count():
		$LapPlayer.play()
		scores[player_id] += 1
		emit_signal("scores_changed", scores)
		checkpoint.count = 0
		checkpoint.done.fill(false)
		emit_signal("checkpoints_changed", _make_checkpoint_count_array(), map.get_checkpoint_count())
		lap_stamps[player_id].append(elapsed_physics_frame)
		(players[player_id] as CarDrift).save_reset_position()
		if scores[player_id] == max_score:
			player.is_ghost = true
			if Global.player_count == 1:
				var record_path := RecordDataBase.generate_record_path(Global.race_map_scene_name)
				player.save_record(record_path)
				Global.update_map_progression(Global.race_map_scene_name, record_path)
			if not $VictoryAudio.playing:
				$VictoryAudio.play()
			if _all_car_have_finished():
				end_race()

func _all_car_have_finished() -> bool:
	for score in scores:
		if score < max_score:
			return false
	return true

func _get_elapsed_time() -> float:
	return float(elapsed_physics_frame) / ProjectSettings.get_setting("physics/common/physics_fps")

func _make_checkpoint_count_array() -> Array:
	var counts := []
	for c in checkpoints:
		counts.append(c.count)
	return counts
