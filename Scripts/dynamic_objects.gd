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
@onready var speed_label = $"../UI/SpeedLabel"
@onready var time_label = $"../UI/Time"


func create_dynamic_onjects(data):
	var rsus = []
	var vehicles = []
	var vehicle_update = []
	var vehicle_removal= []
	var connector_addition = []
	var connector_removal = []
	var emoji_addition = []
	var emoji_removal = []
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
					
					
	time_begin = timesteps[0]
	time_end = timesteps[-1]
	len_of_timesteps = len(timesteps)
	


	time_frame = time_end-time_begin

	var rsu = $RSU
	
	vehicle.create_vehicles(vehicles)
	vehicle.add_timestemps(vehicle_update)
	vehicle.remove_vehicles(vehicle_removal)
	
	
	connector.create_connector(connector_addition, connector_removal, time_end)
	
	emoji.create_emoji(emoji_addition, emoji_removal, time_end)
	
	player(time_begin, time_end)
	
	
func player(start_time: float, end_time:float):

	
	time = start_time
	
	while true:
		while time < end_time and is_playing:
			tick_time = timesteps[pos_of_timesteps+1]- timesteps[pos_of_timesteps]
			update(time)
			await get_tree().create_timer(tick_time / speed).timeout
			if is_playing:
				pos_of_timesteps += 1
				time = timesteps[pos_of_timesteps]

		is_playing = false
		await get_tree().create_timer(0.05).timeout

	

func update(time: float):
	var str_time = str(time)
	vehicle.set_to_time(str_time)
	connector.update_connector(str_time)
	emoji.update_emoji(str_time)
	last_time = time
	time_label.text = str_time + " / " + str(time_end)

	slide.set_value_no_signal(time/time_frame * 100) 

func update_backward(time:float):
	var str_time = str(time)

	vehicle.set_to_time_backwards(str_time)
	connector.update_connector_backwards(str_time)
	emoji.update_emoji_backwards(str_time)
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


func _on_h_slider_value_changed(value: float) -> void:
	is_playing = false
	
	pos_of_timesteps = get_timestemp(value /100 *time_frame,0, len_of_timesteps-1)
	time = timesteps[pos_of_timesteps]
	#this function because its possible, because if you jump to a tick where 
	#the object is already removed, it would not change its visibility
	update_backward(time)
	
	
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
