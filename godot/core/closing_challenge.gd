extends RefCounted

const Previous = preload("res://core/collection_challenge.gd")

static func encode(run: Dictionary) -> String:
	if run.get("edition",0)<29: return Previous.encode(run)
	return "KT36:"+Marshalls.utf8_to_base64(JSON.stringify({"edition":29,"seed":run.seed,"starter":int(run.starter),"mapSize":int(run.mapSize)}))

static func decode(code: String) -> Dictionary:
	if not code.begins_with("KT36:"): return Previous.decode(code)
	if code.length()>1024: return {}
	var payload: String = code.trim_prefix("KT36:")
	if payload.length()<8 or payload.length()%4!=0: return {}
	var body: String = payload.rstrip("=")
	if payload.length()-body.length()>2: return {}
	for character: String in body:
		if character not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/": return {}
	var parser: JSON = JSON.new()
	if parser.parse(Marshalls.base64_to_utf8(payload))!=OK or not parser.data is Dictionary or parser.data.get("edition")!=29: return {}
	var data: Dictionary = parser.data; data.edition = 28
	var validated: Dictionary = Previous.decode("KT35:"+Marshalls.utf8_to_base64(JSON.stringify(data)))
	if not validated.is_empty(): validated.edition = 29
	return validated
