extends Node3D

@onready var vehicles = $"../Vehicles"
@onready var Camera = $"../../Camera3D"

var Marker = preload("res://Scenes/marker.tscn")
var all_markers = []
var all_markers_meta = []
var all_markers_meta_pos = -1
var len_all_meta_markers = 0
var look_back = 2.0
var height_above_vehicle = 5.0

func create_marker(additions, removes, end_time):

	for addition in additions:
		var pos = addition["pos"]
		all_markers_meta.append({"id": addition["id"], "start": addition["t"], "message" : addition["message"], "pos": Vector3(pos["x"], pos["z"], pos["y"])})

	for i in all_markers_meta:
		var has_end = false

		for remove in removes:
			if i["id"] == remove["id"]:
				i["end"] = remove["t"]
				has_end = true
				break
		if not has_end:
			print(i["start"])
			print(i["id"])
			
			i["end"] = end_time
	
	len_all_meta_markers = len(all_markers_meta)
	
func update_marker(time:String):
	var f_time = float(time)

	while all_markers_meta_pos+1 < len_all_meta_markers and all_markers_meta[all_markers_meta_pos+1]["start"] <= f_time:
		all_markers_meta_pos += 1

		var this_marker = all_markers_meta[all_markers_meta_pos]
		var arr = [ this_marker["end"]]
		arr.append(instantiate_marker(this_marker["pos"], this_marker["message"]))
		all_markers.append(arr)
	
	for i in range(all_markers.size() - 1, -1, -1):
		var marker = all_markers[i]
		if marker[0] < f_time:
	
			marker[1].queue_free()
			all_markers.remove_at(i)
	await get_tree().create_timer(0.001).timeout




			
	
func instantiate_marker(pos:Vector3, message:String):

	
	var marker = Marker.instantiate()
	add_child(marker)
	
	#transform the arrow
	marker.global_position = pos
	marker.change_obj(message)
	return marker
func update_marker_backwards(time:String):

	var f_time = float(time)
	for i in range(all_markers.size() - 1, -1, -1):
		all_markers[i][1].queue_free()
	all_markers = []
	
	while all_markers_meta_pos >= 0  and all_markers_meta[all_markers_meta_pos]["start"] >= f_time-look_back:
		all_markers_meta_pos -= 1


	while  all_markers_meta_pos +1 < len_all_meta_markers and all_markers_meta[all_markers_meta_pos+1]["start"] <= f_time :
		all_markers_meta_pos += 1

		if all_markers_meta[all_markers_meta_pos]["end"] >= f_time:
			var this_marker = all_markers_meta[all_markers_meta_pos]
			var arr = [this_marker["end"]]
			arr.append(instantiate_marker(this_marker["pos"], this_marker["message"]))
			all_markers.append(arr)

	for i in range(all_markers.size() - 1, -1, -1):
		var marker = all_markers[i]
		if marker[0] < f_time:
			marker[1].queue_free()
			all_markers.remove_at(i)
	
