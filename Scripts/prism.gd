extends Node3D
var all_prisms = {}
var all_prisms_meta = {}
var heigth = 0.0
@onready var Error = $"../.."
var Prism = preload("res://Scenes/prism.tscn")

func add_prism(data:Array) ->void:
	for prism in data:
		if not prism.has("id"):
			Error.append_error("A Prism has no ID")
			continue
		var id = prism["id"]

		if not prism.has("shape") or  prism["shape"].size() != 4:
			Error.append_error("The Prism with the ID " + str(id) + " has an invalide shape")
			continue
		if not prism.has("z_from") or not (prism["z_from"] is float or prism["z_from"] is float):
			Error.append_error("The Prism with the ID " + str(id) + " has an invalide z_from")
			continue
		if not prism.has("z_to") or not (prism["z_to"] is float or prism["z_to"] is float) :
			Error.append_error("The Prism with the ID " + str(id) + " has an invalide z_to")
			continue
		var shape = []
		for i in prism["shape"]:
			shape.append(Vector2(i["x"], i["y"]))

		if not Error.check_color(prism):
			Error.append_error("The Prism with the ID " + str(id) + " has an invalide color")
			continue
		var color = prism["color"]
		all_prisms_meta[id] = [initialize_prism(shape, prism["z_from"], prism["z_to"], Color(color["r"], color["g"], color["b"], color["a"])), prism["z_from"]]
		if not all_prisms.has("0"):
			all_prisms["0"] = []
		all_prisms["0"].append([id,prism["z_to"]])
func initialize_prism(shape:Array, z_from:int, z_to:int, color:Color) :

	
	var prism = Prism.instantiate()
	add_child(prism)
	shape.sort()
	#transform the arrow
	var vec = shape[3]-shape[0]
	prism.global_position = Vector3(shape[0].x, heigth, shape[0].y)
	prism.scale = Vector3(vec.x, z_to-z_from, vec.y)
	prism.transform_obj(color)
	return prism
func add_update(data:Array):
	for update in data:
		if not update.has("id") or not update["id"] is String:
			Error.append_error("The Update of a Prism has no String Value ID")
			continue
		if not update.has("t") or not (update["t"] is float or update["t"] is float):
			Error.append_error("The Update of a Prism has no Float or Int Value time")
			continue
		if not update.has("z_to") or not (update["z_to"] is float or update["z_to"] is float):
			Error.append_error("The Update of a Prism has no Float or Int Value z_to")
			continue
		var t = str(update["t"])
		if not all_prisms_meta.has(update["id"]):
			Error.append_error("The PrismUpdate with the ID " + update["id"] + "ha no correct ADdition ")
			continue
		if not all_prisms.has(t):
			all_prisms[t] = []
		all_prisms[t].append([update["id"], update["z_to"]])
func update(time:String):
	if not all_prisms.has(time):
		return
	for i_prism in all_prisms[time]:
		var this_prism = all_prisms_meta[i_prism[0]]
		this_prism[0].scale = Vector3(this_prism[0].scale.x, i_prism[1]- this_prism[1] , this_prism[0].scale.z)
