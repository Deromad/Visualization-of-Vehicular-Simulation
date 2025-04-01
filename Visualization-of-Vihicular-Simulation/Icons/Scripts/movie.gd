extends Node3D

func _ready() -> void:
	#get yaml file-path from drag and drop
	var file_path = Globals.path
	if not file_path == "":
		read_json()

func read_json():
	
	#load file-path
	var file_path = Globals.path
	
	#YAML Parser from https://github.com/fimbul-works/godot-yaml
	if FileAccess.file_exists(file_path):
		
		var data_file = FileAccess.open(file_path, FileAccess.READ)
		var data = JSON.parse_string(data_file.get_as_text())
		
		if data is Dictionary:
			var static_obs = $StaticObjects
			static_obs.create_static_objects(data["init"])
			
			#load and render all dynamic objects
			var dynamic_obs = $DynamicObjects
			dynamic_obs.create_dynamic_onjects(data["updates"])
		else:
			print("Error parsing")


	else:
		print("File doesn't exist")
		
	
