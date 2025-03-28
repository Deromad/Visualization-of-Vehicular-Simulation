extends Node3D

func _ready() -> void:
	#get yaml file-path from drag and drop
	var file_path = Globals.path
	if not file_path == "":
		read_yaml()

func read_yaml():
	
	#load file-path
	var file_path = Globals.path
	
	#YAML Parser from https://github.com/fimbul-works/godot-yaml
	var data = YAMLLoader.load_file(file_path)
	if YAMLLoader.last_error != null:
		print("Error loading file: ", YAMLLoader.last_error)
	else:
		#load and render all static objects
		var static_obs = $StaticObjects
		static_obs.create_static_objects(data[0]["init"])
		
		#load and render all dynamic objects
		var dynamic_obs = $DynamicObjects
		dynamic_obs.create_dynamic_onjects(data[0]["updates"])
		

	
