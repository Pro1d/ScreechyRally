class_name Cooldown
extends Node

signal charges_changed(charges, max_charges)
signal activated()
signal terminated()

export(int) var max_charges := 3
export(float) var active_duration := 1.0 setget set_active_duration
export(float) var cooldown_duration := 5.0 setget set_cooldown_duration

var charges : int

onready var cooldown_timer := $CooldownTimer as Timer
onready var active_timer := $ActiveTimer as Timer

func _ready():
	active_timer.wait_time = active_duration
	cooldown_timer.wait_time = cooldown_duration
	var _e = active_timer.connect("timeout", self, "_on_active_timeout")
	_e = cooldown_timer.connect("timeout", self, "_on_cooldown_timeout")

func set_active_duration(d : float):
	active_duration = d
	active_timer.wait_time = active_duration

func set_cooldown_duration(d : float):
	cooldown_duration = d
	cooldown_timer.wait_time = cooldown_duration

func reset(initial_charges=1):
	charges = initial_charges
	emit_signal("charges_changed", charges, max_charges)
	active_timer.stop()
	cooldown_timer.stop()
	if charges < max_charges:
		cooldown_timer.start()

func is_activable():
	return charges >= 1 and active_timer.time_left <= 0

func activate():
	if is_activable():
		charges -= 1
		emit_signal("charges_changed", charges, max_charges)
		
		if active_timer.wait_time > 0:
			active_timer.start()
		emit_signal("activated")
		
		if cooldown_timer.time_left <= 0:
			cooldown_timer.start()

func get_charges():
	return charges

func get_remaining_cooldown_duration():
	return cooldown_timer.time_left

func get_cooldown_duration():
	return cooldown_timer.wait_time

func is_cooling_down():
	return cooldown_timer.time_left > 0

func get_remaining_active_duration():
	return active_timer.time_left

func get_active_duration():
	return active_timer.wait_time

func is_active():
	return active_timer.time_left > 0

func _on_cooldown_timeout():
	charges += 1
	emit_signal("charges_changed", charges, max_charges)
	if charges < max_charges:
		cooldown_timer.start()

func _on_active_timeout():
	emit_signal("terminated")
