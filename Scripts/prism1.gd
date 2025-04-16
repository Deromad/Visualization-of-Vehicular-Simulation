extends Node3D


func transform_obj(color: Color):
	var mesh = $MeshInstance3D

	# create Material for each instance
	var new_material = StandardMaterial3D.new()
	new_material.albedo_color = color  
	new_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mesh.set_surface_override_material(0, new_material)
