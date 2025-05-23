extends Node3D

@onready var Vehic = $"../DynamicObjects/Vehicles"
@onready var ErrorPanel = $"../UI/Error/ErrorLabel"
@onready var TL = $"../DynamicObjects/TrafficLight"
@onready var Prism = $"../DynamicObjects/Prism"
@onready var Conn = $"../DynamicObjects/Connector"
@onready var Emoji = $"../DynamicObjects/Emoji"
@onready var RSU = $"../DynamicObjects/RSU"
@onready var Bubble = $"../DynamicObjects/Bubble"
@onready var Poly = $"../DynamicObjects/Polygon"
@onready var Marker = $"../DynamicObjects/Marker"
@onready var Movie = $".."
@onready var Error = $"../UI/Error"

var is_written = false
var error_arr = []

func testing_static(json: Dictionary)-> bool:
	match json["type"]:
		"prismAddition":
			return prism_addition(json)
		"trafficLight":
			return traffic_light(json)
		"building_2d5":
			return building_2d5(json)
		"junction":
			return junction(json)
		"road":
			return road(json)
		"update":
			return true
		_:
			append_error("The type "+ json["type"] + " is unknown!")
			create_error()
			return false
			
			
func testing_dynamic(json: Dictionary)-> bool:
	match json["type"]:
								"vehicleUpdate":
									return vehicle_update(json)
								"connectorAddition":
									return connector_addition(json)
								"connectorRemoval":
									return connector_removal(json)
								"logLineAddition":
									return log_line_addition(json)
								"vehicleAddition":
									return vehicle_addition(json)
					
								"vehicleRemoval":	
									return vehicle_removal(json)
									
								"prismUpdate":
									return prism_update(json)
								"timestepBegin":
									return timestep_begin(json)
									
								"timestepEnd":
									return timestep_end(json)

								"emojiAddition":
									return emoji_addition(json)
								"emojiRemoval": 
									return emoji_removal(json)
								"bubbleAddition":
									return bubble_addition(json)
								"bubbleRemoval":
									return bubble_removal(json)
								"trafficLightUpdate":
									return traffic_light_update(json)
								"markerAddition":
									return marker_addition(json)
								"markerRemoval":
									return marker_removal(json)
								"polygonAddition":
									return polygon_addition(json)
								"polygonRemoval":
									return polygon_removal(json)
								"rsuAddition":
									return rsu_addition(json)
								"rsuRemoval":
									return rsu_removal(json)
								_:
											append_error("The type "+ json["type"] + " is unknown!")
											return false
func append_error(msg: String) -> void:
	error_arr.append(msg)
		
func create_error():
	if error_arr.size() > 0 and not is_written:
		is_written = true
		Movie.should_play = false
		Error.visible = true
		ErrorPanel.text = "Warning!\n"
		var i = 0
		for msg in error_arr:
			i += 1
			ErrorPanel.append_text( str(i) + ": " + msg + "\n")
func test_array(json) -> bool:
	return typeof(json) == TYPE_ARRAY

func test_controlled_links(json) -> bool:
	if not json is Dictionary:
		return false
	for key in json.keys():
		var val = json[key]
		if not val is Array:
			return false
		for item in val:
			if not item is Dictionary:
				return false
			if not item.has("incoming") or not test_string(str(item["incoming"])):
				return false
			if not item.has("outgoing") or not test_string(str(item["outgoing"])):
				return false
	return true

func test_int(json) -> bool:
	return typeof(json) == TYPE_INT or test_float(json)

func test_color(color)->bool:
	if color is Dictionary:
		if color.has("r") and color.has("g") and color.has("b") and color.has("a"):
			var r = color["r"]
			var g = color["g"]
			var b = color["b"]
			var a = color["a"]
			
			print("asdas")
			if r is float and r < 256 and  r >= 0 and g is float and g < 256 and  g >= 0 and b is float and b < 256 and  b >= 0 and a is float and a < 256 and  a >= 0:
				return true
		

	return false
func test_array_of_strings(arr) -> bool:
	if typeof(arr) != TYPE_ARRAY:
		return false
	for item in arr:
		if not test_string(str(item)):
			return false
	return true
func D2_shape(json) -> bool:
	if not json is Array:
		return false
	for point in json:
		if not D2_position(point):
			return false
	return true
func test_float(json)->bool:
	if json is float:
		return true
	return false
		
