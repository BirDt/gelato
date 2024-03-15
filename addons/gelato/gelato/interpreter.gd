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
		var arg = 1
		var args_str = []
		for i in args:
			exec += "%s," % ("arg%s" %arg)
			args_str.append("arg%s" %arg)
			arg += 1
		exec = exec.trim_suffix(",")
		exec += ")"
		var bindings = []
		bindings.append_array(args_str)
		var err = expr.parse(exec, bindings)
		assert(err == OK, expr.get_error_text())
		var exec_bindings = []
		exec_bindings.append_array(args)
		err = expr.execute(exec_bindings, self)
		assert(not expr.has_execute_failed(), expr.get_error_text())
		return err

func func_applicator(function: String, initial):
	return func(args: Array):
		var exec = function + "("
		var arg = 1
		var args_str = []
		for i in args:
			exec += "%s," % ("arg%s" %arg)
			args_str.append("arg%s" %arg)
			arg += 1
		exec = exec.trim_suffix(",")
		exec += ")"
		var bindings = ["initial"]
		bindings.append_array(args_str)
		var err = expr.parse(exec, bindings)
		assert(err == OK, expr.get_error_text())
		var exec_bindings = [initial]
		exec_bindings.append_array(args)
		err = expr.execute(exec_bindings, self)
		assert(not expr.has_execute_failed(), expr.get_error_text())
		return err

func eval(input):
	var script = GDScript.new()
	script.set_source_code("@tool\nfunc eval():\n\treturn " + input)
	script.reload()
	var ref = RefCounted.new()
	ref.set_script(script)
	return ref.call("eval")

func eval_applicator(function: String):
	return func(args: Array):
		var sc = "@tool\n"
		var arg = 1
		var args_str = []
		for i in args:
			sc += "var %s = %s\n" % [("arg%s" %arg), i if not i is String else '"%s"' % (i as String).c_escape()]
			arg += 1
		sc += "func eval():\n\treturn " + function + "("
		arg = 1
		for i in args:
			sc += "%s," % ("arg%s" %arg)
			arg += 1
		sc = sc.trim_suffix(",")
		sc += ")"
		var script = GDScript.new()
		script.set_source_code(sc)
		script.reload()
		var ref = RefCounted.new()
		ref.set_script(script)
		return ref.call("eval")

func recursive_resolve(initial, continuations: Array, callable):
	var exec = "initial"
	for i in continuations:
		exec += ".%s" % i.value
	if not callable:
		var err = expr.parse(exec, ["initial"])
		assert(err == OK, expr.get_error_text())
		err = expr.execute([initial], self)
		assert(not expr.has_execute_failed(), expr.get_error_text())
		return err
	else:
		return func_applicator(exec, initial)

func dot_identifier(components: Array, callable):
	if symbol_table.has_all([components[0]["value"]]):
		return recursive_resolve(symbol_table[components[0]["value"]], components.slice(1), callable)
	else:
		var exec = components[0].value
		for i in components.slice(1):
			exec += ".%s" % i.value
		if not callable:
			return eval(exec)
		else:
			return eval_applicator(exec)

func apply(list: Array):
	if len(list) == 0:
		return []
	var contents = [execute(list[0], true)]
	contents.append_array(list.slice(1).map(execute))
	if len(list) > 1:
		return contents[0].call(contents.slice(1))
	return contents[0].call([])

func execute(expression: Dictionary, callable: bool=false):
	assert(expression.has_all(["type", "value"]), "Interpreter node is missing either type or value")
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
			return dot_identifier(expression["value"], callable)
		"operation":
			return symbol_table[expression["value"]]

func parse(input: String):
	return execute(parser.parse(input))
