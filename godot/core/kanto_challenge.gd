extends RefCounted

const Legacy = preload("res://core/journey_challenge.gd")

static func encode(run: Dictionary) -> String:
	if run.get("edition",21)<22: return Legacy.encode(run)
	return "KT30:"+Marshalls.utf8_to_base64(JSON.stringify({"edition":22,"seed":run.seed,"starter":int(run.starter),"mapSize":int(run.mapSize)}))

static func decode(code: String) -> Dictionary:
	if code.begins_with("KT25:"): return Legacy.decode(code)
	if not code.begins_with("KT30:") or code.length()>1024: return {}
	var payload: String = code.trim_prefix("KT30:")
	if payload.length()<8 or payload.length()%4!=0: return {}
	for character: String in payload:
		if character not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=": return {}
	# Reuse the published strict format validator, changing only edition/prefix.
	var old: Dictionary = Legacy.decode("KT25:"+code.trim_prefix("KT30:"))
	if not old.is_empty(): return {}
	var raw: String = Marshalls.base64_to_utf8(code.trim_prefix("KT30:"))
	var parser: JSON = JSON.new()
	if parser.parse(raw)!=OK or not parser.data is Dictionary or parser.data.get("edition")!=22: return {}
	var data: Dictionary = parser.data
	data.edition = 21
	var validated: Dictionary = Legacy.decode("KT25:"+Marshalls.utf8_to_base64(JSON.stringify(data)))
	if not validated.is_empty(): validated.edition = 22
	return validated
