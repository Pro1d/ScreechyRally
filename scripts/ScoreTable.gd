class_name ScoreTable
extends CenterContainer

# warning-ignore:unused_signal
signal submit(time, rank)


class PlayerData:
	var player_id : int = 0
	var player_name : String = "???"
	var lap_times: Array = [0] # number of frame, 0=unknown
	var rank : int # 0=unknown
	var medals := [false, false, false, false]
	var show_author_medal := false
	var new_best_time := false
	var new_medals := [false, false, false, false]

enum RowMask {
	PLAYER_NAME = 1 << 0,
	LAP_TIMES = 1 << 1,
	BEST_LAP_TIME = 1 << 2,
	RACE_TIME = 1 << 3,
	RANK = 1 << 4,
	MEDALS = 1 << 5,
	LEADERBOARD = 1 << 6,
}

export(int, FLAGS, "player name", "lap times", "best lap time", "race time", "rank", "medals", "leaderboard") var row_mask := 0xffff setget _set_row_mask
export(int) var player_count := 1 setget _set_player_count

onready var _label_templates := {
	normal = $DataLabelTemplate/Normal,
	local_best = $DataLabelTemplate/LocalBest,
	global_best = $DataLabelTemplate/GlobalBest,
}
onready var _medals_template := $DataLabelTemplate/MedalContainer
onready var _data_control_templates := {
	name_label = $GridContainer/DataNameLabel,
	laps_vbox = $GridContainer/DataLapsVBox,
	best_lap_box = $GridContainer/DataBestLapBox,
	race_time_box = $GridContainer/DataRaceTimeBox,
	rank_label = $GridContainer/DataRankLabel,
	medals_box = $GridContainer/DataMedalsBox,
	leaderboard_container = $GridContainer/DataLeaderboardBox,
}
onready var _row_controls := {
	name_empty = $GridContainer/RowNameEmpty,
	laps_label = $GridContainer/RowLapsLabel,
	best_lap_label = $GridContainer/RowBestLapLabel,
	race_time_label = $GridContainer/RowRaceTimeLabel,
	rank_label = $GridContainer/RowRankLabel,
	medals_label = $GridContainer/RowMedalsLabel,
	leaderboard_label = $GridContainer/RowLeaderboardLabel,
}
onready var _row_controls_ordering := [
	_row_controls.name_empty,
	_row_controls.laps_label,
	_row_controls.best_lap_label,
	_row_controls.race_time_label,
	_row_controls.rank_label,
	_row_controls.medals_label,
	_row_controls.leaderboard_label,
]

func _ready() -> void:
	_update_row_visibility()
	if false:
		_set_player_count(2)
		yield(get_tree().create_timer(1.0), "timeout")
		var p1 := PlayerData.new()
		p1.player_id = 0
		p1.player_name = "PlayerOne"
		p1.lap_times = [600, 768, 750]
		p1.rank = 2
		p1.medals = [true, true, true, true]
		p1.new_medals = [false, false, true, true]
		p1.show_author_medal = true
		p1.new_best_time = false
		set_player_data(p1, "test")
		p1 = PlayerData.new()
		p1.player_id = 1
		p1.player_name = "PlayerTwo"
		p1.lap_times = [325, 453, 786]
		p1.rank = 1
		p1.medals = [true, false, false, false]
		p1.new_medals = [false, false, false, false]
		p1.show_author_medal = true
		p1.new_best_time = false
		set_player_data(p1, "test")

