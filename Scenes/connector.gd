extends Node3D

@onready var vehicles = $"../Vehicles"

var all_connections = {}
var all_connections_meta = {}

func create_connector(additions, removes):
	
	for addition in additions:
		all_connections_meta[addition["id"]] ={}
		all_connections_meta[addition["id"]]["start"] = addition["t"]
		all_connections_meta[addition["id"]]["from"] = addition["from_id"]
		all_connections_meta[addition["id"]]["to"] = addition["to_id"]
	for remove in removes:
		all_connections_meta[remove["id"]]["end"] = remove["t"]
	
	for key in all_connections_meta.keys():
		var conn = all_connections_meta[key]
		var from = {}
		var to = {}
		vehicles.get_all_pos(key, conn["start"], conn["end"], from)
		vehicles.get_all_pos(key, conn["start"], conn["end"], to)
		
		var st_from =  
		
		for key2 in from.keys():
			if not all_connections.has(key2):
				all_connections[key2] = []
			
			
		
