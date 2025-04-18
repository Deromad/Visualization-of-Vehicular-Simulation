extends Node3D
@onready var Error = $".."

func create_static_objects(data):
	var buildings = []
	var junctions = []
	var roads = []
	var traffic_line_add = []
	var prism = []
	var other = {}
	#get every relevant object and assign its objecttype
	for item in data:
		if item.has("type"):
			
			match item["type"]:
				"building_2d5":
					buildings.append(item)
				"junction":
					junctions.append(item)
				"road":
					roads.append(item)
				"trafficLight":
					traffic_line_add.append(item)
				"prismAddition":
					prism.append(item)
				_:
					other[str(item["type"])] = 0 
	
	for key in other.keys():
		Error.append_error("In Init the Type: " + key + "is unknown")
		

	var building2d5 = $Building2d5
	var junction = $Junction
	var road = $Road
	var traffic_light = $"../DynamicObjects/TrafficLight"
	var Prism = $"../DynamicObjects/Prism"
	
	#render the objects in their own nodes
	building2d5.create_building2d5(buildings)
	junction.create_junctions(junctions)
	traffic_light.create_traffic_light_before(traffic_line_add)
	road.create_roads(roads)
	traffic_light.create_traffic_light_after()
	Prism.add_prism(prism)
