class_name GameViewports
extends Node

# Tree of control nodes with viewports.
# Each viewport has a configured camera as only child

func get_viewports(parent : Node = null) -> Array:
	if parent == null:
		parent = self
	if (parent as Viewport) != null:
		return [parent]
	var nodes := []
	for child in parent.get_children():
		nodes.append_array(get_viewports(child))
	return nodes

func _ready() -> void:
	var viewport_count := len(get_viewports())
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Fx"), -6.0 * (viewport_count - 1))
