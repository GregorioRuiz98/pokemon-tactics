extends "res://core/economy_store.gd"

func load_campaign(rules: RefCounted) -> Dictionary:
	if not FileAccess.file_exists(file_path): return super.load_campaign(rules)
	var file: FileAccess = FileAccess.open(file_path,FileAccess.READ)
	if file==null or file.get_length()>16*1024*1024: return {"ok":false,"reason":"No se puede leer la campaña o supera16 MB. Se conserva el archivo."}
	var text: String = file.get_as_text()
	file.close()
	var envelope: Variant = _decode_json(text)
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("checksum") is String or envelope.payload.sha256_text()!=envelope.checksum: return {"ok":false,"reason":"Campaña incompleta o alterada. Se conserva el archivo."}
	var payload: Variant = _decode_json(envelope.payload)
	if not payload is Dictionary or payload.get("version",0)!=21: return super.load_campaign(rules)
	if payload.get("schema")!="kanto-journey" or not _integer(payload.get("startEdition"),12,21) or not payload.get("seed") is String or payload.seed.length()>64 or not _integer(payload.get("starter"),1,7) or int(payload.starter) not in [1,4,7] or not payload.get("commands") is Array or payload.commands.size()>50000 or not payload.get("state") is Dictionary: return {"ok":false,"reason":"Formato de campaña incompatible. Se conserva el archivo."}
	var edition_rules: RefCounted = _rules(int(payload.startEdition))
	var state: Dictionary = edition_rules.create(payload.seed,int(payload.starter))
	for command: Variant in payload.commands:
		if not command is Dictionary: return {"ok":false,"reason":"Historial no válido. Se conserva el archivo."}
		if command.get("kind")=="upgrade":
			if not _integer(command.get("edition"),int(state.get("edition",1))+1,21): return {"ok":false,"reason":"Transición de edición no válida. Se conserva el archivo."}
			edition_rules = _rules(int(command.edition))
		var step: Dictionary = edition_rules.transact(state,command)
		if not step.ok: return {"ok":false,"reason":"No se puede reconstruir la campaña: "+str(step.get("reason",""))+" Se conserva el archivo."}
		state = step.state
	if state.get("edition")!=21 or not equivalent(state,payload.state): return {"ok":false,"reason":"La campaña no coincide con su historial. Se conserva el archivo."}
	stamp = text.sha256_text()
	return {"ok":true,"state":state,"commands":payload.commands,"rules":edition_rules}

func _rules(edition: int) -> RefCounted:
	return load("res://core/adventure_run.gd").new() if edition==21 else super._rules(edition)
