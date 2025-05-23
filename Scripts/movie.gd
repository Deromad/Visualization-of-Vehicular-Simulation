extends Node3D

# References to UI elements and scene nodes  
@onready var ErrorPanel = $UI/Error/ErrorLabel           # Label to show error messages
@onready var Error = $UI/Error                           # Error panel container
@onready var DynamicObjects = $DynamicObjects            # Parent node for dynamic objects
@onready var StaticObjects = $StaticObjects              # Parent node for static objects
@onready var Road = $StaticObjects/Road                   # Road node under static objects
@onready var Vehicle = $DynamicObjects/Vehicles           # Vehicle manager node
@onready var Connector = $DynamicObjects/Connector        # Connector manager node
@onready var Emoji = $DynamicObjects/Emoji                # Emoji manager node
@onready var speed_label = $UI/SpeedLabel                 # UI label to show speed
@onready var slide = $UI/HSlider                           # UI horizontal slider for timeline control
@onready var time_label = $UI/Time                         # UI label to show current time
@onready var Prism = $DynamicObjects/Prism                 # Prism manager node
@onready var Bubble = $DynamicObjects/Bubble               # Bubble manager node
@onready var TL = $DynamicObjects/TrafficLight             # TrafficLight manager node
@onready var Polygon= $DynamicObjects/Polygon              # Polygon manager node
@onready var LogData = $DynamicObjects/LogDaten            # Log data manager node
@onready var Marker = $DynamicObjects/Marker               # Marker manager node
@onready var RSU = $DynamicObjects/RSU                     # RSU (Roadside Unit) manager node
@onready var Earth = $"y-achse"                            # Node for Earth axis rotation
@onready var Kamera = $Camera3D                             # Camera node
@onready var GroundPlane = $StaticBody3D/Groundplane       # Ground collision plane
@onready var Test = $Test                                   # Test/error handling node

# Variables to manage playback and timing
var checkpoint_intervall = 4.0          # Interval in seconds between checkpoints
var time_until_next_cp = 0.0            # Time remaining until next checkpoint
var last_cp = -1.0                      # Time of the last checkpoint
var intervall  = 0.0                    # Last processed time interval

var length_of_programm = 0.0            # Total length of the program (in seconds)
var is_update = false                   # Flag if static objects are loaded
var error_arr = []                     # Array to hold error messages
var ignore_all = false                  # Flag to ignore all errors
var is_playing = true                   # Playback status
var should_play = true                  # Should playback continue
var is_skipping = false                 # Is currently skipping time
var should_skip = true                  # Flag to allow skipping
var time_to_not_skip = 0.0              # Time threshold to stop skipping
var byte_offset = 0                     # Byte offset in data file
var data_file                          # FileAccess handle for input data
var check_points = []                  # List of checkpoints [time, byte_offset]
var speed = 1.0                        # Playback speed multiplier
var can_play = false                   # Flag indicating readiness to play

var time_now = 0.0                     # Current time in playback

var only_ones = false                  # Flag to play only once

var materials = {}                    # Dictionary to hold materials (not used here)

var has_error = false                 # Flag if an error occurred

signal error_acknowledged              # Signal emitted when error acknowledged

var frame_log_file : FileAccess        # File for frame logging
var frame_log_path : String            # Path for frame log file
var frame_start_time : int             # Timestamp for frame log start


# Generate a unique file path by adding incremental suffix if file exists
func get_unique_file_path(base_path: String) -> String:
	var path = base_path
	var i = 1
	while FileAccess.file_exists(path):
		var dot_index = base_path.rfind(".")
		if dot_index != -1:
			path = base_path.substr(0, dot_index) + "_" + str(i) + base_path.substr(dot_index)
		else:
			path = base_path + "_" + str(i)
		i += 1
	return path


func _ready() -> void:
	# Get the file path from Globals (set externally, e.g. by drag & drop)
	var file_path = Globals.path
	Error.visible = false     # Hide error panel initially
	
	if not file_path == "":
		var json_name = Globals.path.get_file().get_basename()
		
		# Setup for optional frame logging (commented out)
		# frame_log_path = get_unique_file_path("frame_log_" + json_name + ".csv")
		# frame_log_file = FileAccess.open(frame_log_path, FileAccess.WRITE)
		# frame_log_file.store_line("timestamp_ms,frame_time_ms")  # CSV header
		
		read_json()  # Start reading and processing the JSON data file


