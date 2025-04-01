extends Node3D

func create_static_objects(data):
	var buildings = []
	var junctions = []
	var roads = []
	
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



	var building2d5 = $Building2d5
	var junction = $Junction
	var road = $Road
	
	#render the objects in their own nodes
	building2d5.create_building2d5(buildings)
	junction.create_junctions(junctions)
	road.create_roads(roads)
	
