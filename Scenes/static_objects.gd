extends Node3D

func create_static_objects(data):
	var buildings = []
	for item in data:
		if item.has("type") and item["type"] == "building_2d5":
			buildings.append(item)

	var building2d5 = get_node("Building2d5")
	building2d5.create_building2d5(buildings)
	
