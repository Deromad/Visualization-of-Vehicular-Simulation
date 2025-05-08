extends Node3D

@onready var Vehicle = $"../Vehicles"
@onready var RSU = $"../RSU"


var Connector = preload("res://Scenes/connector.tscn")


@onready var Movie = $"../.."

var all_conns = {}
var all_conns_temp = {}
var all_conns_meta = {}

func add_addition(data:Dictionary, pos:int)->void :
	all_conns_temp[data["id"]] = data["t"]
	all_conns[data["id"]] = [pos, data["t"], Globals.length_of_programm]

func add_removal(data:Dictionary)->void:
	add_removal_t(data["id"], data["t"])
	
func add_removal_t(id:String, t:float)->void:
	if all_conns_temp.has(id):

		if t - all_conns_temp[id] < Globals.look_back:
			all_conns.erase(id)
			all_conns_temp.erase(id)
		else:
			all_conns_temp.erase(id)
			all_conns[id][1] = t

func clean_all():
	for child in get_children():
		child.queue_free()
	
	all_conns_meta = {}

func create_conns(conn: Dictionary, pos:int):
	var info = [conn["from_id"], conn["to_id"]]
	var color_dic = conn["color"]
	info.append(instantiate_con(info, Color(color_dic["r"], color_dic["g"], color_dic["b"], color_dic["a"])))
	all_conns_meta[conn["id"]]  = info
	add_addition(conn, pos)


	
func update(t:float):
	for key in all_conns_meta.keys():
		var this_con = all_conns_meta[key]
		var from_str = this_con[0]
		var to_str = this_con[1]
		if Vehicle.is_there(from_str):
			if Vehicle.is_there(to_str):
				transform(Vehicle.get_pos(from_str), Vehicle.get_pos(to_str), this_con[2])
			elif RSU.is_there(to_str):
				transform(Vehicle.get_pos(from_str), RSU.get_pos(to_str), this_con[2])
		elif RSU.is_there(to_str):
			if Vehicle.is_there(to_str):
				transform(RSU.get_pos(from_str), Vehicle.get_pos(to_str), this_con[2])
			elif RSU.is_there(to_str):
				transform(RSU.get_pos(from_str), RSU.get_pos(to_str), this_con[2])
		
		else:
			#remove connection
			this_con[2].queue_free()
			all_conns_meta.erase(key)
			add_removal_t(key, t)

func update_to_time(t:float):
	for key in all_conns.keys():
		var this_key = all_conns[key]
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])
			create_conns(json, this_key[0])
func remove_con(conn:Dictionary):
	var id = conn["id"]
	if all_conns_meta.has(id):
		var ins = all_conns_meta[id][2]
		ins.queue_free()
		all_conns_meta.erase(id)
		add_removal(conn)

	
func instantiate_con(info:Array, color:Color) :
	var from =  Vehicle.get_pos(info[0])
	var to = Vehicle.get_pos(info[1])
	if from == null:
		from = RSU.get_pos(info[0])
	if to == null:
		to = RSU.get_pos(info[1])
	var connection = Connector.instantiate()
	connection.transform_obj(Movie.get_material(color))
	add_child(connection)
	
	var vec = to-from
	#transform the arrow
	transform(from, to, connection)
	return connection

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
			
				
