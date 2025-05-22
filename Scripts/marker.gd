extends Node3D

# References to other nodes in the scene hierarchy
@onready var vehicles = $"../Vehicles"      # Reference to the Vehicles node for positions (currently unused here)
@onready var Camera = $"../../Camera3D"     # Camera node reference (unused here)

# Preload the marker scene which will be instantiated to show markers
var Marker = preload("res://Scenes/marker.tscn")

# Reference to Movie node for retrieving marker data by index
@onready var Movie = $"../.."

# Dictionaries to manage markers:
# all_markers: id -> [position index, start time, end time]
var all_markers = {}

# Temporary dict to track last update times: id -> last update time
var all_markers_temp = {}

# Metadata dict to store instantiated marker nodes: id -> marker instance
var all_markers_meta = {}

# Add a new marker or update existing one with start time and position index
func add_addition(data: Dictionary, pos: int) -> void:
	all_markers_temp[data["id"]] = data["t"]  # Save last update time for this marker
	all_markers[data["id"]] = [pos, data["t"], Globals.length_of_programm]  # Store lifecycle info

# Mark a marker for removal using data dictionary (calls helper function)
func add_removal(data: Dictionary) -> void:
	add_removal_t(data["id"], data["t"])

# Remove a marker if the removal time is after a look_back threshold; else erase immediately
func add_removal_t(id: String, t: float) -> void:
	if all_markers_temp.has(id):
		if t - all_markers_temp[id] < Globals.look_back:
			# Too soon to remove, erase immediately from both dictionaries
			all_markers.erase(id)
			all_markers_temp.erase(id)
		else:
			# Otherwise, update marker's end time and erase from temp dict
			all_markers_temp.erase(id)
			all_markers[id][1] = t

# Remove all marker instances and clear metadata (useful for resetting scene)
func clean_all():
	for child in get_children():
		child.queue_free()   # Remove marker node from scene
	all_markers_meta.clear()

# Create and store a marker instance based on marker data and position index
func create_markers(marker: Dictionary, pos: int):
	# Instantiate marker scene, add to metadata dict keyed by marker id
	all_markers_meta[marker["id"]] = instantiate_marker(marker)
	# Register marker addition lifecycle info
	add_addition(marker, pos)

# At time t, create markers whose lifespan covers t
func update_to_time(t: float):
	for key in all_markers.keys():
		var this_key = all_markers[key]
		# Check if current time is within marker's lifespan
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])  # Get marker data by position index
			create_markers(json, this_key[0])

# Remove a marker explicitly using marker data dictionary
func remove_marker(marker: Dictionary):
	var id = marker["id"]
	if all_markers_meta.has(id):
		var ins = all_markers_meta[id]
		ins.queue_free()       # Remove marker node from scene tree
		all_markers_meta.erase(id)
		add_removal(marker)

# Instantiate a marker scene, position it, and apply message text
func instantiate_marker(marker: Dictionary):
	var ins = Marker.instantiate()   # Create new marker instance from scene
	add_child(ins)                    # Add marker instance as child to current node
	var pos = marker["pos"]           # Marker position dictionary with x,y,z coordinates

	# Transform marker instance to its position and apply message
	# Note: Y and Z swapped in Vector3 to match coordinate system (x,z,y)
	transform(Vector3(pos["x"], pos["z"], pos["y"]), marker["message"], ins)

	return ins

# Position marker in 3D space and apply message and scaling
func transform(to: Vector3, message: String, ins) -> void:
	ins.global_position = to              # Set global position of marker
	ins.change_obj(message)               # Update marker with the given message
	var width = Globals.width             # Get global width for marker scaling
	ins.scale = Vector3(width, width, 1) # Scale marker uniformly in X and Y, keep Z = 1

# Check if a marker with the given ID currently exists
func is_there(id: String) -> bool:
	return all_markers_meta.has(id)