func set_player_data(data : PlayerData, map_name: String) -> void:
	# Fill table with data + setup animation
	var table := $GridContainer
	var row_index : int
	var child_index : int
	var tween := get_tree().create_tween()
	tween.tween_interval(0.5)
	var race_time := 0
	for t in data.lap_times:
		race_time += t
	
	if "name":
		row_index = _row_controls_ordering.find(_row_controls.name_empty)
		child_index = row_index * (player_count + 1) + (data.player_id + 1)
		var name_label : Label = table.get_child(child_index)
		name_label.text = data.player_name
	
	if "laps":
		row_index = _row_controls_ordering.find(_row_controls.laps_label)
		child_index = row_index * (player_count + 1) + (data.player_id + 1)
		var laps_vbox : VBoxContainer = table.get_child(child_index)
		for c in laps_vbox.get_children():
			laps_vbox.remove_child(c)
		for t in data.lap_times:
			var template : Label = _label_templates.local_best if t == data.lap_times.min() else _label_templates.normal
			var label : Label = template.duplicate()
			label.text = Global.frames_to_string(t)
			laps_vbox.add_child(label)
			if row_mask & RowMask.LAP_TIMES:
				label.modulate.a = 0.0
				tween.tween_property(label, "modulate:a", 1.0, 0.0)
				if data.player_id == 0:
					tween.tween_callback($TickAudioStreamPlayer, "play")
				tween.tween_callback(self, "_set_rect_pivot_offset", [label])
				tween.tween_property(label, "rect_scale", Vector2.ONE, 0.2) \
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
					.from(Vector2.ONE * 0.8)
				tween.tween_interval(0.2)
	
	if "best lap":
		row_index = _row_controls_ordering.find(_row_controls.best_lap_label)
		child_index = row_index * (player_count + 1) + (data.player_id + 1)
		var box : Control = table.get_child(child_index)
		for c in box.get_children():
			box.remove_child(c)
		var label : Label = _label_templates.normal.duplicate()
		label.text = Global.frames_to_string(data.lap_times.min() if data.lap_times else -1)
		box.add_child(label)
		if row_mask & RowMask.BEST_LAP_TIME:
			label.modulate.a = 0.0
			tween.tween_property(label, "modulate:a", 1.0, 0.0)
			if data.player_id == 0:
				tween.tween_callback($TickAudioStreamPlayer, "play")
			tween.tween_callback(self, "_set_rect_pivot_offset", [label])
			tween.tween_property(label, "rect_scale", Vector2.ONE, 0.2) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
				.from(Vector2.ONE * 0.8)
			tween.tween_interval(0.2)
	
	if "race time":
		row_index = _row_controls_ordering.find(_row_controls.race_time_label)
		child_index = row_index * (player_count + 1) + (data.player_id + 1)
		var box : Control = table.get_child(child_index)
		for c in box.get_children():
			box.remove_child(c)
		var label : Label = _label_templates.normal.duplicate()
		label.text = Global.frames_to_string(race_time if race_time else -1)
		box.add_child(label)
		if row_mask & RowMask.RACE_TIME:
			label.modulate.a = 0.0
			tween.tween_callback(self, "_set_rect_pivot_offset", [label])
			if data.new_best_time:
				tween.tween_property(label, "rect_scale", Vector2.ONE, 1.0) \
					.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC) \
					.from(Vector2.ONE * 2.5)
				tween.parallel().tween_property(label, "modulate:a", 1.0, 1.0) \
					.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO) \
					.from(0.0)
				tween.tween_callback($HitAudioStreamPlayer, "play")
			else:
				tween.tween_property(label, "modulate:a", 1.0, 0.0)
				if data.player_id == 0:
					tween.tween_callback($TickAudioStreamPlayer, "play")
				tween.tween_property(label, "rect_scale", Vector2.ONE, 0.2) \
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
					.from(Vector2.ONE * 0.8)
				tween.tween_interval(0.2)
	
	if "rank":
		row_index = _row_controls_ordering.find(_row_controls.rank_label)
		child_index = row_index * (player_count + 1) + (data.player_id + 1)
		var rank_label : Label = table.get_child(child_index)
		rank_label.text = _rank_to_string(data.rank)
		if row_mask & RowMask.RANK:
			rank_label.rect_pivot_offset = rank_label.rect_size / 2
			rank_label.modulate = (
				Global.medal_icon_colors[3 - data.rank]
				if 1 <= data.rank and data.rank <= 3
				else Color.whitesmoke
			)
			rank_label.modulate.a = 0.0
			var factor := 0.0
			var delay := 0.0
			for i in range(data.rank):
				delay += factor * 1.0
				factor = lerp(1.0, 0.5, pow(inverse_lerp(1, player_count, i + 1), 0.5))
			var duration := factor * 1.0
			var end_delay := 0.0
			var factor2 := 0.0
			for i in range(data.rank, player_count + 1):
				end_delay += factor2 * 1.0
				factor2 = lerp(1.0, 0.5, pow(inverse_lerp(1, player_count, i + 1), 0.5))
			tween.tween_interval(delay)
			tween.tween_callback(self, "_set_rect_pivot_offset", [rank_label])
			tween.tween_property(rank_label, "rect_scale", Vector2.ONE, duration) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC) \
				.from(Vector2.ONE * factor * 5.0)
			tween.parallel().tween_property(rank_label, "modulate:a", 1.0, duration) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
			tween.tween_callback($HitAudioStreamPlayer, "play")
			tween.parallel().tween_interval(end_delay + 0.5)
	
	if "medals":
		row_index = _row_controls_ordering.find(_row_controls.medals_label)
		child_index = row_index * (player_count + 1) + (data.player_id + 1)
		var box : Control = table.get_child(child_index)
		for c in box.get_children():
			box.remove_child(c)
		for i in range(MapsList.MapInfo.Medal.COUNT):
			var m := _medals_template.get_child(i).duplicate() as CheckBox
			m.pressed = data.medals[i]
			box.add_child(m)
			if row_mask & RowMask.MEDALS:
				m.modulate.a = 0.0
				if data.medals[i]:
					tween.tween_property(m, "modulate:a", 1.0, 0.0)
					tween.tween_callback(self, "_set_rect_pivot_offset", [m])
					if data.new_medals[i]:
						tween.tween_property(m, "rect_scale", Vector2.ONE, 1.0) \
							.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC) \
							.from(Vector2.ONE * 3.0)
						tween.parallel().tween_property(m, "modulate:a", 1.0, 1.0) \
							.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC) \
							.from(0.0)
						tween.tween_callback($TlingAudioStreamPlayer, "set_volume_db", [3.0])
						tween.tween_callback($TlingAudioStreamPlayer, "set_pitch_scale", [1.0])
						tween.tween_callback($TlingAudioStreamPlayer, "play", [0.035])
						tween.parallel().tween_callback($HitAudioStreamPlayer, "play")
					else:
						tween.tween_callback($TlingAudioStreamPlayer, "set_volume_db", [-8.0])
						tween.tween_callback($TlingAudioStreamPlayer, "set_pitch_scale", [0.8])
						tween.tween_callback($TlingAudioStreamPlayer, "play", [0.000035])
						tween.tween_property(m, "rect_scale", Vector2.ONE, 0.4) \
							.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
							.from(Vector2.ONE * 0.5)
				else:
					(tween if i == 0 else tween.parallel()).tween_property(m, "modulate:a", 1.0, 0.3).from(0.0)
		box.get_child(MapsList.MapInfo.Medal.AUTHOR).visible = data.show_author_medal
	
	if "leaderboard":
		row_index = _row_controls_ordering.find(_row_controls.leaderboard_label)
		child_index = row_index * (player_count + 1) + (data.player_id + 1)
		var box : Control = table.get_child(child_index)
		box.get_child(1).visible = false
		if row_mask & RowMask.LEADERBOARD:
			_leaderboard_loading_row(box, race_time, map_name)
			box.modulate.a = 0.0
			tween.tween_property(box, "modulate:a", 1.0, 0.0)
			tween.parallel().tween_property(box.get_child(0), "playing", true, 0.1)
	
	tween.play()

