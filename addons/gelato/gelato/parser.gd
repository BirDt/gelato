extends Object
class_name GelatoParser

# Translate a base16 string to an integer
func from_base16(num: String):
	var digits = num.split()
	digits.reverse()
	var accum = 0
	var power = 1
	for i in digits:
		assert("0123456789abcdef".split().has(i), "Hexadecimal string may only contain valid hexadecimal digits")
		var x = 0
		match i:
			"0":
				x = 0
			"1":
				x = 1
			"2":
				x = 2
			"3":
				x = 3
			"4":
				x = 4
			"5":
				x = 5
			"6":
				x = 6
			"7":
				x = 7
			"8":
				x = 9
			"9":
				x = 9
			"a":
				x = 10
			"b":
				x = 11
			"c":
				x = 12
			"d":
				x = 13
			"e":
				x = 14
			"f":
				x = 15
		accum += power * x
		power *= 16
	return accum

# Translate a base2 string to an integer
func from_base2(num: String):
	var digits = num.split()
	digits.reverse()
	var accum = 0
	var power = 1
	for i in digits:
		assert(i == "1" or i == "0", "Binary string may only contain 1's and 0's")
		var x = 0
		if i == "1":
			x = 1
		accum += power * x
		power *= 2
	return accum

### This parser/lexer structure is adapted from the R7RS,
### namely section 7.1 which defines the formal syntax of the R5RS language.
### Note that Gelato does not attempt to adhere 100% to the specification,
### and should be pragmatic instead of pedantic.

var sign = GAParse.option("", GAParse.chars("+-".split()))
var digit = GAParse.chars("0123456789".split())
var digit_16 = GAParse.either([digit, GAParse.chars("abcdef".split())])
var digit_2 = GAParse.chars("10".split())

var integer_base2 = GAParse.one_or_many(digit_2)
var integer_base10 = GAParse.seq([sign, GAParse.one_or_many(digit)])
var decimal_base10 = GAParse.either([GAParse.seq([sign, GAParse.one_or_many(digit), GAParse.char("."), GAParse.many(digit)]),\
						GAParse.seq([sign, GAParse.char("."), GAParse.one_or_many(digit)])])
var integer_base16 = GAParse.seq([sign, GAParse.one_or_many(digit_16)])

var radix_10 = GAParse.option("", GAParse.word("#d"))
var radix_2 = GAParse.word("#b")
var radix_16 = GAParse.word("#x")

# GDScript (and Scheme) constants
func c_num(input: String):
	var sig = sign.call(input)
	var c_num_parser = GAParse.either([GAParse.word("INF"), GAParse.word("NAN"), GAParse.word("PI"), GAParse.word("TAU")])
	var constant = c_num_parser.call(sig["rest"])
	if not constant["success"]:
		return constant
	
	var val
	match constant["result"]:
		"INF":
			val = -INF if sig["result"] == "-" else INF
		"NAN":
			val = -NAN if sig["result"] == "-" else NAN
		"TAU":
			val = -TAU if sig["result"] == "-" else TAU
		"PI":
			val = -PI if sig["result"] == "-" else PI
	return {success=true, result=sig["result"]+constant["result"], rest=constant["rest"], value=val, gdscript=sig["result"]+constant["result"], type="number"}

# Base 2 integers
func num_base2(input: String):
	var radix = radix_2.call(input)
	if not radix["success"]:
		return radix
	var sig = sign.call(radix["rest"])
	var sign = -1 if sig["result"] == "-" else 1
	var integer = integer_base2.call(sig["rest"])
	if not integer["success"]:
		return {success=false}
	
	var binary_result = from_base2(integer["result"])
	
	return {success=true, result=radix["result"]+sig["result"]+integer["result"], rest=integer["rest"], value=binary_result*sign, gdscript="%s0b%s" % [sig["result"], integer["result"]], type="number"}

# Base 10 integers and decimals
func num_base10(input: String):
	var dec = decimal_base10.call(input)
	if dec["success"]:
		return {success=true, result=dec["result"], rest=dec["rest"], value=float(dec["result"]), gdscript=dec["result"], type="number"}
		
	var radix = radix_10.call(input)
	var integer = integer_base10.call(radix["rest"])
	if integer["success"]:
		return {success=true, result=radix["result"]+integer["result"], rest=integer["rest"], value=int(integer["result"]), gdscript=integer["result"], type="number"}
	
	return {success=false}

