extends Node3D

@onready var vehicles = $"../Vehicles"

var Connector = preload("res://Scenes/connector.tscn")
var all_connections = []
var all_connections_meta = []
var all_connections_meta_pos = -1
var len_all_meta_connections = 0
var look_back = 20000.0
var first = true

func create_connector(additions, removes, end_time):

	for addition in additions:
		all_connections_meta.append({"id": addition["id"], "start": addition["t"], "end": end_time, "from": addition["from_id"], "to": addition["to_id"]})

	for i in all_connections_meta:
		var has_end = false
		var ia = 0
		for remove in removes:
			if i["id"] == remove["id"]:
				i["end"] = remove["t"]
				removes.remove_at(ia)
				has_end = true
				break
			i += 1
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

			transform(from, to, ins)

	
	
func instantiate_con(info:Array):
	var from =  vehicles.get_pos(info[0])
	var to = vehicles.get_pos(info[1])
	
	var connection = Connector.instantiate()
	add_child(connection)
	
	var vec = to-from
	#transform the arrow
	transform(from, to, connection)

	
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

			transform(from, to, ins)
func transform(from:Vector3, to:Vector3, ins):
			var vec = to - from
			var length = vec.length()

			if length > 0.001: # um Division durch 0 zu vermeiden
				var direction = vec.normalized()

				# Erstelle eine neue Basis, die in Richtung X zeigt
				var right = direction
				var up = Vector3.UP

				# Falls direction zu nah an UP ist, wähle eine andere UP-Richtung
				if abs(direction.dot(up)) > 0.99:
					up = Vector3.FORWARD

				var forward = right.cross(up).normalized()
				up = forward.cross(right).normalized()

				var basis = Basis(right, up, forward).orthonormalized()
				ins.global_transform = Transform3D(basis, to)
				ins.scale = Vector3(length, 1, 1) # Länge auf X-Achse gestreckt
			
