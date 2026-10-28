extends "res://core/closing_store.gd"

func _rules(edition: int) -> RefCounted:
	if edition!=30: return super._rules(edition)
	if not rule_cache.has(30): rule_cache[30] = preload("res://core/relief_run.gd").new()
	return rule_cache[30]

func _available_edition(edition: int) -> bool:
	return edition>=12 and edition<=30 and (edition==12 or FileAccess.file_exists("res://data/journey-%d.json"%mini(edition+4,21)))

func _read_payload() -> Dictionary:
	var file: FileAccess = FileAccess.open(file_path,FileAccess.READ)
	if file==null or file.get_length()>16*1024*1024: return {"ok":false,"reason":"No se puede leer la campaña. Se conserva el archivo."}
	var text: String = file.get_as_text(); file.close()
	var envelope: Variant = _decode_json(text)
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("checksum") is String or envelope.payload.sha256_text()!=envelope.checksum: return {"ok":false,"reason":"Campaña incompleta o alterada. Se conserva el archivo."}
	var payload: Variant = _decode_json(envelope.payload)
	if not payload is Dictionary or not _integer(payload.get("version"),1,30): return {"ok":false,"reason":"Esta campaña necesita otra versión. Se conserva el archivo."}
	if payload.get("commands") is Array:
		for command: Variant in payload.commands:
			if not command is Dictionary or not command.get("kind") is String: return {"ok":false,"reason":"Historial no válido. Se conserva el archivo."}
	if payload.version<26: return {"ok":true,"legacy":true}
	if payload.get("schema")!="kanto-journey" or not _integer(payload.get("startEdition"),12,int(payload.version)) or not payload.get("seed") is String or payload.seed.length()>64 or not _integer(payload.get("starter"),1,151) or (int(payload.startEdition)<28 and int(payload.starter) not in [1,4,7]) or (int(payload.startEdition)>=28 and Collection.base_species(int(payload.starter))!=int(payload.starter)) or not payload.get("commands") is Array or payload.commands.size()>50000 or not payload.get("state") is Dictionary: return {"ok":false,"reason":"Formato incompatible. Se conserva el archivo."}
	return {"ok":true,"payload":payload,"text":text,"checksum":envelope.checksum}

func _step(edition_rules: RefCounted, state: Dictionary, command: Variant) -> Dictionary:
	if not command is Dictionary or not command.get("kind") is String: return {"ok":false,"reason":"Historial no válido. Se conserva el archivo."}
	if command.kind=="upgrade":
		if not _integer(command.get("edition"),int(state.edition)+1,30): return {"ok":false,"reason":"Transición no válida. Se conserva el archivo."}
		edition_rules = _rules(int(command.edition))
	if command.kind=="battle" and not command.get("order") is Dictionary: return {"ok":false,"reason":"Orden de combate no válida. Se conserva el archivo."}
	var result: Dictionary = edition_rules.transact(state,command)
	result.rules = edition_rules
	return result
