extends Node3D

var VehicleScene = preload("res://Scenes/passenger.tscn")
var all_vehicles = {}
var all_vehicles_meta = {}

func create_vehicles(data):
	all_vehicles_meta = {}

	for vehicle in data:
		var visible_at = vehicle["t"]
		var v_id = str(vehicle["id"])
		var color_dic = vehicle["color"]
		var color = Color.from_rgba8(color_dic["r"], color_dic["g"], color_dic["b"])
		var height = vehicle["height"]
		var dimensions = Vector3(vehicle["length"], height , vehicle["width"])
		var startpos = Vector3(vehicle["pos"]["x"], vehicle["pos"]["z"] + height / 2,vehicle["pos"]["y"])
		var heading_angle = -Vector2(vehicle["heading"]["x"], vehicle["heading"]["y"]).angle()
		
		#create an instandce for a vehicle
		var vehicle_instance = VehicleScene.instantiate()
		add_child(vehicle_instance)
		
		vehicle_instance.global_translate(startpos)
		vehicle_instance.scale_object_local(dimensions)
		vehicle_instance.global_rotation = Vector3(0, heading_angle, 0)
		vehicle_instance.recolor_obj(color)
		vehicle_instance.name = str(v_id) 
		
		#store the meta data for each vehicle
		all_vehicles_meta[v_id] = {}
		all_vehicles_meta[v_id]["height"] = height
		all_vehicles_meta[v_id]["visible_at"] = visible_at
		all_vehicles_meta[v_id]["instance"] = vehicle_instance

func add_timestemps(data):
	for update in data:
		var t = str(float(update["t"]))
		var v_id = str(update["id"])
		var height = all_vehicles_meta[v_id]["height"]
		var startpos = Vector3(update["pos"]["x"], update["pos"]["z"] + height / 2,update["pos"]["y"])
		var heading_angle = -Vector2(update["heading"]["x"], update["heading"]["y"]).angle()
		
		if all_vehicles.has(t):
			all_vehicles[t].append({"id": v_id, "pos": startpos, "angle": heading_angle})
		else:
			
			all_vehicles[t] = []
			all_vehicles[t].append({"id": v_id, "pos": startpos, "angle": heading_angle})
	
func set_to_time(time: String):
	if not all_vehicles.has(time):
		assert(true, "Timestemp is wrong")
		return
	for vehicle in all_vehicles[time]:
		var v_id = vehicle["id"]
		var dic = all_vehicles_meta[v_id]
		var instance  = dic["instance"]
		instance.global_position = vehicle["pos"]
		instance.global_rotation = Vector3( 0, vehicle["angle"], 0)


		
		
		
		

		
		
