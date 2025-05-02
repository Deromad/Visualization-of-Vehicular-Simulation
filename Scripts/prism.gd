extends Node3D

var heigth = 0.0
@onready var Error = $"../.."
var Prism = preload("res://Scenes/prism.tscn")

var first = true
var secon = false
@onready var Movie = $"../.."

var all_prisms = {}
var all_prisms_meta = {}

func add_update(data:Dictionary)->void :
	if data["t"] > Globals.max_t:
		var id = data["id"]
		var this_data = all_prisms[id]

		if not this_data.is_empty() and data["t"] - this_data[-1][1] < Globals.look_back:
			this_data.remove_at(this_data.size()-1)

		this_data.append([data["z_to"], data["t"]])

	




func create_prisms(prisms: Array):
	for prism in prisms:
		var id = prism["id"]
		all_prisms_meta[id]  = instantiate_prism(prism)
		
		all_prisms[id] = []
		add_update({"t": 0.0, "id": id, "z_to": prism["z_to"]})

func update_prism(prism:Dictionary):
	var id = prism["id"]
	var ins = all_prisms_meta[id]
	transform(prism["z_to"], ins)
	add_update(prism)


func update_to_time(t:float):
	for key in all_prisms.keys():
		var this_prism = all_prisms[key]
		for i in range(this_prism.size()-1, -1,-1):
			if this_prism[i][1] <= t:
				
				var ins = all_prisms_meta[key]
				transform(this_prism[i][0], ins)
				

	
func instantiate_prism(prism:Dictionary):
		var shapes = prism["shape"]
		var verts3d = PackedVector3Array()
		var verts2d = PackedVector2Array()
		var normals = PackedVector3Array()
		for shape in shapes:
			normals.append(Vector3(0,1,0))
			var vec = Vector3(shape["x"], 1, shape["y"])
			verts3d.append(vec)
			verts2d.append(Vector2(vec.x, vec.z))
		for shape in shapes:
			normals.append(Vector3(1,0,0))
			var vec = Vector3(shape["x"], 0, shape["y"])
			verts3d.append(vec)
		var indices = Geometry2D.triangulate_polygon(verts2d)
		
		var size = shapes.size()
		for i in range(size-1):
			indices.append(i+1)
			indices.append(i)
			indices.append(size+i)
			indices.append(i+1)
			indices.append(size+i)
			indices.append(size+i+1)
		#last site of polygon
		indices.append(0)
		indices.append(size-1)
		indices.append(2*size-1)
		indices.append(0)
		indices.append(2*size-1)
		indices.append(size)
		# Initialize the ArrayMesh.
		var arr_mesh = ArrayMesh.new()
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts3d
		arrays[Mesh.ARRAY_NORMAL] = normals

		arrays[Mesh.ARRAY_INDEX] = indices
		
		# Create the Mesh.
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var m = MeshInstance3D.new()
		m.mesh = arr_mesh
		
		# create Material for each instance, so that they can have different colors
		var new_material = StandardMaterial3D.new()
		var color = prism["color"]
		new_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		new_material.albedo_color =  Color8(color["r"], color["g"], color["b"], color["a"])

		#add surface zo mesh and add roof to scene
		m.set_surface_override_material(0, new_material)
		m.position = Vector3(0,prism["z_from"],0)
		transform(prism["z_to"], m)
		add_child(m)
		return m
	
func transform(to:float, ins)->void:
		var y = ins.global_position.y
		if y-to == 0:
			ins.visible = false
			return
		ins.visible = true
		ins.scale = Vector3(1, to- y,1)
