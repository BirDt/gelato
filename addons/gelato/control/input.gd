@tool
extends LineEdit

@onready var output = $"../output"

func _on_gui_input(event: InputEvent):
	var input_text = text.trim_suffix("\n").trim_prefix("\n")
	if event.is_action_pressed("ui_text_submit") and input_text != "":
		output.publish(input_text)
		text = ""
