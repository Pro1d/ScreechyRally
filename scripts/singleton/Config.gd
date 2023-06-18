extends Node

var silent_wolf_init_error := false

func dev_mode() -> bool:
	return OS.has_feature("editor")
	
func has_leaderboard() -> bool:
	return (OS.has_feature("leaderboard") or dev_mode()) and not silent_wolf_init_error

func get_records_location() -> String:
	return "res://records/" if dev_mode() else "user://records"
