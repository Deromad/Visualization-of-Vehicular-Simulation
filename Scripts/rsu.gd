extends Node3D

@onready var RSU = preload("res://Scenes/rsu_2.tscn") 




@onready var Movie = $"../.."

var all_rsus = {}
var all_rsus_temp = {}
var all_rsus_meta = {}

func add_addition(data:Dictionary, pos:int)->void :
	all_rsus_temp[data["id"]] = data["t"]
	all_rsus[data["id"]] = [pos, data["t"], Globals.length_of_programm]

func add_removal(data:Dictionary)->void:
	add_removal_t(data["id"], data["t"])
	
func add_removal_t(id:String, t:float)->void:
	if all_rsus_temp.has(id):

		if t - all_rsus_temp[id] < Globals.look_back:
			all_rsus.erase(id)
			all_rsus_temp.erase(id)
		else:
			all_rsus_temp.erase(id)
			all_rsus[id][1] = t

func clean_all():
	for key in all_rsus_meta.keys():
		var ins = all_rsus_meta[key]
		ins.queue_free()
		all_rsus_meta.erase(key)


func create_rsus(rsu: Dictionary, pos:int):
	var posi = rsu["pos"]
	
	all_rsus_meta[rsu["id"]] = instantiate_rsu(Vector3(posi["x"], posi["z"], posi["y"]))
	add_addition(rsu, pos)
	


func update_to_time(t:float):
	for key in all_rsus.keys():
		var this_key = all_rsus[key]
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])
			create_rsus(json, this_key[0])
func remove_rsu(rsu:Dictionary):
	var id = rsu["id"]
	if all_rsus_meta.has(id):
		var ins = all_rsus_meta[id]
		ins.queue_free()
		all_rsus_meta.erase(id)
		add_removal(rsu)
			
	
func instantiate_rsu(pos: Vector3):
		var ins = RSU.instantiate()
		ins.global_position = pos
		add_child(ins)
		print(ins.global_position)

		return ins
func get_pos(id:String)-> Vector3:
	if all_rsus_meta.has(id) :
		return all_rsus_meta[id].global_position
	return Vector3(0,0,0)

func is_there(id:String)->bool:
	if all_rsus_meta.has(id):
		return true
	return false			