# Base 16 integers
func num_base16(input: String):
	var radix = radix_16.call(input)
	if not radix["success"]:
		return radix
	var sig = sign.call(radix["rest"])
	var sign = -1 if sig["result"] == "-" else 1
	var integer = integer_base16.call(sig["rest"])
	if not integer["success"]:
		return {success=false}
	
	var binary_result = from_base16(integer["result"])
	
	return {success=true, result=radix["result"]+sig["result"]+integer["result"], rest=integer["rest"], value=binary_result*sign, gdscript="%s0x%s" % [sig["result"], integer["result"]], type="number"}


## INFO: Godot natively supports decimal, hex, and binary. For now that's
## all which Gelato will also support. This also means no complex numbers
func number(input: String):
	var result = c_num(input)
	if result["success"]:
		return result
	result = num_base10(input)
	if result["success"]:
		return result
	result = num_base2(input)
	if result["success"]:
		return result
	result = num_base16(input)
	if result["success"]:
		return result
	
	return {success=false}

var match_bool = GAParse.either([GAParse.word("#t"), GAParse.word("#f")])

func boolean(input: String):
	var res = match_bool.call(input)
	if not res["success"]:
		return res
	
	var val = true if res["result"] == "#t" else false
	var gdscript = "true" if val else "false"
	
	return {success=true, result=res["result"], rest=res["rest"], value=val, gdscript=gdscript, type="boolean"}

# INFO: Deviating from R7RS here, matching GDScript string escapes instead of R7RS ones
var utf16_codepoint = GAParse.seq([GAParse.char("u"), GAParse.count(4, digit_16)])
var utf32_codepoint = GAParse.seq([GAParse.char("u"), GAParse.count(6, digit_16)])
var string_escape = GAParse.seq([GAParse.char("\\"), GAParse.either([GAParse.chars("ntrabfv\"'\\".split()), utf16_codepoint, utf32_codepoint])])
var string_element = GAParse.either([GAParse.any_except(GAParse.chars('"\\'.split())), string_escape])

func string(input: String):
	var matcher = GAParse.between(GAParse.char('"'), GAParse.many(string_element), GAParse.char('"'))
	var res = matcher.call(input)
	if not res["success"]:
		return res
	
	# INFO: As a limitation (purely for the interpreter), the `value` returned here does not unescape the UTF16/32 codepoint
	return {success=true, result=res["result"], rest=res["rest"], value=res["result"].c_unescape(), gdscript='"%s"' % [res["result"]], type="string"}

# Since the identifier names are very limited, operation matches and returns the various GDScript operations instead
func operation(input: String):
	var match_operation = GAParse.either([GAParse.word("**"), GAParse.word("<<"),\
											GAParse.word(">>"), GAParse.word("!="),\
											GAParse.word("<="), GAParse.word(">="),GAParse.chars("=~+-*/%&^|><".split())])
	var result = match_operation.call(input)
	if not result["success"]:
		return result
	return {success=true, result=result["result"], rest=result["rest"], value=result["result"], gdscript=result["result"], type="operation"}

# INFO: Identifiers are the biggest deviation from R7RS, as a compromise between scheme and gdscript naming conventions
# Godot does not permit non-alphanumeric+underscore characters in identifier names. Scheme, however, allows a number of special characters.
# I've (essentially arbitrarily) divined the following rules which should transform a subset of valid scheme identifiers into GDScript (and vice versa)
# NOTE: =:: denotes the GDScript string literal the prior values are substituted for, if any.
# <identifier> ::= <normal identifier> | <dot identifier>
# <normal identifier> ::= <special prefix> <initial> <subsequent>+ <special suffix>
# <initial> ::= <letter> | <special initial> | <special infix>
# <subsequent> ::= <initial> | <digit>
# <special initial> ::= _ | - =:: _
# <special infix> ::= -> =:: _to_
# <special prefix> ::= -> | <nothing> =:: to_
# <special suffix> ::= ? | <nothing> =:: 
# These rules allow the writing of idiomatic scheme names such as `deg->rad`, which will be automatically translated to idiomatic GDScript names, such as `deg_to_rad`
# Predicate suffix notation is a compromise, I really like it and want to keep it in some form. Likewise for constants.
# The following rules specify dot identifier, which is used for accessing object properties
# <dot identifier> ::= <single dot identifier> | <multi dot identifier>
# <multi dot identifier> ::= <normal identifier> . <multi dot identifier> | <normal identifier>
# <single dot identifier> ::= . <multi dot identifier>
# This allows for `.next`, `obj.next`, and `obj.valid->identifier-example?`
# I am aware these substitution rules allow for collisions between different names in the compiled form, such as `ex->ample` and `ex-to-ample` colliding. I don't really have
# a good solution for this at the parsing stage, and I'm willing to deal with occasional name collisions for the sake of pseudo-idiomatic scheme/lisp