# Reads the JSON/YAML log file line by line and processes the data
func read_json():
	
	var file_path = Globals.path           # Path to data file
	var time_until = Time.get_ticks_msec()  # Record time to calculate delays
	
	# Check if file exists before opening
	if FileAccess.file_exists(file_path):

		data_file = FileAccess.open(file_path, FileAccess.READ)
		
		# Read metadata line (first line)
		var line_meta = data_file.get_line()
		var json_meta = JSON.parse_string(line_meta)
		
		Globals.length_of_programm = json_meta["time"]  # Total program length from metadata
		
		# Setup earth rotation and camera parameters if coordinate data ("kood") is present
		if json_meta.has("kood"):
			Earth.rotatio(json_meta["kood"][0], json_meta["kood"][1])  # (Assuming a custom method for rotation)
			var Scale = $UI/Conn_Scale
			Scale.set_value_no_signal(10.0)
			Kamera.speed_kam = 15000
			Connector._on_conn_scale_value_changed(10.0)
			Emoji._on_conn_scale_value_changed(10.0)
			Bubble._on_conn_scale_value_changed(10.0)
			Kamera.position = Vector3(0, 1000000, 0)
		else:
			# Default settings if no coordinate info
			GroundPlane.visible = true
			Earth.visible = false
			Kamera.far = 3000000
			Kamera.near = 0.5
		
		# Start reading the file lines until EOF
		while true:
			
			while not data_file.eof_reached():
				byte_offset = data_file.get_position()  # Current byte position
				
				var line = data_file.get_line()
				if line.strip_edges() == "":
					continue  # Skip empty lines
				
				var json = JSON.parse_string(line)
				
				if json == null:
					print("Fehler beim Parsen der Zeile: ", line)  # Print parsing error
				else:
					# If static objects are not loaded yet, try to load them
					if not is_update:
						if Globals.warning:
							if json.has("type"):
								if not Test.testing_static(json):
									has_error = true
									continue
							else:
								Test.append_error("A static Object has no type")
								has_error = true
								continue
						
						is_update = StaticObjects.add_static_objects(json)
						
						# Await static object creation after loading
						if is_update:
							await StaticObjects.create_static_objects()
							if has_error:
								Test.create_error()
							can_play = true
						
						# Handle waits between loading batches (likely to avoid freezing)
						if Globals.wait_counter == Globals.wait:
							await get_tree().create_timer(0.0001).timeout
							Globals.wait_counter = 0
						Globals.wait_counter += 1
						
					# Once static objects are loaded and playback can start
					elif can_play:
						if Globals.warning:
							if json.has("type"):
								if not Test.testing_dynamic(json):
									has_error = true
									continue
							else:
								Test.append_error("A dynamic Object has no type")
								has_error = true
								continue
						
						# Handle different types of dynamic objects and events
						match json["type"]:
							"vehicleUpdate":
								Vehicle.add_timestemps(json, byte_offset)
							"connectorAddition":
								Connector.create_conns(json, byte_offset)
							"connectorRemoval":
								Connector.remove_con(json)
							"logLineAddition":
								LogData.create_logs(json)
							"vehicleAddition":
								Vehicle.create_vehicles(json, byte_offset)
							"vehicleRemoval":	
								Vehicle.remove_vehic(json)
							"prismUpdate":
								Prism.update_prism(json)
							"timestepBegin":
								var t = json["t"]
								# Manage checkpoints for timeline navigation
								if time_until_next_cp <= 0 and last_cp < t:
									last_cp = t
									time_until_next_cp = checkpoint_intervall
									check_points.append([t, byte_offset])
								time_until_next_cp -= t - intervall
							"timestepEnd":
								var t = json["t"]
								
								if only_ones:
									only_ones = false
									should_play = false
								
								if not should_play:
									is_playing = false
								
								# Track max time reached in playback
								Globals.max_t = max(Globals.max_t, json["t"])
								time_now = json["t"]
								
								# Update slider UI to reflect current time (as percentage)
								slide.set_value_no_signal(time_now / Globals.length_of_programm * 100)
								
								# Skip management logic for smooth playback
								if not is_skipping:
									should_skip = false
								is_skipping = time_to_not_skip > t
								
								# Update objects for current interval
								update(intervall)
								
								# Update time label UI
								time_label.text = str(t) + "/" + str(Globals.length_of_programm)
								
								# Await next frame or skip timing based on speed and elapsed time
								if not should_skip:
									should_skip = true
									await get_tree().create_timer(((t - intervall) - (Time.get_ticks_msec() - time_until) / 1000) / speed).timeout
								
								intervall = t
								time_until = Time.get_ticks_msec()
								
								# Show error UI if any error was detected
								if has_error:
									Test.create_error()
							
							# Handle additions and removals of emojis, bubbles, traffic lights, markers, polygons, RSUs, etc.
							"emojiAddition":
								Emoji.create_emojis(json, byte_offset)
							"emojiRemoval": 
								Emoji.remove_emoji(json)
							"bubbleAddition":
								Bubble.create_bubbles(json, byte_offset)
							"bubbleRemoval":
								Bubble.remove_bubble(json)
							"trafficLightUpdate":
								TL.update_traffic_light(json, byte_offset)
							"markerAddition":
								Marker.create_markers(json, byte_offset)
							"markerRemoval":
								Marker.remove_marker(json)
							"polygonAddition":
								Polygon.create_polygons(json, byte_offset)
							"polygonRemoval":
								Polygon.remove_polygon(json)
							"rsuAddition":
								RSU.create_rsus(json, byte_offset)
							"rsuRemoval":
								RSU.remove_rsu(json)
				
				# Wait briefly if playback is paused or not ready yet, preventing busy loop
				while (not should_play and not is_playing and not is_skipping) or (not can_play and is_update):
					await get_tree().create_timer(0.01).timeout
				
				is_playing = true  # Resume playing after wait
			
			# If EOF reached, wait a bit before next loop iteration (can be removed if no new data expected)
			await get_tree().create_timer(0.01).timeout

	else:
		print("File doesn't exist")  # File missing error
