@tool
extends TextEdit

@export var prefix = ">> "

func publish(line):
	text += prefix + ("%s" % [line]) + "\n"
	text.trim_prefix("\n")
	scroll_vertical = len(text.split("\n"))

func clear():
	text = ""
