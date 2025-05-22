extends Node3D

# Set height of road slightly above base to avoid Z-fighting with junctions or other surfaces
var height_to_lines = 0.01

# Arrow display settings
var arrow_length = 2.0
var distance_road_to_arrow = 2.0

# Preload scene assets
var ArrowStraight = preload("res://Scenes/arrow_straight.tscn")
var ArrowLeft
var ArrowRight

# Node references
@onready var Error = $"../.."
@onready var TrafficLights = $"../../DynamicObjects/TrafficLight"
@onready var TrainTreck = $"../TrainTrack"

# Lane drawing configuration
@export var dotted_distance = 0.5
@export var line_width = 0.15
@export var height = 1.0

# Material assignments
@export var normal_lane_material = preload("res://Materials/normal_lane.tres")
@export var bus_lane_material = preload("res://Materials/bus_lane.tres")
@export var bike_lane_material = preload("res://Materials/bike_lane.tres")
@export var linee_material = preload("res://Materials/road_lines.tres")

# Traffic light and rail flags
var wait = 20
var wait_counter = 0
var is_rail = false

# Main function to create road geometry from data
func create_roads(data): 
	for road in data:
		var lane_error = false
		var lines = []
		var first = true
		var allowed_classes = []
		is_rail = false

		# Loop through each lane in the road
		for lane in road["lanes"]:
			var shape_points = lane["shape"]
			var name = lane["id"]
			var width = lane["width"]
			var kind = lane["allowedClasses"]
			var color = StandardMaterial3D
			var directions = []

			# Assign direction indicators for traffic lights if available
			if lane["links"] is Array:
				for dir in lane["links"]:
					directions.append(dir["direction"])
					var shape1 = shape_points[-1]
					var shape2 = shape_points[-2]
					TrafficLights.set_direction(
						name, str(dir["lane"]),
						Vector3(shape1["x"], shape1["z"], shape1["y"]),
						Vector3(shape2["x"], shape2["z"], shape2["y"]),
						width, dir["direction"]
					)

			# Determine material by allowed class
			if kind.has("bus"):
				color = bus_lane_material
			elif kind.has("bicycle"):
				color = bike_lane_material
			elif kind.has("rail"):
				is_rail = true
				color = normal_lane_material
			else:
				color = normal_lane_material

			# Track whether lane changing is allowed
			allowed_classes.append(lane["canChangeRight"].is_empty())
			allowed_classes.append(lane["canChangeLeft"].is_empty())

			# Create the lane mesh and collect line data
			var zw = create_road(width, shape_points, name, true, color)
			if zw.is_empty():
				lane_error = true
				continue
			lines.append(zw[1])
			lines.append(zw[0])

			add_arrow(directions, shape_points[-2], shape_points[-1])
			first = false

		if lane_error:
			continue

		# If road is not a rail, add outer lines and dotted lines
		if not is_rail:
			create_outer_line_roads(lines[0])
			create_outer_line_roads(lines[-1])

			for i in range(len(lines) / 2 - 1):
				if allowed_classes[(i+1)*2-1] and allowed_classes[(i+1)*2]:
					create_outer_line_roads(lines[(i+1)*2])
				elif allowed_classes[(i+1)*2]:  # Right lane change allowed
					create_outer_line_roads(lines[(i+1)*2])
					create_dotted_lines(lines[(i+1)*2-1], -line_width)
				elif allowed_classes[(i+1)*2-1]:  # Left lane change allowed
					create_outer_line_roads(lines[(i+1)*2-1])
					create_dotted_lines(lines[(i+1)*2-1], line_width)
				else:  # No lane changes
					create_dotted_lines(lines[(i+1)*2-1], 0.0)

