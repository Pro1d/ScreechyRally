extends Control

const CarControlToolTip = preload("res://scenes/UI/CarControlToolTip.tscn")

enum Menu {Main, MapSelection}

onready var main_menu := $Main
onready var main_play_single := $Main/VBoxContainer/SingleButton
onready var main_play_multi := $Main/VBoxContainer/MultiButton
onready var main_music := $Main/VBoxContainer/MusicButton
onready var main_quit := $Main/VBoxContainer/QuitButton
onready var map_selection_menu := $MapSelection
onready var map_selection_list := $MapSelection/ScrollContainer/CenterContainer/MarginContainer/GridContainer
onready var map_selection_play := $MapSelection/VBoxContainer/PlayButton
onready var map_selection_ranking := $MapSelection/VBoxContainer/RankingButton
onready var map_selection_back := $MapSelection/VBoxContainer/BackButton
onready var leaderboard_overlay := $LeaderboardOverlay

# Called when the node enters the scene tree for the first time.
func _ready():
	var _e : int # Error enum
	_e = main_play_single.connect("pressed", self, "_on_main_play_single_pressed")
	_e = main_play_multi.connect("pressed", self, "_on_main_play_multi_pressed")
	_e = main_music.connect("pressed", SoundUI, "switch_music", [main_music])
	_e = main_quit.connect("pressed", self, "_on_main_quit_pressed")
	_e = map_selection_back.connect("pressed", self, "_on_map_selection_back_pressed")
	if Config.has_leaderboard():
		_e = map_selection_ranking.connect("pressed", self, "_on_map_selection_ranking_pressed")
		map_selection_ranking.show()
	_e = map_selection_play.connect("pressed", self, "_on_map_selection_play_pressed")
	_e = get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	
	if OS.has_feature("HTML5"):
		main_quit.hide()
	
	_on_viewport_size_changed()
	_build_map_selection_list()
	SoundUI.connect_buttons(self)
	SoundUI.update_music_button(main_music)
	_change_menu(main_menu)
	
	for car in [$CarDrift, $CarDrift2]:
		car.save_reset_position()
		car.color = Global.player_colors[car.player_id]
		car.rotation_degrees = rand_range(0, 360)
		# Add control tooltip anchor to new canvas layer
		var remote_anchor := Node2D.new()
		$TooltipCanvasLayer.add_child(remote_anchor)
		# Connect remote anchor to car's control anchor
		var remote_transform := RemoteTransform2D.new()
		car.get_control_anchor().add_child(remote_transform)
		remote_transform.remote_path = remote_anchor.get_path()
		remote_transform.use_global_coordinates = true
		# Instantiate control tooltip as child of remote anchor
		var control_tooltip := CarControlToolTip.instance()
		remote_anchor.add_child(control_tooltip)
		control_tooltip.player_index = car.player_id
	
	$ScreenFadeInOut.fade_in()

func _build_map_selection_list() -> void:
	var model := map_selection_list.get_child(0) as CheckBox
	var medal_models := [
		map_selection_list.get_child(1),
		map_selection_list.get_child(2),
		map_selection_list.get_child(3),
		map_selection_list.get_child(4)
	]
	var map_list := MapsList.get_maps_list()
	var maps_info : Dictionary = Global.maps_info
	var maps_progression : Dictionary = Global.maps_progression
	for scene_file in map_list:
		var checkbox := model.duplicate() as CheckBox
		checkbox.text = MapsList.map_file_to_map_name(scene_file)
		var _e := checkbox.connect("pressed", Global, "set_race_map_scene_name", [scene_file])
		_e = checkbox.connect("button_up", self, "_on_race_map_clicked", [scene_file])
		map_selection_list.add_child(checkbox)
		var info : MapsList.MapInfo = maps_info.get(scene_file)
		var progression : MapsList.MapProgression = maps_progression.get(scene_file)
		var completed := info.medals_completed(progression) if info != null else [0,0,0,0]
		for i in range(MapsList.MapInfo.Medal.COUNT):
			var cb = medal_models[i].duplicate()
			cb.modulate.a = 0.0
			if info != null:
				var medal : RecordDataBase.Record = info.target_medals[i]
				if medal != null and not medal.path.empty():
					cb.modulate.a = 1.0
					if completed[i]:
						cb.pressed = true
					elif i == MapsList.MapInfo.Medal.AUTHOR and not completed[MapsList.MapInfo.Medal.GOLD]:
						cb.modulate.a = 0.0
			map_selection_list.add_child(cb)
	
	map_selection_list.remove_child(model)
	for m in medal_models:
		map_selection_list.remove_child(m)
	(map_selection_list.get_child(0) as CheckBox).pressed = true
	Global.race_map_scene_name = map_list[0]

func _on_viewport_size_changed() -> void:
	var actual_size := get_viewport().size * ($Camera2D as Camera2D).zoom
	$ScreenBorderBody/CollisionShapeRight.position.x = actual_size.x
	$ScreenBorderBody/CollisionShapeBottom.position.y = actual_size.y

func _on_main_play_single_pressed() -> void:
	Global.player_count = 1
	_change_menu(map_selection_menu)

func _on_main_play_multi_pressed() -> void:
	Global.player_count = 2
	_change_menu(map_selection_menu)

func _on_main_quit_pressed() -> void:
	$ScreenFadeInOut.fade_out()
	yield($ScreenFadeInOut, "animation_finished")
	get_tree().quit()

func _on_map_selection_back_pressed() -> void:
	_change_menu(main_menu)

func _on_map_selection_ranking_pressed() -> void:
	var map_name := MapsList.map_file_to_map_name(Global.race_map_scene_name)
	leaderboard_overlay.load_leaderboard(map_name)
	leaderboard_overlay.show()

func _on_map_selection_play_pressed() -> void:
	$ScreenFadeInOut.fade_out()
	var _e = $ScreenFadeInOut.connect(
		"animation_finished",
		Global,
		"change_scene_to_race",
		[],
		CONNECT_ONESHOT)

var __last_scene_file_name_clicked := ""
var __last_scene_file_name_clicked_time := 0.0
const __double_click_delay := 0.3  # sec

func _on_race_map_clicked(scene_file_name: String) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	if (
		scene_file_name == __last_scene_file_name_clicked and
		time - __last_scene_file_name_clicked_time < __double_click_delay
	):
			_on_map_selection_play_pressed()
	__last_scene_file_name_clicked = scene_file_name
	__last_scene_file_name_clicked_time = time

func _change_menu(menu : Control) -> void:
	map_selection_menu.hide()
	main_menu.hide()
	menu.show()
