extends Node3D

func read_yaml(file_path):
	var data = YAMLLoader.load_file(file_path)
	if YAMLLoader.last_error != null:
		print("Error loading file: ", YAMLLoader.last_error)
	else:
		print(data[0]["meta"]["title"])
