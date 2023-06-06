extends Node

enum GameMode { UNDEFINED, TIME_TRIAL, MULTILAPS }

const player_colors := [
	Color.lawngreen,
	Color.red,
	Color.dodgerblue,
	Color(1, 0.5, 0),
	Color.indigo,
	Color.yellow,
	Color.turquoise,
	Color.fuchsia
]
const medal_colors := [
	Color.saddlebrown,
	Color.silver,
	Color.gold,
	Color.aqua,
]
const medal_icon_colors := [
	Color(0xa9844aff),
	Color(0xbabbbdff),
	Color(0xffe07dff),
	Color(0x49cdf0ff),
]

var maps_info = null setget, _get_maps_info
var maps_progression = null setget , _get_maps_progression
var race_map_scene_name := "res://scenes/RaceMap.tscn"
var player_count := 1
var game_mode : int = GameMode.UNDEFINED

onready var _physics_fps : int = ProjectSettings.get_setting("physics/common/physics_fps")

func set_race_map_scene_name(path : String) -> void:
	race_map_scene_name = path

func change_scene_to_main_menu() -> void:
	var _e := get_tree().change_scene("res://scenes/Menu.tscn")

func change_scene_to_race() -> void:
	var _e := get_tree().change_scene("res://scenes/RaceSplitScreen.tscn")

func _get_maps_info() -> Dictionary:
	if maps_info == null:
		maps_info = MapsList.load_maps_info()
	return maps_info

func _get_maps_progression() -> Dictionary:
	if maps_progression == null:
		maps_progression = MapsList.load_maps_progression()
	return maps_progression

func update_map_progression(map_path : String, record_path : String) -> void:
	var mp := _get_maps_progression()
	var duration := CarDrift.Record.read_duration(record_path)
	var progression : MapsList.MapProgression = mp.get(map_path)
	var update := false
	if progression == null:
		progression = MapsList.MapProgression.new()
		progression.path = map_path
		progression.best_record = RecordDataBase.Record.new()
		mp[map_path] = progression
		update = true
	elif duration < progression.best_record.duration:
		update = true
	
	if update:
		progression.best_record.duration = duration
		progression.best_record.path = record_path
		var _e = MapsList.save_maps_progression(mp)

func frames_to_string(frames : int) -> String:
	if frames < 0:
		return "-:--.--"
	var centis := (frames % _physics_fps) * 100 / _physics_fps
	var seconds := (frames / _physics_fps) % 60
	var minutes := (frames / _physics_fps) / 60
	return "%d:%02d.%02d" % [minutes, seconds, centis]
