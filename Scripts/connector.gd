extends Node3D

@onready var vehicles = $"../Vehicles"

var Connector = preload("res://Scenes/connector.tscn")
var all_connections = []
var all_connections_meta = []
var all_connections_meta_pos = -1
var len_all_meta_connections = 0
var look_back = 2.0
var first = true

func create_connector(additions, removes, end_time):

	for addition in additions:
		all_connections_meta.append({"id": addition["id"], "start": addition["t"], "end": end_time, "from": addition["from_id"], "to": addition["to_id"]})

	for i in all_connections_meta:
		var has_end = false

		for remove in removes:
			if i["id"] == remove["id"]:
				i["end"] = remove["t"]
				has_end = true
				break
		if not has_end:
			i["end"] = end_time
	
	len_all_meta_connections = len(all_connections_meta)
	
func update_connector(time:String):
	var f_time = float(time)

	while all_connections_meta_pos +1< len_all_meta_connections and all_connections_meta[all_connections_meta_pos+1]["start"] <= f_time:
		all_connections_meta_pos += 1

		var this_con = all_connections_meta[all_connections_meta_pos]
		var arr = [this_con["from"], this_con["to"], this_con["end"]]
		arr.append(instantiate_con(arr))
		all_connections.append(arr)
	
	for i in range(all_connections.size() - 1, -1, -1):
		var con = all_connections[i]
		if con[2] < f_time or not vehicles.is_there(con[0]) or not vehicles.is_there(con[1]):
			con[3].queue_free()
			all_connections.remove_at(i)
		else:
			var from = vehicles.get_pos(con[0])
			var to = vehicles.get_pos(con[1])
			var ins = con[3]

			var vec = to - from
			ins.global_position = (from + to) / 2
			ins.scale = Vector3(vec.length(), 1, 1)
			ins.global_rotation = Vector3(0, -Vector2(vec.x, vec.z).angle(), 0)
		
	
	
func instantiate_con(info:Array):
	var from =  vehicles.get_pos(info[0])
	var to = vehicles.get_pos(info[1])
	
	var connection = Connector.instantiate()
	add_child(connection)
	
	var vec = to-from
	#transform the arrow
	
	connection.global_position = (from + to) /2
	connection.scale = Vector3(vec.length(), 1, 1)
	connection.global_rotation = Vector3(0, - Vector2(vec.x, vec.z).angle(), 0)
	
	return connection
func update_connector_backwards(time:String):

	var f_time = float(time)
	for i in range(all_connections.size() - 1, -1, -1):
		all_connections[i][3].queue_free()
	all_connections = []

	while all_connections_meta_pos >= 0  and all_connections_meta[all_connections_meta_pos]["start"] >= f_time-look_back:
		all_connections_meta_pos -= 1

	

	while  all_connections_meta_pos + 1 < len_all_meta_connections and all_connections_meta[all_connections_meta_pos + 1]["start"] <= f_time :
		all_connections_meta_pos += 1

		if all_connections_meta[all_connections_meta_pos]["end"] >= f_time:
			var this_con = all_connections_meta[all_connections_meta_pos]
			var arr = [this_con["from"], this_con["to"], this_con["end"]]
			arr.append(instantiate_con(arr))
			all_connections.append(arr)

	for i in range(all_connections.size() - 1, -1, -1):
		var con = all_connections[i]
		if con[2] < f_time or not vehicles.is_there(con[0]) or not vehicles.is_there(con[1]):
			con[3].queue_free()
			all_connections.remove_at(i)
		else:
			var from = vehicles.get_pos(con[0])
			var to = vehicles.get_pos(con[1])
			var ins = con[3]

			var vec = to - from
			ins.global_position = (from + to) / 2
			ins.scale = Vector3(vec.length(), 1, 1)
			ins.global_rotation = Vector3(0, -Vector2(vec.x, vec.z).angle(), 0)
			
