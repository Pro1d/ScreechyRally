extends PanelContainer

const actions := ["up", "down", "left", "right"]

export var control_index := 0 setget set_control_index

onready var timer := $Timer as Timer
onready var labels := [
	$GridContainer/Up/Label,
	$GridContainer/Down/Label,
	$GridContainer/Left/Label,
	$GridContainer/Right/Label,
]

func _ready() -> void:
	var _e := timer.connect("timeout", self, "on_timeout")

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
				var s := OS.get_scancode_string(local_scancode)
				labels[i].text = s.replace("Kp ", "")
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
