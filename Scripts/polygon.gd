extends Node3D

@onready var vehicles = $"../Vehicles"
@onready var Camera = $"../../Camera3D"

var all_polygons = []
var all_polygons_meta = []
var all_polygons_meta_pos = -1
var len_all_meta_polygons = 0
var look_back = 2.0
var height_above_vehicle = 5.0

func create_polygon(additions, removes, end_time):

	for addition in additions:
		var color = addition["color"]
		var shape = PackedVector3Array()
		for s in addition["shape"]:
			shape.append(Vector3(s["x"], s["z"], s["y"]))
		all_polygons_meta.append({"id": addition["id"], "start": addition["t"], "shape": shape, "color": Color(color["r"], color["g"], color["b"], color["a"])})

	for i in all_polygons_meta:
		var has_end = false

		for remove in removes:
			if i["id"] == remove["id"]:
				i["end"] = remove["t"]
				has_end = true
				break
		if not has_end:
			i["end"] = end_time
	
	len_all_meta_polygons = len(all_polygons_meta)
	
func update_polygon(time:String):
	var f_time = float(time)

	while all_polygons_meta_pos+1 < len_all_meta_polygons and all_polygons_meta[all_polygons_meta_pos+1]["start"] <= f_time:
		all_polygons_meta_pos += 1

		var this_polygon = all_polygons_meta[all_polygons_meta_pos]
		var arr = [ this_polygon["end"]]
		arr.append(instantiate_polygon(this_polygon["shape"], this_polygon["color"]))
		all_polygons.append(arr)
	
	for i in range(all_polygons.size() - 1, -1, -1):
		var polygon = all_polygons[i]
		if polygon[0] < f_time:
			polygon[1].queue_free()
			all_polygons.remove_at(i)




			
	
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
func update_polygon_backwards(time:String):

	var f_time = float(time)
	for i in range(all_polygons.size() - 1, -1, -1):
		all_polygons[i][1].queue_free()
	all_polygons = []
	
	while all_polygons_meta_pos >= 0  and all_polygons_meta[all_polygons_meta_pos]["start"] >= f_time-look_back:
		all_polygons_meta_pos -= 1


	while  all_polygons_meta_pos +1 < len_all_meta_polygons and all_polygons_meta[all_polygons_meta_pos+1]["start"] <= f_time :
		all_polygons_meta_pos += 1

		if all_polygons_meta[all_polygons_meta_pos]["end"] >= f_time:
			var this_polygon = all_polygons_meta[all_polygons_meta_pos]
			var arr = [this_polygon["end"]]
			arr.append(instantiate_polygon(this_polygon["shape"], this_polygon["color"]))
			all_polygons.append(arr)

	for i in range(all_polygons.size() - 1, -1, -1):
		var polygon = all_polygons[i]
		if polygon[0] < f_time:
			polygon[1].queue_free()
			all_polygons.remove_at(i)
	
