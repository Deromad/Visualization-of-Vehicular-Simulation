extends Node3D

var VehicleScene = preload("res://Scenes/passenger.tscn")
var Satellite = preload("res://Scenes/leo_2.tscn")
var all_vehicles = {}
var all_vehicles_meta = {}


func create_vehicles(vehicle):
		var visible_at = str(vehicle["t"])
		var v_id = str(vehicle["id"])
		var color_dic = vehicle["color"]
		var color = Color.from_rgba8(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"])
		var height = vehicle["height"]
		var length = vehicle["length"]

		var width = vehicle["width"]
		
		
		var dimensions = Vector3(length, height , width)
		
		var heading_angle = -Vector2(vehicle["heading"]["x"], vehicle["heading"]["y"]).angle()
		#var startpos = Vector3(vehicle["pos"]["x"], height / 2 ,vehicle["pos"]["y"])
	
		var startpos = Vector3(vehicle["pos"]["x"], height / 2 +  vehicle["pos"]["z"] ,vehicle["pos"]["y"])
		var vehicle_instance
		if vehicle["vclass"] == "satellite":
			dimensions *= 10000
			color = Color.REBECCA_PURPLE
			vehicle_instance = Satellite.instantiate()

			
		else:
		#create an instandce for a vehicle
			vehicle_instance = VehicleScene.instantiate()
		add_child(vehicle_instance)
		
		
		vehicle_instance.global_translate(startpos)
		vehicle_instance.scale_object_local(dimensions)
		vehicle_instance.global_rotation = Vector3(0, heading_angle, 0)
		vehicle_instance.recolor_obj(color)
		vehicle_instance.name = str(v_id) 

		
		#store the meta data for each vehicle
		all_vehicles_meta[v_id] = {}
		all_vehicles_meta[v_id]["height"] = height

		all_vehicles_meta[v_id]["visible_at"] = vehicle["t"]
		all_vehicles_meta[v_id]["instance"] = vehicle_instance

func add_timestemps(update):
		
		var t = str(float(update["t"]))
		var v_id = str(update["id"])
		var vehicle = all_vehicles_meta[v_id]["instance"]

		var height = all_vehicles_meta[v_id]["height"]
		var heading_angle = -Vector2(update["heading"]["x"], update["heading"]["y"]).angle()
		#var startpos = Vector3(update["pos"]["x"], height / 2 ,update["pos"]["y"])

		var startpos =Vector3(update["pos"]["x"], height / 2 +  update["pos"]["z"]    ,update["pos"]["y"])
		vehicle.global_position  = startpos
		vehicle.global_rotation = Vector3( 0, heading_angle, 0)
	
func remove_vehic(vehicle):
	var id = vehicle["id"]
	var ins = all_vehicles_meta[id]["instance"]
	ins.queue_free()
	all_vehicles_meta.erase(id)

func set_to_time(time: String):
	if not all_vehicles.has(time):
		assert(true, "Timestemp is wrong")
		return
	var timeste = all_vehicles[time] 
	for vehicle in timeste["add"]:
		var v_id = vehicle["id"]
		var dic = all_vehicles_meta[v_id]
		var instance  = dic["instance"]
		instance.visible = true
		instance.global_position = vehicle["pos"]

	for vehicle in timeste["update"]:
		var v_id = vehicle["id"]
		var dic = all_vehicles_meta[v_id]
		var instance  = dic["instance"]
		instance.global_position = vehicle["pos"]
		instance.visible = true
		instance.global_rotation = Vector3( 0, vehicle["angle"], 0)
		
	for vehicle in timeste["remove"]:
		var v_id = vehicle
		var dic = all_vehicles_meta[v_id]
		var instance  = dic["instance"]
		instance.visible = false
		

#if the scene is moving backwards, some objects may dissapear so you need to check if that happens
func set_to_time_backwards(time: String):
	set_to_time(time)
	for key in all_vehicles_meta.keys():
		var vehicle = all_vehicles_meta[key]
		if vehicle["visible_at"] > float(time):
			# change position and not vissibility because i dont want to check every new tick if the object is vissable again
			vehicle["instance"].visible = false
		elif vehicle.has("remove_at"):
			if vehicle["remove_at"] > float(time):
				vehicle["instance"].visible = true
			else:
				vehicle["instance"].visible = false

		

			
			


func remove_vehicles(data):
	for remove in data:
		var t = str(remove["t"])
		if all_vehicles.has(t):
			all_vehicles[t]["remove"].append(remove["id"])
		else:
			
			all_vehicles[t] = {"add": [], "update": [], "remove": []}
			all_vehicles[t]["remove"].append(remove["id"])
		
		if all_vehicles_meta.has(remove["id"]):
			all_vehicles_meta[remove["id"]]["remove_at"] = remove["t"]

		else:
			all_vehicles_meta[remove["id"]] = {}
			all_vehicles_meta[remove["id"]]["remove_at"] = remove["t"]
		
func get_pos(id:String)-> Vector3:
	if all_vehicles_meta.has(id) :
		return all_vehicles_meta[id]["instance"].global_position
	return Vector3(0,0,0)

func is_there(id:String)->bool:
	if all_vehicles_meta.has(id) and all_vehicles_meta[id]["instance"].visible:
		return true
	return false			
					
	
				
					
		
