extends Node

enum Index {
	WORLD = 1, 
	CAR = 2,
	CAR_LOGIC = 3,
}
enum Bit {
	WORLD = 0b0001,
	CAR = 0b0010,
	CAR_LOGIC = 0b0100,
}

func _enter_tree() -> void:
	assert(_get_layer_name(Index.WORLD) == "world")
	assert(Bit.WORLD == (1 << (Index.WORLD - 1)))
	assert(_get_layer_name(Index.CAR) == "car")
	assert(Bit.CAR == (1 << (Index.CAR - 1)))
	assert(_get_layer_name(Index.CAR_LOGIC) == "car_logic")
	assert(Bit.CAR_LOGIC == (1 << (Index.CAR_LOGIC - 1)))

func _get_layer_name(index : int) -> String:
	return ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(index))
