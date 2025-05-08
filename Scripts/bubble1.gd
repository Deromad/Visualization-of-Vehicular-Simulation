extends Node3D

func change_obj(color: Color, message: String)->void:
	var label = $Label3D
	label.text = message
	label.outline_modulate = color
