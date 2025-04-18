extends Node3D
@onready var ErrorPanel = $UI/Error/ErrorLabel
@onready var Error = $UI/Error
@onready var DynamicObjects = $DynamicObjects
@onready var Road = $StaticObjects/Road
@onready var Vehicle = $DynamicObjects/Vehicles
@onready var Connector = $DynamicObjects/Connector

var length_of_programm = 0.0
var is_update = false
var error_arr = []
var ignore_all = false
signal error_acknowledged

func _ready() -> void:
	#get yaml file-path from drag and drop
	var file_path = Globals.path
	Error.visible = false
	print("1")
	await get_tree().create_timer(0.0001).timeout

	if not file_path == "":
		read_json()
	
func read_json():
	
	#load file-path
	var file_path = Globals.path
	print("2")
	await get_tree().create_timer(0.0001).timeout

	#YAML Parser from https://github.com/fimbul-works/godot-yaml
	if FileAccess.file_exists(file_path):
		print("3")
		await get_tree().create_timer(0.0001).timeout

		var data_file = FileAccess.open(file_path, FileAccess.READ)
		print("4")
		await get_tree().create_timer(0.0001).timeout
		while not data_file.eof_reached():
			var time_until = Time.get_ticks_msec()
			var line = data_file.get_line()
			if line.strip_edges() == "":
				continue
			var json = JSON.parse_string(line)
			if json == null:
				print("Fehler beim Parsen der Zeile: ", line)
			else:
				if not is_update:
					match json["type"]:
						"meta": 
							length_of_programm = json["time"]
							
						"road":
							Road.create_roada(json)
						"update": 
							is_update = true
				else:
					match json["type"]:
						"vehicleAddition":
							Vehicle.create_vehicles(json)
						"vehicleUpdate":
							Vehicle.add_timestemps(json)
						"vehicleRemoval":
							Vehicle.remove_vehic(json)
						"timestepEnd":
							await get_tree().create_timer(0.1).timeout
										
		return
		
	


	else:
		print("File doesn't exist")
		
func append_error(msg: String) -> void:
	error_arr.append(msg)
		
func create_error():
	if error_arr.size() > 0:
		DynamicObjects.is_playing = false
		Error.visible = true
		ErrorPanel.text = "Warning!\n"
		var i = 0
		for msg in error_arr:
			i += 1
			ErrorPanel.append_text( str(i) + ": " + msg + "\n")

# Button callbacks
func _on_ignore_pressed() -> void:
	Error.visible = false
	
	ErrorPanel.text = ""


func _on_close_pressed() -> void:
	ignore_all = true
	get_tree().quit()

func check_color(data:Dictionary)->bool:
	if  data.has("color") and data["color"] is Dictionary:
		var color = data["color"]
		if color.has("r") and color.has("g") and color.has("b") and color.has("a"):
			var r = color["r"]
			var g = color["g"]
			var b = color["b"]
			var a = color["a"]

			if r is float and r < 256 and  r >= 0 and g is float and g < 256 and  g >= 0 and b is float and b < 256 and  b >= 0 and a is float and a < 256 and  a >= 0:
				return true
	return false


func _on_play_pressed() -> void:
	pass # Replace with function body.


func _on_back_pressed() -> void:
	pass # Replace with function body.


func _on_forward_pressed() -> void:
	pass # Replace with function body.


func _on_h_slider_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_speed_value_changed(value: float) -> void:
	pass # Replace with function body.