# Updates dynamic objects based on current time t
func update(t: float):
	Connector.update(t)
	Emoji.update(t)
	Bubble.update(t)
	

# Reads a specific line from the data file at given byte position 'pos' and returns the parsed JSON as a Dictionary
func get_line(pos: int) -> Dictionary:
	data_file.seek(pos)                     # Move file cursor to position 'pos'
	var jump_line = data_file.get_line()   # Read the line at that position
	var parsed = JSON.parse_string(jump_line)  # Parse JSON string to Dictionary
	data_file.seek(byte_offset)             # Reset file cursor to previous position (byte_offset)
	return parsed                           # Return parsed JSON dictionary
		

# Append an error message string to the error array
func append_error(msg: String) -> void:
	error_arr.append(msg)
		

# Show the error panel UI and display all accumulated error messages
func create_error():
	if error_arr.size() > 0:
		DynamicObjects.is_playing = false   # Pause playback
		Error.visible = true                 # Show error panel
		ErrorPanel.text = "Warning!\n"      # Reset error text with heading
		var i = 0
		for msg in error_arr:
			i += 1
			ErrorPanel.append_text(str(i) + ": " + msg + "\n")  # Append each error with index


# Called when the user presses the "Ignore" button to dismiss errors
func _on_ignore_pressed() -> void:
	Error.visible = false   # Hide error panel
	ErrorPanel.text = ""    # Clear error messages


# Called when the user presses the "Close" button to quit the program, ignoring all future errors
func _on_close_pressed() -> void:
	ignore_all = true      # Set flag to ignore further errors
	get_tree().quit()      # Quit the application


