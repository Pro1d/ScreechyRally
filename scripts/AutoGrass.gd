class_name AutoGrass
extends TileMap

func set_rect(r : Rect2, _seed : int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for y in range(int(r.position.y), int(r.end.y)):
		for x in range(int(r.position.x), int(r.end.x)):
			var sub := Vector2(rng.randi() % 2, rng.randi() % 2)
			set_cell(x, y, 0, false, false, false, sub)
