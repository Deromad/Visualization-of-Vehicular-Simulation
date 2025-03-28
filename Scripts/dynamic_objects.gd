extends Node3D

var dyn_obj = {}
var time_slot

func create_dynamic_onjects(data):
	var rsus = []
	var vehicles = []
	var vehicle_update = []
	var time_begin
	var first = true
	var time_end
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
				"timestepEnd":
					time_end = item["t"]
					
				



	var rsu = $RSU
	var vehicle = $Vehicles
	vehicle.create_vehicles(vehicles)
	vehicle.add_timestemps(vehicle_update)
	player(time_begin, time_end)
	
	
func player(start_time: float, end_time:float, speed: float = 1.0):
	var vehicle = $Vehicles

	while start_time <= end_time:
		print(start_time)
		vehicle.set_to_time(str(start_time))
		await get_tree().create_timer(0.01).timeout
		start_time = snapped(start_time+0.1, 0.01)
		
	

func set_time(time):
	pass
