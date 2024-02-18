extends Object
class_name GelatoLib

static func sum(args: Array):
	assert(len(args) >= 1, "Sum should have 1 or more arguments")
	var result = args[0]
	for i in args.slice(1):
		result += i
	return result

static func sub(args: Array):
	assert(len(args) >= 1, "Subtract should have 1 or more arguments")
	if len(args) == 1:
		return -args[0]
	var result = args[0]
	for i in args.slice(1):
		result -= i
	return result

static func mul(args: Array):
	assert(len(args) >= 2, "Multiply should have 2 or more arguments")
	var result = args[0] * args[1]
	for i in args.slice(2):
		result *= i
	return result

static func div(args: Array):
	assert(len(args) >= 2, "Divide should have 2 or more arguments")
	var result = args[0] / args[1]
	for i in args.slice(2):
		result /= i
	return result

static func pow(args: Array):
	assert(len(args) >= 2, "Power should have 2 or more arguments")
	var result = args[0] ** args[1]
	for i in args.slice(2):
		result = result ** i
	return result
