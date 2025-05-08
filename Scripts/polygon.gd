extends Node3D

@onready var vehicles = $"../Vehicles"
@onready var Camera = $"../../Camera3D"



@onready var Movie = $"../.."

var all_polygons = {}
var all_polygons_temp = {}
var all_polygons_meta = {}

func add_addition(data:Dictionary, pos:int)->void :
	all_polygons_temp[data["id"]] = data["t"]
	all_polygons[data["id"]] = [pos, data["t"], Globals.length_of_programm]

func add_removal(data:Dictionary)->void:
	add_removal_t(data["id"], data["t"])
	
func add_removal_t(id:String, t:float)->void:
	if all_polygons_temp.has(id):

		if t - all_polygons_temp[id] < Globals.look_back:
			all_polygons.erase(id)
			all_polygons_temp.erase(id)
		else:
			all_polygons_temp.erase(id)
			all_polygons[id][1] = t

func clean_all():
	for child in get_children():
		child.queue_free()
	
	all_polygons_meta = {}


func create_polygons(polygon: Dictionary, pos:int):
	var color = polygon["color"]
	var shapes = PackedVector3Array()
	for i in polygon["shape"]:
		shapes.append(Vector3(i["x"], i["z"], i["y"]))
	all_polygons_meta[polygon["id"]] = instantiate_polygon(shapes, Color(color["r"], color["g"], color["b"], color["a"]))
	add_addition(polygon, pos)
	


func update_to_time(t:float):
	for key in all_polygons.keys():
		var this_key = all_polygons[key]
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])
			create_polygons(json, this_key[0])
func remove_polygon(polygon:Dictionary):
	var id = polygon["id"]
	if all_polygons_meta.has(id):
		var ins = all_polygons_meta[id]
		ins.queue_free()
		all_polygons_meta.erase(id)
		add_removal(polygon)




			
	
func instantiate_polygon(shape:PackedVector3Array, color: Color):

		var vec2d = PackedVector2Array()
		var normals = PackedVector3Array()
		for i in shape:
			vec2d.append(Vector2(i.x,i.z))
			normals.append(Vector3(0,1,0))
		var indices = Geometry2D.triangulate_polygon(vec2d)
		
		# Initialize the ArrayMesh.
		var arr_mesh = ArrayMesh.new()
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = shape
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices

		# Create the Mesh.
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var m = MeshInstance3D.new()
		m.mesh = arr_mesh
		
		# create Material for each instance, so that they can have different colors
		var new_material = preload("res://Materials/roof.tres")
		new_material.color = color
		
		#add surface zo mesh and add roof to scene
		m.set_surface_override_material(0, new_material)
		add_child(m)
		return m

	