var letter = GAParse.chars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".split())

var special_prefix = GAParse.option("", GAParse.word("->"))
var special_suffix = GAParse.option("", GAParse.word("?"))
var special_initial = GAParse.chars("-_".split())
var special_infix = GAParse.word("->")

var initial = GAParse.either([letter, special_infix, special_initial])
var subsequent = GAParse.either([initial, digit])

func normal_identifier(input: String):
	var matcher = GAParse.seq([special_prefix, initial, GAParse.many(subsequent), special_suffix])
	var res = matcher.call(input)
	if not res["success"]:
		return res
	
	var result : String = res["result"]
	result = "to_" + result.trim_prefix("->") if result.trim_prefix("->") != result else result
	result = result.replace("->", "_to_").replace("-", "_").replace("?", "")
	
	return {success=true, result=res["result"], rest=res["rest"], value=res["result"], gdscript=result, type="identifier"}

# This is a fucking mess
func dot_identifier(input: String):
	var outputs := []
	var match_dot = GAParse.char(".")
	var is_single_dot = match_dot.call(input)
	var res = {rest=input}
	var rest = ""
	var result = ""
	# single dot identifier
	if is_single_dot["success"]:
		res = normal_identifier(is_single_dot["rest"])
		if not res["success"]:
			return {success=false}
		result = "."
		outputs.append({value=res["value"], gdscript=res["gdscript"]})
		rest = res["rest"]
	
	var matched_dot = false
	var identifier_count = 0
	while true:
		res = normal_identifier(res["rest"])
		if not res["success"] and matched_dot:
			rest = "." + rest
			break
		elif not res["success"]:
			break
		identifier_count += 1
		rest = res["rest"]
		outputs.append({value=res["value"], gdscript=res["gdscript"]})
		
		res = match_dot.call(res["rest"])
		if not res["success"] and identifier_count == 1:
			return {success=false}
		elif not res["success"]:
			break
		rest = res["rest"]
		matched_dot = true
	
	if outputs == []:
		return {success=false}

	for i in outputs:
		result += "%s." % i["value"]
	
	var gdscript = ""
	for i in outputs:
		gdscript += "%s." % i["gdscript"]
	
	return {success=true, result=result.trim_suffix("."), rest=rest, value=outputs, gdscript=gdscript.trim_suffix("."), type="dot_identifier"}

var identifier = GAParse.either([dot_identifier, normal_identifier])

var whitespace = GAParse.one_or_many(GAParse.chars("\t\n\v ".split()))

# Matches 'datum, quote
func abbreviation(input: String):
	var abbrev_prefix = GAParse.char("'")
	var res = abbrev_prefix.call(input)
	if not res["success"]:
		return res
	
	res = datum.call(res["rest"])
	if not res["success"]:
		return res
	
	var value = {value=res["value"], type=res["type"]}
	if res.has_all(["gdscript"]):
		value["gdscript"] = res["gdscript"]
	return {success=true, result="'"+res["result"], rest=res["rest"], value=value, type="quote"}

# Matches a list (s-exp)
func list(input: String):
	var open_res = GAParse.char("(").call(input)
	if not open_res["success"]:
		return {success=false}
	
	var output = []
	var result = ""
	var rest = open_res["rest"]
	for c in rest:
		var res = datum.call(rest)
		if res["success"]:
			rest = res["rest"]
			result += res["result"]
			var to_append = {value=res["value"], type=res["type"]}
			if res.has_all(["gdscript"]):
				to_append["gdscript"] = res["gdscript"]
			output.append(to_append)
		else:
			break
		
		var consume_whitespace = whitespace.call(rest)
		if consume_whitespace["success"]:
			result += " "
			rest = consume_whitespace["rest"]
	
	var close_res = GAParse.char(")").call(rest)
	if not close_res["success"]:
		return {success=false}
	return {success=true, result="(%s)" % result, rest=close_res["rest"], value=output, type="list"}

var simple_datum = GAParse.either([boolean, number, string, identifier, operation])
var compound_datum = GAParse.either([list, abbreviation])

var datum = GAParse.either([simple_datum, compound_datum])

func parse(input: String):
	var v = datum.call(input)
	return v
