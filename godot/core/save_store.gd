class_name LabSaveStore
extends RefCounted

const Rules = preload("res://core/battle.gd")
var file_path: String
var stamp: String = ""

static func equivalent(a, b) -> bool:
	# JSON numbers are doubles, including IDs and coordinates originally stored as ints.
	if (a is float or a is int) and (b is float or b is int):
		if float(a) == float(b): return true
		if float(a) == floor(float(a)) or float(b) == floor(float(b)): return false
		# Godot's decimal JSON parser can shift a non-integer by one ULP.
		# Only tolerate roundoff; the reconstructed state remains authoritative.
		return abs(float(a) - float(b)) <= maxf(1.0, maxf(abs(float(a)), abs(float(b)))) * 0.000000000000001
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for index in a.size():
			if not equivalent(a[index], b[index]): return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for field in a:
			if not b.has(field) or not equivalent(a[field], b[field]): return false
		return true
	return a == b

func _init(destination: String = "user://laboratory-save.json"):
	file_path = destination
	if FileAccess.file_exists(file_path): stamp = FileAccess.get_file_as_string(file_path).sha256_text()

func _payload(state: Dictionary, commands: Array, mode: String) -> Dictionary:
	return {"schema": 1, "version": "0.13.0", "mode": mode, "seed": state.seed, "variance": state.variance, "composition": state.composition, "commands": commands, "state": state}

func save(state: Dictionary, commands: Array, mode: String) -> Dictionary:
	if commands.size() > 4000: return {"ok": false, "reason": "El ensayo supera el límite de guardado del laboratorio. Se conserva el guardado anterior; puedes seguir en memoria."}
	var current = FileAccess.get_file_as_string(file_path).sha256_text() if FileAccess.file_exists(file_path) else ""
	if current != stamp: return {"ok": false, "reason": "Otra instancia ha cambiado el guardado. Carga esa partida antes de guardar."}
	var payload = _payload(state, commands, mode)
	# Hash exact persisted bytes; never hash a re-encoded floating point snapshot.
	var text = JSON.stringify(payload, "", true, true)
	var envelope = JSON.stringify({"checksum": text.sha256_text(), "payload": text})
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

func load_game(rules: Rules) -> Dictionary:
	if not FileAccess.file_exists(file_path): return {"ok": false, "reason": "No hay una partida guardada."}
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null or file.get_length() > 8 * 1024 * 1024: return {"ok": false, "reason": "No se puede leer el guardado o supera el tamaño admitido. El archivo se conserva."}
	var text = file.get_as_text()
	file.close()
	var parser = JSON.new()
	if parser.parse(text) != OK: return {"ok": false, "reason": "Guardado no válido. Se conserva el archivo sin sobrescribirlo."}
	var envelope = parser.data
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("checksum") is String: return {"ok": false, "reason": "Guardado no válido. Se conserva el archivo sin sobrescribirlo."}
	if envelope.payload.sha256_text() != envelope.checksum: return {"ok": false, "reason": "El guardado está incompleto o alterado. Se conserva el archivo."}
	if parser.parse(envelope.payload) != OK or not parser.data is Dictionary: return {"ok": false, "reason": "Contenido de guardado no válido."}
	var payload = parser.data
	if payload.get("schema") != 1 or payload.get("version") != "0.13.0": return {"ok": false, "reason": "Versión de guardado incompatible. Se conserva el archivo."}
	if payload.get("mode") not in ["classic", "current"] or payload.get("composition") not in ["starters", "mixed"] or payload.get("variance") not in [0.05, 0.1] or not payload.get("seed") is String or not payload.get("commands") is Array or not payload.get("state") is Dictionary: return {"ok": false, "reason": "Cabecera de guardado no válida. El archivo se conserva."}
	if payload.commands.size() > 4000 or payload.seed.length() > 64: return {"ok": false, "reason": "El guardado excede los límites del laboratorio."}
	var replay = rules.create(payload.seed, payload.variance, payload.composition, payload.mode)
	for command in payload.commands:
		if not command is Dictionary or command.get("kind") not in ["move", "attack", "finish"]: return {"ok": false, "reason": "El historial contiene una orden no válida."}
		if command.kind == "move" and (not command.get("destination") is Dictionary or not command.destination.get("x") is float or not command.destination.get("y") is float): return {"ok": false, "reason": "Coordenadas de guardado no válidas."}
		if command.kind == "attack" and (not command.get("target") is float or not command.get("actionId", "basic") is String): return {"ok": false, "reason": "Ataque de guardado no válido."}
		if command.kind == "finish" and command.has("facing") and (not (command.facing is float or command.facing is int) or int(command.facing) != command.facing or int(command.facing) not in Rules.FACINGS): return {"ok": false, "reason": "Orientación de guardado no válida."}
		var result = rules.apply_command(replay, command)
		if not result.ok: return {"ok": false, "reason": "No se puede reconstruir la partida. El archivo se conserva."}
		replay = result.state
	if not equivalent(replay, payload.state): return {"ok": false, "reason": "El estado no coincide con su historial. El archivo se conserva."}
	stamp = text.sha256_text()
	return {"ok": true, "state": replay, "commands": payload.commands, "mode": payload.mode}

func preserve_before_new() -> Dictionary:
	if FileAccess.file_exists(file_path):
		var backup = file_path + ".before-new-%d-%d.json" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(file_path), ProjectSettings.globalize_path(backup)) != OK: return {"ok": false, "reason": "No se puede conservar la partida anterior; no se inicia otra."}
		stamp = FileAccess.get_file_as_string(file_path).sha256_text()
	return {"ok": true}
