extends Node3D

@onready var vehicles = $"../Vehicles"
@onready var Camera = $"../../Camera3D"

var Emoji = preload("res://Scenes/emoji.tscn")
var all_emojis = []
var all_emojis_meta = []
var all_emojis_meta_pos = 0
var len_all_meta_emojis = 0
var look_back = 2.0
var height_above_vehicle = 5.0

func create_emoji(additions, removes, end_time):

	for addition in additions:
		var color = addition["color"]
		all_emojis_meta.append({"id": addition["id"], "start": addition["t"], "end": end_time, "to": addition["to_id"], "message" : addition["message"], "color": Color(color["r"], color["g"], color["b"], color["a"])})

	for i in all_emojis_meta:
		var has_end = false

		for remove in removes:
			if i["id"] == remove["id"]:
				i["end"] = remove["t"]
				has_end = true
				break
		if not has_end:
			i["end"] = end_time
	
	len_all_meta_emojis = len(all_emojis_meta)
	
func update_emoji(time:String):
	var f_time = float(time)

	while all_emojis_meta_pos < len_all_meta_emojis and all_emojis_meta[all_emojis_meta_pos]["start"] <= f_time:

		var this_emoji = all_emojis_meta[all_emojis_meta_pos]
		var arr = [this_emoji["to"], this_emoji["end"]]
		arr.append(instantiate_emoji(this_emoji))
		all_emojis.append(arr)
		all_emojis_meta_pos += 1
	
	for i in range(all_emojis.size() - 1, -1, -1):
		var emoji = all_emojis[i]
		if emoji[1] < f_time or not vehicles.is_there(emoji[0]):
			emoji[2].queue_free()
			all_emojis.remove_at(i)
		else:
			var to = vehicles.get_pos(emoji[0])
			var ins = emoji[2]


			ins.global_position = to + Vector3(0, height_above_vehicle, 0)
			ins.look_at(Camera.position)

			
	
func instantiate_emoji(info:Dictionary):
	var to = vehicles.get_pos(info["to"])
	
	var emoji = Emoji.instantiate()
	add_child(emoji)
	
	#transform the arrow
	emoji.global_position = to + Vector3(0, height_above_vehicle, 0)
	emoji.change_obj(info["color"], info["message"])
	emoji.look_at(Camera.position)

	
	return emoji
func update_emoji_backwards(time:String):

	var f_time = float(time)
	for i in range(all_emojis.size() - 1, -1, -1):
		all_emojis[i][2].queue_free()
	all_emojis = []
	if all_emojis_meta_pos == len_all_meta_emojis:
		all_emojis_meta_pos -= 1
	while all_emojis_meta_pos > 0  and all_emojis_meta[all_emojis_meta_pos]["start"] >= f_time-look_back:
		all_emojis_meta_pos -= 1


	while  all_emojis_meta[all_emojis_meta_pos]["start"] <= f_time :
		if all_emojis_meta[all_emojis_meta_pos]["end"] >= f_time:
			var this_emoji = all_emojis_meta[all_emojis_meta_pos]
			var arr = [ this_emoji["to"], this_emoji["end"]]
			arr.append(instantiate_emoji(this_emoji))
			all_emojis.append(arr)
		all_emojis_meta_pos += 1

	for i in range(all_emojis.size() - 1, -1, -1):
		var emoji = all_emojis[i]
		if emoji[1] < f_time or not vehicles.is_there(emoji[0]):
			emoji[2].queue_free()
			all_emojis.remove_at(i)
		else:
			var to = vehicles.get_pos(emoji[0])
			var ins = emoji[2]

			ins.global_position = to + Vector3(0, height_above_vehicle, 0)
			ins.look_at(Camera.position)
