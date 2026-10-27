extends "res://core/tactics_quality_store.gd"

const Collection = preload("res://core/collection_catalog.gd")

func _rules(edition: int) -> RefCounted:
	if edition!=28: return super._rules(edition)
	if not rule_cache.has(28): rule_cache[28] = preload("res://core/collection_run.gd").new()
	return rule_cache[28]

func _read_payload() -> Dictionary:
	var file: FileAccess = FileAccess.open(file_path,FileAccess.READ)
	if file==null or file.get_length()>16*1024*1024: return {"ok":false,"reason":"No se puede leer la campaña. Se conserva el archivo."}
	var text: String = file.get_as_text(); file.close()
	var envelope: Variant = _decode_json(text)
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("checksum") is String or envelope.payload.sha256_text()!=envelope.checksum: return {"ok":false,"reason":"Campaña incompleta o alterada. Se conserva el archivo."}
	var payload: Variant = _decode_json(envelope.payload)
	if not payload is Dictionary: return {"ok":false,"reason":"Contenido no válido. Se conserva el archivo."}
	if not _integer(payload.get("version"),1,28): return {"ok":false,"reason":"Esta campaña necesita otra versión. Se conserva el archivo."}
	if payload.version<26: return {"ok":true,"legacy":true}
	if payload.get("schema")!="kanto-journey" or not _integer(payload.get("startEdition"),12,int(payload.version)) or not payload.get("seed") is String or payload.seed.length()>64 or not _integer(payload.get("starter"),1,151) or (int(payload.startEdition)<28 and int(payload.starter) not in [1,4,7]) or (int(payload.startEdition)==28 and Collection.base_species(int(payload.starter))!=int(payload.starter)) or not payload.get("commands") is Array or payload.commands.size()>50000 or not payload.get("state") is Dictionary: return {"ok":false,"reason":"Formato incompatible. Se conserva el archivo."}
	return {"ok":true,"payload":payload,"text":text,"checksum":envelope.checksum}

func _step(edition_rules: RefCounted, state: Dictionary, command: Variant) -> Dictionary:
	if not command is Dictionary: return {"ok":false,"reason":"Historial no válido. Se conserva el archivo."}
	if command.get("kind")=="upgrade":
		if not _integer(command.get("edition"),int(state.edition)+1,28): return {"ok":false,"reason":"Transición no válida. Se conserva el archivo."}
		edition_rules = _rules(int(command.edition))
	var result: Dictionary = edition_rules.transact(state,command)
	result.rules = edition_rules
	return result

func record(rules: RefCounted, before: Dictionary, after: Dictionary, command: Dictionary, presentation: Dictionary, definition: Dictionary, location: Dictionary = {}) -> void:
	super.record(rules,before,after,command,presentation,definition,location)
	var seen: Array = []
	if command.kind=="enter":
		for unit: Dictionary in after.get("battle",{}).get("units",[]):
			if int(unit.speciesId) not in seen: seen.append(int(unit.speciesId))
	var obtained: Array = []
	if command.kind=="adopt":
		var previous: Array = (before.party+before.reserve).map(func(member):return int(member.id))
		for member: Dictionary in after.party+after.reserve:
			if int(member.id) not in previous: obtained.append(int(member.speciesId))
	if seen.is_empty() and obtained.is_empty(): return
	if profile_events.is_empty() or profile_events[-1].revision!=after.revision: profile_events.append({"revision":int(after.revision),"flags":[],"species":[]})
	var event: Dictionary = profile_events[-1]
	if not seen.is_empty(): event.seen = seen
	for species: int in obtained:
		if species not in event.species: event.species.append(species)
