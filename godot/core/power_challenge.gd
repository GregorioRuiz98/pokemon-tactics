extends RefCounted

const Previous = preload("res://core/kanto_challenge.gd")

static func encode(run: Dictionary) -> String:
	if run.get("edition",0)<23: return Previous.encode(run)
	return "KT31:"+Marshalls.utf8_to_base64(JSON.stringify({"edition":23,"seed":run.seed,"starter":int(run.starter),"mapSize":int(run.mapSize)}))

static func decode(code: String) -> Dictionary:
	if not code.begins_with("KT31:"): return Previous.decode(code)
	if code.length()>1024: return {}
	var payload: String = code.trim_prefix("KT31:")
	if payload.length()<8 or payload.length()%4!=0: return {}
	for character: String in payload:
		if character not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=": return {}
	var parser: JSON = JSON.new()
	if parser.parse(Marshalls.base64_to_utf8(payload))!=OK or not parser.data is Dictionary or parser.data.get("edition")!=23: return {}
	var data: Dictionary = parser.data
	data.edition = 22
	var valid: Dictionary = Previous.decode("KT30:"+Marshalls.utf8_to_base64(JSON.stringify(data)))
	if not valid.is_empty(): valid.edition = 23
	return valid
