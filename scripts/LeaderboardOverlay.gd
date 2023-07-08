extends Control

enum State {NONE, LOADING_LEADERBOARD, SUBMIT_FORM, SUBMITTING, DELETING_PREV_SUBMISSION}
enum Visible {LOADING, EMPTY, RANK, SUBMIT}
var leaderboard_name := ""
var state : int = State.NONE
var submit_form := {"time": 0, "rank": -1}

onready var title_label := $VCenter/HCenter/PanelContainer/PanelLayout/TitleLabel as Control
onready var rank_template := $RankTemplate as Control
onready var rank_scroll := $VCenter/HCenter/PanelContainer/PanelLayout/ContentMargin/ContentLayout/Container/RankingScroll as ScrollContainer
onready var rank_list := rank_scroll.find_node("RankingMargin").find_node("RankingList") as Container
onready var loading_animation := $VCenter/HCenter/PanelContainer/PanelLayout/ContentMargin/ContentLayout/Container/LoadingAnimation as LoadingAnimation
onready var empty_leaderboard_label := $VCenter/HCenter/PanelContainer/PanelLayout/ContentMargin/ContentLayout/Container/EmptyLeaderboardLabel as Control
onready var close_button := $VCenter/HCenter/PanelContainer/PanelLayout/ContentMargin/ContentLayout/CloseButton as Button
onready var submit_container := $VCenter/HCenter/PanelContainer/PanelLayout/ContentMargin/ContentLayout/SubmitContainer as Container
onready var name_edit := submit_container.find_node("NameEdit") as LineEdit
onready var submit_button := submit_container.find_node("SubmitButton") as Button
onready var submission_preview := $VCenter/HCenter/PanelContainer/PanelLayout/ContentMargin/ContentLayout/Container/SubmissionPreview as Container

func _ready() -> void:
	close_button.connect("pressed", self, "_on_close_button_pressed")
	submit_container.hide()
	name_edit.connect("text_changed", self, "_on_name_changed")
	submit_button.connect("pressed", self, "_on_submit_button_pressed")
	SilentWolf.Scores.connect("sw_scores_received", self, "_on_scores_received")
	SilentWolf.Scores.connect("sw_score_posted", self, "_on_score_posted")
	SilentWolf.Scores.connect("sw_score_deleted", self, "_on_score_deleted")

func _exit_tree():
	_abort_loading()

###### LEADERBOARD LIST ######

func load_leaderboard(map_name: String) -> void:
	_abort_loading()
	_set_leaderboard_name(map_name)
	_set_visibility(Visible.LOADING)
	SilentWolf.Scores.get_high_scores(100, leaderboard_name)
	state = State.LOADING_LEADERBOARD

func _on_scores_received(lb_name: String, scores: Array) -> void:
	if state != State.LOADING_LEADERBOARD:
		return
	state = State.NONE
	if lb_name != leaderboard_name or not (lb_name in SilentWolf.Scores.leaderboards) or len(scores) == 0:
		_set_visibility(Visible.EMPTY)
	else:
		var old_child_count := rank_list.get_child_count()
		var player_index := -1
		var player_score_id := (
			SWLeaderboard.get_leaderboard_submission(lb_name).score_id as String
			if SWLeaderboard.has_leaderboard_submission(lb_name)
			else ""
		)
		for i in range(len(scores)):
			if scores[i].score_id == player_score_id:
				player_index = i
			var player_name : String = scores[i].player_name
			var time : int = -scores[i].score
			var row := _create_rank_row( # re-use existing row
				i + 1,
				player_name,
				time,
				rank_list.get_child(i) if i < old_child_count else null,
				player_index == i
			)
			# add row if newly created
			if i >= old_child_count:
				rank_list.add_child(row)
		# show only valid row
		for i in range(rank_list.get_child_count()):
			rank_list.get_child(i).visible = i < len(scores)
		_set_visibility(Visible.RANK)
		
		if player_index >= 0:
			yield(get_tree(), "idle_frame")
			rank_scroll.ensure_control_visible(rank_list.get_child(player_index))
		yield(get_tree(), "idle_frame")
		var sep := rank_list.get_constant("separation") as int
		var real_max_value := rank_scroll.scroll_vertical - rank_scroll.rect_size.y
		print("TODO center score", " ",
			rank_scroll.get_v_scrollbar().min_value, " ",
			rank_scroll.get_v_scrollbar().max_value, " ",
			rank_scroll.get_v_scrollbar().value, " ",
			real_max_value, " ",
			rank_scroll.rect_size.y, " ",
			rank_template.rect_size.y, " ",
			sep, " ",
			len(scores) * (sep + rank_template.rect_size.y) - sep
		)

###### SUBMIT BEST TIME ######

