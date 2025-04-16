extends Node3D

#set height of road so that it wont cut with other objects e.g. Junctions
var height_to_lines = 0.01

var arrow_length = 2.0
var distance_road_to_arrow = 2.0


var ArrowStraight = preload("res://Scenes/arrow_straight.tscn")
var ArrowLeft
var ArrowRight


@onready var Error = $"../.."
@onready var TrafficLights = $"../../DynamicObjects/TrafficLight"

@export var dotted_distance = 0.5
@export var line_width = 0.15
@export var height = 1.0

@export var normal_lane_color = Color.DIM_GRAY
@export var bus_lane_color = Color.DARK_SLATE_GRAY
@export var bike_lane_color = Color.FIREBRICK

func create_roads(data): 
	for road in data:
		var lane_error = false

		var lines = []
		#a road can have more then one lane
		
		var first = true
		if not road.has("id"):
			Error.append_error("A Road has no ID")
			continue
		if not road.has("lanes"):
			Error.append_error("The Road with the id: " + road["id"] + " has no entry \"lanes\" ")
			continue
		
		for lane in road["lanes"]:
			if not lane.has("id"):
				Error.append_error("A lane on the road " + road["id"] + " has no ID")
				lane_error = true
				continue
			if not lane.has("shape"):
				Error.append_error("The lane with the id: " + lane["id"] + " on the road " + road["id"] + " has no entry \"shape\" ")
				lane_error = true
				continue
			if not lane.has("width"):
				Error.append_error("The lane with the id: " + lane["id"] + " on the road " + road["id"] + " has no entry \"width\" ")
				lane_error = true
				continue
			if not lane.has("allowedClasses"):
				Error.append_error("The lane with the id: " + lane["id"] + " on the road " + road["id"] + " has no entry \"allowedClasses\" ")
				lane_error = true
				continue
			if not lane.has("links"):
				Error.append_error("The lane with the id: " + lane["id"] + " on the road " + road["id"] + " has no entry \"links\" ")
				lane_error = true
				continue

			
			var shape_points = lane["shape"]
			var name = lane["id"]
			var width = lane["width"]
			var kind = lane["allowedClasses"]
			var color = Color()
			var directions = []
						#error if there are less then 2 shape points
			if len(shape_points) < 2:
				Error.append_error("The lane with the ID: " + str(name)  + " on the road " + road["id"] +  " has only one ore no shape point")
				lane_error = true

				continue
				
			if lane["links"] is Array:
		
					for dir in lane["links"]:
						directions.append(dir["direction"])
						var shape1 = shape_points[-1]
						var shape2 = shape_points[-2]
					
						TrafficLights.set_direction(name, str(dir["lane"]), Vector3(shape1["x"], shape1["z"], shape1["y"]),Vector3(shape2["x"], shape2["z"], shape2["y"]), width, dir["direction"])
				
			if kind.has("bus"):
				color = bus_lane_color
			elif kind.has("bicycle"):
				color = bike_lane_color
			else:
				color = normal_lane_color
			
			

			
			#create road
			if first:
				var zw = create_road(width, shape_points, name, true, color)
				if zw.is_empty():
					lane_error = true
					continue
				lines.append(zw[1])
				lines.append(zw[0])
			else:
				var zw = create_road(width, shape_points, name, false, color)
				if zw.is_empty():
					lane_error = true
					continue
				lines.append(zw[0])
			
			add_arrow(directions, shape_points[-2], shape_points[-1])
			first = false
		
		if lane_error:
			continue
	
		create_outer_line_roads(lines[0])
		create_outer_line_roads(lines[-1])
		
		for i in range(len(lines)-2):
			create_dotted_lines(lines[i+1])





func create_road(width: float, shape_points, name: String, first: bool, color: Color) -> Array[PackedVector3Array]:
	
	#important values for ArrayMesh
	var verts3d = PackedVector3Array()
	var normals = PackedVector3Array()
	var index = PackedInt32Array()
	
	var line1 = PackedVector3Array()
	var line2 = PackedVector3Array()

	
	#calculate the edges of the road because only the middle of the lane is given
	if not shape_points[0].has("x") or not shape_points[0].has("y") or not shape_points[1].has("x") or not shape_points[1].has("y") :
		Error.append_error("The Road with the Lane with the id: " + name + " has an invalid shapepoint ")
		return []

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
	
	line1.append(prepoint1 +Vector3(0, height_to_lines, 0))
	line1.append(Vector3(start_point.x + line_orth.x, height + height_to_lines, start_point.y + line_orth.y))
	if first:
		line2.append(Vector3(start_point.x - line_orth.x, height + height_to_lines, start_point.y - line_orth.y))
		line2.append(prepoint2+ Vector3(0, height_to_lines, 0))

					
	for i in range(1, len(shape_points)-1):
		start_point = Vector3(shape_points[i-1]["x"], height, shape_points[i-1]["y"])
		var middle_point  = Vector3(shape_points[i]["x"], height, shape_points[i]["y"])
		end_point = Vector3(shape_points[i+1]["x"], height, shape_points[i+1]["y"])
		var path1 = Vector2(middle_point.x-start_point.x, middle_point.z-start_point.z).normalized()
		var path2 = Vector2(end_point.x-middle_point.x, end_point.z - middle_point.z).normalized()
		var orth = (path1+path2).orthogonal().normalized()
		var angle = path1.angle_to(orth)

		var width_vec = Vector3(orth.x, 0, orth.y) * (width/(sin(angle)*2))
		var line_width_vec = Vector3(orth.x, 0,orth.y) * ((width/2 - line_width) / sin(angle))
		
		line1.append(middle_point - width_vec + Vector3(0, height_to_lines, 0))
		line1.append(middle_point -line_width_vec + Vector3(0, height_to_lines, 0))
		if first:
			line2.append(middle_point + line_width_vec + Vector3(0, height_to_lines, 0))
			line2.append(middle_point + width_vec + Vector3(0, height_to_lines, 0))
		
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
	
	line_orth = (end_point-start_point).orthogonal().normalized() * ((width) / 2 -line_width)
	
	line1.append(prepoint1 + Vector3(0, height_to_lines, 0))
	line1.append(Vector3(end_point.x + line_orth.x, height + height_to_lines, end_point.y + line_orth.y))
	if first:
		line2.append(Vector3(end_point.x - line_orth.x, height + height_to_lines, end_point.y - line_orth.y))
		line2.append(prepoint2 + Vector3(0, height_to_lines, 0))

	
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

 

	new_material.albedo_color = color

		
	m.set_surface_override_material(0, new_material)
	add_child(m)
	if first:
		return[line1, line2]
	return [line1]
	
