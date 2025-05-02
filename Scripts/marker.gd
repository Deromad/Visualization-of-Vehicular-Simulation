extends Node3D

@onready var vehicles = $"../Vehicles"
@onready var Camera = $"../../Camera3D"

var Marker = preload("res://Scenes/marker.tscn")
@onready var Movie = $"../.."

var all_markers = {}
var all_markers_temp = {}
var all_markers_meta = {}

func add_addition(data:Dictionary, pos:int)->void :
	all_markers_temp[data["id"]] = data["t"]
	all_markers[data["id"]] = [pos, data["t"], Globals.length_of_programm]

func add_removal(data:Dictionary)->void:
	add_removal_t(data["id"], data["t"])
	
func add_removal_t(id:String, t:float)->void:
	if all_markers_temp.has(id):

		if t - all_markers_temp[id] < Globals.look_back:
			all_markers.erase(id)
			all_markers_temp.erase(id)
		else:
			all_markers_temp.erase(id)
			all_markers[id][1] = t

func clean_all():
	for key in all_markers_meta.keys():
		var ins = all_markers_meta[key]
		ins.queue_free()
		all_markers_meta.erase(key)


func create_markers(marker: Dictionary, pos:int):
	all_markers_meta[marker["id"]] = instantiate_marker(marker)
	add_addition(marker, pos)
	


func update_to_time(t:float):
	for key in all_markers.keys():
		var this_key = all_markers[key]
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])
			create_markers(json, this_key[0])
func remove_marker(marker:Dictionary):
	var id = marker["id"]
	if all_markers_meta.has(id):
		var ins = all_markers_meta[id]
		ins.queue_free()
		all_markers_meta.erase(id)
		add_removal(marker)

	

	
func instantiate_marker(marker: Dictionary):
	var ins = Marker.instantiate()
	add_child(ins)
	var pos = marker["pos"]

	transform(Vector3(pos["x"], pos["z"], pos["y"]), marker["message"], ins)

	return ins
	
func transform(to:Vector3, message:String, ins)->void:
		ins.global_position = to 
		ins.change_obj( message)
