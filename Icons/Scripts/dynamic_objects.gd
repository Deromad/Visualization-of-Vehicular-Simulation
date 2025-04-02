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

@onready var slide = $"../UI/HSlider"
@onready var vehicle = $Vehicles
@onready var speed_label = $"../UI/SpeedLabel"
@onready var time_label = $"../UI/Time"


func create_dynamic_onjects(data):
	var rsus = []
	var vehicles = []
	var vehicle_update = []
	var vehicle_removal= []
	var first = true
	var second = false
	for item in data:
		if item.has("type"):
			
			match item["type"]:
				"rsuAddition":
					rsus.append(item)
				"vehicleAddition":
					vehicles.append(item)
				"vehicleUpdate":
					vehicle_update.append(item)
				"timestepBegin":
					if first:
						time_begin = item["t"]
						first = false
						second = true
					elif(second):
						tick_time = item["t"]- time_begin 
						second = false
				"timestepEnd":
					time_end = item["t"]
				
				"vehicleRemoval":
					vehicle_removal.append(item)
					
					
				

	time_frame = time_end-time_begin

	var rsu = $RSU
	
	vehicle.create_vehicles(vehicles)
	vehicle.add_timestemps(vehicle_update)
	vehicle.remove_vehicles(vehicle_removal)
	player(time_begin, time_end)
	
	
func player(start_time: float, end_time:float):

	time = start_time
	while true:
		while time <= end_time and is_playing:
			update(time)
			await get_tree().create_timer(tick_time / speed).timeout
			if is_playing:
				time = snapped(time+tick_time, tick_time)

		is_playing = false
		await get_tree().create_timer(0.05).timeout

	

func update(time: float):
	vehicle.set_to_time(str(time))
	last_time = time
	time_label.text = str(time) + " / " + str(time_end)

	slide.set_value_no_signal(time/time_frame * 100) 

func update_backward(time:float):
	vehicle.set_to_time_backwards(str(time))
	last_time = time
	time_label.text = str(time) + "/" + str(time_end)
	slide.set_value_no_signal(time/time_frame * 100) 


func _on_play_pressed() -> void:
	is_playing = not is_playing

func _on_back_pressed() -> void:
	if time -tick_time >= time_begin:
		is_playing = false
		time = snapped(time  - tick_time,tick_time)
		update_backward(time)

func _on_forward_pressed() -> void:
	if time + tick_time <= time_end:
		
		is_playing = false
		time = snapped(time  + tick_time,tick_time)
		update(time)


func _on_h_slider_value_changed(value: float) -> void:
	is_playing = false
	time = snapped(value /100 *time_frame,tick_time)
	
	#this function because its possible, because if you jump to a tick where 
	#the object is already removed, it would not change its visibility
	update_backward(time)
	

	


func _on_speed_value_changed(value: float) -> void:
	if value <= 0:
		speed = (10 + value) / 10
	else:
		speed = value + 1
	speed_label.text = str(speed) + "x"
