extends Node3D


@onready var slide = $"../UI/HSlider"
@onready var vehicle = $Vehicles
@onready var connector = $Connector
@onready var emoji = $Emoji 
@onready var logData = $LogDaten
@onready var speed_label = $"../UI/SpeedLabel"
@onready var time_label = $"../UI/Time"
@onready var rsu = $RSU
@onready var Error = $".."
@onready var TrafficLight = $TrafficLight
@onready var Prism = $Prism
@onready var Bubble = $Bubble
@onready var Polygon = $Polygon
@onready var Marker = $Marker


#when  ajump is triggered skips many steps and just store most important infos
func skipping_objects(data:Dictionary, value:float, pos:int)-> bool:
	match data["type"]:
		"vehicleUpdate":
			vehicle.add_update(data, pos)
		"connectorAddition":
			connector.add_addition(data, pos)
		"connectorRemoval":
			connector.add_removal(data)
		"vehicleAddition":
			vehicle.add_addition(data, pos)
		"vehicleRemoval":
			vehicle.add_removal(data)
		
		"prismUpdate":
			Prism.add_update(data)
		"timestepBegin":
			var t = data["t"]
			if Error.time_until_next_cp <= 0 and Error.last_cp < t:
				Error.last_cp = t
				Error.time_until_next_cp = Error.checkpoint_intervall
				Error.check_points.append([t, pos])

			Error.time_until_next_cp -= t-Error.intervall

			if data["t"] > value:
				return true
		"timestepEnd":
			
			Error.intervall = data["t"]
			Globals.max_t = max(Globals.max_t, data["t"])
		"emojiAddition":
			emoji.add_addition(data, pos)
		"emojiRemoval":
			emoji.add_removal(data)
		"bubbleAddition":
			Bubble.add_addition(data, pos)
		"bubbleRemoval":
			Bubble.add_removal(data)
		"trafficLightUpdate":
			TrafficLight.add_update(data, pos)
		"markerAddition":
			Marker.add_addition(data, pos)
		"markerRemoval":
			Marker.add_removal(data)
		"polygonAddition":
			Polygon.add_addition(data, pos)
		"polygonRemoval":
			Polygon.add_removal(data)
		"rsuAddition":
			rsu.add_addition(data, pos)
		"rsuRemoval":
			rsu.add_removal(data)
	return false



	
	
