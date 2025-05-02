extends Control

@onready var file_loader = $FileLoader  # Referenz auf den Unter-Node
var has_args = false
signal level_changed

func _ready():
	var args = OS.get_cmdline_args()
	if args.size() > 0:
		print(args)
		has_args = true
		on_files_dropped(args[0])
		
	get_viewport().files_dropped.connect(on_files_dropped)

func on_files_dropped(files):
	await get_tree().create_timer(0.0001).timeout

	var mouse_pos = get_global_mouse_position()
	if file_loader.get_global_rect().has_point(mouse_pos)or has_args:
		var valid_files = []
		var temp = PackedStringArray()
		if not files is PackedStringArray:
			temp.append(files)
		else:
			temp = files
		for file in temp:
			if file.ends_with(".json") or file.ends_with(".jsonl"):
				valid_files.append(file)

		if valid_files.size() == 1:
			var yaml_path = valid_files[0]
			change_scene(yaml_path)
		elif valid_files.size() > 1:
			print("Bitte nur eine JSON-Datei auf einmal ziehen!")
		else:
			print("Keine gültige JSON-Datei gefunden!")
	else:
		print("Drop außerhalb von FileLoader!")

func change_scene(file_path):
		Globals.path = file_path
		get_tree().change_scene_to_file("res://Scenes/Movie.tscn")
