extends Node3D

# Preload RSU (Roadside Unit) scene for instantiation
@onready var RSU = preload("res://Scenes/rsu_2.tscn") 

# Reference to the main Movie node (assumed to be two levels up in scene tree)
@onready var Movie = $"../.."

# Dictionaries to track RSUs and their metadata
var all_rsus = {}          # Stores active RSUs with [position_index, start_time, end_time]
var all_rsus_temp = {}     # Temporary storage for RSUs to help with time checks
var all_rsus_meta = {}     # Stores instantiated RSU scene instances keyed by RSU ID

# Register a new RSU addition at a given position index and time
func add_addition(data: Dictionary, pos: int) -> void:
	# Store the start time temporarily
	all_rsus_temp[data["id"]] = data["t"]
	# Add or update RSU entry with position index, start time, and program length as end time
	all_rsus[data["id"]] = [pos, data["t"], Globals.length_of_programm]

# Register removal of RSU based on data dictionary
func add_removal(data: Dictionary) -> void:
	add_removal_t(data["id"], data["t"])

# Remove RSU based on ID and time, considering look-back window to avoid premature deletion
func add_removal_t(id: String, t: float) -> void:
	if all_rsus_temp.has(id):
		# If removal time is within look_back window, erase immediately
		if t - all_rsus_temp[id] < Globals.look_back:
			all_rsus.erase(id)
			all_rsus_temp.erase(id)
		else:
			# Otherwise, update RSU's end time and clear temp record
			all_rsus_temp.erase(id)
			all_rsus[id][1] = t

# Remove all RSU instances and clear metadata
func clean_all():
	for child in get_children():
		child.queue_free()  # Free all RSU nodes from scene tree
	all_rsus_meta = {}       # Clear RSU metadata dictionary

# Create and instantiate RSU at specified position and store metadata
func create_rsus(rsu: Dictionary, pos: int):
	var posi = rsu["pos"]
	# Instantiate RSU scene at given position (note: y and z swapped)
	all_rsus_meta[rsu["id"]] = instantiate_rsu(Vector3(posi["x"], posi["z"], posi["y"]))
	# Record addition time and position index
	add_addition(rsu, pos)

# Update RSUs to reflect their state at a specific time t
func update_to_time(t: float):
	for key in all_rsus.keys():
		var this_key = all_rsus[key]
		# Check if current time is within the RSU's active interval
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])  # Get RSU data at stored position index
			create_rsus(json, this_key[0])          # Create or update RSU instance accordingly

# Remove RSU instance from scene and metadata dictionaries
func remove_rsu(rsu: Dictionary):
	var id = rsu["id"]
	if all_rsus_meta.has(id):
		var ins = all_rsus_meta[id]
		ins.queue_free()      # Free RSU node from scene tree
		all_rsus_meta.erase(id) # Remove metadata entry
		add_removal(rsu)      # Register RSU removal event

# Instantiate RSU scene instance at a given global position
func instantiate_rsu(pos: Vector3):
	var ins = RSU.instantiate()
	ins.global_position = pos   # Set global position (note z and y are swapped in create_rsus)
	add_child(ins)              # Add instance as child to this node
	return ins

# Retrieve global position of RSU instance by ID; return zero vector if not found
func get_pos(id: String) -> Vector3:
	if all_rsus_meta.has(id):
		return all_rsus_meta[id].global_position
	return Vector3(0, 0, 0)

# Check if RSU instance with given ID exists
func is_there(id: String) -> bool:
	if all_rsus_meta.has(id):
		return true
	return false
