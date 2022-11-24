extends Control

export(bool) var allow_pause := true

var exit_to_menu_func : FuncRef
var reset_race_func : FuncRef

func _enter_tree() -> void:
	visible = false

func _ready() -> void:
	var _e : int # Error
	var container := $PanelContainer/MarginContainer/VBoxContainer
	var music_button := container.get_node("MusicButton")
	_e = container.get_node("ResumeButton").connect("pressed", self, "_set_pause", [false])
	_e = container.get_node("RestartButton").connect("pressed", self, "_on_restart_pressed")
	_e = music_button.connect("pressed", SoundUI, "switch_music", [music_button])
	_e = container.get_node("ExitButton").connect("pressed", self, "_exit_to_menu")
	SoundUI.update_music_button(music_button)

func _input(_event : InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		var pause := not visible
		if allow_pause or not pause:
			_set_pause(pause)

func _set_pause(pause : bool) -> void:
	get_tree().paused = pause
	visible = pause

func _exit_to_menu() -> void:
	_set_pause(false)
	if exit_to_menu_func != null:
		exit_to_menu_func.call_func()

func _on_restart_pressed() -> void:
	_set_pause(false)
	if reset_race_func != null:
		reset_race_func.call_func()