func create_outer_line_roads(line: PackedVector3Array):
	var normals = PackedVector3Array()
	var index = PackedInt32Array()

	for i in range(len(line)):
		normals.append(Vector3(0,1,0))
		
	for i in range((len(line) / 2)-1):
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
	arrays[Mesh.ARRAY_VERTEX] = line
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = index

	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
			
	# create Material for each instance
	var new_material = StandardMaterial3D.new()

	new_material.albedo_color = Color.FLORAL_WHITE 

		
	m.set_surface_override_material(0, new_material)
	add_child(m)
	
func create_dotted_lines(line: PackedVector3Array):
	
	var length_of_current_stripe = 0.0
	var last_point1 = Vector3()
	var last_point2 = Vector3()
	var is_stripe = false
	var j = 0.0

	#move the stripe in the middle of the to lines
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
					verts.append(line[i] + j* norm * dotted_distance - orth3d * line_width / 2)
					verts.append(line[i] + j* norm * dotted_distance + orth3d * line_width / 2)	
				
				#last two verts at each stripe
				if j+1 > number_of_stripes:
					var angle_vec = (line[i+3] - line[i+2]).normalized()
					var angle = -Vector2(angle_vec.x, angle_vec.z).angle()
					last_point1 = line[i+2] - angle_vec*line_width/(2 * cos(angle))
					last_point2 = line[i+2] + angle_vec*line_width/(2 * cos(angle))
					length_of_current_stripe = number_of_stripes-j
					verts.append(last_point2)

					verts.append(last_point1)
				else:
					
					verts.append(line[i] + (new_j)* norm * dotted_distance - orth3d * line_width / 2)
					verts.append(line[i] + (new_j)* norm * dotted_distance + orth3d * line_width / 2)
					is_stripe = false
				j = new_j 
				create_stripe(verts)

				
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

						

func create_stripe(line: PackedVector3Array):
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
			
	# create Material for each instance
	var new_material = StandardMaterial3D.new()

	new_material.albedo_color = Color.FLORAL_WHITE 

		
	m.set_surface_override_material(0, new_material)
	add_child(m)
	

func add_arrow(dir, p1, p2):
	var point1 = Vector3(p1["x"], p1["z"], p1["y"])
	var point2 = Vector3(p2["x"], p2["z"], p2["y"])

	var norm_vec = (point2-point1).normalized()
	var angle = -Vector2(norm_vec.x, norm_vec.z).angle()
	
	for i in dir:
		match i: 
			"straight":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
			
				#transform the arrow
				arrow.position = point2-norm_vec*(distance_road_to_arrow + arrow_length)+ Vector3(0,height_to_lines,0)
				arrow.scale_object_local(Vector3(1,1,arrow_length))
				arrow.rotate_y(angle - PI/2)
				arrow.name = str(name) 
			"right":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
			
				#transform the arrow
				arrow.position = point2-norm_vec*(distance_road_to_arrow + arrow_length /4 )+ Vector3(0,height_to_lines,0)
				arrow.scale_object_local(Vector3(1,1,arrow_length / 3))
				arrow.rotate_y(angle -PI)
				arrow.name = str(name)
			"left":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
			
				#transform the arrow
				arrow.position = point2-norm_vec*(distance_road_to_arrow + arrow_length / 4 )+ Vector3(0,height_to_lines,0)
				arrow.scale_object_local(Vector3(1,1,arrow_length / 3))
				arrow.rotate_y(angle)
				arrow.name = str(name)
			"partleft":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
			
				#transform the arrow
				arrow.position = point2-norm_vec*(distance_road_to_arrow + arrow_length / 3 )+ Vector3(0,height_to_lines,0)
				arrow.scale_object_local(Vector3(1,1,arrow_length / 3))
				arrow.rotate_y(angle-PI * 1 /4)
				arrow.name = str(name)
			"partright":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
			
				#transform the arrow
				arrow.position = point2-norm_vec*(distance_road_to_arrow + arrow_length / 3 )+ Vector3(0.5,height_to_lines,0)
				arrow.scale_object_local(Vector3(1,1,arrow_length / 3))
				arrow.rotate_y(angle-PI *3 /4)
				arrow.name = str(name)
			"turn":
				var arrow = ArrowStraight.instantiate()
				add_child(arrow)
			
				#transform the arrow
				arrow.position = point2-norm_vec*(distance_road_to_arrow + arrow_length * 1/4)+ Vector3(0,height_to_lines,0)
				arrow.scale_object_local(Vector3(1,1,arrow_length))
				arrow.rotate_y(angle + PI/2)
				arrow.name = str(name) 
				
			_:
				Error.append_error("The direction: " + i + " of a lane is not known" )
			
				
	

				
			
				
				
