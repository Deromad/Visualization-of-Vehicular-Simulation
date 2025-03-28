extends Node3D

#height of every house
@export var height = 10.0

#load the simple facade scene
var SimpleFacadeScene = preload("res://Scenes/simple_facade.tscn")

func create_building2d5(data):
	for house in data:
		#the 2D verts are better for the triangulation of the 
		#roofs and are like the 3D verts without the height
		var verts2d = PackedVector2Array()
		
		#3D verts store the verticies of the roof
		var verts3d = PackedVector3Array()
		
		#normals are necessary, so that the light knows how to interact also  for the roof
		var normals = PackedVector3Array()
		
		#get infos from the yaml input
		var shape_points = house["shape"]
		var color_dic = house["color"]
		var color = Color.from_rgba8(color_dic["r"], color_dic["g"], color_dic["b"])
		var name = house["id"]
		
		#for each edge of the building create a wall and a roof
		for i in range(len(shape_points)-1):
			
			#for each wall of a house create a rectangle
			var start_point = Vector2(shape_points[i]["x"], shape_points[i]["y"])
			
			var end_point = Vector2(shape_points[i + 1]["x"], shape_points[i + 1]["y"])
			# Calculate the middle point of the rectangle
			var middle_point = Vector3((start_point.x + end_point.x) / 2, height / 2, (start_point.y + end_point.y) / 2)
			#calculate the length of the site
			var length = start_point.distance_to(end_point)
			#create new site with SimpleFacade
			var scale_vec = Vector3(length, height, 1)
			#calculate rotation angle
			var angle = start_point.angle_to_point(end_point)
			
			#create facade (wall) instance and add it to the scene
			var facade_instance = SimpleFacadeScene.instantiate()
			add_child(facade_instance)
		
			#transform the wall
			facade_instance.translate(middle_point)
			facade_instance.scale_object_local(scale_vec)
			facade_instance.rotate_y(-angle)
			facade_instance.transform_obj(color)
			facade_instance.name = str(name) 
			
			#store the verticies for the roof
			verts3d.append(Vector3(start_point.x, height, start_point.y))
			verts2d.append(start_point)
			normals.append(Vector3(0,1,0))
			
		#create roof
		
		#triangulate so that its known which verticies should form a triangle
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
		
		# create Material for each instance, so that they can have different colors
		var new_material = StandardMaterial3D.new()
		new_material.albedo_color = color  
		
		#add surface zo mesh and add roof to scene
		m.set_surface_override_material(0, new_material)
		add_child(m)

	
