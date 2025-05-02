extends Node3D


func transform_obj(color: Color):
	var mesh = $Facade/Mesh

	# Lade das Originalmaterial (z. B. "facade.tres")
	var original_material = preload("res://Materials/facade.tres")

	# Klone das Material, um das Original nicht zu verändern
	var new_material = original_material.duplicate()
	new_material.albedo_color = color
	new_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Setze das neue Material auf das Mesh
	mesh.set_surface_override_material(0, new_material)
