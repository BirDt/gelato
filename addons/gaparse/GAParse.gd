extends Object
class_name GAParse

# Returns a parser matching only an empty string
static func eof() -> Callable:
	return func(input: String) -> Dictionary:
		if input == "":
			return {success=true, result="", rest=""}
		else:
			return {success=false}

# Returns a parser matching any character, except ""
static func any() -> Callable:
	return func(input: String) -> Dictionary:
		if input == "":
			return {success=false}
		else:
			return {success=true, result=input[0], rest=input.substr(1)}

# Returns a parser matching any character, except "" and the given parser
static func any_except(parser: Callable) -> Callable:
	return func(input: String) -> Dictionary:
		if input == "":
			return {success=false}
			
		var res = parser.call(input)
		if not res["success"]:
			return {success=true, result=input[0], rest=input.substr(1)}
		return {success=false}

# Returns a parser matching a single character
static func char(mchar: String) -> Callable:
	assert(len(mchar) == 1, "char parser must take a string argument of exactly length 1")
	return func(input: String) -> Dictionary:
		if len(input) > 0 && input[0] == mchar:
			return {success=true, result=mchar, rest=input.substr(1)}
		else:
			return {success=false}

# Returns a parser matching any of the chars in the input array
static func chars(mchars: Array[String]) -> Callable:
	var char_matchers: Array[Callable] = []
	for c in mchars:
		char_matchers.push_back(GAParse.char(c))
	return GAParse.either(char_matchers)

# Returns a parser matching a word or substring
static func word(mword: String) -> Callable:
	return func(input: String) -> Dictionary:
		if input.begins_with(mword):
			return {success=true, result=mword, rest=input.substr(len(mword))}
		else:
			return {success=false}

# Returns a parser which returns the result of the first matching parser it takes
# If string `a` is matched by parser `y` and `z`, `any([x, y, z])` will return the result of `y`
static func either(parsers: Array[Callable]) -> Callable:
	return func(input: String) -> Dictionary:
		for p in parsers:
			var res = p.call(input)
			if res["success"]:
				return res
		return {success=false}

# Returns a parser matching a sequence of parsers
static func seq(parsers: Array[Callable]) -> Callable:
	return func(input: String) -> Dictionary:
		var result = ""
		var rest = input
		for p in parsers:
			var res = p.call(rest)
			if res["success"]:
				rest = res["rest"]
				result += res["result"]
			else:
				return {success=false}
		return {success=true, result=result, rest=rest}

# Returns a parser matching (and returning) another parser, before hitting the end of file
static func eof_seq(parser: Callable) -> Callable:
	return func(input: String) -> Dictionary:
		var result = parser.call(input)
		if not result["success"]:
			return {success=false}
		var eof_parser = eof()
		var hit_eof = eof_parser.call(result["rest"])
		if hit_eof["success"]:
			return result
		return {success=false}

# Returns a parser matching it's input parser 1 or * times
static func one_or_many(parser: Callable) -> Callable:
	return func(input: String) -> Dictionary:
		var result = ""
		var rest = input
		var res = parser.call(rest)
		if not res["success"]:
			return {success=false}
		rest = res["rest"]
		result += res["result"]
		for c in rest:
			res = parser.call(rest)
			if res["success"]:
				rest = res["rest"]
				result += res["result"]
			else:
				break
		return {success=true, result=result, rest=rest}

# Returns a parser matching it's input parser 0 or * times
static func many(parser: Callable) -> Callable:
	return func(input: String) -> Dictionary:
		var result = ""
		var rest = input
		for c in rest:
			var res = parser.call(rest)
			if res["success"]:
				rest = res["rest"]
				result += res["result"]
			else:
				break
		return {success=true, result=result, rest=rest}

# Returns a parser matching an input between an open and close parser
# The result of the open and close parsers is ignored, only the result of parser is returned
static func between(open: Callable, parser: Callable, close: Callable) -> Callable:
	return func(input: String) -> Dictionary:
		var open_res = open.call(input)
		if not open_res["success"]:
			return {success=false}
		var res = parser.call(open_res["rest"])
		if not res["success"]:
			return {success=false}
		var close_res = close.call(res["rest"])
		if not close_res["success"]:
			return {success=false}
		return {success=true, result=res["result"], rest=close_res["rest"]}

# Returns a parser matching a parser num times
static func count(num: int, parser: Callable) -> Callable:
	assert(num >= 0, "count parser must take a positive num value")
	var parsers: Array[Callable] = []
	for n in range(num):
		parsers.append(parser)
	return GAParse.seq(parsers)

# Returns a parser which returns a default value when parser does not matched
# No input is consumed when the default is returned
static func option(default: String, parser: Callable) -> Callable:
	return func(input: String) -> Dictionary:
		var res = parser.call(input)
		if not res["success"]:
			return {success=true, result=default, rest=input}
		return res

# Returns a parser which returns success only when parser fails to match
static func not_followed_by(parser: Callable) -> Callable:
	return func(input: String) -> Dictionary:
		var res = parser.call(input)
		if res["success"]:
			return {success=false}
		return {success=true, result="", rest=input}