# Validates if a JSON dictionary contains a valid color dictionary with r,g,b,a floats in [0,255]
func check_color(data: Dictionary) -> bool:
	if data.has("color") and data["color"] is Dictionary:
		var color = data["color"]
		if color.has("r") and color.has("g") and color.has("b") and color.has("a"):
			var r = color["r"]
			var g = color["g"]
			var b = color["b"]
			var a = color["a"]

			if r is float and r < 256 and r >= 0 and \
			   g is float and g < 256 and g >= 0 and \
			   b is float and b < 256 and b >= 0 and \
			   a is float and a < 256 and a >= 0:
				return true
	return false


# Toggles playback play/pause state when Play button pressed
func _on_play_pressed() -> void:
	should_play = not should_play


# Handles Back button press: pauses playback, enables skipping backward, and jumps slightly back in time
func _on_back_pressed() -> void:
	should_play = false   # Pause playback
	is_skipping = true    # Enable skipping state

	clean_all()           # Reset all dynamic objects and states
	jump_to_timestemp(time_now - 0.11)  # Jump playback 0.11 seconds backward

	# The code below is unreachable due to 'return' above, possibly leftover logic to find previous checkpoints
	return
	var last_checkpoint = 0.0
	var last1 = 0.0
	var last2 = 0.0
	if time_now == 0:
		return
	for i in range(check_points.size()):
		if check_points[i][1] >= time_now:
			data_file.seek(check_points[i - 1][0])
			while not data_file.eof_reached():
				var last_byte_offset = data_file.get_position()
				var line = data_file.get_line()
				
				if line.strip_edges() == "":
					continue
				var json = JSON.parse_string(line)
				if json == null:
					print("Fehler beim Parsen der Zeile: ", line)
				else:
					if json["type"] == "timestepBegin":
						if json["t"] == time_now:
							jump_to_timestemp(last1)
							break
						else:
							last2 = last1
							last1 = json["t"]
			break
			

# Handles Forward button press: resumes playback and only plays once (used for single step forward)
func _on_forward_pressed() -> void:
	should_play = true
	only_ones = true


# Handles horizontal slider value change event to jump timeline to specified value (percentage)
func _on_h_slider_value_changed(value: float) -> void:
	should_play = false    # Pause playback during jump
	is_skipping = true     # Enable skipping state
	
	var t = value / 100 * Globals.length_of_programm  # Calculate absolute time from slider percentage
	var bla = true

	# If the jump is very large (>1800 seconds), split jump into smaller jumps for smoother updates
	while t - time_now > 1800:
		while not bla:
			await get_tree().create_timer(0.01).timeout
		clean_all()
		jump_to_timestemp(time_now + 1800)

		bla = false
		await get_tree().create_timer(0.01).timeout
		bla = true

	# Final jump to requested time
	while true:
		var sh = false
		if bla:
			clean_all()
			jump_to_timestemp(value / 100 * Globals.length_of_programm)
			sh = true
		if sh:
			break

	should_play = true  # Resume playback after jump
	only_ones = true    # Play only once to avoid auto-continuing


# Cleans/removes all dynamic objects and resets their states
func clean_all():
	Vehicle.clean_all()
	Connector.clean_all()
	Emoji.clean_all()
	Bubble.clean_all()
	LogData.clean_all()
	Polygon.clean_all()
	Marker.clean_all()
	RSU.clean_all()


