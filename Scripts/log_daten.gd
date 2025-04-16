extends Node3D

@onready var textEdit =$"../../UI/LogData"


var all_log_datas_meta = []
var all_log_datas_meta_pos = -1
var len_all_meta_log_datas = 0


func create_log_data(additions):

	for addition in additions:
		var color = addition["color"]
		all_log_datas_meta.append({"t": addition["t"], "message" : addition["message"], "color": Color(color["r"], color["g"], color["b"], color["a"])})

	
	len_all_meta_log_datas = len(all_log_datas_meta)
	
func update_log_data(time:String):
	var f_time = float(time)

	while all_log_datas_meta_pos+1 < len_all_meta_log_datas and all_log_datas_meta[all_log_datas_meta_pos+1]["t"] <= f_time:
		all_log_datas_meta_pos += 1

		var this_data = all_log_datas_meta[all_log_datas_meta_pos]

		textEdit.insert_line_at(all_log_datas_meta_pos, str(this_data["t"]) + ": " +this_data["message"])
	textEdit.scroll_vertical = all_log_datas_meta_pos + 5
	


			

func update_log_data_backwards(time:String):
	var f_time = float(time)
	
	
	while all_log_datas_meta_pos + 1 < len_all_meta_log_datas and all_log_datas_meta[all_log_datas_meta_pos+1]["t"] <= f_time:
		all_log_datas_meta_pos += 1

		var this_data = all_log_datas_meta[all_log_datas_meta_pos]
		textEdit.insert_line_at(all_log_datas_meta_pos, str(this_data["t"]) + ": " +this_data["message"])


	
	while all_log_datas_meta_pos >=  0 and all_log_datas_meta[all_log_datas_meta_pos]["t"] > f_time:
		textEdit.remove_line_at(all_log_datas_meta_pos, false)
		all_log_datas_meta_pos -= 1
	await get_tree().create_timer(0.0001).timeout

	textEdit.scroll_vertical = all_log_datas_meta_pos + 5





	
