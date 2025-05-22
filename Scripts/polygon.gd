extends Node3D

# References to other nodes
@onready var vehicles = $"../Vehicles"      # Reference to Vehicles node (unused here, but may be useful)
@onready var Camera = $"../../Camera3D"     # Reference to Camera node (unused here)

@onready var Movie = $"../.."                # Reference to Movie node that provides polygon data

# Dictionaries to manage polygons:
# all_polygons: id -> [position index, start time, end time]
var all_polygons = {}

# Temporary dictionary to track last update times for polygons: id -> last update time
var all_polygons_temp = {}

# Metadata dictionary to store instantiated polygon MeshInstance3D nodes: id -> instance
var all_polygons_meta = {}

# Add a new polygon or update existing polygon with start time and position index
func add_addition(data: Dictionary, pos: int) -> void:
	all_polygons_temp[data["id"]] = data["t"]                # Save last update time
	all_polygons[data["id"]] = [pos, data["t"], Globals.length_of_programm]  # Store lifecycle info

# Mark a polygon for removal based on data dictionary (calls helper function)
func add_removal(data: Dictionary) -> void:
	add_removal_t(data["id"], data["t"])

# Remove polygon if removal time is after look_back threshold; else erase immediately
func add_removal_t(id: String, t: float) -> void:
	if all_polygons_temp.has(id):
		if t - all_polygons_temp[id] < Globals.look_back:
			# Too soon to remove, erase polygon immediately from tracking dictionaries
			all_polygons.erase(id)
			all_polygons_temp.erase(id)
		else:
			# Otherwise, update polygon's end time and remove from temp dict
			all_polygons_temp.erase(id)
			all_polygons[id][1] = t

# Remove all polygon instances and clear metadata (useful for resetting scene)
func clean_all():
	for child in get_children():
		child.queue_free()   # Remove all child nodes (polygons)
	all_polygons_meta.clear()  # Clear metadata dictionary

# Create polygon instance from polygon data dictionary and position index
func create_polygons(polygon: Dictionary, pos: int):
	var color = polygon["color"]              # Extract color dictionary (r,g,b,a)
	var shapes = PackedVector3Array()         # Prepare array for 3D points
	for i in polygon["shape"]:
		# Convert polygon points from dictionary to Vector3 with y and z swapped for coordinate system alignment
		shapes.append(Vector3(i["x"], i["z"], i["y"]))
	
	# Instantiate polygon MeshInstance3D and store in metadata
	all_polygons_meta[polygon["id"]] = instantiate_polygon(shapes, Color(color["r"], color["g"], color["b"], color["a"]))
	
	# Register polygon lifecycle info
	add_addition(polygon, pos)

# At time t, create polygons whose lifespan covers t
func update_to_time(t: float):
	for key in all_polygons.keys():
		var this_key = all_polygons[key]
		# Check if current time is within polygon's active interval
		if this_key[1] <= t and this_key[2] > t:
			var json = Movie.get_line(this_key[0])  # Get polygon data by position index
			create_polygons(json, this_key[0])

# Remove polygon explicitly by polygon data dictionary
func remove_polygon(polygon: Dictionary):
	var id = polygon["id"]
	if all_polygons_meta.has(id):
		var ins = all_polygons_meta[id]
		ins.queue_free()      # Remove polygon MeshInstance3D node from scene tree
		all_polygons_meta.erase(id)
		add_removal(polygon)

# Instantiate a polygon MeshInstance3D from given shape vertices and color
func instantiate_polygon(shape: PackedVector3Array, color: Color):
	var vec2d = PackedVector2Array()    # 2D points for triangulation (projected to XZ plane)
	var normals = PackedVector3Array()  # Normals for each vertex (flat upward)
	
	# Convert 3D shape points to 2D for triangulation and set normals
	for i in shape:
		vec2d.append(Vector2(i.x, i.z))  # Project (x,z) for 2D polygon triangulation
		normals.append(Vector3(0, 1, 0)) # Upward facing normals (flat polygon)
	
	# Use Geometry2D triangulation to generate triangle indices from 2D polygon points
	var indices = Geometry2D.triangulate_polygon(vec2d)
	
	# Initialize an ArrayMesh for the polygon surface
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = shape     # 3D vertices
	arrays[Mesh.ARRAY_NORMAL] = normals   # Normals for lighting
	arrays[Mesh.ARRAY_INDEX] = indices    # Triangle indices
	
	# Create the mesh surface with triangles
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Create a new MeshInstance3D node to hold the mesh
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	
	# Create a material instance so each polygon can have its own color
	var new_material = preload("res://Materials/roof.tres")
	new_material.color = color             # Apply specified color
	
	# Assign the material to the mesh surface
	m.set_surface_override_material(0, new_material)
	
	# Add the MeshInstance3D to the current scene node
	add_child(m)
	
	return m

# Check if a polygon with the given ID currently exists
func is_there(id: String) -> bool:
	return all_polygons_meta.has(id)
