extends Node3D

# Distance between each wooden plank along the track
var dotted_distance = 0.5

# Materials for the rails and wooden planks
var rail_material = preload("res://Materials/train_track_rails.tres")
var wood_material = preload("res://Materials/rail_track_wood.tres")

# Position of the rail relative to the center (0 = outer edge, 1 = inner edge)
var rail_in_middle = 0.2

# Width of the metal rail relative to the total track width
var rail_width = 0.05

# Main function to create wooden planks (sleepers) along a path and then rails
func create_train_wood(line: PackedVector3Array, offset: float, line_width: float):
	var length_of_current_stripe = 0.0
	var last_point1 = Vector3()
	var last_point2 = Vector3()
	var is_stripe = false
	var j = 0.0

	# Loop through each segment between the points
	for k in range((len(line) / 2) - 1):
		var i = 2 * k	
		var middle_line = line[i + 2] - line[i]
		var norm = middle_line.normalized()

		# Calculate perpendicular vector for width direction
		var orth = Vector2(middle_line.x, middle_line.z).orthogonal().normalized()
		var orth3d = Vector3(orth.x, 0, orth.y)

		var number_of_stripes = middle_line.length() / dotted_distance

		# Loop to add wooden planks at regular intervals along this segment
		while j <= number_of_stripes:
			if is_stripe:
				var verts = PackedVector3Array()
				var new_j = j + 1

				# Handle first stripe with leftover length from previous segment
				if j == 0.0:
					verts.append(last_point2)
					verts.append(last_point1)
					new_j = 1 - length_of_current_stripe
				else:
					verts.append(line[i] + j * norm * dotted_distance - orth3d * (line_width / 2 - offset))
					verts.append(line[i] + j * norm * dotted_distance + orth3d * (line_width / 2 + offset))

				# Check if last stripe in this segment
				if j + 1 > number_of_stripes:
					pass  # No end cap needed
				else:
					verts.append(line[i] + new_j * norm * dotted_distance - orth3d * (line_width / 2 - offset))
					verts.append(line[i] + new_j * norm * dotted_distance + orth3d * (line_width / 2 + offset))
					is_stripe = false  # Next loop will be a gap

				j = new_j
				create_wood(verts, wood_material)  # Create wood mesh with calculated vertices
			else:
				var new_j = j + 1

				if j == 0.0:
					new_j = 1 - length_of_current_stripe

				if j + 1 > number_of_stripes:
					length_of_current_stripe = number_of_stripes - j
				else:
					is_stripe = true  # Next loop will be a stripe

				j = new_j

		j = 0.0  # Reset j for next segment

	# After wooden planks are placed, add rails on top
	create_rails(line, line_width)

# Helper function to create a wood plank mesh from 4 points (quad made of 2 triangles)
func create_wood(line: PackedVector3Array, material: StandardMaterial3D):
	var normals = PackedVector3Array()
	var index = PackedInt32Array()

	# Set normals for each vertex (pointing up)
	for i in range(len(line)):
		normals.append(Vector3(0, 1, 0))

	# Build index array to define triangles (2 per quad)
	for i in range((len(line) / 2) - 1):
		index.append(2 * i)
		index.append(2 * i + 1)
		index.append(2 * i + 2)
		index.append(2 * i + 3)
		index.append(2 * i + 2)
		index.append(2 * i + 1)

	# Initialize and assign mesh data
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = line
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = index

	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	m.set_surface_override_material(0, material)
	add_child(m)

# Function to create two rails running parallel along the wooden base
func create_rails(line: PackedVector3Array, width: float):
	var line1 = PackedVector3Array()
	var line2 = PackedVector3Array()

	# Loop over each left/right pair of points in the path
	for k in range((len(line) / 2)):
		var i = 2 * k
		var norm = (line[i + 1] - line[i]).normalized()

		# Slight vertical offset to avoid z-fighting
		line[i] += Vector3(0, 0.01, 0)

		# Left rail
		line1.append(line[i] + norm * width * (rail_in_middle + rail_width))
		line1.append(line[i] + norm * width * (rail_in_middle - rail_width))

		# Right rail
		line2.append(line[i] + norm * width * (1 - rail_in_middle + rail_width))
		line2.append(line[i] + norm * width * (1 - rail_in_middle - rail_width))

	# Use the same function for creating both wood and metal rails
	create_wood(line1, rail_material)
	create_wood(line2, rail_material)
