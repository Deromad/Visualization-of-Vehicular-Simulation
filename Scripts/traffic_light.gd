extends Node3D

@onready var vehicles = $"../Vehicles"    # Reference to Vehicles node (not used here but likely needed elsewhere)
@onready var Camera = $"../../Camera3D"   # Reference to Camera node (not used here but likely needed elsewhere)
@onready var Error = $"../.."              # Reference to Error handler node for logging errors

var TrafficLight = preload("res://Scenes/traffic_light.tscn")  # Preload the traffic light scene to instantiate

var all_traffic_lights_temp = {}   # Temporary storage for traffic light link data before final initialization

var height_of_traff = 0.5          # Height offset for positioning traffic light objects

@onready var Movie = $"../.."       # Reference to Movie node, used for timeline or data retrieval

var all_traffic_lights = {}        # Dictionary storing traffic light update history per ID (pos, time)
var all_traffic_lights_meta = {}   # Dictionary storing actual instantiated traffic light nodes per ID

# Adds or updates the traffic light state changes based on timestamp and position index
func add_update(data:Dictionary, pos:int)->void :
	if data["t"] > Globals.max_t:  # Only update if time is beyond a threshold max_t
		var id = data["id"]
		var this_data = all_traffic_lights[id]  # Get history list for this traffic light ID

		# If the last recorded update is recent (within look_back), remove it to avoid duplicates
		if not this_data.is_empty() and data["t"] - this_data[-1][1] < Globals.look_back:
			this_data.remove_at(this_data.size()-1)

		# Append new update as [position index, timestamp]
		this_data.append([pos, data["t"]])


# Update the visual state of the traffic light at given position with current data
func update_traffic_light(traffic_light:Dictionary, pos:int):
	var id = traffic_light["id"]
	var ins = all_traffic_lights_meta[id]  # Get instantiated traffic light objects
	transform(traffic_light["state"], ins) # Update the visual state
	add_update(traffic_light, pos)          # Record the update for timeline tracking


# Update all traffic lights to reflect the state at time t
func update_to_time(t:float):
	for key in all_traffic_lights.keys():
		var this_traffic_light = all_traffic_lights[key]
		# Iterate backwards through update history to find latest update before or at time t
		for i in range(this_traffic_light.size()-1, -1,-1):
			if this_traffic_light[i][1] <= t:
				var ins = all_traffic_lights_meta[key]
				var states = Movie.get_line(this_traffic_light[i][0])["state"]  # Get states from Movie data at position
				transform(states, ins)  # Apply those states to the traffic light instance(s)
				break


# Apply state changes (array of states) to all traffic light parts
func transform(to:Array, ins:Array)->void:
	for i in range(ins.size()):
		ins[i].change_obj(to[i])  # Change the state of each traffic light component accordingly


# Prepares traffic light structures before final initialization
func create_traffic_light_before(additions):
	for addition in additions:
		var id = addition["id"]

		all_traffic_lights_meta[id] = []

		var state  = addition["state"]
		for link in addition["controlledLinks"].keys():
			var incoming = addition["controlledLinks"][link][0]["incoming"]
			
			# Initialize temporary storage for incoming traffic lanes if not present
			if not all_traffic_lights_temp.has(incoming):
				all_traffic_lights_temp[incoming] = []
			# Initialize meta storage for this traffic light ID if not present
			if not all_traffic_lights_meta.has(id):
				all_traffic_lights_meta[id] = []

			all_traffic_lights_meta[id].append(null)  # Placeholder for traffic light instances
			# Append data about controlled links: outgoing lane, traffic light id, link index, active flag (false initially)
			all_traffic_lights_temp[incoming].append([addition["controlledLinks"][link][0]["outgoing"], id, int(link), false])

		all_traffic_lights[id] = []  # Initialize history list for this traffic light ID


# Sets detailed direction and position info for traffic lights on a specific link
func set_direction(in_id: String, out_id: String, pos1: Vector3, pos2:Vector3, width:float , dir:String):
	if not all_traffic_lights_temp.has(in_id):
		return

	for i in all_traffic_lights_temp[in_id]:
		if i[0] == out_id:
			i.append(pos1)    # Start position of lane/link
			i.append(pos2)    # End position of lane/link
			i.append(dir)     # Direction string (e.g. "left", "straight")
			i.append(width)   # Width of lane/link
			i[3] = true       # Mark this entry as active (used)


# Finalizes traffic light creation after all directions and positions are set
func create_traffic_light_after():
	for key in all_traffic_lights_temp.keys():
		var this_traf = all_traffic_lights_temp[key]
		
		# Remove any entries not marked active (didn't get full direction info)
		for i in range(this_traf.size()-1,-1,-1):
			if not this_traf[i][3]:
				this_traf.remove_at(i)
		
		# Sort the traffic light links by direction priority (left first, right last, etc.)
		this_traf.sort_custom(func(a,b): return sort_by_dir(a[6], b[6]))
		
		var j = 0
		for i in this_traf:
			# Initialize traffic light instance for this link and store it in the meta dictionary
			all_traffic_lights_meta[i[1]][i[2]] = initialize_traf(i[4], i[5], i[7], j, this_traf.size())
			j += 1
	
	# Clear temporary storage after creation
	all_traffic_lights_temp = []


# Instantiate and position a traffic light instance based on lane positions and width
func initialize_traf(pos1:Vector3, pos2:Vector3, width:float, index:int, length: int):
	length = float(length)
	var traffic_line = TrafficLight.instantiate()
	add_child(traffic_line)

	# Calculate a perpendicular 2D vector to the lane direction for offset positioning
	var vec = Vector2(pos1.x - pos2.x, pos1.z - pos2.z).normalized().orthogonal()
	var vec3d = Vector3(vec.x, 0, vec.y)
	
	# Compute the position offset for the traffic light relative to lane center and index among multiple lanes
	var urpos = pos1 + vec3d * width / 2
	
	# Position the traffic light with offsets for spacing and height
	traffic_line.global_position = urpos - vec3d * float(index) / length * float(width) + Vector3(0, 0.02 , 0)
	
	# Scale the traffic light to fit lane width and predefined height
	traffic_line.scale = Vector3(float(width) / length / 2, 1, height_of_traff)
	
	# Rotate traffic light to align with lane direction
	traffic_line.global_rotation = Vector3(0, -vec.angle(), 0)

	return traffic_line


# Custom sorting function to order traffic lights by direction priority
func sort_by_dir(a:String, b:String) -> bool:
	match a:
		"left":
			return true    # left has highest priority
		"partleft":
			if b == "left":
				return false
			return true
		"straight":
			if b == "left" or b == "partleft":
				return false
			return true
		"partright":
			if b == "right":
				return true
			return false
		"right":
			return false
		"turn":
			return true
		_:
			# Unknown direction logs an error and treats as lowest priority
			Error.append_error("The Direction: " + a + " of a roadlane is unknown")
			return true

# Check if a traffic light with a given ID exists
func is_there(id: String) -> bool:
	return all_traffic_lights.has(id)
