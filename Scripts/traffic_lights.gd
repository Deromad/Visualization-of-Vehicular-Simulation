extends Node3D

var last = ""

func change_obj(state:String)-> bool:
	if last == state: 
		return true
	last = state
	var mesh = $MeshInstance3D
	var new_material
	match state:
		"red":
			new_material = preload("res://Materials/red_traffic.tres")
		"green_major":
			new_material = preload("res://Materials/green_major.tres")
		"green_minor":
			new_material = preload("res://Materials/green_minor.tres")
		"yellow_major":
			new_material = preload("res://Materials/yellow_major.tres")
		"yellow_minor":
			new_material = preload("res://Materials/yellow_major.tres")
		"red_yellow":
			new_material = preload("res://Materials/red_yellow.tres")
		"off_blinking":
			new_material = preload("res://Materials/off_blinking.tres")
		"off_nosignal":
			new_material = preload("res://Materials/off_no_signal.tres")
		"stop":
			new_material = preload("res://Materials/stop.tres")

		_:
			return false

	mesh.set_surface_override_material(0, new_material)
	return true
