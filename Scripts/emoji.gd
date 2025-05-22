extends Node3D

@onready var Vehicle = $"../Vehicles"         # Reference to the Vehicles node
@onready var RSU = $"../RSU"                   # Reference to the RSU node

@onready var Camera = $"../../Camera3D"        # Reference to the Camera3D node

var Emoji = preload("res://Scenes/emoji.tscn") # Preload the emoji scene

var height_above_vehicle = 5.0                 # Height offset to position emoji above vehicle

@onready var Movie = $"../.."                   # Reference to parent Movie node

var all_emojis = {}           # Stores active emojis with [pos, start_time, end_time]
var all_emojis_temp = {}      # Temporary storage for emoji start times (for look-back checks)
var all_emojis_meta = {}      # Stores instantiated emoji objects keyed by emoji ID
var all_scale = 1.0           # Scale factor for emojis

# Register addition of an emoji with data and position index
func add_addition(data: Dictionary, pos: int) -> void:
	all_emojis_temp[data["id"]] = data["t"]
	all_emojis[data["id"]] = [pos, data["t"], Globals.length_of_programm]

# Register removal of emoji by data dictionary
func add_removal(data: Dictionary) -> void:
	add_removal_t(data["id"], data["t"])

# Remove emoji by ID and time, with look-back to prevent premature removal
func add_removal_t(id: String, t: float) -> void:
	if all_emojis_temp.has(id):
		if t - all_emojis_temp[id] < Globals.look_back:
			all_emojis.erase(id)
			all_emojis_temp.erase(id)
		else:
			all_emojis_temp.erase(id)
			all_emojis[id][1] = t

# Remove all instantiated emojis and clear metadata
func clean_all():
	for child in get_children():
		child.queue_free()
	all_emojis_meta = {}

# Create an emoji instance using provided data and position index
func create_emojis(emoji: Dictionary, pos: int):
	var info = [emoji["to_id"]]
	var color_dic = emoji["color"]
	# Instantiate emoji with color and message, store it with relevant info
	info.append(instantiate_emoji(info, Color(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"]), emoji["message"]))
	all_emojis_meta[emoji["id"]] = info
	add_addition(emoji, pos)

# Update all emojis based on current time and linked vehicle or RSU presence
func update(t: float):
	for key in all_emojis_meta.keys():
		var this_emoji = all_emojis_meta[key]
		var to_str = this_emoji[0]

		# Update position if linked Vehicle exists
		if Vehicle.is_there(to_str):
			transform(Vehicle.get_pos(to_str), this_emoji[1])
		# Else if linked RSU exists, update position accordingly
		elif RSU.is_there(to_str): 
			transform(RSU.get_pos(to_str), this_emoji[1])
		else:
			# Remove emoji instance if linked entity no longer exists
			this_emoji[1].queue_free()
			all_emojis_meta.erase(key)
			add_removal_t(key, t)

# Update emojis according to current time t, creating new ones if active
func update_to_time(t: float):
	for key in all_emojis.keys():
		var this_key = all_emojis[key]
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])
			create_emojis(json, this_key[0])

# Remove emoji instance and metadata by emoji dictionary
func remove_emoji(emoji: Dictionary):
	var id = emoji["id"]
	if all_emojis_meta.has(id):
		var ins = all_emojis_meta[id][1]
		ins.queue_free()
		all_emojis_meta.erase(id)
		add_removal(emoji)

# Instantiate an emoji object at the position of the 'to' entity, with color and message
func instantiate_emoji(info: Array, color: Color, message: String):
	var to = Vehicle.get_pos(info[0])
	if to == null:
		to = RSU.get_pos(info[0])

	var emoji = Emoji.instantiate()
	add_child(emoji)

	# Position emoji above the target entity
	transform(to, emoji)

	# Apply color and set message text on the emoji
	emoji.change_obj(color, message)

	return emoji

# Position and scale the emoji instance above the given Vector3 position
func transform(to: Vector3, ins) -> void:
	ins.global_position = to + Vector3(0, height_above_vehicle, 0)
	ins.scale = Vector3(all_scale, all_scale, 1)

# Check if emoji with given ID exists
func is_there(id: String) -> bool:
	return all_emojis_meta.has(id)

# Callback to update emoji scales when a scale slider or control changes
func _on_conn_scale_value_changed(value: float) -> void:
	if value == 0.0:
		value = 0.001  # this value is needed for normal scenes to have a scale of 1

	for key in all_emojis_meta.keys():
		var this_conn = all_emojis_meta[key][1]
		this_conn.scale = Vector3(1000 * value, 1000 * value, 1)

	all_scale = value * 1000
