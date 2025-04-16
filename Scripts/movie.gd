extends Node3D
@onready var ErrorPanel = $UI/Error/ErrorLabel
@onready var Error = $UI/Error
@onready var DynamicObjects = $DynamicObjects

var error_arr = []
var ignore_all = false
signal error_acknowledged

func _ready() -> void:
	#get yaml file-path from drag and drop
	var file_path = Globals.path
	Error.visible = false
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
