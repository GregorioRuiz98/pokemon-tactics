extends RefCounted

const Previous = preload("res://core/sleep_challenge.gd")

static func encode(run: Dictionary) -> String:
	if run.get("edition",0)<25: return Previous.encode(run)
	return "KT32:"+Marshalls.utf8_to_base64(JSON.stringify({"edition":25,"seed":run.seed,"starter":int(run.starter),"mapSize":int(run.mapSize)}))

static func decode(code: String) -> Dictionary:
	if not code.begins_with("KT32:"): return Previous.decode(code)
	if code.length()>1024: return {}
	var payload: String = code.trim_prefix("KT32:")
	if payload.length()<8 or payload.length()%4!=0: return {}
	for character: String in payload:
		if character not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=": return {}
	var parser: JSON = JSON.new()
	if parser.parse(Marshalls.base64_to_utf8(payload))!=OK or not parser.data is Dictionary or parser.data.get("edition")!=25: return {}
	var data: Dictionary = parser.data
	data.edition = 24
	var validated: Dictionary = Previous.decode("KT31S:"+Marshalls.utf8_to_base64(JSON.stringify(data)))
	if not validated.is_empty(): validated.edition = 25
	return validated
