extends Node3D

@onready var Vehicle = $"../Vehicles"  # Reference to Vehicles node to get vehicle positions
@onready var Camera = $"../../Camera3D" # Camera node reference (unused here, but likely useful)
@onready var RSU = $"../RSU"            # Reference to RSU nodes for alternative positions

var bubble = preload("res://Scenes/bubble.tscn")  # Bubble scene preloaded for instantiation

var height_above_vehicle = 3  # Vertical offset above vehicle/RSU for placing the bubble

@onready var Movie = $"../.."   # Reference to Movie node for retrieving bubble data by index

var all_bubbles = {}        # Stores active bubbles with: [position index, start time, end time]
var all_bubbles_temp = {}   # Temporarily stores bubble IDs and their last update time
var all_bubbles_meta = {}   # Stores metadata: [to_id, instantiated bubble node, etc.] per bubble ID

var all_scale = 1.0         # Global scale multiplier for all bubbles

# Add a new bubble or update an existing bubble with start time and position index
func add_addition(data: Dictionary, pos: int) -> void:
	all_bubbles_temp[data["id"]] = data["t"]  # Record latest update time for bubble
	all_bubbles[data["id"]] = [pos, data["t"], Globals.length_of_programm]  # Store position and lifespan

# Mark a bubble for removal based on data (calls helper with id and time)
func add_removal(data: Dictionary) -> void:
	add_removal_t(data["id"], data["t"])

# Helper to remove bubble if the removal time is sufficiently after last update (respecting look_back)
func add_removal_t(id: String, t: float) -> void:
	if all_bubbles_temp.has(id):
		if t - all_bubbles_temp[id] < Globals.look_back:
			# Removal is too soon after last update — just erase immediately
			all_bubbles.erase(id)
			all_bubbles_temp.erase(id)
		else:
			# Delay removal — update end time of bubble
			all_bubbles_temp.erase(id)
			all_bubbles[id][1] = t

# Remove all bubbles and clear metadata (e.g., on reset)
func clean_all():
	for child in get_children():
		child.queue_free()
	all_bubbles_meta = {}

# Create and store a bubble instance based on bubble data and position index
func create_bubbles(bubble: Dictionary, pos: int):
	var info = [ bubble["to_id"] ]  # Target ID (vehicle or RSU)
	var color_dic = bubble["color"]
	# Instantiate bubble with color and message, and store reference
	info.append(instantiate_bubble(info, Color(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"]), bubble["message"]))
	all_bubbles_meta[bubble["id"]] = info
	add_addition(bubble, pos)

# Update all bubbles' positions based on current Vehicle or RSU positions
func update(t: float):
	for key in all_bubbles_meta.keys():
		var this_bubble = all_bubbles_meta[key]
		var to_str = this_bubble[0]  # Target entity ID
		if Vehicle.is_there(to_str):
			transform(Vehicle.get_pos(to_str), this_bubble[1])  # Update bubble position above vehicle
		elif RSU.is_there(to_str):
			transform(RSU.get_pos(to_str), this_bubble[1])      # Update bubble position above RSU
		else:
			# If target no longer exists, remove bubble instance and metadata
			this_bubble[1].queue_free()
			all_bubbles_meta.erase(key)
			add_removal_t(key, t)

# Create bubbles that should be active at time t according to their stored start/end times
func update_to_time(t: float):
	for key in all_bubbles.keys():
		var this_key = all_bubbles[key]
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])  # Retrieve bubble data for given position index
			create_bubbles(json, this_key[0])

# Remove a bubble explicitly by its dictionary data
func remove_bubble(bubble: Dictionary):
	var id = bubble["id"]
	if all_bubbles_meta.has(id):
		var ins = all_bubbles_meta[id][1]
		ins.queue_free()  # Remove bubble node from scene
		all_bubbles_meta.erase(id)
		add_removal(bubble)

# Instantiate a new bubble scene, position it, and set its color/message
func instantiate_bubble(info: Array, color: Color, message: String):
	var to = Vehicle.get_pos(info[0])
	if to == null:
		to = RSU.get_pos(info[0])  # Fallback to RSU position if vehicle not found
	var bubble_instance = bubble.instantiate()
	add_child(bubble_instance)
	transform(to, bubble_instance)
	bubble_instance.change_obj(color, message)  # Apply color and message to bubble visual

	return bubble_instance

# Position bubble above target position with offset and scale
func transform(to: Vector3, ins) -> void:
	ins.global_position = to + Vector3(0, height_above_vehicle, 0)
	ins.scale = Vector3(all_scale, all_scale, 1)

# Check if bubble with given ID currently exists
func is_there(id: String) -> bool:
	return all_bubbles_meta.has(id)

# Slot to update scale of all bubbles based on slider input or UI value change
func _on_conn_scale_value_changed(value: float) -> void:
	if value == 0.0:
		value = 0.001  # Avoid zero scale to prevent invisibility
	for key in all_bubbles_meta.keys():
		var this_conn = all_bubbles_meta[key][1]
		this_conn.scale = Vector3(1000 * value, 1000 * value, 1)  # Scale bubbles proportionally
	all_scale = value * 1000  # Store global scale multiplier
