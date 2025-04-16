extends Node3D

@onready var vehicles = $"../Vehicles"
@onready var Camera = $"../../Camera3D"

var bubble = preload("res://Scenes/bubble.tscn")
var all_bubbles = []
var all_bubbles_meta = []
var all_bubbles_meta_pos = -1
var len_all_meta_bubbles = 0
var look_back = 2.0
var height_above_vehicle = 3

func create_bubble(additions, removes, end_time):

	for addition in additions:
		var color = addition["color"]
		all_bubbles_meta.append({"id": addition["id"], "start": addition["t"], "end": end_time, "to": addition["to_id"], "message" : addition["message"], "color": Color(color["r"], color["g"], color["b"], color["a"])})

	for i in all_bubbles_meta:
		var has_end = false

		for remove in removes:
			if i["id"] == remove["id"]:
				i["end"] = remove["t"]
				has_end = true
				break
		if not has_end:
			i["end"] = end_time
	
	len_all_meta_bubbles = len(all_bubbles_meta)
	
func update_bubble(time:String):
	var f_time = float(time)

	while all_bubbles_meta_pos+1 < len_all_meta_bubbles and all_bubbles_meta[all_bubbles_meta_pos+1]["start"] <= f_time:
		all_bubbles_meta_pos += 1

		var this_bubble = all_bubbles_meta[all_bubbles_meta_pos]
		var arr = [this_bubble["to"], this_bubble["end"]]
		arr.append(instantiate_bubble(this_bubble))
		all_bubbles.append(arr)
	
	for i in range(all_bubbles.size() - 1, -1, -1):
		var bubble = all_bubbles[i]
		if bubble[1] < f_time or not vehicles.is_there(bubble[0]):
			bubble[2].queue_free()
			all_bubbles.remove_at(i)
		else:
			var to = vehicles.get_pos(bubble[0])
			var ins = bubble[2]


			ins.global_position = to + Vector3(0, height_above_vehicle, 0)

			
	
func instantiate_bubble(info:Dictionary):
	var to = vehicles.get_pos(info["to"])
	
	var bubble = bubble.instantiate()
	add_child(bubble)
	
	#transform the arrow
	bubble.global_position = to + Vector3(0, height_above_vehicle, 0)
	bubble.change_obj(info["color"], info["message"])
	bubble.look_at(Camera.position)

	
	return bubble
func update_bubble_backwards(time:String):

	var f_time = float(time)
	for i in range(all_bubbles.size() - 1, -1, -1):
		all_bubbles[i][2].queue_free()
	all_bubbles = []
	
	while all_bubbles_meta_pos >= 0  and all_bubbles_meta[all_bubbles_meta_pos]["start"] >= f_time-look_back:
		all_bubbles_meta_pos -= 1


	while  all_bubbles_meta_pos +1 < len_all_meta_bubbles and all_bubbles_meta[all_bubbles_meta_pos+1]["start"] <= f_time :
		all_bubbles_meta_pos += 1

		if all_bubbles_meta[all_bubbles_meta_pos]["end"] >= f_time:
			var this_bubble = all_bubbles_meta[all_bubbles_meta_pos]
			var arr = [ this_bubble["to"], this_bubble["end"]]
			arr.append(instantiate_bubble(this_bubble))
			all_bubbles.append(arr)

	for i in range(all_bubbles.size() - 1, -1, -1):
		var bubble = all_bubbles[i]
		if bubble[1] < f_time or not vehicles.is_there(bubble[0]):
			bubble[2].queue_free()
			all_bubbles.remove_at(i)
		else:
			var to = vehicles.get_pos(bubble[0])
			var ins = bubble[2]

			ins.global_position = to + Vector3(0, height_above_vehicle, 0)
