extends Node3D

@onready var Vehicle = $"../Vehicles"
@onready var RSU = $"../RSU"

var Connector = preload("res://Scenes/connector.tscn")

@onready var Movie = $"../.."

var all_conns = {}        # Active connections with [pos, start_time, end_time]
var all_conns_temp = {}   # Temporary connection times for look-back checks
var all_conns_meta = {}   # Instantiated connection objects keyed by connection ID
var all_scale = 1.0       # Scale factor for connections

# Register addition of a connection at a given position and time
func add_addition(data: Dictionary, pos: int) -> void:
	all_conns_temp[data["id"]] = data["t"]
	all_conns[data["id"]] = [pos, data["t"], Globals.length_of_programm]

# Register removal of connection by data dictionary
func add_removal(data: Dictionary) -> void:
	add_removal_t(data["id"], data["t"])

# Remove connection by ID and time, considering look-back to avoid premature deletion
func add_removal_t(id: String, t: float) -> void:
	if all_conns_temp.has(id):
		if t - all_conns_temp[id] < Globals.look_back:
			all_conns.erase(id)
			all_conns_temp.erase(id)
		else:
			all_conns_temp.erase(id)
			all_conns[id][1] = t

# Remove all instantiated connections and clear metadata
func clean_all():
	for child in get_children():
		child.queue_free()
	all_conns_meta = {}

# Create a connection instance and store metadata
func create_conns(conn: Dictionary, pos: int):
	var info = [conn["from_id"], conn["to_id"]]
	var color_dic = conn["color"]
	info.append(instantiate_con(info, Color(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"])))
	all_conns_meta[conn["id"]] = info
	add_addition(conn, pos)

# Update all connections based on current time and existence of linked nodes
func update(t: float):
	for key in all_conns_meta.keys():
		var this_con = all_conns_meta[key]
		var from_str = this_con[0]
		var to_str = this_con[1]

		# Check existence of "from" and "to" entities and update connection transform accordingly
		if Vehicle.is_there(from_str):
			if Vehicle.is_there(to_str):
				transform(Vehicle.get_pos(from_str), Vehicle.get_pos(to_str), this_con[2])
			elif RSU.is_there(to_str):
				transform(Vehicle.get_pos(from_str), RSU.get_pos(to_str), this_con[2])
			else:
				# Remove connection if "to" does not exist
				this_con[2].queue_free()
				all_conns_meta.erase(key)
				add_removal_t(key, t)
		elif RSU.is_there(from_str):
			if Vehicle.is_there(to_str):
				transform(RSU.get_pos(from_str), Vehicle.get_pos(to_str), this_con[2])
			elif RSU.is_there(to_str):
				transform(RSU.get_pos(from_str), RSU.get_pos(to_str), this_con[2])
			else:
				# Remove connection if "to" does not exist
				this_con[2].queue_free()
				all_conns_meta.erase(key)
				add_removal_t(key, t)
		else:
			# Remove connection if "from" does not exist
			this_con[2].queue_free()
			all_conns_meta.erase(key)
			add_removal_t(key, t)

# Update connections based on time t, creating them if within active interval
func update_to_time(t: float):
	for key in all_conns.keys():
		var this_key = all_conns[key]
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])
			create_conns(json, this_key[0])

# Remove connection instance and metadata by connection dictionary
func remove_con(conn: Dictionary):
	var id = conn["id"]
	if all_conns_meta.has(id):
		var ins = all_conns_meta[id][2]
		ins.queue_free()
		all_conns_meta.erase(id)
		add_removal(conn)

# Instantiate a connection object between two points with a given color
func instantiate_con(info: Array, color: Color):
	var from = Vehicle.get_pos(info[0])
	var to = Vehicle.get_pos(info[1])
	if from == null:
		from = RSU.get_pos(info[0])
	if to == null:
		to = RSU.get_pos(info[1])
	
	var connection = Connector.instantiate()
	connection.transform_obj(Movie.get_material(color)) # Apply material with color
	add_child(connection)
	
	# Set initial transform based on positions
	transform(from, to, connection)
	return connection

# Transform and scale connection object from 'from' to 'to' positions
func transform(from: Vector3, to: Vector3, ins):
	var vec = to - from
	var length = vec.length()

	if length > 0.001: # Avoid division by zero or too small distances
		var direction = vec.normalized()

		# Create a new basis oriented along the direction vector (X-axis)
		var right = direction
		var up = Vector3.UP

		# If direction is too close to UP vector, use FORWARD as alternative up vector
		if abs(direction.dot(up)) > 0.99:
			up = Vector3.FORWARD

		var forward = right.cross(up).normalized()
		up = forward.cross(right).normalized()

		var basis = Basis(right.normalized(), up, forward)
		ins.global_transform = Transform3D(basis, to)

		# Scale connection along X by length, scale Y and Z by all_scale factor
		ins.scale = Vector3(length, all_scale, all_scale)

# Check if connection with given ID exists
func is_there(id: String) -> bool:
	return all_conns_meta.has(id)

# Adjust the scale of all connections when scale value changes
func _on_conn_scale_value_changed(value: float) -> void:
	if value == 0.0:
		value = 0.001  # this value is needed for normal scenes to have a scale of 1
	for key in all_conns_meta.keys():
		var this_conn = all_conns_meta[key][2]
		this_conn.scale = Vector3(this_conn.scale.x, 1000 * value, 1000 * value)
	all_scale = value * 1000
