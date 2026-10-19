extends "res://core/kanto_store.gd"

const Journey = preload("res://core/journey_run.gd")

func _payload(state: Dictionary, commands: Array, mode: String) -> Dictionary:
	if state.get("edition",1)<13: return super._payload(state,commands,mode)
	return {"schema":"kanto-journey","version":state.edition,"startEdition":state.startEdition,"seed":state.seed,"starter":state.starter,"commands":commands,"state":state}

func load_campaign(rules: RefCounted) -> Dictionary:
	if not FileAccess.file_exists(file_path): return super.load_campaign(rules)
	var file: FileAccess = FileAccess.open(file_path,FileAccess.READ)
	if file==null or file.get_length()>16*1024*1024: return {"ok":false,"reason":"No se puede leer la campaña o supera16 MB. Se conserva el archivo."}
	var text: String = file.get_as_text()
	file.close()
	var envelope: Variant = _decode_json(text)
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("checksum") is String or envelope.payload.sha256_text()!=envelope.checksum: return {"ok":false,"reason":"Campaña incompleta o alterada. Se conserva el archivo."}
	var payload: Variant = _decode_json(envelope.payload)
	if not payload is Dictionary: return {"ok":false,"reason":"Contenido no válido. Se conserva el archivo."}
	if payload.get("schema")!="kanto-journey": return super.load_campaign(rules)
	if not _integer(payload.get("version"),13,18) or not _integer(payload.get("startEdition"),12,int(payload.version)) or not payload.get("seed") is String or payload.seed.length()>64 or not _integer(payload.get("starter"),1,7) or int(payload.starter) not in [1,4,7] or not payload.get("commands") is Array or payload.commands.size()>50000 or not payload.get("state") is Dictionary: return {"ok":false,"reason":"Formato de campaña incompatible. Se conserva el archivo."}
	if not _available_edition(int(payload.version)) or not _available_edition(int(payload.startEdition)): return {"ok":false,"reason":"Esta campaña requiere contenido de una versión posterior. Se conserva el archivo."}
	var edition_rules: RefCounted = load("res://core/roster_run.gd").new() if payload.startEdition==12 else Journey.new(int(payload.startEdition)+4)
	var state: Dictionary = edition_rules.create(payload.seed,int(payload.starter))
	for command: Variant in payload.commands:
		if not command is Dictionary: return {"ok":false,"reason":"Historial no válido. Se conserva el archivo."}
		if command.get("kind")=="upgrade":
			if not _integer(command.get("edition"),int(state.get("edition",1))+1,int(payload.version)): return {"ok":false,"reason":"Transición de edición no válida. Se conserva el archivo."}
			if not _available_edition(int(command.edition)): return {"ok":false,"reason":"Falta el contenido de esa edición. Se conserva el archivo."}
			edition_rules = Journey.new(int(command.edition)+4)
		var step: Dictionary = edition_rules.transact(state,command)
		if not step.ok: return {"ok":false,"reason":"No se puede reconstruir la campaña: "+str(step.get("reason",""))+" Se conserva el archivo."}
		state = step.state
	if state.get("edition")!=payload.version or not equivalent(state,payload.state): return {"ok":false,"reason":"La campaña no coincide con su historial. Se conserva el archivo."}
	stamp = text.sha256_text()
	return {"ok":true,"state":state,"commands":payload.commands,"rules":edition_rules}

func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and value==int(value) and value>=minimum and value<=maximum

func _decode_json(text: String) -> Variant:
	var parser: JSON = JSON.new()
	return parser.data if parser.parse(text)==OK else null

func _available_edition(edition: int) -> bool:
	var installed: int = int(str(ProjectSettings.get_setting("application/config/version")).split(".")[1])-4
	if edition>installed or edition<12: return false
	if edition==12: return true
	var snapshot: String = "res://data/journey-%d.json" % mini(edition+4,21)
	return FileAccess.file_exists(snapshot)


func save(state: Dictionary, commands: Array, mode: String) -> Dictionary:
	if state.get("edition",1)<13: return super.save(state,commands,mode)
	if commands.size() > 50000: return {"ok": false, "reason": "La campaña supera el límite de50000 órdenes. Se conserva el guardado anterior; puedes seguir en memoria."}
	var current = FileAccess.get_file_as_string(file_path).sha256_text() if FileAccess.file_exists(file_path) else ""
	if current != stamp: return {"ok": false, "reason": "Otra instancia ha cambiado el guardado. Carga esa partida antes de guardar."}
	var payload = _payload(state, commands, mode)
	# Hash exact persisted bytes; never hash a re-encoded floating point snapshot.
	var text = JSON.stringify(payload, "", true, true)
	var envelope = JSON.stringify({"checksum": text.sha256_text(), "payload": text})
	if envelope.to_utf8_buffer().size()>16*1024*1024: return {"ok":false,"reason":"La campaña supera16 MB. Se conserva el guardado anterior; puedes seguir en memoria."}
	var directory = ProjectSettings.globalize_path(file_path).get_base_dir()
	var ancestor = directory
	while not ancestor.is_empty():
		if FileAccess.file_exists(ancestor): return {"ok": false, "reason": "La carpeta de guardado está bloqueada por un archivo. Puedes seguir jugando en memoria."}
		var parent = ancestor.get_base_dir()
		if parent == ancestor: break
		ancestor = parent
	var error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK: return {"ok": false, "reason": "No se puede crear la carpeta de guardado. Puedes seguir jugando en memoria."}
	var temporary = FileAccess.open(file_path + ".tmp", FileAccess.WRITE)
	if temporary == null: return {"ok": false, "reason": "No se puede escribir el guardado. Puedes seguir jugando en memoria."}
	temporary.store_string(envelope)
	temporary.flush()
	var write_error = temporary.get_error()
	temporary.close()
	if write_error != OK: return {"ok": false, "reason": "No se ha podido completar la escritura del guardado."}
	if FileAccess.file_exists(file_path):
		error = DirAccess.copy_absolute(ProjectSettings.globalize_path(file_path), ProjectSettings.globalize_path(file_path + ".bak"))
		if error != OK: return {"ok": false, "reason": "No se ha podido conservar la copia anterior. El guardado original sigue intacto."}
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(file_path + ".tmp"), ProjectSettings.globalize_path(file_path))
	if error != OK: return {"ok": false, "reason": "No se ha podido reemplazar el guardado; se conserva la copia anterior."}
	stamp = envelope.sha256_text()
	return {"ok": true}