func test_string(json)->bool:
	if json is String:
		return true
	return false
func D3_position(json)->bool:
	if not json is Dictionary:
		return false 
	if not json.has("x") or not test_float(json["x"]):
		return false
	if not json.has("y") or not test_float(json["y"]):
		return false
	if not json.has("z") or not test_float(json["z"]):
		return false
	return true
func D2_position(json)->bool:
	if not json is Dictionary:
		return false 
	if not json.has("x") or not test_float(json["x"]):
		return false
	if not json.has("y") or not test_float(json["y"]):
		return false
	return true
func test_bool(json) -> bool:
	return typeof(json) == TYPE_BOOL

func test_line_width(json) -> bool:
	return typeof(json) in [TYPE_INT, TYPE_FLOAT] and json >= 0

func D3_shape(json) -> bool:
	if not json is Array:
		return false
	for point in json:
		if not D3_position(point):
			return false
	return true
func vehicle_update(json)->bool:
	if json.has("t") and test_float(json["t"]):
		pass
	else:
		append_error("A VehicleUpdate has no or an invalid time t")
		return false
	var t = json["t"]

	if json.has("id") and test_string(str(json["id"])):
		pass
	else:
		append_error("A VehicleUpdate has no or an invalid id at time :" + str(t))
		return false
	var id = str(json["id"])
	if not Vehic.is_there(id):
		append_error("The VehicleUpdate with the id: " + id+ " at the time " + t + " can't update because there is no Vehicle currently initialized with the same id")
		return false
	if not (json.has("pos") and D3_position(json["pos"])):
		append_error("The VehicleUpdate with the id: " + id+ " at the time " + t + " has no valid position")
		return false
	if not (json.has("heading") and D2_position(json["heading"])):
		append_error("The VehicleUpdate with the id: " + id+ " at the time " + t + " has no valid heading")
		return false
	return true



