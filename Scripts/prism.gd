extends Node3D

var heigth = 0.0  # (Unused variable? Possibly a typo of "height"?)
@onready var Error = $"../.."  # Reference to Error node for logging errors
var Prism = preload("res://Scenes/prism.tscn")  # Preload prism scene (not used here but might be needed)

var first = true  # Flags, possibly for initialization logic (unused in shown code)
var secon = false
@onready var Movie = $"../.."  # Reference to Movie node, used for timeline or data retrieval

var all_prisms = {}       # Stores prism update history per prism ID: array of [z_to, time]
var all_prisms_meta = {}  # Stores actual instantiated prism MeshInstance3D per prism ID

# Adds or updates the height (z_to) of a prism at a specific time
func add_update(data:Dictionary) -> void:
	if data["t"] > Globals.max_t:  # Only update if time exceeds max_t threshold
		var id = data["id"]
		var this_data = all_prisms[id]  # Get history array for this prism

		# If last recorded update is too recent (within look_back), remove it to avoid duplicates
		if not this_data.is_empty() and data["t"] - this_data[-1][1] < Globals.look_back:
			this_data.remove_at(this_data.size() - 1)

		# Append new data as [z_to, time]
		this_data.append([data["z_to"], data["t"]])


# Create prism instances for all given prism dictionaries
func create_prisms(prisms: Array):
	for prism in prisms:
		var id = prism["id"]
		all_prisms_meta[id] = instantiate_prism(prism)  # Create and store the MeshInstance3D
		
		all_prisms[id] = []  # Initialize history list for this prism
		add_update({"t": 0.0, "id": id, "z_to": prism["z_to"]})  # Initialize update history at t=0


# Update a single prism's height and record the update
func update_prism(prism: Dictionary):
	var id = prism["id"]
	var ins = all_prisms_meta[id]  # Get instantiated MeshInstance3D
	transform(prism["z_to"], ins)  # Update prism scale/visibility according to new z_to
	add_update(prism)               # Record this update in history


# Update all prisms to their state at time t by applying the latest update <= t
func update_to_time(t: float):
	for key in all_prisms.keys():
		var this_prism = all_prisms[key]
		# Iterate backwards through update history to find latest update before or at t
		for i in range(this_prism.size() - 1, -1, -1):
			if this_prism[i][1] <= t:
				var ins = all_prisms_meta[key]
				transform(this_prism[i][0], ins)  # Apply height update
				break


# Instantiate a new prism MeshInstance3D based on prism shape data
func instantiate_prism(prism: Dictionary):
	var shapes = prism["shape"]
	
	# Arrays for 3D vertices, 2D vertices, and normals for the prism mesh
	var verts3d = PackedVector3Array()
	var verts2d = PackedVector2Array()
	var normals = PackedVector3Array()
	
	# Create top face vertices and normals
	for shape in shapes:
		normals.append(Vector3(0, 1, 0))  # Upward normal for top face
		var vec = Vector3(shape["x"], 1, shape["y"])
		verts3d.append(vec)
		verts2d.append(Vector2(vec.x, vec.z))
	
	# Create bottom face vertices and normals
	for shape in shapes:
		normals.append(Vector3(1, 0, 0))  # Side normal for sides (approximate)
		var vec = Vector3(shape["x"], 0, shape["y"])
		verts3d.append(vec)
	
	# Triangulate top face polygon using 2D vertices
	var indices = Geometry2D.triangulate_polygon(verts2d)
	
	var size = shapes.size()
	
	# Create triangles for the sides of the prism by connecting top and bottom vertices
	for i in range(size - 1):
		indices.append(i + 1)
		indices.append(i)
		indices.append(size + i)
		indices.append(i + 1)
		indices.append(size + i)
		indices.append(size + i + 1)
	
	# Close the side polygon by connecting last vertices to first ones
	indices.append(0)
	indices.append(size - 1)
	indices.append(2 * size - 1)
	indices.append(0)
	indices.append(2 * size - 1)
	indices.append(size)
	
	# Initialize the ArrayMesh to build the prism geometry
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts3d
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Add the constructed surface to the mesh
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Create a new MeshInstance3D node with this mesh
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	
	# Create a unique material for this prism instance to set its color and transparency
	var new_material = StandardMaterial3D.new()
	var color = prism["color"]
	new_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	new_material.albedo_color = Color8(color["r"], color["g"], color["b"], color["a"])
	
	# Assign the material to the mesh surface
	m.set_surface_override_material(0, new_material)
	
	# Position the prism at the base height (z_from)
	m.position = Vector3(0, prism["z_from"], 0)
	
	# Adjust the prism's height and visibility according to z_to value
	transform(prism["z_to"], m)
	
	# Add the prism to the scene tree as a child of this node
	add_child(m)
	
	return m


# Adjust the prism's scale and visibility based on desired top height (to)
func transform(to: float, ins) -> void:
	var y = ins.global_position.y  # Current bottom position (y)
	
	# If height difference is zero or target height is zero, hide the prism
	if y - to == 0 or to == 0:
		ins.visible = false
	else:
		ins.visible = true
	
	# Scale prism in y axis to stretch from bottom (y) to target height (to)
	ins.scale = Vector3(1, to - y, 1)


# Check if prism with given id exists in all_prisms dictionary
func is_there(id: String) -> bool:
	return all_prisms.has(id)
