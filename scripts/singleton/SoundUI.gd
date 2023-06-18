extends Node

onready var pressed_player := $SoundUI/UIPressedPlayer
onready var hovered_player := $SoundUI/UIHoveredPlayer

onready var music_bus_index := AudioServer.get_bus_index("Music")

func _enter_tree():
	pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(preload("res://scenes/SoundUI.tscn").instance())

func connect_buttons(parent : Control) -> void:
	for child in parent.get_children():
		if (child as Button) != null:
			child.connect("pressed", pressed_player, "play")
			child.connect("mouse_entered", self, "_on_button_mouse_entered", [child])
		elif (child as Control) != null:
			connect_buttons(child)

func _on_button_mouse_entered(button : Button) -> void:
	if not button.disabled:
		hovered_player.play()

func update_music_button(button : Button) -> void:
	var mute := AudioServer.is_bus_mute(music_bus_index)
	if button.toggle_mode:
		button.pressed = not mute
	else:
		button.text = "Music " + ("off" if mute else "on")

func switch_music(button : Button = null) -> void:
	var mute := AudioServer.is_bus_mute(music_bus_index)
	AudioServer.set_bus_mute(music_bus_index, not mute)
	if button != null:
		update_music_button(button)
