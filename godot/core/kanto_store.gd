extends "res://core/save_store.gd"

func _init(destination: String = "user://kanto-save.json") -> void:
	super(destination)

func _payload(state: Dictionary, commands: Array, _mode: String) -> Dictionary:
	return {"schema":"kanto", "version":state.get("edition",1), "seed":state.seed, "starter":state.starter, "commands":commands, "state":state}

func load_campaign(_rules: RefCounted) -> Dictionary:
	if not FileAccess.file_exists(file_path): return {"ok":false,"reason":"No hay una campaña guardada."}
	var file: FileAccess = FileAccess.open(file_path,FileAccess.READ)
	if file == null or file.get_length() > 8 * 1024 * 1024: return {"ok":false,"reason":"No se puede leer la campaña. Se conserva el archivo."}
	var text: String = file.get_as_text()
	file.close()
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary: return {"ok":false,"reason":"Campaña no válida. Se conserva el archivo."}
	var envelope: Dictionary = parser.data
	if not envelope.get("payload") is String or not envelope.get("checksum") is String or envelope.payload.sha256_text() != envelope.checksum: return {"ok":false,"reason":"Campaña incompleta o alterada. Se conserva el archivo."}
	if parser.parse(envelope.payload) != OK or not parser.data is Dictionary: return {"ok":false,"reason":"Contenido de campaña no válido."}
	var payload: Dictionary = parser.data
	if payload.get("schema") != "kanto" or (payload.get("version") != 1 and payload.get("version") != 2 and payload.get("version") != 3 and payload.get("version") != 4 and payload.get("version") != 5) or not payload.get("seed") is String or payload.seed.length() > 64 or not (payload.get("starter") is int or payload.get("starter") is float) or payload.starter != int(payload.starter) or int(payload.starter) not in [1,4,7] or not payload.get("commands") is Array or payload.commands.size() > 4000 or not payload.get("state") is Dictionary: return {"ok":false,"reason":"Formato de campaña incompatible. Se conserva el archivo."}
	var edition_rules: RefCounted
	match int(payload.version):
		1: edition_rules = load("res://core/kanto_run.gd").new()
		2: edition_rules = load("res://core/progression_run.gd").new()
		3: edition_rules = load("res://core/shop_run.gd").new()
		4: edition_rules = load("res://core/growth_run.gd").new()
		5: edition_rules = load("res://core/letsgo_run.gd").new()
	var replay: Dictionary = edition_rules.create(payload.seed,int(payload.starter))
	for command: Variant in payload.commands:
		if not command is Dictionary: return {"ok":false,"reason":"Historial de campaña no válido."}
		var step: Dictionary = edition_rules.transact(replay,command)
		if not step.ok: return {"ok":false,"reason":"No se puede reconstruir la campaña. Se conserva el archivo."}
		replay = step.state
	if not equivalent(replay,payload.state): return {"ok":false,"reason":"La campaña no coincide con su historial."}
	stamp = text.sha256_text()
	return {"ok":true,"state":replay,"commands":payload.commands,"rules":edition_rules}
