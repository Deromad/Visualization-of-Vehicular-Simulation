extends Node3D
@onready var ErrorPanel = $UI/Error/ErrorLabel
@onready var Error = $UI/Error
@onready var DynamicObjects = $DynamicObjects
@onready var StaticObjects = $StaticObjects
@onready var Road = $StaticObjects/Road
@onready var Vehicle = $DynamicObjects/Vehicles
@onready var Connector = $DynamicObjects/Connector
@onready var Emoji = $DynamicObjects/Emoji
@onready var speed_label = $UI/SpeedLabel
@onready var slide = $UI/HSlider
@onready var time_label = $UI/Time
@onready var Prism = $DynamicObjects/Prism
@onready var Bubble = $DynamicObjects/Bubble
@onready var TL = $DynamicObjects/TrafficLight
@onready var Polygon= $DynamicObjects/Polygon
@onready var LogData = $DynamicObjects/LogDaten
@onready var Marker = $DynamicObjects/Marker
@onready var RSU = $DynamicObjects/RSU
@onready var Earth = $"y-achse"
@onready var Kamera = $Camera3D
@onready var GroundPlane = $StaticBody3D/Groundplane

var checkpoint_intervall = 4.0
var time_until_next_cp = 0.0
var last_cp = -1.0
var intervall  = 0.0

var length_of_programm = 0.0
var is_update = false
var error_arr = []
var ignore_all = false
var is_playing = true
var should_play = true
var is_skipping = false
var should_skip = true
var time_to_not_skip = 0.0
var byte_offset = 0
var data_file
var check_points = []
var speed = 1.0
var can_play = false


var time_now = 0.0

var only_ones = false


var materials = {}

signal error_acknowledged
var frame_log_file : FileAccess
var frame_log_path : String
var frame_start_time : int
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

	#get yaml file-path from drag and drop
	var file_path = Globals.path
	Error.visible = false
	if not file_path == "":
		var json_name = Globals.path.get_file().get_basename()
		#frame_log_path = get_unique_file_path("frame_log_" +json_name + ".csv")
		#print(frame_log_path)
		#frame_log_file = FileAccess.open(frame_log_path, FileAccess.WRITE)
		#frame_log_file.store_line("timestamp_ms,frame_time_ms")  # CSV-Header
		read_json()
#func _process(delta: float) -> void:
	#if frame_log_file:
		#var timestamp = Time.get_ticks_msec()
		#var delta_ms = delta * 1000.0
		#frame_log_file.store_line(str(timestamp) + "," + str(delta_ms))
#func _exit_tree():
	#if frame_log_file:
		#frame_log_file.close()
func read_json():
	
	#load file-path
	var file_path = Globals.path
	var time_until = Time.get_ticks_msec()

	#YAML Parser from https://github.com/fimbul-works/godot-yaml
	if FileAccess.file_exists(file_path):


		data_file = FileAccess.open(file_path, FileAccess.READ)
		
		var line_meta = data_file.get_line()
		var json_meta = JSON.parse_string(line_meta)
		Globals.length_of_programm = json_meta["time"]
		if json_meta.has("kood"):
			Earth.rotatio(json_meta["kood"][0], json_meta["kood"][1])

			Kamera.speed_kam = 15000
			Globals.width = 10000
			Kamera.position = Vector3(0, 1000000, 0)

			
		else:
			GroundPlane.visible = true
			Earth.visible = false
			Kamera.far = 3000000
			Kamera.near = 0.5
		while true:
			
			while not data_file.eof_reached():
				byte_offset = data_file.get_position()
				
				var line = data_file.get_line()
				
				if line.strip_edges() == "":
					continue
				var json = JSON.parse_string(line)
				
				
				if json == null:
					print("Fehler beim Parsen der Zeile: ", line)
					
					
				else:
						if not is_update:
							is_update =StaticObjects.add_static_objects(json)
							if is_update:
								await StaticObjects.create_static_objects()
								can_play = true
							if Globals.wait_counter == Globals.wait:
								await get_tree().create_timer(0.0001).timeout
								Globals.wait_counter = 0

							Globals.wait_counter+=1
						elif can_play:
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
									if time_until_next_cp <= 0 and last_cp <t:
										last_cp = t
										time_until_next_cp = checkpoint_intervall
										check_points.append([t, byte_offset])
									time_until_next_cp -= t-intervall
									
								"timestepEnd":
									var t = json["t"]

									if only_ones:
										only_ones = false
										should_play = false
									if not should_play:
										is_playing = false
									
									Globals.max_t = max(Globals.max_t, json["t"])
									time_now = json["t"]
									slide.set_value_no_signal(time_now/Globals.length_of_programm * 100) 
									if not is_skipping:
										should_skip = false
									is_skipping = time_to_not_skip > t
									
									update(intervall)
									time_label.text = str(t) + "/" + str(Globals.length_of_programm)

									if not should_skip:
										should_skip = true
										await get_tree().create_timer(((t-intervall) -(Time.get_ticks_msec() -time_until)/1000)/speed).timeout
									intervall = t
									
									time_until = Time.get_ticks_msec()

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
									print("a")
								"rsuRemoval":
									RSU.remove_rsu(json)
									
				while (not should_play and not is_playing and not is_skipping) or( not can_play and is_update):
					await get_tree().create_timer(0.01).timeout
				is_playing = true
			
			await get_tree().create_timer(0.01).timeout


	else:
		print("File doesn't exist")
		
