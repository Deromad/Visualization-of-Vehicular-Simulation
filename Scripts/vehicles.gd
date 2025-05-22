extends Node3D

# Reference to the main scene for material handling
@onready var Movie = $"../.."

# Preloaded vehicle scenes
var VehicleScene = preload("res://Scenes/passenger.tscn")
var Satellite = preload("res://Scenes/leo_2.tscn")

# Data storage for vehicles and metadata
var all_vehicles = {}            # Stores simulation tracking info
var all_vehicles_temp = {}       # Temporary storage to help manage lifetime
var all_vehicles_meta = {}       # Holds metadata and actual instances
var materials_used = {}          # Material cache (not yet used)

# Special handling for scaling
var not_scalable = []            # IDs of vehicles (e.g. satellites) that don't scale
var twopart_classes = ["bus", "truck", "rail", "trailer"]  # Vehicles with multiple parts
var all_scale = 1.0              # Global scale for normal vehicles
var all_scale_satellite = 10000.0 # Global scale for satellites

# Exported settings
@export var wagon_length = 8.0   # Used for rail/truck length
@export var truck_ratio = 0.2    # Ratio of trailer to truck length

# Helper flags
var first = true                 # Used to flag first vehicle
var first_id                     # Stores ID of the first vehicle added

# Called when a new vehicle is added
func add_addition(data: Dictionary, pos: float) -> void:
	if data["t"] > Globals.max_t:
		if data["vclass"] in twopart_classes:
			var heading = data["heading"]
			var posi = data["pos"]
			all_vehicles_temp[data["id"]] = data["t"]
			# Store [position, path points, heading vector, update positions]
			all_vehicles[data["id"]] = [
				pos, 
				[Vector2(posi["x"], posi["y"])], 
				Vector2(heading["x"], heading["y"]).normalized(), 
				[pos]
			]
		else:
			all_vehicles_temp[data["id"]] = data["t"]
			all_vehicles[data["id"]] = [pos]

# Updates vehicle's movement path if heading changes
func add_update(data: Dictionary, posi: int) -> void:
	if data["t"] > Globals.max_t:
		var this_vehic = all_vehicles[data["id"]]
		if this_vehic.size() > 1:
			var pos = data["pos"]
			var heading = data["heading"]
			var vec = Vector2(heading["x"], heading["y"]).normalized()

			# Add intersection point when heading changes
			if vec != this_vehic[2]:
				this_vehic[1].append(
					intersect_lines(this_vehic[1][-1], this_vehic[2], Vector2(pos["x"], pos["y"]), vec)
				)
				this_vehic[2] = vec
				this_vehic[3].append(posi)

# Finds intersection point of two lines in 2D space
func intersect_lines(p: Vector2, r: Vector2, q: Vector2, d: Vector2) -> Vector2:
	var cross = r.cross(d)
	if abs(cross) < 0.1:
		return q  # Lines are nearly parallel

	var q_p = q - p
	var t = q_p.cross(d) / cross
	return p + t * r  # Intersection point

# Removes vehicle if it's recently added and no longer relevant
func add_removal(data: Dictionary) -> void:
	if data["t"] > Globals.max_t:
		var id = data["id"]
		if all_vehicles_temp.has(id):
			if data["t"] - all_vehicles_temp[id] < Globals.look_back:
				all_vehicles.erase(id)
				all_vehicles_temp.erase(id)
			else:
				all_vehicles_temp.erase(id)

# Clears all currently loaded vehicle instances from scene
func clean_all():
	for child in get_children():
		child.queue_free()
	all_vehicles_meta = {}

# Instantiates the correct vehicle type based on its class
func create_vehicles(vehicle, pos):
	match vehicle["vclass"]:
		"satellite":
			instantiate_satellite(vehicle, pos)
		"bus":
			instantiate_bus(vehicle, pos)
		"rail":
			instantiate_train(vehicle, pos)
		"truck", "trailer":
			instantiate_lkw(vehicle, pos)
		_:
			instantiate_single_vehic(vehicle, pos)

