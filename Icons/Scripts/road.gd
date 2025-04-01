extends Node3D

#set height of road so that it wont cut with other objects e.g. Junctions
@export var height = 1.0

func create_roads(data):
	for road in data:
		
		#a road can have more then one lane
		for lane in road["lanes"]:
			
			#important values for ArrayMesh
			var verts3d = PackedVector3Array()
			var normals = PackedVector3Array()
			var index = PackedInt32Array()
			
			var shape_points = lane["shape"]
			var name = lane["id"]
			var width = lane["width"]
			
			#error if there are less then 2 shape points
			if len(shape_points) < 2:
				assert(false, "The road with the ID: " + str(name) + "has only one ore no shape point")
				continue
			
			#calculate the edges of the road because only the middle of the lane is given
			
			var start_point = Vector2(shape_points[0]["x"], shape_points[0]["y"])
			var end_point = Vector2(shape_points[1]["x"], shape_points[1]["y"])
			var orthnorm = (end_point-start_point).orthogonal().normalized() * width / 2
			var prepoint1 = Vector3(start_point.x + orthnorm.x, height, start_point.y + orthnorm.y)
			var prepoint2 = Vector3(start_point.x - orthnorm.x, height, start_point.y -orthnorm.y)
			verts3d.append(prepoint1)
			normals.append(Vector3(0,1,0))
			verts3d.append(prepoint2)
			normals.append(Vector3(0,1,0))
					
			for i in range(1, len(shape_points)-1):
				start_point = Vector3(shape_points[i-1]["x"], height, shape_points[i-1]["y"])
				var middle_point  = Vector3(shape_points[i]["x"], height, shape_points[i]["y"])
				end_point = Vector3(shape_points[i+1]["x"], height, shape_points[i+1]["y"])
				var path1 = Vector2(middle_point.x-start_point.x, middle_point.z-start_point.z).normalized()
				var path2 = Vector2(end_point.x-middle_point.x, end_point.z - middle_point.z).normalized()
				var orth = (path1+path2).orthogonal().normalized()
				var angle = path1.angle_to(orth)
	
				var width_vec = Vector3(orth.x, 0, orth.y) * (width/(sin(angle)*2))
				verts3d.append(middle_point - width_vec)
				verts3d.append(middle_point + width_vec)
				normals.append(Vector3(0,1,0))
				normals.append(Vector3(0,1,0))
			var length = len(shape_points)
			start_point = Vector2(shape_points[length-2]["x"], shape_points[length-2]["y"])
			end_point = Vector2(shape_points[length-1]["x"], shape_points[length-1]["y"])
			orthnorm = (end_point-start_point).orthogonal().normalized() * width / 2
			prepoint1 = Vector3(end_point.x + orthnorm.x, height, end_point.y + orthnorm.y)
			prepoint2 = Vector3(end_point.x - orthnorm.x, height, end_point.y -orthnorm.y)
			verts3d.append(prepoint1)
			normals.append(Vector3(0,1,0))
			verts3d.append(prepoint2)
			normals.append(Vector3(0,1,0))
			
			#set the order of the triangles
			for i in range (len(shape_points)-1):
				#first tirangle
				index.append(2*i+1)
				index.append(2*i)
				index.append(2*i+2)
				#second triangle
				index.append(2*i+2)
				index.append(2*i+3)
				index.append(2*i+1)
			
			# Initialize the ArrayMesh.
			var arr_mesh = ArrayMesh.new()
			var arrays = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = verts3d
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_INDEX] = index

			# Create the Mesh.
			arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var m = MeshInstance3D.new()
			m.mesh = arr_mesh
			
			# create Material for each instance
			var new_material = StandardMaterial3D.new()
	
			new_material.albedo_color = Color.DARK_SLATE_GRAY  

			
			m.set_surface_override_material(0, new_material)
			add_child(m)
