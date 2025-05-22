extends Node3D
@export var height = 2.0
@onready var Error = $"../.."

func create_junctions(junction):
	
		var verts2d = PackedVector2Array()
		var verts3d = PackedVector3Array()

		var normals = PackedVector3Array()
		
		
		
		var shape_points = junction["shape"]
		var name = junction["id"]
		
		
		for i in range(len(shape_points)-1):
			#for each side of a junction create a rectangle

			var start_point = Vector2(shape_points[i]["x"], shape_points[i]["y"])
			
			verts3d.append(Vector3(start_point.x, height, start_point.y))
			verts2d.append(start_point)
			normals.append(Vector3(0,1,0))

		
		#triangulate the geometric form
		var indices = Geometry2D.triangulate_polygon(verts2d)
		
		# Initialize the ArrayMesh.
		var arr_mesh = ArrayMesh.new()
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts3d
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices

		# Create the Mesh.
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var m = MeshInstance3D.new()
		m.mesh = arr_mesh
		
		# create Material for each instance
		var new_material = StandardMaterial3D.new()
		new_material.albedo_color = Color.DIM_GRAY  

		
		m.set_surface_override_material(0, new_material)
		add_child(m)
