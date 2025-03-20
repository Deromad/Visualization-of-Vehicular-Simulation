extends Control

@onready var file_loader = $FileLoader  # Referenz auf den Unter-Node

func _ready():
	get_viewport().files_dropped.connect(on_files_dropped)

func on_files_dropped(files):
	var mouse_pos = get_global_mouse_position()
	if file_loader.get_global_rect().has_point(mouse_pos):
		var valid_files = []

		for file in files:
			if file.ends_with(".yaml") or file.ends_with(".yml"):
				valid_files.append(file)

		if valid_files.size() == 1:
			var yaml_path = valid_files[0]
			change_scene(yaml_path)
		elif valid_files.size() > 1:
			print("Bitte nur eine YAML-Datei auf einmal ziehen!")
		else:
			print("Keine gültige YAML-Datei gefunden!")
	else:
		print("Drop außerhalb von FileLoader!")

func change_scene(file_path):
	get_tree().change_scene_to_file("res://Scenes/Movie.tscn")
