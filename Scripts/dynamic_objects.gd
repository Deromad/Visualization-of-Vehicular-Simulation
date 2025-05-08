extends Node3D

var dyn_obj = {}
var time_slot
var is_playing = true
var tick_time = 0.0
var time = 0.0
var time_frame = 0.0
var currently_rendering = 0
var last_time = 0.0
var time_begin = 0.0
var time_end = 0.0
var speed = 1.0
var timesteps = []
var pos_of_timesteps = 0
var len_of_timesteps = 0

var batchsize = 500
var back_batchsize = 100

@onready var slide = $"../UI/HSlider"
@onready var vehicle = $Vehicles
@onready var connector = $Connector
@onready var emoji = $Emoji 
@onready var logData = $LogDaten
@onready var speed_label = $"../UI/SpeedLabel"
@onready var time_label = $"../UI/Time"
@onready var rsu = $RSU
@onready var Error = $".."
@onready var TrafficLight = $TrafficLight
@onready var Prism = $Prism
@onready var Bubble = $Bubble
@onready var Polygon = $Polygon
@onready var Marker = $Marker

func skipping_objects(data:Dictionary, value:float, pos:int)-> bool:
	match data["type"]:
		"vehicleUpdate":
			vehicle.add_update(data, pos)
		"connectorAddition":
			connector.add_addition(data, pos)
		"connectorRemoval":
			connector.add_removal(data)
		"vehicleAddition":
			vehicle.add_addition(data, pos)
		"vehicleRemoval":
			vehicle.add_removal(data)
		
		"prismUpdate":
			Prism.add_update(data)
		"timestepBegin":
			var t = data["t"]
			if Error.time_until_next_cp <= 0 and Error.last_cp < t:
				Error.last_cp = t
				Error.time_until_next_cp = Error.checkpoint_intervall
				Error.check_points.append([t, pos])

			Error.time_until_next_cp -= t-Error.intervall

			if data["t"] > value:
				return true
		"timestepEnd":
			
			Error.intervall = data["t"]
			Globals.max_t = max(Globals.max_t, data["t"])
		"emojiAddition":
			emoji.add_addition(data, pos)
		"emojiRemoval":
			emoji.add_removal(data)
		"bubbleAddition":
			Bubble.add_addition(data, pos)
		"bubbleRemoval":
			Bubble.add_removal(data)
		"trafficLightUpdate":
			TrafficLight.add_update(data, pos)
		"markerAddition":
									Marker.add_addition(data, pos)
		"markerRemoval":
									Marker.add_removal(data)
		"polygonAddition":
									Polygon.add_addition(data, pos)
		"polygonRemoval":
									Polygon.add_removal(data)
		"rsuAddition":
			rsu.add_addition(data, pos)
		"rsuRemoval":
			rsu.add_removal(data)
	return false

func create_dynamic_onjects(data):
	if data.size() == 0:
		return
	var rsus = []
	var vehicles = []
	var vehicle_update = []
	var vehicle_removal= []
	var connector_addition = []
	var connector_removal = []
	var emoji_addition = []
	var emoji_removal = []
	var log_data = []
	var traffic_line_updates = []
	var prism_update = []
	var bubble_add = []
	var bubble_rem = []
	var polygon_add = []
	var polygon_rem = []
	var marker_add = []
	var marker_rem = []
	var other = {}
	var first = true
	var second = false
	var bla = {}
	for item in data:
		if item.has("type"):
			bla[item["type"]] = 0
			match item["type"]:
				"rsuAddition":
					rsus.append(item)
				"vehicleAddition":
					vehicles.append(item)
				"vehicleUpdate":
					vehicle_update.append(item)
				"timestepBegin":
					timesteps.append(item["t"])
				"timestepEnd":
					pass
				
				"vehicleRemoval":
					vehicle_removal.append(item)
				"connectorAddition":
					connector_addition.append(item)
				"connectorRemoval":
					connector_removal.append(item)
				"emojiAddition":
					emoji_addition.append(item)
				"emojiRemoval":
					emoji_removal.append(item)
				"logLineAddition":
					log_data.append(item)
				"trafficLightUpdate":
					traffic_line_updates.append(item)
				"prismUpdate":
					prism_update.append(item)
				"bubbleAddition":
					bubble_add.append(item)
				"bubbleRemoval":
					bubble_rem.append(item)
				"polygonAddition":
					polygon_add.append(item)
				"polygonRemoval":
					polygon_rem.append(item)
				"markerAddition":
					marker_add.append(item)
				"markerRemoval":
					marker_rem.append(item)
				
				_:
					other[str(item["type"])] = 0 
	
	for key in other.keys():
		Error.append_error("In Update the Type: " + key + "is unknown")
					
	time_begin = timesteps[0]
	time_end = timesteps[-1]
	len_of_timesteps = len(timesteps)
	


	time_frame = time_end-time_begin

	
	vehicle.create_vehicles(vehicles)
	vehicle.add_timestemps(vehicle_update)
	vehicle.remove_vehicles(vehicle_removal)
	TrafficLight.add_update(traffic_line_updates)
	Prism.add_update(prism_update)
	
	rsu.create_rsu(rsus)
	
	connector.create_connector(connector_addition, connector_removal, time_end)
	print(Time.get_time_dict_from_system())
	emoji.create_emoji(emoji_addition, emoji_removal, time_end)
	Bubble.create_bubble(bubble_add, bubble_rem, time_end)
	Polygon.create_polygon(polygon_add, polygon_rem, time_end)
	Marker.create_marker(marker_add, marker_rem, time_end)
	print(Time.get_time_dict_from_system())
	logData.create_log_data(log_data)
	
	
	Error.create_error()
	player(time_begin, time_end)
	
	
