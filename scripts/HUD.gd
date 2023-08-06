class_name HUD
extends Control

# The tree contains a TimeDisplay node.
# The tree contains one or many Control node named "ScoreContainer".
# Each "ScoreContainer" has the Label children named "ScoreLabel",
# "CurrentCheckpointsLabel" and "TotalCheckpointsLabel"

onready var score_containers := _get_score_containers(self)
onready var time_display := _get_time_display(self)

var get_elapsed_time_func

func _ready() -> void:
	var player_id := 0
	# Update score panel colors
	for c in score_containers:
		var panel : PanelContainer = c.get_parent()
		var style_box : StyleBoxFlat = panel.get_stylebox("panel")
		var color : Color = Global.player_colors[player_id]
		color.v *= 0.8
		style_box.bg_color = color
		color.v *= 0.8
		style_box.border_color = color
		player_id += 1

func _get_score_containers(parent : Node) -> Array:
	if parent.name == "ScoreContainer":
		return [parent]
	var nodes := []
	for child in parent.get_children():
		nodes.append_array(_get_score_containers(child))
	return nodes

func _get_time_display(parent : Node) -> TimeDisplay:
	if (parent as TimeDisplay) != null:
		return parent as TimeDisplay
	for child in parent.get_children():
		var node := _get_time_display(child)
		if node != null:
			return node
	return null

func _process(_delta : float) -> void:
	var time := 0.0
	if get_elapsed_time_func != null:
		time = get_elapsed_time_func.call_func()
	time_display.set_time(time)

func _on_scores_changed(scores : Array) -> void:
	assert(len(scores) == len(score_containers))
	for i in range(len(score_containers)):
		score_containers[i] \
			.get_node("LapContainer") \
			.get_node("HBoxContainer") \
			.get_node("ScoreLabel") \
			.text = str(scores[i])

func _on_checkpoints_changed(current : Array, total_checkpoints : int) -> void:
	assert(len(current) == len(score_containers))
	for i in range(len(score_containers)):
		score_containers[i].get_node("CurrentCheckpointsLabel").text = str(current[i])
		score_containers[i].get_node("TotalCheckpointsLabel").text = str(total_checkpoints)
