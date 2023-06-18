extends Node

const api_key_path := "res://silent-wolf-api-key-itch-io.json"
const _leaderboard_config_path := "user://leaderboard_config.ini"
var _leaderboard_config: ConfigFile

func _ready() -> void:
	if Config.has_leaderboard():
		Config.silent_wolf_init_error = not _configure_silent_wolf()
		_load_leaderboard_config()

static func _configure_silent_wolf() -> bool:
	var file := File.new()
	if file.open(api_key_path, File.READ) != OK:
		printerr("Cannot open SilentWolf API key file.")
		return false
	var json_result := JSON.parse(file.get_as_text())
	if json_result.error != OK or not (json_result.result is Dictionary):
		printerr("Cannot parse SilentWolf API key file.")
		return false
	var config := json_result.result as Dictionary
	config["log_level"] = 1 if Config.dev_mode() else 0
	SilentWolf.configure(config)
	return true

func _load_leaderboard_config() -> void:
	if _leaderboard_config == null:
		_leaderboard_config =  ConfigFile.new()
		_leaderboard_config.load_encrypted_pass(_leaderboard_config_path, _leaderboard_config_path)

func _save_leaderboard_config() -> void:
	if _leaderboard_config != null:
		_leaderboard_config.save_encrypted_pass(_leaderboard_config_path, _leaderboard_config_path)

func save_player_name(pn: String):
	if get_player_name() != pn:
		_leaderboard_config.set_value("player", "name", pn)
		_save_leaderboard_config()

func get_player_name() -> String:
	return _leaderboard_config.get_value("player", "name", "")

func save_leaderboard_submission(leaderboard_name: String, submission: Dictionary) -> void:
	if get_leaderboard_submission(leaderboard_name).score_id != submission.score_id:
		_leaderboard_config.set_value("leaderboard", leaderboard_name, submission)
		_save_leaderboard_config()

func get_leaderboard_submission(leaderboard_name: String) -> Dictionary:
	return _leaderboard_config.get_value("leaderboard", leaderboard_name, {"score_id": ""})

func make_leaderboard_submission(score_id: String, time: int) -> Dictionary:
	return {"score_id": score_id, "time": time}

func clear_leader_board_config() -> int:
	var dir := Directory.new()
	return dir.remove(_leaderboard_config_path)
