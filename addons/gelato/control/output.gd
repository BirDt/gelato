@tool
extends TextEdit

@export var prefix = ">> "

func publish(line:String):
	text += prefix + line + "\n"
	text.trim_prefix("\n")
	scroll_vertical = len(text.split("\n"))
