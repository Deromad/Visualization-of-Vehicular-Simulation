extends Node3D

func transform_obj(material: StandardMaterial3D):
	var mesh = $Conn

	
	# Setze das neue Material auf das Mesh
	mesh.set_surface_override_material(0, material)
	
