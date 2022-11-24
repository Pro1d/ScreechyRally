class_name RecordDataBase
extends Object

class Record:
	var path : String
	var duration : int # number of frames

	func to_dict() -> Dictionary:
		return {path=path if path else "", duration=duration}

	static func from_dict(d : Dictionary) -> Record:
		var r := Record.new()
		r.path = d.path
		r.duration = d.duration
		return r

const location := "res://records/"
const separator := "_"
const extension := ".record"

static func generate_record_path(race_map_scene_name : String) -> String:
	var date := Time.get_datetime_string_from_system(true).replace(":","-").replace("T","-")
	var map_name := race_map_scene_name.get_file().get_basename()
	return location + map_name + separator + date + extension

static func get_all_record_paths(race_map_scene_name : String) -> Array:
	var map_name := race_map_scene_name.get_file().get_basename()
	var prefix := map_name + separator
	var dir := Directory.new()
	var record_paths := []
	if dir.open(location) == OK:
		var _e := dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.begins_with(prefix) and file_name.ends_with(extension):
				record_paths.append(dir.get_current_dir().plus_file(file_name))
			file_name = dir.get_next()
	record_paths.sort()
	return record_paths
