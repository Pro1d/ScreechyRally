extends Control

var current_maps_info : Dictionary
onready var log_label := $MarginContainer/VBoxContainer/PanelContainer/ScrollContainer/VBoxContainer/Label
onready var generate_button := $MarginContainer/VBoxContainer/HBoxContainer/Button
onready var clear_logs_button := $MarginContainer/VBoxContainer/HBoxContainer/Button2
onready var dump_button := $MarginContainer/VBoxContainer/HBoxContainer/Button3
onready var load_button := $MarginContainer/VBoxContainer/HBoxContainer/Button4
onready var save_button := $MarginContainer/VBoxContainer/HBoxContainer/MenuButton
onready var clear_progression_button := $MarginContainer/VBoxContainer/HBoxContainer/MenuButton2
onready var quit_button := $MarginContainer/VBoxContainer/HBoxContainer/Button5

onready var _physics_fps : int = ProjectSettings.get_setting("physics/common/physics_fps")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _e := generate_button.connect("pressed", self, "_on_generate_pressed")
	_e = clear_logs_button.connect("pressed", self, "_on_clear_logs_pressed")
	_e = save_button.get_popup().connect("id_pressed", self, "_on_save_pressed")
	_e = clear_progression_button.get_popup().connect("id_pressed", self, "_on_clear_progression_pressed")
	_e = dump_button.connect("pressed", self, "_on_dump_pressed")
	_e = load_button.connect("pressed", self, "_on_load_pressed")
	_e = quit_button.connect("pressed", get_tree(), "quit")

func _on_dump_pressed() -> void:
	print_log(["Maps info:"])
	var map_paths := current_maps_info.keys()
	map_paths.sort()
	for map_path in map_paths:
		var info : MapsList.MapInfo = current_maps_info[map_path]
		print_log([" - ", MapsList.map_file_to_map_name(info.path), ":"])
		print_log(["   - path: ", info.path])
		for i in range(4):
			print_log(["   - ", MapsList.MapInfo.medal_names[i], ": "], false)
			if info.target_medals[i] != null:
				print_log([info.target_medals[i].duration,
					" (", _frames_to_string(info.target_medals[i].duration), ") "], false)
				if info.target_medals[i].path:
					print_log([info.target_medals[i].path])
				else:
					print_log(["-- missing"])
			else:
				print_log(["--"])

func _on_load_pressed() -> void:
	current_maps_info = MapsList.load_maps_info()
	if current_maps_info.empty():
		print_log(["Error reading ", MapsList.maps_info_path])
	else:
		print_log(["Read from ", MapsList.maps_info_path])

func _on_save_pressed(id : int) -> void:
	assert(id == 0)
	if MapsList.save_maps_info(current_maps_info) != OK:
		print_log(["Error writing ", MapsList.maps_info_path])
	else:
		print_log(["Written to ", MapsList.maps_info_path])

func _on_clear_progression_pressed(id : int) -> void:
	assert(id == 0)
	var dir := Directory.new()
	if dir.remove(MapsList.progression_path) != OK:
		print_log(["Error removing ", MapsList.progression_path])
	else:
		print_log(["Removed ", MapsList.progression_path])

func _on_clear_logs_pressed() -> void:
	log_label.text = ""

func _on_generate_pressed() -> void:
	current_maps_info = generate_map_info()

func print_log(array : Array, endl : bool = true) -> void:
	var string := ""
	for obj in array:
		string += str(obj)
	if endl:
		string += "\n"
	log_label.text += string

static func _get_closest_time_index(times : Array, target : int, atol : float = 50, rtol : float = 0.10) -> int:
	var closest_index := -1
	var closest_distance := 0.0
	for i in range(times.size()):
		var distance := abs(times[i] - target)
		if closest_index == -1 or distance < closest_distance:
			closest_distance = distance
			closest_index = i
	if closest_index != -1 and max(0, closest_distance - atol) / float(target) < rtol:
		return closest_index
	return -1

func generate_map_info() -> Dictionary:
	var maps_info := {}

	var maps := []
	for mg in MapsList.get_maps():
		maps.append_array(mg.map_paths)

	for map_path in maps:
		var info := MapsList.MapInfo.new()
		info.path = map_path

		print_log(["MAP ", map_path])

		var records := RecordDataBase.get_all_record_paths(map_path)
		if not records.empty():
			var times := []
			var min_time_index := -1
			for record_path in records:
				var time := CarDrift.Record.read_duration(record_path)
				if min_time_index < 0 or time < times[min_time_index]:
					min_time_index = times.size()
				times.append(time)
			var author := RecordDataBase.Record.new()
			author.path = records[min_time_index]
			author.duration = times[min_time_index]
			info.target_medals[MapsList.MapInfo.Medal.AUTHOR] = author
			info.auto_target_medals()
			
			var targets := ["Target times: "]
			for i in range(MapsList.MapInfo.Medal.AUTHOR + 1):
				targets.append(" ")
				targets.append(info.target_medals[i].duration)
			print_log(targets)
			
			var medal_indices := []
			for m in range(MapsList.MapInfo.Medal.GOLD + 1):
				var medal : RecordDataBase.Record = info.target_medals[m]
				var index := _get_closest_time_index(times, medal.duration)
				if index != -1:
					assert(not (index in medal_indices))
					medal.path = records[index]
					medal.duration = times[index]
				else:
					print_log(["No record for ", MapsList.MapInfo.medal_names[m], " medal"])
				medal_indices.append(index)
			medal_indices.append(min_time_index)
			
			for i in range(records.size()):
				var idx := medal_indices.find(i)
				var medal_name = "#" + MapsList.MapInfo.medal_names[idx] if idx >= 0 else ""
				print_log([records[i], " ", times[i], medal_name])
		else:
			print_log([map_path, ": No records at all"])
		maps_info[map_path] = info

	return maps_info

func _frames_to_string(frames : int) -> String:
	if frames < 0:
		return "-:--.--"
	var centis := (frames % _physics_fps) * 100 / _physics_fps
	var seconds := (frames / _physics_fps) % 60
	var minutes := (frames / _physics_fps) / 60
	return "%d:%02d.%02d" % [minutes, seconds, centis]