# Create mesh geometry for a road segment
func create_road(width: float, shape_points, name: String, first: bool, material: StandardMaterial3D) -> Array[PackedVector3Array]:
	var verts3d = PackedVector3Array()
	var normals = PackedVector3Array()
	var index = PackedInt32Array()
	var line1 = PackedVector3Array()
	var line2 = PackedVector3Array()

	# Process the start point
	var start_point = Vector2(shape_points[0]["x"], shape_points[0]["y"])
	var end_point = Vector2(shape_points[1]["x"], shape_points[1]["y"])
	var orthnorm = (end_point-start_point).orthogonal().normalized() * width / 2
	var line_orth = (end_point-start_point).orthogonal().normalized() * ((width) / 2 -line_width)
	var prepoint1 = Vector3(start_point.x + orthnorm.x, height, start_point.y + orthnorm.y)
	var prepoint2 = Vector3(start_point.x - orthnorm.x, height, start_point.y -orthnorm.y)
	verts3d.append(prepoint1)
	normals.append(Vector3(0,1,0))
	verts3d.append(prepoint2)
	normals.append(Vector3(0,1,0))
	line1.append(prepoint1 + Vector3(0, height_to_lines, 0))
	line1.append(Vector3(start_point.x + line_orth.x, height + height_to_lines, start_point.y + line_orth.y))
	if first:
		line2.append(Vector3(start_point.x - line_orth.x, height + height_to_lines, start_point.y - line_orth.y))
		line2.append(prepoint2 + Vector3(0, height_to_lines, 0))

	# Loop through shape and calculate vertices
	for i in range(1, len(shape_points) - 1):
		start_point = Vector3(shape_points[i - 1]["x"], height, shape_points[i - 1]["y"])
		var middle_point = Vector3(shape_points[i]["x"], height, shape_points[i]["y"])
		end_point = Vector3(shape_points[i + 1]["x"], height, shape_points[i + 1]["y"])
		var path1 = Vector2(middle_point.x - start_point.x, middle_point.z - start_point.z).normalized()
		var path2 = Vector2(end_point.x - middle_point.x, end_point.z - middle_point.z).normalized()
		var orth = (path1 + path2).orthogonal().normalized()
		var angle = path1.angle_to(orth)

		var width_vec = Vector3(orth.x, 0, orth.y) * (width / (sin(angle) * 2))
		var line_width_vec = Vector3(orth.x, 0, orth.y) * ((width / 2 - line_width) / sin(angle))
		line1.append(middle_point - width_vec + Vector3(0, height_to_lines, 0))
		line1.append(middle_point - line_width_vec + Vector3(0, height_to_lines, 0))
		if first:
			line2.append(middle_point + line_width_vec + Vector3(0, height_to_lines, 0))
			line2.append(middle_point + width_vec + Vector3(0, height_to_lines, 0))
		verts3d.append(middle_point - width_vec)
		verts3d.append(middle_point + width_vec)
		normals.append(Vector3(0,1,0))
		normals.append(Vector3(0,1,0))

	# Process final point
	var length = len(shape_points)
	start_point = Vector2(shape_points[length-2]["x"], shape_points[length-2]["y"])
	end_point = Vector2(shape_points[length-1]["x"], shape_points[length-1]["y"])
	orthnorm = (end_point - start_point).orthogonal().normalized() * width / 2
	prepoint1 = Vector3(end_point.x + orthnorm.x, height, end_point.y + orthnorm.y)
	prepoint2 = Vector3(end_point.x - orthnorm.x, height, end_point.y - orthnorm.y)
	line_orth = (end_point - start_point).orthogonal().normalized() * ((width) / 2 - line_width)
	line1.append(prepoint1 + Vector3(0, height_to_lines, 0))
	line1.append(Vector3(end_point.x + line_orth.x, height + height_to_lines, end_point.y + line_orth.y))
	if first:
		line2.append(Vector3(end_point.x - line_orth.x, height + height_to_lines, end_point.y - line_orth.y))
		line2.append(prepoint2 + Vector3(0, height_to_lines, 0))
	verts3d.append(prepoint1)
	normals.append(Vector3(0,1,0))
	verts3d.append(prepoint2)
	normals.append(Vector3(0,1,0))

	# Define triangle indices for mesh
	for i in range(len(shape_points) - 1):
		index.append(2*i + 1)
		index.append(2*i)
		index.append(2*i + 2)
		index.append(2*i + 2)
		index.append(2*i + 3)
		index.append(2*i + 1)

	# Rail vs road
	if is_rail:
		TrainTreck.create_train_wood(verts3d, -width / 2, width)
	else:
		var arr_mesh = ArrayMesh.new()
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts3d
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = index
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var m = MeshInstance3D.new()
		m.mesh = arr_mesh
		m.set_surface_override_material(0, material)
		add_child(m)

	if first:
		return [line1, line2]
	return []
	
# Function to create the mesh for outer road lines (edges)
func create_outer_line_roads(line: PackedVector3Array):
	var normals = PackedVector3Array()
	var index = PackedInt32Array()
	
	# Set all normals pointing upward
	for i in range(len(line)):
		normals.append(Vector3(0, 1, 0))
	
	# Build the index array to define triangles between the two edges
	for i in range((len(line) / 2) - 1):
		# First triangle of the quad
		index.append(2 * i + 1)
		index.append(2 * i)
		index.append(2 * i + 2)
		
		# Second triangle of the quad
		index.append(2 * i + 2)
		index.append(2 * i + 3)
		index.append(2 * i + 1)
	
	# Create and populate the mesh with vertices, normals, and triangle indices
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = line
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = index
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Create and configure a MeshInstance3D
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	
	# Set a material for visual appearance
	var new_material = StandardMaterial3D.new()
	new_material.albedo_color = Color.FLORAL_WHITE 
	m.set_surface_override_material(0, new_material)
	
	add_child(m)


