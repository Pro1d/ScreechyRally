extends Line2D

export var max_points := 200

var instanced_lines := []
var total_points := 0
var emitting := false setget _set_emitting, _is_emitting

# To be overriden if tree's root is not the world's root
onready var world := get_tree().get_root() as Node

func _exit_tree():
	clear_all()

func _physics_process(_delta : float):
	if emitting:
		_emit_point()

func _set_emitting(emit : bool) -> void:
	if emitting != emit:
		emitting = emit
		if emitting:
			var line2d := duplicate(DUPLICATE_USE_INSTANCING) as Line2D
			line2d.transform = Transform2D.IDENTITY
			instanced_lines.append(line2d)
			world.add_child(line2d)
			_emit_point()

func _is_emitting() -> bool:
	return emitting

func _emit_point() -> void:
	var emit_pos := global_transform.origin
	var line2d := instanced_lines.back() as Line2D
	var point_count := line2d.get_point_count()

	if point_count >= 1:
		var d := line2d.get_point_position(point_count - 1).distance_to(emit_pos)
		if d < 1e-3:
			return

	var erase_last := false
	if point_count >= 3:
		erase_last = true
		var last_point := line2d.get_point_position(point_count - 2)
		var current_length := last_point.distance_to(emit_pos)
		if current_length > 10 * width:
			erase_last = false
		elif current_length > 3 * width:
			var prev_last_point := line2d.get_point_position(point_count - 3)
			var last_segment_dir := last_point - prev_last_point
			if abs(last_segment_dir.angle_to(emit_pos - last_point)) > deg2rad(4):
				erase_last = false

	if erase_last:
		line2d.set_point_position(point_count - 1, emit_pos)
	else:
		line2d.add_point(emit_pos)
		total_points += 1

	_clear_old_points()

func _clear_old_points() -> void:
	while total_points > max_points:
		var line2d := instanced_lines.front() as Line2D
		if line2d.get_point_count() - 1 <= total_points - max_points:
			total_points -= line2d.get_point_count()
			instanced_lines.pop_front()
			line2d.queue_free()
		else:
			while total_points > max_points:
				line2d.remove_point(0)
				total_points -= 1

func clear_all() -> void:
	for line2d in instanced_lines:
		line2d.queue_free()
	instanced_lines.clear()
	total_points = 0
