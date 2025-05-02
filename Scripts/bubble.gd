extends Node3D

@onready var Vehicle = $"../Vehicles"
@onready var Camera = $"../../Camera3D"
@onready var RSU = $"../RSU"

var bubble = preload("res://Scenes/bubble.tscn")

var height_above_vehicle = 3



@onready var Movie = $"../.."

var all_bubbles = {}
var all_bubbles_temp = {}
var all_bubbles_meta = {}

func add_addition(data:Dictionary, pos:int)->void :
	all_bubbles_temp[data["id"]] = data["t"]
	all_bubbles[data["id"]] = [pos, data["t"], Globals.length_of_programm]

func add_removal(data:Dictionary)->void:
	add_removal_t(data["id"], data["t"])
	
func add_removal_t(id:String, t:float)->void:
	if all_bubbles_temp.has(id):

		if t - all_bubbles_temp[id] < Globals.look_back:
			all_bubbles.erase(id)
			all_bubbles_temp.erase(id)
		else:
			all_bubbles_temp.erase(id)
			all_bubbles[id][1] = t

func clean_all():
	for key in all_bubbles_meta.keys():
		var ins = all_bubbles_meta[key][1]
		ins.queue_free()
		all_bubbles_meta.erase(key)

func create_bubbles(bubble: Dictionary, pos:int):
	var info = [ bubble["to_id"]]
	var color_dic = bubble["color"]
	info.append(instantiate_bubble(info, Color(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"]), bubble["message"]))
	all_bubbles_meta[bubble["id"]]  = info
	add_addition(bubble, pos)
	
func update(t:float):
	for key in all_bubbles_meta.keys():
		var this_bubble = all_bubbles_meta[key]
		var to_str = this_bubble[0]
		if Vehicle.is_there(to_str):
			transform(Vehicle.get_pos(to_str), this_bubble[1])
		elif RSU.is_there(to_str):
			transform(RSU.get_pos(to_str), this_bubble[1])

		else:
			#remove bubbleection
			this_bubble[1].queue_free()
			all_bubbles_meta.erase(key)
			add_removal_t(key, t)

func update_to_time(t:float):
	for key in all_bubbles.keys():
		var this_key = all_bubbles[key]
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])
			create_bubbles(json, this_key[0])
func remove_bubble(bubble:Dictionary):
	var id = bubble["id"]
	if all_bubbles_meta.has(id):
		var ins = all_bubbles_meta[id][1]
		ins.queue_free()
		all_bubbles_meta.erase(id)
		add_removal(bubble)

	

	
func instantiate_bubble(info:Array, color:Color, message:String):
	var to = Vehicle.get_pos(info[0])
	if to == null:
		to = RSU.get_pos(info[0])
	var bubble = bubble.instantiate()
	add_child(bubble)
	#transform the arrow
	transform(to, bubble)
	bubble.change_obj(color, message)

	return bubble
	
func transform(to:Vector3, ins)->void:
		ins.global_position = to + Vector3(0, height_above_vehicle, 0)