# Function to create dashed (dotted) lane lines between roads
func create_dotted_lines(line: PackedVector3Array, offset):
	var length_of_current_stripe = 0.0
	var last_point1 = Vector3()
	var last_point2 = Vector3()
	var is_stripe = false
	var j = 0.0

	# Iterate through each segment in the road
	for k in range((len(line) / 2) - 1):
		var i = 2 * k
		var middle_line = line[i + 2] - line[i]
		var norm = middle_line.normalized()
		var orth = Vector2(middle_line.x, middle_line.z).orthogonal().normalized()
		var orth3d = Vector3(orth.x, 0, orth.y)
		var number_of_stripes = middle_line.length() / dotted_distance
			
		while j <= number_of_stripes:
			if is_stripe:
				var verts = PackedVector3Array()
				var new_j = j + 1
				
				# If it's the first stripe and a continuation
				if j == 0.0:
					verts.append(last_point2)
					verts.append(last_point1)
					new_j = 1 - length_of_current_stripe
				else:
					# Generate two starting points of the stripe
					verts.append(line[i] + j * norm * dotted_distance - orth3d * (line_width / 2 - offset))
					verts.append(line[i] + j * norm * dotted_distance + orth3d * (line_width / 2 + offset))
				
				# Handle end-of-segment edge case
				if j + 1 > number_of_stripes:
					var angle_vec = (line[i + 3] - line[i + 2]).normalized()
					var angle = -Vector2(angle_vec.x, angle_vec.z).angle()
					last_point1 = line[i + 2] - angle_vec * line_width / (2 * cos(angle))
					last_point2 = line[i + 2] + angle_vec * line_width / (2 * cos(angle))
					length_of_current_stripe = number_of_stripes - j
					verts.append(last_point2)
					verts.append(last_point1)
				else:
					# Generate two ending points of the stripe
					verts.append(line[i] + (new_j) * norm * dotted_distance - orth3d * (line_width / 2 - offset))
					verts.append(line[i] + (new_j) * norm * dotted_distance + orth3d * (line_width / 2 + offset))
					is_stripe = false
				
				j = new_j
				create_stripe(verts)
				
			else:
				var new_j = j + 1
				if j == 0.0:
					new_j = 1 - length_of_current_stripe
				if j + 1 > number_of_stripes:
					length_of_current_stripe = number_of_stripes - j
				else:
					is_stripe = true
				j = new_j
		
		j = 0.0


# Create mesh for a single stripe (dashed line segment)
func create_stripe(line: PackedVector3Array):
	var normals = PackedVector3Array()
	var index = PackedInt32Array()

	# Upward-facing normals
	for i in range(len(line)):
		normals.append(Vector3(0, 1, 0))
		
	# Connect vertices into triangles
	for i in range((len(line) / 2) - 1):
		index.append(2 * i)
		index.append(2 * i + 1)
		index.append(2 * i + 2)
		
		index.append(2 * i + 3)
		index.append(2 * i + 2)
		index.append(2 * i + 1)
	
	# Build mesh from stripe vertices
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = line
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = index
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Create MeshInstance and apply material
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	m.set_surface_override_material(0, linee_material)
	add_child(m)


# Function to add directional arrows to the road
func add_arrow(dir, p1, p2):
	# Convert input coordinates to 3D vectors
	var point1 = Vector3(p1["x"], p1["z"], p1["y"])
	var point2 = Vector3(p2["x"], p2["z"], p2["y"])

	# Get normalized direction and angle between the two points
	var norm_vec = (point2 - point1).normalized()
	var angle = -Vector2(norm_vec.x, norm_vec.z).angle()
	
	# Add arrows depending on the direction list
	for i in dir:
		match i:
			"straight":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
				arrow.position = point2 - norm_vec * (distance_road_to_arrow + arrow_length) + Vector3(0, height_to_lines, 0)
				arrow.scale_object_local(Vector3(1, 1, arrow_length))
				arrow.rotate_y(angle - PI / 2)
				arrow.name = str(name)

			"right":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
				arrow.position = point2 - norm_vec * (distance_road_to_arrow + arrow_length / 4) + Vector3(0, height_to_lines, 0)
				arrow.scale_object_local(Vector3(1, 1, arrow_length / 3))
				arrow.rotate_y(angle - PI)
				arrow.name = str(name)

			"left":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
				arrow.position = point2 - norm_vec * (distance_road_to_arrow + arrow_length / 4) + Vector3(0, height_to_lines, 0)
				arrow.scale_object_local(Vector3(1, 1, arrow_length / 3))
				arrow.rotate_y(angle)
				arrow.name = str(name)

			"partleft":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
				arrow.position = point2 - norm_vec * (distance_road_to_arrow + arrow_length / 3) + Vector3(0, height_to_lines, 0)
				arrow.scale_object_local(Vector3(1, 1, arrow_length / 3))
				arrow.rotate_y(angle - PI * 1 / 4)
				arrow.name = str(name)

			"partright":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
				arrow.position = point2 - norm_vec * (distance_road_to_arrow + arrow_length / 3) + Vector3(0.5, height_to_lines, 0)
				arrow.scale_object_local(Vector3(1, 1, arrow_length / 3))
				arrow.rotate_y(angle - PI * 3 / 4)
				arrow.name = str(name)

			"turn":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
				arrow.position = point2 - norm_vec * (distance_road_to_arrow + arrow_length * 1 / 4) + Vector3(0, height_to_lines, 0)
				arrow.scale_object_local(Vector3(1, 1, arrow_length))
				arrow.rotate_y(angle + PI / 2)
				arrow.name = str(name)

			_:
				# Log an error if direction is unknown
				Error.append_error("The direction: " + i + " of a lane is not known")
	

				
			
				
				
