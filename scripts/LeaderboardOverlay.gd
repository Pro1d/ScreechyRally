extends CenterContainer

var loading_leaderboard_name := ""
var cached_rows := []

onready var title_label := $PanelContainer/VBoxContainer/TitleLabel as Control
onready var rank_template := $RankTemplate as Control
onready var rank_scroll := $PanelContainer/VBoxContainer/MarginContainer/VBoxContainer/ScrollContainer as ScrollContainer
onready var rank_list := rank_scroll.find_node("MarginContainer").find_node("VBoxContainer") as VBoxContainer
onready var loading_animation := $LoadingAnimation as Control
onready var empty_leaderboard_label := $EmptyLeaderboardLabel as Control
onready var close_button := $PanelContainer/VBoxContainer/MarginContainer/VBoxContainer/CloseButton as Button

func _ready() -> void:
	close_button.connect("pressed", self, "_on_close_button_pressed")
	SoundUI.connect_buttons(self)

func _exit_tree():
	_abort_loading()

func load_leaderboard(leaderboard_name: String) -> void:
	_abort_loading()
	_set_loading_animation_visibility(true)
	_set_empty_leaderboard_visibility(false)
	_set_rank_list_visibility(false)
	
	loading_leaderboard_name = leaderboard_name
	title_label.text = leaderboard_name
	SilentWolf.Scores.connect("sw_scores_received", self, "_on_scores_received", [], CONNECT_ONESHOT)
	SilentWolf.Scores.get_high_scores(100, leaderboard_name)

func _on_scores_received(leaderboard_name: String, scores: Array) -> void:
	_set_loading_animation_visibility(false)
	
	if leaderboard_name != loading_leaderboard_name or not (leaderboard_name in SilentWolf.Scores.leaderboards) or len(scores) == 0:
		_set_empty_leaderboard_visibility(true)
		_set_rank_list_visibility(false)
	else:
		var old_child_count := rank_list.get_child_count()
		for i in range(len(scores)):
			var player_name : String = scores[i].player_name
			var time : int = -scores[i].score
			var row := _create_rank_row( # re-use existing row
				i + 1, player_name, time, rank_list.get_child(i) if i < old_child_count else null
			)
			# add row if newly created
			if i >= old_child_count:
				rank_list.add_child(row)
		# show only valid row
		for i in range(rank_list.get_child_count()):
			rank_list.get_child(i).visible = i < len(scores)
		_set_empty_leaderboard_visibility(false)
		_set_rank_list_visibility(true)

func _abort_loading() -> void:
	if loading_leaderboard_name != "":
		loading_leaderboard_name = ""
		if SilentWolf.Scores.is_connected("sw_scores_received", self, "_on_scores_received"):
			SilentWolf.Scores.disconnect("sw_scores_received", self, "_on_scores_received")
		if SilentWolf.Scores.wrHighScores != null and SilentWolf.Scores.HighScores != null:
			SilentWolf.free_request(SilentWolf.Scores.wrHighScores, SilentWolf.Scores.HighScores)
		_set_loading_animation_visibility(false)
		_set_empty_leaderboard_visibility(true)
		_set_rank_list_visibility(false)

func _create_rank_row(rank: int, player_name: String, time: int, line = null) -> Control:
	var control: Control = rank_template.duplicate() if line == null else line
	control.visible = true
	var rank_suffix: String = "."#["st", "nd", "rd"][rank - 1] if rank <= 3 else ""
	(control.get_child(0) as Label).text = str(rank) + rank_suffix
	(control.get_child(1) as Label).text = player_name
	(control.get_child(2) as Label).text = Global.frames_to_string(time)
	# (control.get_child(0) as Label).modulate = Global.medal_icon_colors[rank - 1] if rank <= 3 else Color.white
	return control

func _set_empty_leaderboard_visibility(v: bool) -> void:
	empty_leaderboard_label.visible = v

func _set_loading_animation_visibility(v: bool) -> void:
	loading_animation.visible = v
	if v:
		loading_animation.find_node("AnimationPlayer").play("loading")
	else:
		loading_animation.find_node("AnimationPlayer").stop()

func _set_rank_list_visibility(v: bool) -> void:
	rank_list.visible = v
	if v:
		rank_scroll.scroll_vertical = 0

func _on_close_button_pressed() -> void:
	_abort_loading()
	hide()
