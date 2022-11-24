class_name TimeDisplay
extends Control

onready var ten_minutes_label := $TimeContainer/TenMinutesLabel
onready var unit_minutes_label := $TimeContainer/UnitMinutesLabel
onready var ten_seconds_label := $TimeContainer/TenSecondsLabel
onready var unit_seconds_label := $TimeContainer/UnitSecondsLabel
onready var tenth_seconds_label := $TimeContainer/TenthSecondsLabel

func set_time(time : float) -> void:
	time = min(time, 60 * 99 + 59.9)
	var tenth := int(fmod(time * 10, 10))
	var seconds := int(fmod(time, 60))
	var minutes := int(time / 60)
	ten_minutes_label.text = str(minutes / 10)
	unit_minutes_label.text = str(minutes % 10)
	ten_seconds_label.text = str(seconds / 10)
	unit_seconds_label.text = str(seconds % 10)
	tenth_seconds_label.text = str(tenth)