func _set_rect_pivot_offset(control: Control) -> void:
	control.rect_pivot_offset = control.rect_size / 2

func _set_player_count(count : int) -> void:
	assert(count > 0)
	if player_count != count:
		$GridContainer.columns = count + 1
		_change_column_count(player_count, count)
		player_count = count
		var align := Label.ALIGN_LEFT if player_count == 1 else Label.ALIGN_CENTER
		_change_data_label_align(self, align)

func _change_column_count(from : int, to : int) -> void:
	var table := $GridContainer
	var child_index := 0
	for row_index in range(len(_row_controls_ordering)):
		assert(table.get_child(child_index) == _row_controls_ordering[row_index])
		child_index += 1
		var template := table.get_child(child_index)
		for i in range(from):
			if i >= to:
				table.remove_child(table.get_child(child_index))
			else:
				child_index += 1
		if to > from:
			for _i in range(to - from):
				table.add_child_below_node(table.get_child(child_index - 1), template.duplicate())
				child_index += 1

func _change_data_label_align(parent : Control, align : int) -> void:
	for c in parent.get_children():
		if c is Label and _row_controls_ordering.find(c) < 0:
			c.align = align
		if c is Control:
			_change_data_label_align(c, align)

func _set_row_mask(mask : int) -> void:
	if mask != row_mask:
		row_mask = mask
		_update_row_visibility()

func _has_row(row_index: int) -> bool:
	return (row_mask & (1 << row_index)) != 0

func _update_row_visibility() -> void:
	if _row_controls_ordering == null:
		return
	var table := $GridContainer
	var child_index := 0
	for row_index in range(_row_controls_ordering.size()):
		assert(table.get_child(child_index) == _row_controls_ordering[row_index])
		var row_visible : bool = _has_row(row_index)
		for _i in range(player_count + 1):
			table.get_child(child_index).visible = row_visible
			child_index += 1

func _leaderboard_loading_row(view: Control, time: int, map_name: String) -> void:
	# Load expected rank of new time
	var leaderboard_name := SWLeaderboard.leaderboard_name_from_map_name(map_name)
	SilentWolf.Scores.get_score_position(-time, leaderboard_name)
	SilentWolf.Scores.connect(
		"sw_position_received",
		self,
		"_on_score_position_received",
		[view, time, map_name],
		CONNECT_ONESHOT
	)
	# Show loading animation
	var anim := view.get_child(0) as LoadingAnimation
	anim.playing = false  # started by the set_player_data's animation
	anim.visible = true
	var container := view.get_child(1) as Container
	container.visible = false

func _on_score_position_received(
	score_position: int, view: Control, time: int, map_name: String
) -> void:
	var rank := score_position + 1
	# Show rank and submit button
	var anim := view.get_child(0) as LoadingAnimation
	anim.playing = false
	anim.visible = false
	var container := view.get_child(1) as Container
	container.visible = true
	(container.get_child(0) as Label).text = _rank_to_string(rank)
	var leaderboard_name := SWLeaderboard.leaderboard_name_from_map_name(map_name)
	var allow_new_submit := (
		not SWLeaderboard.has_leaderboard_submission(leaderboard_name)
		or time < (SWLeaderboard.get_leaderboard_submission(leaderboard_name).time as int)
	)
	var submit_button := container.get_child(1) as Button
	submit_button.disabled = not allow_new_submit
	if submit_button.is_connected("pressed", self, "emit_signal"):
		submit_button.disconnect("pressed", self, "emit_signal")
	submit_button.connect(
		"pressed",
		self,
		"emit_signal",
		["submit", time, rank]
	)

func _rank_to_string(rank: int) -> String:
	return str(rank) + ["st", "nd", "rd", "th"][min(rank - 1, 3)]
