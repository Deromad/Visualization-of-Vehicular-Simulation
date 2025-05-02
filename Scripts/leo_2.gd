extends Node3D


func recolor_obj(material: StandardMaterial3D):
	var mesh = $leo
	mesh.set_surface_override_material(0, material)