# Loads dynamic objects from a given checkpoint to a specific point in time
func go_to_startline(point: float, time: Array):
	data_file.seek(time[1])       # Seek to byte offset of checkpoint in file
	var is_in_loadupdates = false
	while not data_file.eof_reached():
		var last_byte_offset = data_file.get_position()
		var time_until = Time.get_ticks_msec()
		var line = data_file.get_line()
		byte_offset = data_file.get_position()

		if line.strip_edges() == "":
			continue
		var json = JSON.parse_string(line)
		if json == null:
			print("Fehler beim Parsen der Zeile: ", line)
		else:
			# Once we reach timestepBegin with time >= target point, start applying updates
			if json["type"] == "timestepBegin" and json["t"] >= point:
				if is_in_loadupdates:
					return 
				is_in_loadupdates = true
				update_to_time(json["t"])  # Update UI and internal time state
			elif is_in_loadupdates:
				match json["type"]:
					"vehicleUpdate":
						Vehicle.set_to_time(json, last_byte_offset)
					"connectorAddition":
						Connector.create_conns(json, last_byte_offset)
					"connectorRemoval":
						Connector.remove_con(json)
					"logLineAddition":
						LogData.create_logs(json)
					"vehicleAddition":
						Vehicle.create_vehicles(json, last_byte_offset)
					"prismUpdate":
						Prism.update_prism(json)
					"emojiAddition":
						Emoji.create_emojis(json, last_byte_offset)
					"emojiRemoval":
						Emoji.remove_emoji(json)
					"bubbleAddition":
						Bubble.create_bubbles(json, last_byte_offset)
					"bubbleRemoval":
						Bubble.remove_bubble(json)
					"trafficLightUpdate":
						TL.update_traffic_light(json, last_byte_offset)
					"timestepEnd":
						Globals.max_t = max(Globals.max_t, json["t"])
						time_now = json["t"]
						slide.set_value_no_signal(time_now / Globals.length_of_programm * 100)
						if not should_play:
							is_playing = false 
					"markerAddition":
						Marker.create_markers(json, last_byte_offset)
					"markerRemoval":
						Marker.remove_marker(json)
					"polygonAddition":
						Polygon.create_polygons(json, last_byte_offset)
					"polygonRemoval":
						Polygon.remove_polygon(json)
					"rsuAddition":
						RSU.create_rsus(json, last_byte_offset)
					"rsuRemoval":
						RSU.remove_rsu(json)


# Updates dynamic object managers to reflect state at time 't'
func update_to_time(t: float) -> void:
	Connector.update_to_time(t)
	Emoji.update_to_time(t)
	Bubble.update_to_time(t)
	Prism.update_to_time(t)
	TL.update_to_time(t)
	Marker.update_to_time(t)
	Polygon.update_to_time(t)
	RSU.update_to_time(t)


# Jump playback to a given timestamp 'value', using checkpoints to speed up loading
func jump_to_timestemp(value: float):
	time_to_not_skip = value
	var point = value - Globals.look_back   # Look back to ensure all relevant updates are applied
	if value <= Globals.look_back:
		point = 0.0
	for i in range(check_points.size()):
		var time = check_points[i]
		if time[0] > point:
			go_to_startline(point, check_points[i - 1])  # Load from previous checkpoint
			return
	play_until_point(point)  # If no checkpoint found, simulate until point


# Simulate (play) from last checkpoint until given point, applying updates as needed
func play_until_point(point: float):
	data_file.seek(check_points[-1][1])   # Seek to last checkpoint byte offset
	var i = 0
	while not data_file.eof_reached():
		byte_offset = data_file.get_position()
		var time_until = Time.get_ticks_msec()
		var line = data_file.get_line()
		if line.strip_edges() == "":
			continue
		var json = JSON.parse_string(line)
		if json == null:
			print("Fehler beim Parsen der Zeile: ", line)
		else:
			# If skipping_objects returns true, we've reached or passed point to stop simulation
			if DynamicObjects.skipping_objects(json, point, byte_offset):
				break
		i += 1
	if check_points.size() >= 2:
		go_to_startline(point, check_points[-2])  # Load from second last checkpoint
	else:
		go_to_startline(point, check_points[-1])  # Or last checkpoint if only one


# Handles speed slider changes, updates playback speed multiplier and label text
func _on_speed_value_changed(value: float) -> void:
	if value <= 0:
		speed = (10 + value) / 10    # Map negative/low values to fractional speed < 1
	else:
		speed = value + 1            # Otherwise speed > 1
	speed_label.text = str(speed) + "x"  # Update UI label with current speed


# Get or create and cache a StandardMaterial3D with the specified color
func get_material(color: Color) -> StandardMaterial3D:
	var col_str = str(color)  # Convert color to string key
	if materials.has(col_str):
		return materials[col_str]   # Return cached material if exists
	var new_material = StandardMaterial3D.new()
	new_material.albedo_color = color  
	new_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials[col_str] = new_material     # Cache new material for reuse
	return new_material