func submit_to_leaderboard(map_name: String, time: int, rank: int = -1) -> void:
	_abort_loading()
	_set_leaderboard_name(map_name)
	_set_visibility(Visible.SUBMIT)
	if SWLeaderboard.get_player_name() == "":
		name_edit.text = ""
		name_edit.grab_focus()
	else:
		name_edit.text = SWLeaderboard.get_player_name()
		name_edit.editable = false
	_update_submit_button()
	submit_form["time"] = time
	submit_form["rank"] = rank
	_create_rank_row(
		submit_form["rank"],
		SWLeaderboard.get_player_name(),
		submit_form["time"],
		submission_preview
	)
	state = State.SUBMIT_FORM

func _on_name_changed(text: String) -> void:
	_update_submit_button()
	_create_rank_row(submit_form["rank"], text, submit_form["time"], submission_preview)

func _update_submit_button() -> void:
	submit_button.disabled = (len(name_edit.text) < 3)

func _on_submit_button_pressed() -> void:
	if state != State.SUBMIT_FORM:
		return
	SWLeaderboard.save_player_name(name_edit.text)
	name_edit.editable = false
	submit_button.disabled = true
	SilentWolf.Scores.persist_score(
		SWLeaderboard.get_player_name(), -submit_form["time"], leaderboard_name
	)
	state = State.SUBMITTING
	_set_loading_animation_visibility(true)

func _on_score_posted(score_id: String) -> void:
	if state != State.SUBMITTING:
		return
	if SWLeaderboard.has_leaderboard_submission(leaderboard_name):
		var prev_submission := SWLeaderboard.get_leaderboard_submission(leaderboard_name)
		SilentWolf.Scores.delete_score(prev_submission.score_id)
		state = State.DELETING_PREV_SUBMISSION
	var submission := SWLeaderboard.make_leaderboard_submission(score_id, submit_form["time"])
	SWLeaderboard.save_leaderboard_submission(leaderboard_name, submission)
	if state == State.SUBMITTING:
		_finalize_submission()

func _on_score_deleted() -> void:
	if state != State.DELETING_PREV_SUBMISSION:
		return
	_finalize_submission()

func _finalize_submission() -> void:
	state = State.NONE
	load_leaderboard(leaderboard_name)

####### Common ######

func _create_rank_row(
	rank: int, player_name: String, time: int, line = null, highlight: bool = false
) -> Control:
	var control: Control = rank_template.duplicate() if line == null else line
	control.visible = true
	if rank > 0:
		var rank_suffix: String = "."#["st", "nd", "rd"][rank - 1] if rank <= 3 else ""
		(control.get_child(0) as Label).text = str(rank) + rank_suffix
	else:
		(control.get_child(0) as Label).text = "???"
	(control.get_child(1) as Label).text = player_name
	(control.get_child(2) as Label).text = Global.frames_to_string(time)
	if control != submission_preview:
		control.modulate = submission_preview.modulate if highlight else Color.white
	# (control.get_child(0) as Label).modulate = Global.medal_icon_colors[rank - 1] if rank <= 3 else Color.white
	return control

func _abort_loading() -> void:
	match state:
		State.LOADING_LEADERBOARD:
			state = State.NONE
			if SilentWolf.Scores.wrHighScores != null and SilentWolf.Scores.HighScores != null:
				SilentWolf.free_request(SilentWolf.Scores.wrHighScores, SilentWolf.Scores.HighScores)
			_set_visibility(Visible.EMPTY)
		State.LOADING_LEADERBOARD:
			state = State.NONE
			if SilentWolf.Scores.wrPostScore != null and SilentWolf.Scores.PostScore != null:
				SilentWolf.free_request(SilentWolf.Scores.wrPostScore, SilentWolf.Scores.PostScore)
			_set_visibility(Visible.EMPTY)

func _set_visibility(v: int) -> void:
	_set_loading_animation_visibility(v == Visible.LOADING)
	_set_empty_leaderboard_visibility(v == Visible.EMPTY)
	_set_rank_list_visibility(v == Visible.RANK)
	_set_submission_visibility(v == Visible.SUBMIT)

func _set_empty_leaderboard_visibility(v: bool) -> void:
	empty_leaderboard_label.visible = v

func _set_loading_animation_visibility(v: bool) -> void:
	loading_animation.visible = v
	loading_animation.playing = v

func _set_rank_list_visibility(v: bool) -> void:
	rank_scroll.visible = v
	if v:
		rank_scroll.scroll_vertical = 0

func _set_submission_visibility(v: bool) -> void:
	submission_preview.visible = v
	submit_container.visible = v

func _set_leaderboard_name(map_name: String) -> void:
	leaderboard_name = SWLeaderboard.leaderboard_name_from_map_name(map_name)
	title_label.text = map_name

func _on_close_button_pressed() -> void:
	_abort_loading()
	hide()
