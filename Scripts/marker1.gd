extends Node3D

func change_obj( message: String)->void:
	var label = $Label3D
	label.text = message
