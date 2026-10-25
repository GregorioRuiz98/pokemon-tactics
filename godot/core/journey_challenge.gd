extends RefCounted

static func encode(run: Dictionary) -> String:
	return "KT25:"+Marshalls.utf8_to_base64(JSON.stringify({"edition":21,"seed":run.seed,"starter":int(run.starter),"mapSize":int(run.mapSize)}))

static func decode(code: String) -> Dictionary:
	if not code.begins_with("KT25:") or code.length()>1024: return {}
	var payload: String = code.trim_prefix("KT25:")
	if payload.length()<8 or payload.length()%4!=0: return {}
	for character: String in payload:
		if character not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=": return {}
	var parser: JSON = JSON.new()
	if parser.parse(Marshalls.base64_to_utf8(payload))!=OK: return {}
	var data: Variant = parser.data
	if not data is Dictionary or data.get("edition")!=21 or not data.get("seed") is String or data.seed.strip_edges().is_empty() or data.seed.length()>64: return {}
	for key: String in ["starter","mapSize"]:
		if not (data.get(key) is int or data.get(key) is float) or data[key]!=int(data[key]): return {}
	if int(data.starter) not in [1,4,7] or int(data.mapSize) not in [16,24]: return {}
	return data
