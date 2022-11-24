extends CanvasLayer

signal animation_finished()

onready var animation_players := [$AnimationPlayer]

func _ready() -> void:
	var _e := $AnimationPlayer.connect("animation_finished", self, "_on_animation_finished")

	for child_index in range(2, get_child_count()):
		var anim := get_child(child_index) as AnimationPlayer
		if anim != null:
			animation_players.append(anim)

	_play_animation("RESET")

func fade_in() -> void:
	_play_animation("fade_in")

func fade_out() -> void:
	_play_animation("fade_out")

func _play_animation(animation_name : String) -> void:
	for anim in animation_players:
		if anim.has_animation(animation_name):
			anim.play(animation_name)

func _on_animation_finished(_name : String) -> void:
	emit_signal("animation_finished")
