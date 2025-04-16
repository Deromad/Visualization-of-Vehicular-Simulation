extends Node3D

@onready var RSU = preload("res://Scenes/rsu_2.tscn") 


var all_rsus_meta = []
var all_rsus = []
var all_rsus_meta_pos = -1
var len_all_meta_rsus = 0


func create_rsu(additions):

	for addition in additions:
		var pos = addition["pos"]
		all_rsus_meta.append({"t": addition["t"], "pos": Vector3(pos["x"], pos["z"], pos["y"])})

	
	len_all_meta_rsus = len(all_rsus_meta)
	
func update_rsu(time:String):
	var f_time = float(time)

	while all_rsus_meta_pos + 1 < len_all_meta_rsus and all_rsus_meta[all_rsus_meta_pos + 1]["t"] <= f_time:
		all_rsus_meta_pos += 1

		var this_data = all_rsus_meta[all_rsus_meta_pos]

		all_rsus.append(instantiate_rsu(this_data))



func instantiate_rsu(info:Dictionary):
	
	var rsu = RSU.instantiate()
	add_child(rsu)
	
	#transform the arrow
	rsu.global_position = info["pos"]
	return rsu

func update_rsu_backwards(time:String):
	var f_time = float(time)
	
	while all_rsus_meta_pos +1 < len_all_meta_rsus and all_rsus_meta[all_rsus_meta_pos+1]["t"] <= f_time:
		all_rsus_meta_pos += 1

		var this_data = all_rsus_meta[all_rsus_meta_pos]
		all_rsus.append(instantiate_rsu(this_data))


	for i in range(all_rsus_meta_pos, -1, -1):

		if all_rsus_meta[i]["t"] > f_time:
			all_rsus[i].queue_free()
			all_rsus.remove_at(i)
			all_rsus_meta_pos -= 1
		else:
			break
