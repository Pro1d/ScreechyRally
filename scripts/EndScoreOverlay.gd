extends Control

var exit_to_menu_func : FuncRef
var reset_race_func : FuncRef

onready var score_table : ScoreTable = $PanelContainer/MarginContainer/VBoxContainer/ScoreTable

func _ready():
	var _e : int # Error
	var container := $PanelContainer/MarginContainer/VBoxContainer
	_e = container.get_node("RestartButton").connect("pressed", self, "_on_restart_pressed")
	_e = container.get_node("ExitButton").connect("pressed", self, "_exit_to_menu")

func _exit_to_menu() -> void:
	if exit_to_menu_func != null:
		exit_to_menu_func.call_func()

func _on_restart_pressed() -> void:
	if reset_race_func != null:
		reset_race_func.call_func()
