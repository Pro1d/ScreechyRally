class_name LoadingAnimation
extends HBoxContainer


var playing := false setget _set_playing

onready var anim := $AnimationPlayer as AnimationPlayer


func _set_playing(p: bool) -> void:
	if playing != p:
		playing = p
		if playing:
			anim.play("loading")
		else:
			anim.stop()
