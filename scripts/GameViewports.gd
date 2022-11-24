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
