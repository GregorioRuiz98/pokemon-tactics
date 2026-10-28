extends RefCounted

const Previous = preload("res://core/closing_challenge.gd")

static func encode(run: Dictionary) -> String:
	if run.get("edition",0)<30: return Previous.encode(run)
	return "KT40:"+Marshalls.utf8_to_base64(JSON.stringify({"edition":30,"seed":run.seed,"starter":int(run.starter),"mapSize":int(run.mapSize)}))

static func decode(code: String) -> Dictionary:
	if not code.begins_with("KT40:"): return Previous.decode(code)
	if code.length()>1024: return {}
	var payload: String = code.trim_prefix("KT40:")
	if payload.length()<8 or payload.length()%4!=0: return {}
	var body: String = payload.rstrip("=")
	if payload.length()-body.length()>2: return {}
	for character: String in body:
		if character not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/": return {}
	var parser: JSON = JSON.new()
	if parser.parse(Marshalls.base64_to_utf8(payload))!=OK or not parser.data is Dictionary or parser.data.get("edition")!=30: return {}
	var data: Dictionary = parser.data; data.edition = 29
	var checked: Dictionary = Previous.decode("KT36:"+Marshalls.utf8_to_base64(JSON.stringify(data)))
	if not checked.is_empty(): checked.edition = 30
	return checked
