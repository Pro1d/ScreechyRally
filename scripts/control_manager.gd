extends Node

signal control_assignment_changed(player_index, prev_control_index, new_control_index)

const UNASSIGNED := -1
const NOT_FOUND := -1
var _control_action_prefix := [
	"player1_", "player2_", "player4_", "player6_", "player7_",
]
# _control_assignment[control_index] = player_index
var _control_assignment := [0, 1, UNASSIGNED, UNASSIGNED, UNASSIGNED]
# _player_assignment[player_index] = control_index
var _player_assignment := [0, 1, UNASSIGNED, UNASSIGNED, UNASSIGNED, UNASSIGNED, UNASSIGNED, UNASSIGNED]

func _ready():
	var _i := get_joypad_count()

func control_count() -> int:
	return _control_assignment.size()

func is_available(control_index : int, player_index : int) -> bool:
	var assignment : int = _control_assignment[control_index]
	return assignment == -1 or assignment == player_index

func _find_first_assignment(player_index : int) -> int:
	for control_index in range(_control_assignment.size()):
		if _control_assignment[control_index] == player_index:
			return control_index
	return NOT_FOUND

func find_unassigned() -> int:
	return _find_first_assignment(UNASSIGNED)

func player_assignment(player_index : int) -> int:
	return _player_assignment[player_index]

# assigning same control to many player is allowed
func assign(control_index : int, player_index : int) -> void:
	# Clear previous assignment
	var prev := player_assignment(player_index)
	if prev != NOT_FOUND:
		_control_assignment[prev] = UNASSIGNED
	# New assignment
	_control_assignment[control_index] = player_index
	_player_assignment[player_index] = control_index
	emit_signal("control_assignment_changed", player_index, prev, control_index)

func action_prefix(control_index : int) -> String:
	return _control_action_prefix[control_index]

####### Controller Support #######
func get_joypad_count() -> int:
	var device_ids := Input.get_connected_joypads()
	for id in device_ids:
		print(id, " ", Input.get_joy_name(id)," : ",Input.get_joy_guid(id))
	return device_ids.size()

func get_joypad_name(joypad_index : int) -> String:
	return Input.get_joy_name(joypad_index)