func prism_addition(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("A PrismAddition has no or an invalid time t")
		return false
	var t = json["t"]

	if not json.has("id") or not test_string(str(json["id"])):
		append_error("A PrismAddition has no or an invalid id at time: " + str(t))
		return false
	if Prism.is_there(str(json["id"])):
		append_error("PrismUpdate with id: " + str(json["id"]) + " at time " + str(json.get("t", "?")) + " can't find Prism with same id")
		return false

	if not json.has("shape") or not D2_shape(json["shape"]):
		append_error("A PrismAddition with id: " + str(json["id"]) + " at time " + str(t) + " has an invalid shape")
		return false

	if not json.has("z_from") or not test_float(json["z_from"]):
		append_error("A PrismAddition with id: " + str(json["id"]) + " at time " + str(t) + " has an invalid z_from")
		return false

	if not json.has("z_to") or not test_float(json["z_to"]):
		append_error("A PrismAddition with id: " + str(json["id"]) + " at time " + str(t) + " has an invalid z_to")
		return false

	if not json.has("color") or not test_color(json["color"]):
		append_error("A PrismAddition with id: " + str(json["id"]) + " at time " + str(t) + " has an invalid color")
		return false

	return true

func traffic_light(json) -> bool:
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("A TrafficLight has no or an invalid id")
		return false

	if not json.has("controlledLinks") or not test_controlled_links(json["controlledLinks"]):
		append_error("TrafficLight with id: " + str(json["id"]) + " has invalid controlledLinks")
		return false

	if not json.has("state") or not test_array(json["state"]):
		append_error("TrafficLight with id: " + str(json["id"]) + " has invalid or missing state")
		return false

	if json["state"].size() != json["controlledLinks"].size():
		append_error("TrafficLight with id: " + str(json["id"]) + " has mismatch between state size and controlledLinks size")
		return false

	return true

func building_2d5(json) -> bool:
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("A Building_2D5 has no or an invalid id")
		return false

	if not json.has("shape") or not D3_shape(json["shape"]):
		append_error("Building_2D5 with id: " + str(json["id"]) + " has invalid shape")
		return false

	if not json.has("color") or not test_color(json["color"]):
		append_error("Building_2D5 with id: " + str(json["id"]) + " has invalid color")
		return false


	return true
func junction(json) -> bool:
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("A Junction has no or an invalid id")
		return false


	if not json.has("shape") or not D3_shape(json["shape"]):
		append_error("Junction with id: " + str(json["id"]) + " has no or invalid shape")
		return false

	return true
func test_lane(json) -> bool:
	if not json.has("id") or not test_string(str(json["id"])):
		return false
	if not json.has("width") or not test_float(json["width"]):
		return false

	if not json.has("allowedClasses") or not test_array_of_strings(json["allowedClasses"]):
		return false
	if not json.has("canChangeLeft") or not test_array_of_strings(json["canChangeLeft"]):
		return false
	if not json.has("canChangeRight") or not test_array_of_strings(json["canChangeRight"]):
		return false
	if not json.has("shape") or not D3_shape(json["shape"]):
		return false

	if json.has("links"):
		if typeof(json["links"]) != TYPE_ARRAY:
			return false
		for link in json["links"]:
			if not link is Dictionary:
				return false
			if not link.has("lane") or not test_string(str(link["lane"])):
				return false
			if not link.has("direction") or not test_string(str(link["direction"])):
				return false

	return true

func road(json) -> bool:
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("A Road has no or an invalid id")
		return false


	if not json.has("laneCount") or not test_int(json["laneCount"]):
		append_error("Road " + str(json["id"]) + " has no or invalid laneCount")
		return false

	if not json.has("lanes") or typeof(json["lanes"]) != TYPE_ARRAY:
		append_error("Road " + str(json["id"]) + " has no or invalid lanes array")
		return false

	for lane in json["lanes"]:
		if not test_lane(lane):
			append_error("Road " + str(json["id"]) + " contains an invalid lane")
			return false

	return true
func timestep_begin(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("A TimestepBegin has no or an invalid time t")
		return false
	return true
func rsu_addition(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("RSUAddition has no or an invalid time t")
		return false

	if not json.has("id") or not test_string(str(json["id"])):
		
		append_error("RSUAddition has no or an invalid id at time " + str(json["t"]))
		return false

	if not json.has("pos") or not D3_position(json["pos"]):
		append_error("RSUAddition with id " + str(json["id"]) + " at time " + str(json["t"]) + " has no valid position")
		return false

	return true
func timestep_end(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("A TimestepEnd has no or an invalid time t")
		return false
	return true
func vehicle_addition(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("VehicleAddition has no or an invalid time t")
		return false

	if not json.has("id") or not test_string(str(json["id"])):
		append_error("VehicleAddition has no or an invalid id at time " + str(json["t"]))
		return false
	if Vehic.is_there(str(json["id"])):
		append_error("VehicleUpdate with id: " + str(json["id"]) + " at time " + str(json.get("t", "?")) + " can't find Vehicle with same id")
		return false
	if not json.has("vclass") or not test_string(str(json["vclass"])):
		append_error("VehicleAddition with id " + str(json["id"]) + " has no or invalid vclass")
		return false

	if not json.has("vshape") or not test_string(str(json["vshape"])):
		append_error("VehicleAddition with id " + str(json["id"]) + " has no or invalid vshape")
		return false

	if not json.has("color") or not test_color(json["color"]):
		append_error("VehicleAddition with id " + str(json["id"]) + " has invalid color")
		return false

	if not json.has("length") or not test_float(json["length"]):
		append_error("VehicleAddition with id " + str(json["id"]) + " has invalid length")
		return false

	if not json.has("width") or not test_float(json["width"]):
		append_error("VehicleAddition with id " + str(json["id"]) + " has invalid width")
		return false

	if not json.has("height") or not test_float(json["height"]):
		append_error("VehicleAddition with id " + str(json["id"]) + " has invalid height")
		return false

	if not json.has("pos") or not D3_position(json["pos"]):
		append_error("VehicleAddition with id " + str(json["id"]) + " has invalid position")
		return false

	if not json.has("heading") or not D2_position(json["heading"]):
		append_error("VehicleAddition with id " + str(json["id"]) + " has invalid heading")
		return false


	return true
func prism_update(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("PrismUpdate has no or an invalid time t")
		return false

	if not json.has("id") or not test_string(str(json["id"])):
		append_error("PrismUpdate has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	if not Prism.is_there(str(json["id"])):
		append_error("PrismUpdate with id: " + str(json["_id"]) + " at time " + str(json.get("t", "?")) + " can't find Prism with same id")
		return false
	if not json.has("z_to") or not test_float(json["z_to"]):
		append_error("PrismUpdate with id " + str(json["id"]) + " has no or invalid z_to value at time " + str(json["t"]))
		return false

	return true

func connector_addition(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("ConnectorAddition has no or an invalid time t")
		return false

	if not json.has("id") or not test_string(str(json["id"])):
		append_error("ConnectorAddition has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	if Conn.is_there(str(json["id"])):
		append_error("ConnectorUpdate with id: " + str(json["id"]) + " at time " + str(json.get("t", "?")) + " can't find Connector with same id")
		return false
	if not json.has("from_id") or not test_string(str(json["from_id"])):
		append_error("ConnectorAddition has no or an invalid from_id at time " + str(json.get("t", "?")))
		return false

	if not json.has("to_id") or not test_string(str(json["to_id"])):
		append_error("ConnectorAddition has no or an invalid to_id at time " + str(json.get("t", "?")))
		return false
	
	if not (Vehic.is_there(str(json["from_id"])) or RSU.is_there(str(json["from_id"]))):
		append_error("The VehicleUpdate with the id: " + str(json["from_id"])+ " at the time " +  str(json.get("t", "?")) + " can't update because there is no Vehicle currently initialized with the same id")
		return false
	if not (Vehic.is_there(str(json["to_id"])) or RSU.is_there(str(json["to_id"]))):
		append_error("The VehicleUpdate with the id: " + str(json["to_id"])+ " at the time " +  str(json.get("t", "?")) + " can't update because there is no Vehicle currently initialized with the same id")
		return false
	if not json.has("color") or not test_color(json["color"]):
		append_error("ConnectorAddition with id " + str(json["id"]) + " has invalid color")
		return false

	return true
func emoji_addition(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("EmojiAddition has no or an invalid time t")
		return false

	if not json.has("id") or not test_string(str(json["id"])):
		append_error("EmojiAddition has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	if Emoji.is_there(str(json["id"])):
		append_error("EmojiUpdate with id: " + str(json["id"]) + " at time " + str(json.get("t", "?")) + " can't find Emoji with same id")
		return false
	if not json.has("to_id") or not test_string(str(json["to_id"])):
		append_error("EmojiAddition has no or an invalid to_id at time " + str(json.get("t", "?")))
		return false

	if not (Vehic.is_there(str(json["to_id"])) or RSU.is_there(str(json["to_id"]))):
		append_error("EmojiAddition with to_id: " + str(json["to_id"]) + " at time " + str(json.get("t", "?")) + " can't add emoji because no Vehicle is initialized with this id")
		return false

	if not json.has("message") or not test_string(str(json["message"])):
		append_error("EmojiAddition with id " + str(json["id"]) + " has no or invalid message")
		return false

	if not json.has("color") or not test_color(json["color"]):
		append_error("EmojiAddition with id " + str(json["id"]) + " has invalid color")
		return false

	return true

func log_line_addition(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("LogLineAddition has no or an invalid time t")
		return false

	if not json.has("message") or not test_string(str(json["message"])):
		append_error("LogLineAddition has no or an invalid message at time " + str(json.get("t", "?")))
		return false

	if not json.has("color") or not test_color(json["color"]):
		append_error("LogLineAddition has invalid color at time " + str(json.get("t", "?")))
		return false

	return true
func marker_addition(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("MarkerAddition has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("MarkerAddition has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	if Marker.is_there(str(json["id"])):
		append_error("MarkerUpdate with id: " + str(json["id"]) + " at time " + str(json.get("t", "?")) + " can't find Marker with same id")
		return false
	if not json.has("message") or not test_string(str(json["message"])):
		append_error("MarkerAddition has no or an invalid message at time " + str(json.get("t", "?")))
		return false
	
	if not json.has("pos") or not D3_position(json["pos"]):
		append_error("MarkerAddition has no or an invalid position at time " + str(json.get("t", "?")))
		return false
	
	return true
func polygon_addition(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("PolygonAddition has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("PolygonAddition has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	if Poly.is_there(str(json["id"])):
		append_error("PolygonUpdate with id: " + str(json["id"]) + " at time " + str(json.get("t", "?")) + " can't find Polygon with same id")
		return false
	if not json.has("shape") or not json["shape"] is Array:
		append_error("PolygonAddition has no or an invalid shape at time " + str(json.get("t", "?")))
		return false
	
	for point in json["shape"]:
		if not D3_position(point):
			append_error("PolygonAddition has invalid shape point at time " + str(json.get("t", "?")))
			return false
	
	if not json.has("color") or not test_color(json["color"]):
		append_error("PolygonAddition has invalid color at time " + str(json.get("t", "?")))
		return false
	
	return true
func traffic_light_update(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("TrafficLightUpdate has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("TrafficLightUpdate has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	if not TL.is_there(str(json["id"])):
		append_error("VehicleUpdate with id: " + str(json["_id"]) + " at time " + str(json.get("t", "?")) + " can't find Traffc Light with same id")
		return false
	
	if not json.has("state") or not json["state"] is Array:
		append_error("TrafficLightUpdate has no or an invalid state array at time " + str(json.get("t", "?")))
		return false
	
	for s in json["state"]:
		if not test_string(str(s)):
			append_error("TrafficLightUpdate has invalid state element at time " + str(json.get("t", "?")))
			return false
	
	return true
func connector_removal(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("ConnectorRemoval has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("ConnectorRemoval has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	
	if not Conn.is_there(str(json["id"])):
		append_error("ConnectorRemoval refers to non-existent connector id: " + str(json["id"]) + " at time " + str(json.get("t", "?")))
		return false
	
	return true
func marker_removal(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("MarkerRemoval has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("MarkerRemoval has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	
	if not Marker.is_there(str(json["id"])):
		append_error("MarkerRemoval refers to non-existent marker id: " + str(json["id"]) + " at time " + str(json.get("t", "?")))
		return false
	
	return true
func polygon_removal(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("PolygonRemoval has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("PolygonRemoval has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	
	if not Poly.is_there(str(json["id"])):
		append_error("PolygonRemoval refers to non-existent polygon id: " + str(json["id"]) + " at time " + str(json.get("t", "?")))
		return false
	
	return true
func emoji_removal(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("EmojiRemoval has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("EmojiRemoval has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	
	if not Emoji.is_there(str(json["id"])):
		append_error("EmojiRemoval refers to non-existent emoji id: " + str(json["id"]) + " at time " + str(json.get("t", "?")))
		return false
	
	return true
func rsu_removal(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("RSURemoval has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("RSURemoval has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	
	if not RSU.is_there(str(json["id"])):
		append_error("RSURemoval refers to non-existent emoji id: " + str(json["id"]) + " at time " + str(json.get("t", "?")))
		return false
	
	return true
func bubble_addition(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("BubbleAddition has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("BubbleAddition has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	if Bubble.is_there(str(json["id"])):
		append_error("BubbleUpdate with id: " + str(json["id"]) + " at time " + str(json.get("t", "?")) + " can't find Bubble with same id")
		return false
	if not json.has("to_id") or not test_string(str(json["to_id"])):
		append_error("BubbleAddition has no or an invalid to_id at time " + str(json.get("t", "?")))
		return false
	
	if not Vehic.is_there(str(json["to_id"])):
		append_error("BubbleAddition with to_id: " + str(json["to_id"]) + " at time " + str(json.get("t", "?")) + " refers to non-existent vehicle")
		return false
	
	if not json.has("message") or not test_string(str(json["message"])):
		append_error("BubbleAddition has no or an invalid message at time " + str(json.get("t", "?")))
		return false
	
	if not json.has("color") or not test_color(json["color"]):
		append_error("BubbleAddition with id " + str(json["id"]) + " has invalid color")
		return false
	
	return true
func bubble_removal(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("BubbleRemoval has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("BubbleRemoval has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	
	if not Bubble.is_there(str(json["id"])):
		append_error("BubbleRemoval refers to non-existent bubble id: " + str(json["id"]) + " at time " + str(json.get("t", "?")))
		return false
	
	return true
func vehicle_removal(json) -> bool:
	if not json.has("t") or not test_float(json["t"]):
		append_error("VehicleRemoval has no or an invalid time t")
		return false
	
	if not json.has("id") or not test_string(str(json["id"])):
		append_error("VehicleRemoval has no or an invalid id at time " + str(json.get("t", "?")))
		return false
	
	if not Vehic.is_there(str(json["id"])):
		append_error("VehicleRemoval refers to non-existent vehicle id: " + str(json["id"]) + " at time " + str(json.get("t", "?")))
		return false
	
	return true

func _on_ignore_pressed() -> void:
	is_written = false
	Error.visible = false
	error_arr = []
	Movie.has_error = false
	ErrorPanel.text = ""


func _on_close_pressed() -> void:
	get_tree().quit()
