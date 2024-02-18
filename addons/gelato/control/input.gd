@tool
extends LineEdit

@onready var output = $"../../output"
var interpreter = GelatoInterpreter.new()

func _on_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_text_submit"):
		var result = interpreter.parse(text)
		output.publish(result)
		text = ""
