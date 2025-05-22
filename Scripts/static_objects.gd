extends Node3D
@onready var Error = $".."



var roads = []
var traffic_line_add = []
var prism = []
var other = {}
var wait = 20
var wait_counter = 0

@onready var building2d5 = $Building2d5
@onready 	var junction = $Junction


func add_static_objects(item)-> bool:

	if item.has("type"):
			
			match item["type"]:
				
				#are rendered immediately
				"building_2d5":
					building2d5.create_building2d5(item)
				"junction":
					junction.create_junctions(item)
					
				#have to be stored in an array
				"road":
					roads.append(item)
				"trafficLight":
					traffic_line_add.append(item)
				"prismAddition":
					prism.append(item)
					
				#if update then cancel static generation and go to dynamic objects
				"update":
					return true
				_:
					other[str(item["type"])] = 0 
	return false
	
func create_static_objects():
	
	
	for key in other.keys():
		Error.append_error("In Init the Type: " + key + "is unknown")
		

	var road = $Road
	var traffic_light = $"../DynamicObjects/TrafficLight"
	var Prism = $"../DynamicObjects/Prism"
	
	#render the objects in their own nodes
	traffic_light.create_traffic_light_before(traffic_line_add)
	road.create_roads(roads)
	traffic_light.create_traffic_light_after()
	Prism.create_prisms(prism)
