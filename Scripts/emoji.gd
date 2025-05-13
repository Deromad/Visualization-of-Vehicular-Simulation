extends Node3D

@onready var Vehicle = $"../Vehicles"
@onready var RSU = $"../RSU"

@onready var Camera = $"../../Camera3D"

var Emoji = preload("res://Scenes/emoji.tscn")

var height_above_vehicle = 5.0


@onready var Movie = $"../.."

var all_emojis = {}
var all_emojis_temp = {}
var all_emojis_meta = {}

func add_addition(data:Dictionary, pos:int)->void :
	all_emojis_temp[data["id"]] = data["t"]
	all_emojis[data["id"]] = [pos, data["t"], Globals.length_of_programm]

func add_removal(data:Dictionary)->void:
	add_removal_t(data["id"], data["t"])
	
func add_removal_t(id:String, t:float)->void:
	if all_emojis_temp.has(id):

		if t - all_emojis_temp[id] < Globals.look_back:
			all_emojis.erase(id)
			all_emojis_temp.erase(id)
		else:
			all_emojis_temp.erase(id)
			all_emojis[id][1] = t

func clean_all():
	for child in get_children():
		child.queue_free()
	
	all_emojis_meta = {}

func create_emojis(emoji: Dictionary, pos:int):
	var info = [ emoji["to_id"]]
	var color_dic = emoji["color"]
	info.append(instantiate_emoji(info, Color(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"]), emoji["message"]))
	all_emojis_meta[emoji["id"]]  = info
	add_addition(emoji, pos)


	
func update(t:float):
	for key in all_emojis_meta.keys():
		var this_emoji = all_emojis_meta[key]
		var to_str = this_emoji[0]
		if Vehicle.is_there(to_str):
			transform(Vehicle.get_pos(to_str), this_emoji[1])
		elif RSU.is_there(to_str): 
			transform(RSU.get_pos(to_str), this_emoji[1])

		else:
			#remove emojiection
			this_emoji[1].queue_free()
			all_emojis_meta.erase(key)
			add_removal_t(key, t)

func update_to_time(t:float):
	for key in all_emojis.keys():
		var this_key = all_emojis[key]
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])
			create_emojis(json, this_key[0])
func remove_emoji(emoji:Dictionary):
	var id = emoji["id"]
	if all_emojis_meta.has(id):
		var ins = all_emojis_meta[id][1]
		ins.queue_free()
		all_emojis_meta.erase(id)
		add_removal(emoji)

	

	
func instantiate_emoji(info:Array, color:Color, message:String):
	var to = Vehicle.get_pos(info[0])
	if to == null:
		to = RSU.get_pos(info[0])
	var emoji = Emoji.instantiate()
	add_child(emoji)
	#transform the arrow
	transform(to, emoji)
	emoji.change_obj(color, message)

	return emoji
	
func transform(to:Vector3, ins)->void:
		ins.global_position = to + Vector3(0, height_above_vehicle, 0)
		var width = Globals.width
		ins.scale = Vector3(width, width, 1)
