extends Control

onready var leaderboard_line_edit := $VBoxContainer/MarginContainer/HBoxContainer/LeaderboardEdit as LineEdit
onready var player_line_edit := $VBoxContainer/MarginContainer/HBoxContainer/PlayerEdit as LineEdit
onready var time_spin_box := $VBoxContainer/MarginContainer/HBoxContainer/TimeSpinBox as SpinBox
onready var log_label := $VBoxContainer/PanelContainer/ScrollContainer/VBoxContainer/Label as Label


func _ready():
	$VBoxContainer/MarginContainer/HBoxContainer/ShowButton.connect("pressed", self, "_on_show_pressed")
	$VBoxContainer/MarginContainer/HBoxContainer/AddScoreButton.connect("pressed", self, "_on_add_score")
	$VBoxContainer/MarginContainer/HBoxContainer/DumpButton.connect("pressed", self, "_on_dump_pressed")
	$VBoxContainer/MarginContainer/HBoxContainer/RandomButton.connect("pressed", self, "_on_randomize_pressed")
	$VBoxContainer/MarginContainer/HBoxContainer/ClearButton.get_popup().connect("id_pressed", self, "_on_clear_pressed")
	SilentWolf.Scores.connect("sw_score_posted", self, "_on_score_posted")
	SilentWolf.Scores.connect("sw_scores_received", self, "_on_scores_received")
	SilentWolf.Scores.connect("sw_leaderboard_wiped", self, "_on_wipe_finished")

func _on_show_pressed() -> void:
	var ld_name := leaderboard_line_edit.text
	$LeaderboardOverlay.load_leaderboard(ld_name)
	$LeaderboardOverlay.show()

func _on_dump_pressed() -> void:
	var ld_name := leaderboard_line_edit.text
	print_log(["Loading: ", ld_name])
	SilentWolf.Scores.get_high_scores(0, ld_name)

func _on_add_score() -> void:
	var ld_name := leaderboard_line_edit.text
	var p_name := player_line_edit.text
	var time := int(time_spin_box.value)
	var score := -time
	print_log(["Add score: ", ld_name, " ", p_name, " ", score])
	SilentWolf.Scores.persist_score(p_name, score, ld_name)

func _on_score_posted(score_id=null) -> void:
	print_log(["Successfully posted score: ", score_id])

func _on_scores_received(ld_name: String, scores: Array) -> void:
	print_log(["Successfully loaded scores: ", ld_name, " - ", len(scores), " entries:"])
	for i in range(len(scores)):
		print_log([i+1, " ", scores[i].player_name, " ", scores[i].score, " -- ", scores[i]])

func _on_randomize_pressed() -> void:
	player_line_edit.text = str(randf()).md5_text().substr(0, 8)
	time_spin_box.value = randi() % 1000

func _on_clear_pressed(_id: int) -> void:
	var ld_name := leaderboard_line_edit.text
	print_log(["Wipe: ", ld_name])
	SilentWolf.Scores.wipe_leaderboard(ld_name)

func _on_wipe_finished() -> void:
	print_log(["Wipe successful"])

func print_log(array : Array, endl : bool = true) -> void:
	var string := ""
	for obj in array:
		string += str(obj)
	if endl:
		string += "\n"
	log_label.text += string