func player(start_time: float, end_time:float):

	
	time = start_time
	
	while true:
		while time < end_time and is_playing:
			var time_until = Time.get_ticks_msec()
			tick_time = timesteps[pos_of_timesteps+1]- timesteps[pos_of_timesteps]
			update(time)
			var time_now = float(time_until - Time.get_ticks_msec())/ 1000
			if time_now < -(tick_time / speed):
				print(str(time_now) )
			await get_tree().create_timer((tick_time / speed) + float(time_until - Time.get_ticks_msec())/ 1000).timeout
			if is_playing:
				pos_of_timesteps += 1
				time = timesteps[pos_of_timesteps]

		is_playing = false
		await get_tree().create_timer(0.05).timeout

	

func update(time: float):
	
	var str_time = str(time)
	TrafficLight.update_traffic(str_time)
	Prism.update(str_time)
	vehicle.set_to_time(str_time)
	rsu.update_rsu(str_time)
	connector.update_connector(str_time)
	emoji.update_emoji(str_time)
	Bubble.update_bubble(str_time)
	Polygon.update_polygon(str_time)
	Marker.update_marker(str_time)
	logData.update_log_data(str_time)
	last_time = time
	time_label.text = str_time + " / " + str(time_end)

	slide.set_value_no_signal(time/time_frame * 100) 

func update_backward(time:float):
	var str_time = str(time)
	TrafficLight.update_traffic(str_time)
	Prism.update(str_time)
	vehicle.set_to_time_backwards(str_time)
	rsu.update_rsu_backwards(str_time)
	connector.update_connector_backwards(str_time)
	emoji.update_emoji_backwards(str_time)
	Bubble.update_bubble_backwards(str_time)
	Polygon.update_polygon_backwards(str_time)
	Marker.update_marker_backwards(str_time)
	logData.update_log_data_backwards(str_time)
	last_time = time
	time_label.text = str_time + "/" + str(time_end)
	slide.set_value_no_signal(time/time_frame * 100) 


func _on_play_pressed() -> void:
	is_playing = not is_playing

func _on_back_pressed() -> void:
	if pos_of_timesteps -1 >= 0 :
		is_playing = false
		pos_of_timesteps -= 1
		time = timesteps[pos_of_timesteps]
		update_backward(time)

func _on_forward_pressed() -> void:
	if pos_of_timesteps + 1 <= len_of_timesteps-1:
		
		is_playing = false
		pos_of_timesteps += 1
		time = timesteps[pos_of_timesteps]
		update(time)



	
func get_timestemp(value:float, start: int, end: int, step: int = 0) -> int:
	if end -start <=1 or step >= 10:
		return  end
	var new = start + floor((end-start)/2)
	if timesteps[new] < value:
		return get_timestemp(value, new, end, step+ 1)
	elif timesteps[new] > value:
		return get_timestemp(value, start, new, step +1)
	else:
		return new
		
	

	


func _on_speed_value_changed(value: float) -> void:
	if value <= 0:
		speed = (10 + value) / 10
	else:
		speed = value + 1
	speed_label.text = str(speed) + "x"



func _on_prism_check_pressed() -> void:
	Prism.visible = not Prism.visible


func _on_polygon_check_pressed() -> void:
	Polygon.visible = not Polygon.visible
