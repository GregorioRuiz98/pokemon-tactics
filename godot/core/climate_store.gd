extends "res://core/sleep_store.gd"

func _rules(edition: int) -> RefCounted:
	return preload("res://core/climate_run.gd").new() if edition==25 else super._rules(edition)

func load_campaign(rules: RefCounted) -> Dictionary:
	if not FileAccess.file_exists(file_path): return super.load_campaign(rules)
	var file: FileAccess = FileAccess.open(file_path,FileAccess.READ)
	if file==null or file.get_length()>16*1024*1024: return {"ok":false,"reason":"No se puede leer la campaña. Se conserva el archivo."}
	var text: String = file.get_as_text(); file.close()
	var envelope: Variant = _decode_json(text)
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("checksum") is String or envelope.payload.sha256_text()!=envelope.checksum: return {"ok":false,"reason":"Campaña incompleta o alterada. Se conserva el archivo."}
	var payload: Variant = _decode_json(envelope.payload)
	if payload is Dictionary and (payload.get("version") is int or payload.get("version") is float) and payload.version>25: return {"ok":false,"reason":"Esta campaña necesita una versión posterior. Se conserva el archivo."}
	if not payload is Dictionary or payload.get("version")!=25: return super.load_campaign(rules)
	if payload.get("schema")!="kanto-journey" or not _integer(payload.get("startEdition"),12,25) or not payload.get("seed") is String or payload.seed.length()>64 or not _integer(payload.get("starter"),1,7) or int(payload.starter) not in [1,4,7] or not payload.get("commands") is Array or payload.commands.size()>50000 or not payload.get("state") is Dictionary: return {"ok":false,"reason":"Formato incompatible. Se conserva el archivo."}
	var edition_rules: RefCounted = _rules(int(payload.startEdition))
	var state: Dictionary = edition_rules.create(payload.seed,int(payload.starter))
	for command: Variant in payload.commands:
		if not command is Dictionary: return {"ok":false,"reason":"Historial no válido. Se conserva el archivo."}
		if command.get("kind")=="upgrade":
			if not _integer(command.get("edition"),int(state.edition)+1,25): return {"ok":false,"reason":"Transición no válida. Se conserva el archivo."}
			edition_rules = _rules(int(command.edition))
		var step: Dictionary = edition_rules.transact(state,command)
		if not step.ok: return {"ok":false,"reason":"No se puede reconstruir la campaña: "+step.get("reason","")}
		state = step.state
	if state.edition!=25 or not equivalent(state,payload.state): return {"ok":false,"reason":"La campaña no coincide con su historial. Se conserva el archivo."}
	stamp = text.sha256_text()
	campaign_id = "legacy-"+envelope.checksum.substr(0,32); trainer_id = ""; profile_events = []; tracker = {"known":false,"kos":0}
	var meta: Variant = payload.get("trainer",{})
	if valid_meta(meta,int(state.revision)):
		campaign_id = meta.campaignId; trainer_id = meta.profileId; profile_events = meta.events.duplicate(true); tracker = meta.tracker.duplicate(true)
	return {"ok":true,"state":state,"commands":payload.commands,"rules":edition_rules}
