extends Node

var _silent_wolf_error := false

func dev_mode() -> bool:
	return OS.has_feature("editor")
	
func has_leaderboard() -> bool:
	return (OS.has_feature("leaderboard") or dev_mode()) and not _silent_wolf_error

func get_records_location() -> String:
	return "res://records/" if dev_mode() else "user://records"

func _ready() -> void:
	if has_leaderboard():
		_silent_wolf_error = not _configure_silent_wolf()

func _configure_silent_wolf() -> bool:
	var path := "res://silent-wolf-api-key-itch-io.json"
	var file := File.new()
	if file.open(path, File.READ) != OK:
		printerr("Cannot open SilentWolf API key file.")
		return false
	var json_result := JSON.parse(file.get_as_text())
	if json_result.error != OK or not (json_result.result is Dictionary):
		printerr("Cannot parse SilentWolf API key file.")
		return false
	var config := json_result.result as Dictionary
	config["log_level"] = 2 if dev_mode() else 0
	SilentWolf.configure(config)
	return true
