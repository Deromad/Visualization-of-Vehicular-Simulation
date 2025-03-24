extends Node3D

func _ready() -> void:
	var file_path = Globals.path
	if not file_path == "":
		
		
		read_yaml()

func read_yaml():
	
	##Lade den File-Path
	var file_path = Globals.path
	
	##YAML Parser von https://github.com/fimbul-works/godot-yaml
	var data = YAMLLoader.load_file(file_path)
	if YAMLLoader.last_error != null:
		print("Error loading file: ", YAMLLoader.last_error)
	else:
		var static_obs = get_node("StaticObjects") 
		static_obs.create_static_objects(data[0]["init"])

	
