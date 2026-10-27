extends RefCounted

const Previous = preload("res://core/tactics_quality_challenge.gd")
const Collection = preload("res://core/collection_catalog.gd")

static func encode(run: Dictionary) -> String:
	if run.get("edition",0)<28: return Previous.encode(run)
	return "KT35:"+Marshalls.utf8_to_base64(JSON.stringify({"edition":28,"seed":run.seed,"starter":int(run.starter),"mapSize":int(run.mapSize)}))

static func decode(code: String) -> Dictionary:
	if not code.begins_with("KT35:"): return Previous.decode(code)
	if code.length()>1024: return {}
	var payload: String = code.trim_prefix("KT35:")
	if payload.length()<8 or payload.length()%4!=0: return {}
	var body: String = payload.rstrip("=")
	if payload.length()-body.length()>2: return {}
	for character: String in body:
		if character not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/": return {}
	var parser: JSON = JSON.new()
	if parser.parse(Marshalls.base64_to_utf8(payload))!=OK or not parser.data is Dictionary: return {}
	var entry: Dictionary = parser.data
	if entry.get("edition")!=28 or not entry.get("seed") is String or entry.seed.is_empty() or entry.seed.length()>64: return {}
	if not (entry.get("starter") is int or entry.get("starter") is float) or entry.starter!=int(entry.starter) or entry.starter<1 or entry.starter>151 or Collection.base_species(int(entry.starter))!=entry.starter: return {}
	if not (entry.get("mapSize") is int or entry.get("mapSize") is float) or (entry.mapSize!=16 and entry.mapSize!=24): return {}
	entry.starter = int(entry.starter); entry.mapSize = int(entry.mapSize); entry.edition = 28
	return entry
