extends Object
class_name GelatoInterpreter

var parser = GelatoParser.new()
var expr = Expression.new()

func is_builtin(identifier: String):
	var err = expr.parse("%s()" % identifier)
	if err != OK:
		var err_txt = expr.get_error_text()
		return true if err_txt.contains("Builtin") else false
	err = expr.execute([], self, false)
	return false if expr.has_execute_failed() else true

var symbol_table = {"+": GelatoLib.sum, "-": GelatoLib.sub,\
					"*": GelatoLib.mul, "/": GelatoLib.div,\
					"**": GelatoLib.pow}

func builtin_applicator(builtin: String):
	return func(args: Array):
		var exec = builtin + "("
		for i in args:
			exec += "%s," %i
		exec.trim_suffix(",")
		exec += ")"
		var err = expr.parse(exec)
		assert(err == OK, expr.get_error_text())
		err = expr.execute([], self)
		assert(not expr.has_execute_failed(), expr.get_error_text())
		return err

func apply(list: Array):
	if len(list) == 0:
		return []
	var contents = list.map(execute)
	if len(list) > 1:
		print(list)
		return contents[0].call(contents.slice(1))
	return contents[0].call([])

func execute(expression: Dictionary):
	assert(expression.has_all(["type", "value"]), "Interpreter node is missing either type or value")
	print(expression)
	match expression["type"]:
		"string", "boolean", "number":
			return expression["value"]
		"list":
			return apply(expression["value"])
		"quote":
			pass
		"identifier":
			if symbol_table.has_all([expression["value"]]):
				return symbol_table[expression["value"]]
			elif is_builtin(expression["gdscript"]):
				return builtin_applicator(expression["gdscript"])
			else:
				assert(false, "Unbound identifier: %s" % expression["value"])
		"dot_identifier":
			pass
		"operation":
			return symbol_table[expression["value"]]

func parse(input: String):
	return execute(parser.parse(input))
