extends Node3D

var dotted_distance = 0.5
var rail_material = preload("res://Materials/train_track_rails.tres")
var wood_material = preload("res://Materials/rail_track_wood.tres")

#0 metal will be on the side of the track, 1.0 metall will be in the middle
var rail_in_middle = 0.2
#width is relative to the rail width
var rail_width = 0.05
func create_train_wood(line: PackedVector3Array, offset:float, line_width:float):
	var length_of_current_stripe = 0.0
	var last_point1 = Vector3()
	var last_point2 = Vector3()
	var is_stripe = false
	var j = 0.0

	#move the stripe in the middle of the two lines
	for k in range((len(line) / 2)-1):
		var i = 2*k	
		var middle_line = line[i+2]-line[i]
		var norm = middle_line.normalized()
		var orth = Vector2(middle_line.x, middle_line.z).orthogonal().normalized()
		var orth3d = Vector3(orth.x, 0, orth.y)
		var number_of_stripes = middle_line.length() / dotted_distance
			
		while j<= number_of_stripes:
			

			if is_stripe:
				var verts = PackedVector3Array()
				#offset
				var new_j = j + 1
				#first two verticies of each stripe
				if j == 0.0:
					verts.append(last_point2)

					verts.append(last_point1)
					new_j = 1-length_of_current_stripe
				else:
					verts.append(line[i] + j* norm * dotted_distance - orth3d * (line_width / 2 - offset))
					verts.append(line[i] + j* norm * dotted_distance + orth3d * (line_width / 2 + offset))
				
				#last two verts at each stripe
				if j+1 > number_of_stripes:
					pass
				else:
					
					verts.append(line[i] + (new_j)* norm * dotted_distance - orth3d * (line_width / 2 - offset))
					verts.append(line[i] + (new_j)* norm * dotted_distance + orth3d * (line_width / 2 + offset))
					is_stripe = false
				j = new_j 
				create_wood(verts, wood_material)

				
			else:
				var new_j = j+1
				if j == 0.0:
					new_j = 1-length_of_current_stripe

				if j+1 > number_of_stripes:
					length_of_current_stripe = number_of_stripes-j
				else: 
					is_stripe = true
				j = new_j
		j = 0.0	
	create_rails(line, line_width)


						

func create_wood(line: PackedVector3Array, material:StandardMaterial3D):
	var normals = PackedVector3Array()
	var index = PackedInt32Array()

	for i in range(len(line)):
		normals.append(Vector3(0,1,0))
		
	for i in range((len(line) / 2)-1):
		#first tirangle
		index.append(2*i)

		index.append(2*i+1)
		index.append(2*i+2)
		#second triangle
		index.append(2*i+3)

		index.append(2*i+2)
		index.append(2*i+1)
	
		# Initialize the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = line
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = index

	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
			

		
	m.set_surface_override_material(0, material)
	add_child(m)


func create_rails(line: PackedVector3Array, width:float):
	var line1 =  PackedVector3Array()
	var line2 =  PackedVector3Array()

	for k in range((len(line) / 2)):
		var i = 2*k
		var norm = (line[i+1]-line[i]).normalized()
		line[i] += Vector3(0,0.01,0)
		line1.append(line[i]+norm*(width)*(rail_in_middle+rail_width))

		line1.append(line[i]+norm*(width)*(rail_in_middle-rail_width))
		line2.append(line[i]+norm*(width)*(1-rail_in_middle+rail_width))
		line2.append(line[i]+norm*(width)*(1-rail_in_middle-rail_width))

	create_wood(line1, rail_material)
	create_wood(line2, rail_material)