func update(t:float):
	Connector.update(t)
	Emoji.update(t)
	Bubble.update(t)
	

func get_line(pos:int)->Dictionary:
	data_file.seek(pos)
	var jump_line = data_file.get_line()
	var parsed = JSON.parse_string(jump_line)
	data_file.seek(byte_offset)
	return parsed
		
		
func append_error(msg: String) -> void:
	error_arr.append(msg)
		
func create_error():
	if error_arr.size() > 0:
		DynamicObjects.is_playing = false
		Error.visible = true
		ErrorPanel.text = "Warning!\n"
		var i = 0
		for msg in error_arr:
			i += 1
			ErrorPanel.append_text( str(i) + ": " + msg + "\n")

# Button callbacks
func _on_ignore_pressed() -> void:
	Error.visible = false
	
	ErrorPanel.text = ""


func _on_close_pressed() -> void:
	ignore_all = true
	get_tree().quit()

func check_color(data:Dictionary)->bool:
	if  data.has("color") and data["color"] is Dictionary:
		var color = data["color"]
		if color.has("r") and color.has("g") and color.has("b") and color.has("a"):
			var r = color["r"]
			var g = color["g"]
			var b = color["b"]
			var a = color["a"]

			if r is float and r < 256 and  r >= 0 and g is float and g < 256 and  g >= 0 and b is float and b < 256 and  b >= 0 and a is float and a < 256 and  a >= 0:
				return true
	return false


func _on_play_pressed() -> void:
	should_play = not should_play

func _on_back_pressed() -> void:
	should_play = false
	is_skipping = true

	clean_all()
	jump_to_timestemp(time_now-0.11)
	return
	var last_checkpoint = 0.0
	var last1 = 0.0
	var last2 = 0.0
	if time_now == 0:
		return
	for i in range(check_points.size()):
		if check_points[i][1] >= time_now:
			data_file.seek(check_points[i-1][0])
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
			

func _on_forward_pressed() -> void:
	should_play = true
	only_ones = true


func _on_h_slider_value_changed(value: float) -> void:
	should_play = false
	is_skipping = true
	var t = value/100 * Globals.length_of_programm
	var bla = true
	while t-time_now > 1800:
			while not bla:
				await get_tree().create_timer(0.01).timeout
			print("start")
			clean_all()

			jump_to_timestemp(time_now+1800)
			print(time_now)
			print(t)
			
			bla = false
			
			await get_tree().create_timer(0.01).timeout
			print("end")

			bla = true
	while true:
		var sh = false
		if bla: 
			print("last")
			clean_all()

			jump_to_timestemp(value/100 * Globals.length_of_programm)
			sh = true
			print("endlast")
		if sh:
			break
	should_play = true
	only_ones = true
	#this function because its possible, because if you jump to a tick where 
	#the object is already removed, it would not change its visibility
	
	
func clean_all():
	Vehicle.clean_all()
	Connector.clean_all()
	Emoji.clean_all()
	Bubble.clean_all()
	LogData.clean_all()
	Polygon.clean_all()
	Marker.clean_all()
	RSU.clean_all()
	

func go_to_startline(point:float, time:Array):
			data_file.seek(time[1])
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
					if json["type"] == "timestepBegin" and json["t"] >= point:
						if is_in_loadupdates:
							return 
						is_in_loadupdates = true
						update_to_time(json["t"])
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
								slide.set_value_no_signal(time_now/Globals.length_of_programm * 100)
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
								

func update_to_time(t:float)->void:
	Connector.update_to_time(t)
	Emoji.update_to_time(t)
	Bubble.update_to_time(t)
	Prism.update_to_time(t)
	TL.update_to_time(t)
	Marker.update_to_time(t)
	Polygon.update_to_time(t)
	RSU.update_to_time(t)
	
func jump_to_timestemp(value:float):
	time_to_not_skip = value
	var point = value-Globals.look_back
	if value <= Globals.look_back:
		point = 0.0
	for i in range(check_points.size()):
		var time = check_points[i]
		if time[0] > point:
			go_to_startline(point, check_points[i-1])
			return
	play_until_point(point)
			
#if the point isnt already loaded you have to simulate until this point, because every line can be relevant
func play_until_point(point: float):
	data_file.seek(check_points[-1][1])
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
					if DynamicObjects.skipping_objects(json, point, byte_offset):
						break
				i+=1
	if check_points.size()>= 2:
		go_to_startline(point, check_points[-2])
	else:
		go_to_startline(point, check_points[-1])
			
	


func _on_speed_value_changed(value: float) -> void:
	if value <= 0:
		speed = (10 + value) / 10
	else:
		speed = value + 1
	speed_label.text = str(speed) + "x"

func get_material(color:Color)-> StandardMaterial3D:
	var col_str = str(color)
	if materials.has(col_str):
		return materials[col_str]
	var new_material = StandardMaterial3D.new()
	new_material.albedo_color = color  
	new_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials[col_str] = new_material
	return new_material
