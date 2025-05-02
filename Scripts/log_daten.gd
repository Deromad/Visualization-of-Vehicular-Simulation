extends Node3D

@onready var textEdit =$"../../UI/LogData"


var all_log_datas_meta = []
var all_log_datas_meta_pos = 0




@onready var Movie = $"../.."

var all_conns = {}
var all_conns_temp = {}
var all_conns_meta = {}



func clean_all():
	textEdit.clear()
	textEdit.clear_undo_history()
	all_log_datas_meta_pos = 0
func create_logs(this_data: Dictionary):
	textEdit.insert_line_at(all_log_datas_meta_pos, str(this_data["t"]) + ": " +this_data["message"])
	all_log_datas_meta_pos += 1
	await get_tree().create_timer(0.00001).timeout

	textEdit.scroll_vertical = all_log_datas_meta_pos + 4


	
	
