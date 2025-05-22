extends Node3D

@onready var textEdit = $"../../UI/LogData"  # Reference to the UI text editor for displaying logs

var all_log_datas_meta_pos = 0   # Tracks current line position for inserting new log entries

@onready var Movie = $"../.."     # Reference to parent Movie node (not used here but likely needed elsewhere)



# Clears all logs and resets the log position counter and undo history
func clean_all():
	textEdit.clear()               # Clear all text in the log UI
	textEdit.clear_undo_history() # Clear undo history to prevent undoing cleared logs
	all_log_datas_meta_pos = 0     # Reset the log insertion position to top

# Insert a new log entry with timestamp and message, then scrolls to the latest entry
func create_logs(this_data: Dictionary):
	# Insert a new line at current position with time and message formatted as "time: message"
	textEdit.insert_line_at(all_log_datas_meta_pos, str(this_data["t"]) + ": " + this_data["message"])
	all_log_datas_meta_pos += 1   # Increment position to insert next log line
	
	# Yield briefly to allow UI update/rendering
	await get_tree().create_timer(0.00001).timeout

	# Automatically scroll vertical scrollbar so latest log is visible (slightly past last line)
	textEdit.scroll_vertical = all_log_datas_meta_pos + 4
