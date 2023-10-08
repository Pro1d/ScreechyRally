extends PanelContainer

const IconUp := preload("res://resources/icons/up.tres")
const IconDown := preload("res://resources/icons/down.tres")
const IconLeft := preload("res://resources/icons/left.tres")
const IconRight := preload("res://resources/icons/right.tres")
const IconEnter := preload("res://resources/icons/enter.tres")
const JoypadIcon := preload("res://resources/icons/joypad.tres")
const icon_keys := {
	KEY_UP: IconUp,
	KEY_DOWN: IconDown,
	KEY_LEFT: IconLeft,
	KEY_RIGHT: IconRight,
	KEY_ENTER: IconEnter,
	KEY_KP_ENTER: IconEnter,
}
const actions := ["up", "down", "left", "right", "reset"]
var control_options := [
	[true, OS.get_scancode_string(OS.keyboard_get_scancode_from_physical(KEY_W))+OS.get_scancode_string(OS.keyboard_get_scancode_from_physical(KEY_A))+'SD'],
	[true, 'Arrows'],
	#[true, 3, 'Num Pad'],
	[true, 'Ergo'],
	#[true, 5, 'OKLM'],
	[false, 'Joypad 1'],
	[false, 'Joypad 2'],
]
const joypad_mapping := ["RT", "LT", KEY_LEFT, KEY_RIGHT, "B"]

export var player_index := 0 setget set_player_index

onready var timer := $Timer as Timer
onready var up_container := $GridContainer/Up as PanelContainer
var up_container_tween : SceneTreeTween
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
onready var keyboard_icon = $GridContainer/OptionButton.icon

func _ready() -> void:
	var _e := timer.connect("timeout", self, "_on_timeout")
	$AnimationPlayer.playback_speed = 1.0 / 0.4
	assert(control_options.size() == ControlManager.control_count())
	for c in control_options:
		if c[0]:
			$GridContainer/OptionButton.add_icon_item(keyboard_icon, c[1])
		else:
			$GridContainer/OptionButton.add_icon_item(JoypadIcon, c[1])
	_e = $GridContainer/OptionButton.connect("item_selected", self, "_on_control_selected")
	_e = ControlManager.connect("control_assignment_changed", self, "_on_control_assignment_changed")
	SoundUI.connect_buttons(self)
	
	# Press forward animation hint
	var style_box_default := up_container.get_stylebox("panel") as StyleBoxFlat
	var style_box_pressed := style_box_default.duplicate() as StyleBoxFlat
	style_box_pressed.bg_color = lerp(style_box_pressed.bg_color, Color.white, 0.5)
	style_box_pressed.border_color = lerp(style_box_pressed.border_color, Color.white, 0.5)
	var tween := create_tween()
	tween.tween_callback(up_container, "add_stylebox_override", ["panel", style_box_default])
	tween.tween_interval(2.0)
	tween.tween_callback(up_container, "add_stylebox_override", ["panel", style_box_pressed])
	tween.tween_interval(0.8)
	tween.set_loops()
	up_container_tween = tween

func _process(_delta : float) -> void:
	set_position(init_offset)
	var global_rect := get_global_rect()
	var margin := Vector2(10.0, 10.0)
	var min_pos := margin
	var max_pos := get_viewport_rect().size - margin - global_rect.size
	set_global_position(Vector2(
		clamp(global_rect.position.x, min_pos.x, max_pos.x),
		clamp(global_rect.position.y, min_pos.y, max_pos.y)))

func _input(_event : InputEvent) -> void:
	var control_index := ControlManager.player_assignment(player_index)
	if control_index == ControlManager.NOT_FOUND:
		return
	var action_prefix := ControlManager.action_prefix(control_index )
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

func _on_timeout() -> void:
	if visible:
		$AnimationPlayer.play("fade_out")
		up_container_tween.stop()
	else:
		$AnimationPlayer.play("fade_in")

func set_player_index(p_idx : int) -> void:
	player_index = p_idx
	var control_index := ControlManager.player_assignment(player_index)
	$GridContainer/OptionButton.select(control_index)
	_update_control_availability()
	_override_option_button_display()
	_update_keys_display()
	_update_player_color()

func _update_player_color() -> void:
	var style_box : StyleBoxFlat = get_stylebox("panel").duplicate()
	var color : Color = Global.player_colors[player_index]
	color.v *= 0.8
	style_box.border_color = color
	add_stylebox_override("panel", style_box)

func _update_control_availability() -> void:
	for i in range(ControlManager.control_count()):
		$GridContainer/OptionButton.set_item_disabled(i, not ControlManager.is_available(i, player_index))

func _update_keys_display() -> void:
	var control_index := ControlManager.player_assignment(player_index)
	var action_prefix := ControlManager.action_prefix(control_index)
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
					(labels[i] as Label).text = s.replace("Kp ", "").replace("Comma", ",").replace("Semicolon", ";")
				break # display only first
			else:
				if joypad_mapping[i] is int:
					labels[i].visible = false
					texture_rects[i].visible = true
					(texture_rects[i] as TextureRect).texture = icon_keys[joypad_mapping[i]]
				else:
					labels[i].visible = true
					texture_rects[i].visible = false
					(labels[i] as Label).text = joypad_mapping[i]

func _override_option_button_display() -> void:
	$GridContainer/OptionButton.text = ""
	var control_index := ControlManager.player_assignment(player_index)
	$GridContainer/OptionButton.icon = keyboard_icon if control_options[control_index][0] else JoypadIcon

func _on_control_selected(control_index : int):
	ControlManager.assign(control_index, player_index)
	_override_option_button_display()

func _on_control_assignment_changed(_player_index : int, _prev_control_index : int, _new_control_index : int) -> void:
	if _player_index == player_index:
		_update_keys_display()
	_update_control_availability()
