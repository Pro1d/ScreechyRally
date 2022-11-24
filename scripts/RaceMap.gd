class_name RaceMap
extends Node2D

const ModelLineArea2D = preload("res://resources/MapLineArea2D.res")

signal checkpoint_area_entered(checkpoint_id, body)
signal start_area_entered(body)

var checkpoint_areas := []
var start_area : Area2D

onready var tile_map := $TileMap as TileMap
onready var cell_size := tile_map.cell_size

func _ready():
	for cell_pos in tile_map.get_used_cells():
		var tile_index := tile_map.get_cellv(cell_pos) as int
		var tile_name := tile_map.tile_set.tile_get_name(tile_index) as String
		match tile_name:
			"start":
				if start_area != null:
					printerr("More than one start tile in the map.")
				else:
					if cell_pos != Vector2.ZERO:
						printerr("Start tile should be at cell (0,0)")
					start_area = _add_line_area(cell_pos, 20)
					var _e := start_area.connect("body_entered", self, "_body_entered_start_area")
			"checkpoint":
				var cp_area := _add_line_area(cell_pos, 15)
				var cp_id := len(checkpoint_areas)
				checkpoint_areas.append(cp_area)
				var _e := cp_area.connect("body_entered", self, "_body_entered_checkpoint_area", [cp_id])
	if start_area == null:
		printerr("The map does not have a start tile.")
	if len(checkpoint_areas) == 0:
		print("The map does not have checkpoint tiles.")

func get_checkpoint_count() -> int:
	return len(checkpoint_areas)

func get_player_spawn(player_id : int) -> Transform2D:
	var rank := player_id / 2
	var side := 1 if player_id % 2 == 0 else -1
	var offset := Vector2(-100 * (rank + 1), 45 * side)
	return start_area.global_transform * Transform2D(0, offset)

func _get_cell_transform(cell_pos : Vector2) -> Transform2D:
	var flip_x := tile_map.is_cell_x_flipped(int(cell_pos.x), int(cell_pos.y))
	var flip_y := tile_map.is_cell_y_flipped(int(cell_pos.x), int(cell_pos.y))
	var inv_xy := tile_map.is_cell_transposed(int(cell_pos.x), int(cell_pos.y))
	
	var t := Transform2D.IDENTITY
	t.origin = (cell_pos + Vector2(.5, .5)) * cell_size
	if flip_x:
		t.x *= -1
	if flip_y:
		t.y *= -1
	if inv_xy:
		var old_t_x := t.x
		t.x = t.y
		t.y = old_t_x
	
	return t

func _add_line_area(cell_pos : Vector2, thickness : float) -> Area2D:
	var area : Area2D = ModelLineArea2D.instance()
	
	# Tile position and orientation
	area.transform = _get_cell_transform(cell_pos)
	
	# Shape
	var rectangle_shape : RectangleShape2D = (area.get_child(0) as CollisionShape2D).shape
	rectangle_shape.extents.x = thickness / 2
	
	# Add objects to tree
	tile_map.add_child(area)
	
	return area

func _body_entered_checkpoint_area(body, checkpoint_id) -> void:
	emit_signal("checkpoint_area_entered", checkpoint_id, body)

func _body_entered_start_area(body) -> void:
	emit_signal("start_area_entered", body)