# Instantiates a single vehicle (e.g. car, motorcycle)
func instantiate_single_vehic(vehicle: Dictionary, pos: int):
	var v_id = str(vehicle["id"])
	var color_dic = vehicle["color"]
	var color = Color.from_rgba8(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"])
	var height = vehicle["height"]
	var length = vehicle["length"]
	var width = vehicle["width"]

	var dimensions = Vector3(length, height, width) * all_scale
	var heading_angle = -Vector2(vehicle["heading"]["x"], vehicle["heading"]["y"]).angle()
	var startpos = Vector3(vehicle["pos"]["x"], height / 2 + vehicle["pos"]["z"], vehicle["pos"]["y"])

	var vehicle_instance = VehicleScene.instantiate()
	add_child(vehicle_instance)

	vehicle_instance.global_translate(startpos)
	vehicle_instance.scale_object_local(dimensions)
	vehicle_instance.global_rotation = Vector3(0, heading_angle, 0)
	vehicle_instance.recolor_obj(Movie.get_material(color))
	vehicle_instance.name = v_id

	# Store instance metadata
	all_vehicles_meta[v_id] = {
		"height": height,
		"instance": [vehicle_instance]
	}

	# Log the addition in vehicle tracker
	add_addition(vehicle, pos)

# Instantiates and scales a satellite object
func instantiate_satellite(vehicle: Dictionary, pos: int):
	var v_id = str(vehicle["id"])
	not_scalable.append(v_id)

	var color_dic = vehicle["color"]
	var color = Color.from_rgba8(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"])
	var height = vehicle["height"]
	var length = vehicle["length"]
	var width = vehicle["width"]

	var dimensions = Vector3(length, height, width) * all_scale_satellite
	var heading_angle = -Vector2(vehicle["heading"]["x"], vehicle["heading"]["y"]).angle()
	var startpos = Vector3(vehicle["pos"]["x"], height / 2 + vehicle["pos"]["z"], vehicle["pos"]["y"])

	var vehicle_instance = Satellite.instantiate()
	add_child(vehicle_instance)

	vehicle_instance.global_translate(startpos)
	vehicle_instance.scale_object_local(dimensions)
	vehicle_instance.global_rotation = Vector3(0, heading_angle, 0)
	vehicle_instance.recolor_obj(Movie.get_material(color))

	all_vehicles_meta[v_id] = {
		"height": height,
		"instance": [vehicle_instance]
	}

	add_addition(vehicle, pos)
func instantiate_bus(vehicle: Dictionary, pos: int):
	# Extract vehicle metadata
	var v_id = str(vehicle["id"])
	var color_dic = vehicle["color"]
	var color = Color.from_rgba8(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"])
	var height = vehicle["height"]
	var length = vehicle["length"]
	var width = vehicle["width"]

	# Set the dimensions for each bus segment
	var dimensions = Vector3(length / 2, height , width) * all_scale

	# Calculate heading angle from 2D vector (XZ plane in 3D)
	var heading_angle = -Vector2(vehicle["heading"]["x"], vehicle["heading"]["y"]).angle()

	# Position is in XZY order due to Godot's coordinate system
	var startpos = Vector3(vehicle["pos"]["x"], height / 2 +  vehicle["pos"]["z"], vehicle["pos"]["y"])

	# Instantiate the front and rear segments of the bus
	var vehicle_instance1 = VehicleScene.instantiate()
	var vehicle_instance2 = VehicleScene.instantiate()
	add_child(vehicle_instance1)
	add_child(vehicle_instance2)

	# Position front segment
	vehicle_instance1.global_translate(startpos)
	vehicle_instance1.scale = dimensions
	vehicle_instance1.global_rotation = Vector3(0, heading_angle, 0)
	vehicle_instance1.recolor_obj(Movie.get_material(color))

	# Position rear segment slightly behind the front, based on heading
	vehicle_instance2.global_translate(startpos - Vector3(vehicle["heading"]["x"], 0, vehicle["heading"]["y"]).normalized() * length / 2)
	vehicle_instance2.scale = dimensions
	vehicle_instance2.global_rotation = Vector3(0, heading_angle, 0)
	vehicle_instance2.recolor_obj(Movie.get_material(color))

	# Store bus metadata for updates and tracking
	all_vehicles_meta[v_id] = {}
	all_vehicles_meta[v_id]["height"] = height
	all_vehicles_meta[v_id]["length"] = [length / 2, length / 2]
	all_vehicles_meta[v_id]["pointer"] = 0
	all_vehicles_meta[v_id]["lh"] = Vector2(vehicle["heading"]["x"], vehicle["heading"]["y"])
	all_vehicles_meta[v_id]["instance"] = [vehicle_instance1, vehicle_instance2]

	add_addition(vehicle, pos)

func instantiate_train(vehicle: Dictionary, pos: int):
	# Extract metadata
	var v_id = str(vehicle["id"])
	var color_dic = vehicle["color"]
	var color = Color.from_rgba8(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"])
	var height = vehicle["height"]
	var length = vehicle["length"]
	var width = vehicle["width"]

	# Calculate how many wagons based on fixed wagon length
	var wagon_count = floor(length / wagon_length)

	# Standard wagon size
	var dimensions = Vector3(wagon_length, height , width)
	var heading_vec = Vector2(vehicle["heading"]["x"], vehicle["heading"]["y"])
	var heading_angle = -heading_vec.angle()
	var startpos = Vector3(vehicle["pos"]["x"], height / 2 +  vehicle["pos"]["z"], vehicle["pos"]["y"])

	# Arrays to store instances and per-wagon length
	var ins_array = []
	var length_array = []
	var dec_length = length

	# Instantiate wagons from rear to front (except front engine)
	for i in range(wagon_count - 1):
		var new_startpos = startpos - Vector3(heading_vec.x, 0, heading_vec.y).normalized() * (length - (i + 1) * wagon_length)
		var vehicle_instance1 = VehicleScene.instantiate()
		add_child(vehicle_instance1)

		vehicle_instance1.global_translate(new_startpos)
		vehicle_instance1.scale = dimensions * all_scale
		vehicle_instance1.global_rotation = Vector3(0, heading_angle, 0)
		vehicle_instance1.recolor_obj(Movie.get_material(color))

		length_array.append(wagon_length)
		ins_array.append(vehicle_instance1)
		dec_length -= wagon_length

	# Create the front segment (could be longer if leftover length)
	var vehicle_instance1 = VehicleScene.instantiate()
	add_child(vehicle_instance1)
	vehicle_instance1.global_translate(startpos)
	vehicle_instance1.scale = Vector3(dec_length, height , width) * all_scale
	vehicle_instance1.global_rotation = Vector3(0, heading_angle, 0)
	vehicle_instance1.recolor_obj(Movie.get_material(color))

	length_array.append(dec_length)
	ins_array.append(vehicle_instance1)

	# Reverse to match order from front to back
	length_array.reverse()
	ins_array.reverse()

	# Store metadata for movement and updates
	all_vehicles_meta[v_id] = {}
	all_vehicles_meta[v_id]["height"] = height
	all_vehicles_meta[v_id]["length"] = length_array
	all_vehicles_meta[v_id]["pointer"] = 0
	all_vehicles_meta[v_id]["lh"] = Vector2(vehicle["heading"]["x"], vehicle["heading"]["y"])
	all_vehicles_meta[v_id]["instance"] = ins_array

	add_addition(vehicle, pos)
func instantiate_lkw(vehicle: Dictionary, pos: int):
	var v_id = str(vehicle["id"])
	var color_dic = vehicle["color"]
	var color = Color.from_rgba8(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"])
	var height = vehicle["height"]
	var length = vehicle["length"]
	var width = vehicle["width"]

	# First segment: truck cab
	var dimensions = Vector3(length * truck_ratio, height , width)
	var heading_angle = -Vector2(vehicle["heading"]["x"], vehicle["heading"]["y"]).angle()
	var startpos = Vector3(vehicle["pos"]["x"], height / 2 +  vehicle["pos"]["z"], vehicle["pos"]["y"])

	var vehicle_instance1 = VehicleScene.instantiate()
	var vehicle_instance2 = VehicleScene.instantiate()
	add_child(vehicle_instance1)
	add_child(vehicle_instance2)

	vehicle_instance1.global_translate(startpos)
	vehicle_instance1.scale = dimensions * all_scale
	vehicle_instance1.global_rotation = Vector3(0, heading_angle, 0)
	vehicle_instance1.recolor_obj(Movie.get_material(color))

	# Second segment: trailer, offset by truck_ratio * length
	dimensions = Vector3(length * (1 - truck_ratio), height , width)
	vehicle_instance2.global_translate(startpos - Vector3(vehicle["heading"]["x"], 0, vehicle["heading"]["y"]).normalized() * length * truck_ratio)
	vehicle_instance2.scale = dimensions * all_scale
	vehicle_instance2.global_rotation = Vector3(0, heading_angle, 0)
	vehicle_instance2.recolor_obj(Movie.get_material(color))

	# Metadata for updates
	all_vehicles_meta[v_id] = {}
	all_vehicles_meta[v_id]["height"] = height
	all_vehicles_meta[v_id]["length"] = [length * truck_ratio, length * (1 - truck_ratio)]
	all_vehicles_meta[v_id]["pointer"] = 0
	all_vehicles_meta[v_id]["lh"] = Vector2(vehicle["heading"]["x"], vehicle["heading"]["y"])
	all_vehicles_meta[v_id]["instance"] = [vehicle_instance1, vehicle_instance2]

	add_addition(vehicle, pos)

func add_timestemps(update, posi:int):
	add_update(update, posi)
	transform_after_skip(update, posi)

	return  # The rest of the code below is currently unreachable

	var t = str(float(update["t"]))
	var v_id = str(update["id"])
	var this_vehic = all_vehicles_meta[v_id]
	var vehic_bla = all_vehicles[v_id]
	var vehicle = this_vehic["instance"]
	var number_of_wagons = vehicle.size()
	var height = this_vehic["height"]

	# Handle multi-segment vehicles
	if number_of_wagons > 1:
		var headings = update["heading"]
		var new_heading = Vector2(headings["x"], headings["y"]).normalized()

		# If heading changes, move to next segment
		if new_heading != this_vehic["lh"]:
			this_vehic["pointer"] += 1
			this_vehic["lh"] = new_heading

		var pos = this_vehic["pointer"]
		var i = pos
		var instance_pos = 0
		var startpos = Vector2(update["pos"]["x"], update["pos"]["y"])
		var nextpos

		# Walk back through previous positions to update wagon positions
		while i > 0:
			var len = this_vehic["length"][instance_pos]
			if vehic_bla[1][i].distance_to(startpos) >= len:
				if i == pos:
					nextpos = get_points_on_line_at_distance(startpos, vehic_bla[1][i], this_vehic["lh"], len)
				else:
					nextpos = get_points_on_line_at_distance(startpos, vehic_bla[1][i], vehic_bla[1][i + 1] - vehic_bla[1][i], len)

				vehicle[instance_pos].global_position = Vector3(startpos.x, height / 2, startpos.y)
				vehicle[instance_pos].global_rotation = -Vector3(0, (startpos - nextpos).angle(), 0)
				instance_pos += 1

				if instance_pos >= number_of_wagons:
					break

				startpos = nextpos
			else:
				i -= 1

		# For wagons with no data left, extrapolate backward
		for j in range(instance_pos, number_of_wagons):
			var len = vehicle[j].scale.x
			if pos == 0:
				nextpos = -len * this_vehic["lh"].normalized() + startpos
			else:
				nextpos = len * (vehic_bla[1][0] - vehic_bla[1][1]).normalized()

			vehicle[j].global_position = Vector3(startpos.x, height / 2, startpos.y)
			vehicle[j].global_rotation = Vector3(0, (startpos - nextpos).angle(), 0)
			startpos = nextpos
	else:
		# Single segment vehicle (car, etc.)
		var heading_angle = -Vector2(update["heading"]["x"], update["heading"]["y"]).angle()
		var startpos = Vector3(update["pos"]["x"], height / 2 + update["pos"]["z"], update["pos"]["y"])
		vehicle[0].global_position = startpos
		vehicle[0].global_rotation = Vector3(0, heading_angle, 0)
func transform_after_skip(update, posi:int):
	# Extract string timestamp and vehicle ID from update dictionary
	var t = str(float(update["t"]))
	var v_id = str(update["id"])

	# Proceed only if vehicle metadata exists for this ID
	if all_vehicles_meta.has(v_id):
		var this_vehic = all_vehicles_meta[v_id]
		var vehic_bla = all_vehicles[v_id]
		var vehicle = this_vehic["instance"]
		var number_of_wagons = vehicle.size()
		var height = this_vehic["height"]

		# For vehicles with multiple segments (e.g., trains, buses)
		if number_of_wagons > 1:
			var headings = update["heading"]
			var new_heading = Vector2(headings["x"], headings["y"]).normalized()

			# Find the position index in the vehicle's history before the given posi timestamp
			var pos = vehic_bla[3].size() - 1
			var k = 0
			for i in vehic_bla[3]:
				if posi < i:
					pos = k - 1
					break
				k += 1

			# Update the vehicle's current position pointer and last heading vector
			this_vehic["position"] = pos
			var heading = update["heading"]
			this_vehic["lh"] = Vector2(heading["x"], heading["y"]).normalized()

			var i = pos
			var instance_pos = 0
			var startpos = Vector2(update["pos"]["x"], update["pos"]["y"])
			var leng = vehic_bla[1].size()
			var nextpos

			# Update position and rotation for each wagon by walking backwards in history
			while i > 0:
				var len = this_vehic["length"][instance_pos]

				# Check if distance from historic point is sufficient for wagon placement
				if vehic_bla[1][i].distance_to(startpos) >= len:

					# Calculate next position on line for smooth wagon placement
					if i == leng - 1:
						nextpos = get_points_on_line_at_distance(startpos, vehic_bla[1][i], vehic_bla[2], len)
					else:
						nextpos = get_points_on_line_at_distance(startpos, vehic_bla[1][i], vehic_bla[1][i+1] - vehic_bla[1][i], len)

					# Set wagon's global position and rotation based on calculated points
					vehicle[instance_pos].global_position = Vector3(startpos.x, height / 2, startpos.y)
					vehicle[instance_pos].global_rotation = -Vector3(0, (startpos - nextpos).angle(), 0)

					instance_pos += 1
					startpos = nextpos
					pos = i - 1

					# Stop if all wagons are positioned
					if instance_pos >= number_of_wagons:
						break
				else:
					i -= 1

			# For wagons that have no direct historic data, extrapolate position and rotation backwards
			for j in range(instance_pos, number_of_wagons):
				var len = this_vehic["length"][j]
				if pos != 0:
					pos = 0
					if leng == 1:
						nextpos = get_points_on_line_at_distance(startpos, vehic_bla[1][0], vehic_bla[2], len)
					else:
						nextpos = get_points_on_line_at_distance(startpos, vehic_bla[1][0], (vehic_bla[1][1] - vehic_bla[1][0]).normalized(), len)
				else:
					if leng == 1:
						# Direct backward extrapolation if only one point exists
						nextpos = -len * vehic_bla[2] + startpos
					else:
						# Backward extrapolation based on the normalized vector between first two points
						nextpos = -len * (vehic_bla[1][1] - vehic_bla[1][0]).normalized() + startpos

				vehicle[j].global_position = Vector3(startpos.x, height / 2, startpos.y)
				vehicle[j].global_rotation = -Vector3(0, (startpos - nextpos).angle(), 0)
				startpos = nextpos

		else:
			# For single-segment vehicles (e.g., cars), just update position and rotation directly
			var heading_angle = -Vector2(update["heading"]["x"], update["heading"]["y"]).angle()
			var startpos = Vector3(update["pos"]["x"], height / 2 + update["pos"]["z"], update["pos"]["y"])
			vehicle[0].global_position = startpos
			vehicle[0].global_rotation = Vector3(0, heading_angle, 0)


# P: point, A: origin vector, r: direction vector, d: distance
func get_points_on_line_at_distance(P: Vector2, A: Vector2, r: Vector2, d: float) -> Vector2:
	# Calculate vector from P to A
	var AP = A - P

	# Coefficients of quadratic equation a*t^2 + b*t + c = 0
	var a = r.dot(r)
	var b = 2 * AP.dot(r)
	var c = AP.dot(AP) - d * d

	# Calculate discriminant to find real roots
	var discriminant = b * b - 4 * a * c
	var sqrt_disc = sqrt(discriminant)

	# Calculate both possible points on the line at distance d
	var t1 = (-b + sqrt_disc) / (2 * a)
	var t2 = (-b - sqrt_disc) / (2 * a)
	var point1 = A + t1 * r
	var point2 = A + t2 * r

	# Return the point closer to origin A (likely the correct forward point)
	if point1.distance_to(A) < point2.distance_to(A):
		return point1
	else:
		return point2


func remove_vehic(vehicle):
	# Remove vehicle instances and metadata by vehicle ID
	var id = vehicle["id"]
	if all_vehicles_meta.has(id):
		var ins = all_vehicles_meta[id]["instance"]
		for i in ins:
			i.queue_free()  # Free instance nodes from scene tree
		all_vehicles_meta.erase(id)
		add_removal(vehicle)  # Notify system that vehicle is removed


func set_to_time(data: Dictionary, posi: int):
	# Set the scene state for a specific timestamp using vehicle history and update position
	if all_vehicles.has(data["id"]):
		var pos = all_vehicles[data["id"]][0]
		var vehicle = Movie.get_line(pos)
		create_vehicles(vehicle, pos)  # Instantiate vehicles if not already
		transform_after_skip(data, posi)  # Update vehicle transform at given time


func get_pos(id: String):
	# Return the global position of the first instance of the vehicle with given ID
	if all_vehicles_meta.has(id):
		return all_vehicles_meta[id]["instance"][0].global_position
	return null


func is_there(id: String) -> bool:
	# Check if a vehicle with the given ID exists
	if all_vehicles_meta.has(id):
		return true
	return false


func _on_car_scale_value_changed(value: float) -> void:
	# Scale all vehicles except those flagged as not scalable
	for key in all_vehicles_meta.keys():
		if not key in not_scalable:
			var this_vehic = all_vehicles_meta[key]
			var this_all_scale = value / all_scale  # Calculate relative scale factor
			for ins in this_vehic["instance"]:
				ins.scale = ins.scale * this_all_scale
	all_scale = value  # Update global scale reference


func _on_satellite_scale_value_changed(value: float) -> void:
	# Avoid zero scale value to prevent errors
	if value == 0.0:
		value = 0.001
	# Scale only vehicles flagged as not scalable (special satellites)
	for key in all_vehicles_meta.keys():
		if key in not_scalable:
			var this_vehic = all_vehicles_meta[key]
			var this_all_scale_satellite = value * 1000 / all_scale_satellite  # Calculate relative scale factor
			for ins in this_vehic["instance"]:
				ins.scale = ins.scale * this_all_scale_satellite
	all_scale_satellite = value * 1000  # Update global satellite scale reference
