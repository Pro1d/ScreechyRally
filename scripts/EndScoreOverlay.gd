class_name EndScoreOverlaay
extends Control

var exit_to_menu_func : FuncRef
var reset_race_func : FuncRef

onready var score_table := $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScoreTable# as ScoreTable
onready var map_name := MapsList.map_file_to_map_name(Global.race_map_scene_name)

func _ready():
	var _e : int # Error
	var container := $CenterContainer/PanelContainer/MarginContainer/VBoxContainer
	_e = container.get_node("ScoreTable").connect("submit", self, "_on_submit")
	_e = container.get_node("LeaderboardButton").connect("pressed", self, "_on_ldboard_pressed")
	_e = container.get_node("RestartButton").connect("pressed", self, "_on_restart_pressed")
	_e = container.get_node("ExitButton").connect("pressed", self, "_exit_to_menu")
	if not Config.has_leaderboard():
		container.get_node("LeaderboardButton").hide()
	SoundUI.connect_buttons(self)
	$LeaderboardOverlay.connect("visibility_changed", self, "_on_leaderboard_visibility_changed")

func _on_submit(time: int, rank: int) -> void:
	$LeaderboardOverlay.submit_to_leaderboard(map_name, time, rank)
	$LeaderboardOverlay.show()

func _on_ldboard_pressed() -> void:
	$LeaderboardOverlay.load_leaderboard(map_name)
	$LeaderboardOverlay.show()

func _exit_to_menu() -> void:
	if exit_to_menu_func != null:
		exit_to_menu_func.call_func()

func _on_restart_pressed() -> void:
	if reset_race_func != null:
		reset_race_func.call_func()

func _on_leaderboard_visibility_changed() -> void:
	$CenterContainer.visible = not $LeaderboardOverlay.visible
