extends Node3D


@onready var vehicles = $"../Vehicles"
@onready var Camera = $"../../Camera3D"
@onready var Error = $"../.."

var TrafficLight = preload("res://Scenes/traffic_light.tscn")

var all_traffic_lights_temp = {}


var height_of_traff = 0.5



@onready var Movie = $"../.."

var all_traffic_lights = {}
var all_traffic_lights_meta = {}

func add_update(data:Dictionary, pos:int)->void :
	if data["t"] > Globals.max_t:
		var id = data["id"]
		var this_data = all_traffic_lights[id]

		if not this_data.is_empty() and data["t"] - this_data[-1][1] < Globals.look_back:
			this_data.remove_at(this_data.size()-1)

		this_data.append([pos, data["t"]])

	






func update_traffic_light(traffic_light:Dictionary, pos:int):
	var id = traffic_light["id"]
	var ins = all_traffic_lights_meta[id]
	transform(traffic_light["state"], ins)
	add_update(traffic_light, pos)


func update_to_time(t:float):
	for key in all_traffic_lights.keys():
		var this_traffic_light = all_traffic_lights[key]
		for i in range(this_traffic_light.size()-1, -1,-1):
			if this_traffic_light[i][1] <= t:
				var ins = all_traffic_lights_meta[key]
				var states = Movie.get_line(this_traffic_light[i][0])["state"]
				transform(states, ins)
				

	
func transform(to:Array, ins:Array)->void:
		for i in range(ins.size()):
			ins[i].change_obj(to[i])

func create_traffic_light_before(additions):
	var k = 0
	for addition in additions:
		if not addition.has("id"):
			Error.append_error("A traffic light has no ID")
			continue
		var id = addition["id"]
		
		all_traffic_lights_meta[id] = []
		if not addition.has("controlledLinks"):
			Error.append_error("The traffic Light with the id: " + id + "has no controlledLinks entry")
			continue
		if not addition.has("state"):
			Error.append_error("The traffic Light with the id: " + id + "has no state entry")
			continue
		var state  = addition["state"]
		for link in addition["controlledLinks"].keys():
				
				
				if not addition["controlledLinks"][link][0].has("incoming") or not addition["controlledLinks"][link][0].has("outgoing"):
					Error.append_error("The traffic Light with the id: " + id + "has an invalid controllLink")
					continue
				
				var incoming = addition["controlledLinks"][link][0]["incoming"]
				if not all_traffic_lights_temp.has(incoming):
					all_traffic_lights_temp[incoming] = []
				if not all_traffic_lights_meta.has(id):
					all_traffic_lights_meta[id] = []
				all_traffic_lights_meta[id].append(null)
				all_traffic_lights_temp[incoming].append([addition["controlledLinks"][link][0]["outgoing"], id,int(link), false])
				
				
		all_traffic_lights[id] = []
func set_direction(in_id: String, out_id: String, pos1: Vector3, pos2:Vector3, width:float , dir:String):
	if not all_traffic_lights_temp.has(in_id):
		return
	for i in all_traffic_lights_temp[in_id]:
		if i[0] == out_id:
			
			i.append(pos1)
			i.append(pos2)
			i.append(dir)
			i.append(width)
			i[3] = true
		
func create_traffic_light_after():
	for key in all_traffic_lights_temp.keys():
		var this_traf = all_traffic_lights_temp[key]
		for i in range(this_traf.size()-1,-1,-1):
			if not this_traf[i][3]:
				this_traf.remove(i)
			
		this_traf.sort_custom(func(a,b): return sort_by_dir(a[6], b[6]))
		var length = all_traffic_lights_temp.size()
		var j = 0
		for i in this_traf:
			all_traffic_lights_meta[i[1]][i[2]] = initialize_traf(i[4], i[5], i[7], j, this_traf.size())
			j+=1
	all_traffic_lights_temp = []
			
func initialize_traf(pos1:Vector3, pos2:Vector3, width:float, index:int, length: int):
	length = float(length)
	var traffic_line = TrafficLight.instantiate()
	add_child(traffic_line)
		
	var vec = Vector2(pos1.x-pos2.x, pos1.z-pos2.z).normalized().orthogonal()
	var vec3d = Vector3(vec.x, 0, vec.y)
	var urpos = pos1+ vec3d * width / 2
			#transform the wall
	traffic_line.global_position = urpos - vec3d * float(index) / length * float(width) + Vector3(0, 0.02 , 0)
	traffic_line.scale = Vector3( float(width)/length / 2, 1, height_of_traff)
	traffic_line.global_rotation = Vector3(0,-vec.angle(), 0)


	return traffic_line

	
		
func sort_by_dir(a:String,b:String)-> bool:#
	
	match a:
		"left":
			return true
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
			Error.append_error("The Direction: " + a + "of a roadlane is unknown")
			return true


	
			
