extends PanelContainer

const IconUp := preload("res://resources/arrows/up.tres")
const IconDown := preload("res://resources/arrows/down.tres")
const IconLeft := preload("res://resources/arrows/left.tres")
const IconRight := preload("res://resources/arrows/right.tres")
const IconEnter := preload("res://resources/arrows/enter.tres")
const icon_keys := {
	KEY_UP: IconUp,
	KEY_DOWN: IconDown,
	KEY_LEFT: IconLeft,
	KEY_RIGHT: IconRight,
	KEY_ENTER: IconEnter,
	KEY_KP_ENTER: IconEnter,
}
const actions := ["up", "down", "left", "right", "reset"]

export var control_index := 0 setget set_control_index

onready var timer := $Timer as Timer
onready var labels := [
	$GridContainer/Up/Label,
	$GridContainer/Down/Label,
	$GridContainer/Left/Label,
	$GridContainer/Right/Label,
	$GridContainer/Reset/Label,
]
onready var texture_rects := [
	$GridContainer/Up/TextureRect,
	$GridContainer/Down/TextureRect,
	$GridContainer/Left/TextureRect,
	$GridContainer/Right/TextureRect,
	$GridContainer/Reset/TextureRect,
]
onready var init_offset := rect_position

func _ready() -> void:
	var _e := timer.connect("timeout", self, "on_timeout")
	$AnimationPlayer.playback_speed = 1.0 / 0.4

func _process(_delta : float) -> void:
	set_position(init_offset)
	var global_rect := get_global_rect()
	var margin := Vector2(10.0, 10.0)
	var min_pos := margin
	var max_pos := get_viewport_rect().size - margin - global_rect.size
	set_global_position(Vector2(
		clamp(global_rect.position.x, min_pos.x, max_pos.x),
		clamp(global_rect.position.y, min_pos.y, max_pos.y)))

func set_player_color(player_id : int) -> void:
	var style_box : StyleBoxFlat = get_stylebox("panel").duplicate()
	var color : Color = Global.player_colors[player_id]
	color.v *= 0.8
	style_box.border_color = color
	add_stylebox_override("panel", style_box)

func set_control_index(index : int) -> void:
	control_index = index
	var action_prefix := "player" + str(control_index + 1) + "_"
	for i in range(actions.size()):
		for e in InputMap.get_action_list(action_prefix + actions[i]):
			if e is InputEventKey:
				var key := e as InputEventKey
				var local_scancode := OS.keyboard_get_scancode_from_physical(key.physical_scancode)
				if local_scancode in icon_keys:
					labels[i].visible = false
					texture_rects[i].visible = true
					(texture_rects[i] as TextureRect).texture = icon_keys[local_scancode]
				else:
					labels[i].visible = true
					texture_rects[i].visible = false
					var s := OS.get_scancode_string(local_scancode)
					(labels[i] as Label).text = s.replace("Kp ", "")
					print(action_prefix + actions[i], ": ", e.physical_scancode, " [", s, "]")
				break # display only first
			else:
				print(action_prefix + actions[i], " not key event:", e)

func on_timeout() -> void:
	if visible:
		$AnimationPlayer.play("fade_out")
	else:
		$AnimationPlayer.play("fade_in")

func _input(_event : InputEvent) -> void:
	var action_prefix := "player" + str(control_index + 1) + "_"
	
	var action_pressed := false
	for a in actions:
		if Input.is_action_pressed(action_prefix + a):
			action_pressed = true
			break
	
	if action_pressed == visible:
		if timer.time_left == 0:
			timer.start()
	else:
		timer.stop()
