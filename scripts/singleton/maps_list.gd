extends Node

class MapInfo:
	enum Medal {BRONZE=0, SILVER, GOLD, AUTHOR, COUNT}
	
	const medal_names := ["bronze", "silver", "gold", "author"]
	const time_factors := [1.55, 1.23, 1.08, 1.0]
	
	var path : String
	var target_medals := [null, null, null, null]
	
	static func round_duration(d : int) -> int:
		return int(round(d / 50) * 50)
	
	func auto_target_medals() -> void:
		var author : RecordDataBase.Record = target_medals[Medal.AUTHOR]
		assert(author != null)
		for m in range(Medal.GOLD + 1):
			if target_medals[m] == null:
				target_medals[m] = RecordDataBase.Record.new()
				target_medals[m].duration = int(author.duration * time_factors[m])
	
	func to_dict() -> Dictionary:
		var tg := [null, null, null, null]
		for m in range(Medal.COUNT):
			if target_medals[m] != null:
				tg[m] = target_medals[m].to_dict()
	
		return {path = path, target_medals = tg}
	
	static func from_dict(d : Dictionary) -> MapInfo:
		var mi := MapInfo.new()
		mi.path = d.path
		for m in range(Medal.COUNT):
			if d.target_medals[m] != null:
				mi.target_medals[m] = RecordDataBase.Record.from_dict(d.target_medals[m])
		return mi
	
	func medals_completed(progression : MapProgression) -> Array:
		var completed := [false, false, false, false]
		for m in range(Medal.COUNT):
			if progression != null and target_medals[m] != null:
				if progression.best_record.duration <= target_medals[m].duration:
					completed[m] = true
		return completed

class MapProgression:
	var path : String
	var best_record : RecordDataBase.Record
	
	func to_dict() -> Dictionary:
		return { path = path, best_record = best_record.to_dict() }
	
	static func from_dict(d : Dictionary) -> MapProgression:
		var mp := MapProgression.new()
		mp.path = d.path
		mp.best_record = RecordDataBase.Record.from_dict(d.best_record)
		return mp

const map_dir_path := "res://scenes/race_maps/"
const maps_info_path := "res://records/maps_info.bin"
const progression_path := "user://progression.bin"
	
static func map_file_to_map_name(full_path : String) -> String:
	var basename := full_path.get_file().get_basename()
	return basename.replace('_', ' ')

static func get_maps_list() -> Array:
	var dir := Directory.new()
	var map_paths := []
	if dir.open(map_dir_path) == OK:
		var _e := dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				map_paths.append(dir.get_current_dir().plus_file(file_name))
			file_name = dir.get_next()
	map_paths.sort()
	return map_paths

static func _read_bin_object_map(path : String, dict_to_obj : FuncRef) -> Dictionary:
	var f := File.new()
	var _e := f.open(path, File.READ)
	if _e != OK:
		return {}
	var dict = bytes2var(f.get_buffer(f.get_len()))
	f.close()
	
	for k in dict.keys():
		dict[k] = dict_to_obj.call_func(dict[k])
	return dict

static func _write_bin_object_map(path : String, obj_map : Dictionary) -> int:
	var dict := {}
	for k in obj_map.keys():
		dict[k] = obj_map[k].to_dict()
	
	var f := File.new()
	var e := f.open(path, File.WRITE)
	if e != OK:
		return e
	f.store_buffer(var2bytes(dict))
	f.close()
	return OK

static func load_maps_info() -> Dictionary: # map_path->MapInfo
	return _read_bin_object_map(maps_info_path, funcref(MapsList.MapInfo, "from_dict"))

static func save_maps_info(maps_info : Dictionary) -> int:
	return _write_bin_object_map(maps_info_path, maps_info)

static func load_maps_progression() -> Dictionary: # String map_path->MapProgression
	return _read_bin_object_map(progression_path, funcref(MapProgression, "from_dict"))

static func save_maps_progression(maps_progression : Dictionary) -> int:
	return _write_bin_object_map(progression_path, maps_progression)
