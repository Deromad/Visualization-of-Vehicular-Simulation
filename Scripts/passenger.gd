extends Node3D


func recolor_obj(material: StandardMaterial3D):
	var mesh = $Cube/Mesh

	
	mesh.set_surface_override_material(0, material)
func getting_scale():
		return scale
		
