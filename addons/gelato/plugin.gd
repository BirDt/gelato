@tool
extends EditorPlugin

var repl = preload("res://addons/gelato/control/repl.tscn").instantiate()

func _enter_tree():
	add_control_to_bottom_panel(repl, "Gelato")


func _exit_tree():
	remove_control_from_bottom_panel(repl)
