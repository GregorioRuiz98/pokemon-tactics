extends RefCounted

const Model = preload("res://core/trainer_profile.gd")
var file_path: String
var stamp: String = ""
var blocked: bool = false
var recovery: Dictionary = {}

func _init(destination: String = "user://trainer-profile.json") -> void:
	file_path = destination

func decode(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>4*1024*1024: return {}
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text())!=OK or not parser.data is Dictionary: return {}
	var envelope: Dictionary = parser.data
	if not envelope.get("payload") is String or not envelope.get("checksum") is String or envelope.payload.sha256_text()!=envelope.checksum: return {}
	if parser.parse(envelope.payload)!=OK or not Model.valid(parser.data): return {}
	return parser.data

func load_profile() -> Dictionary:
	stamp = FileAccess.get_file_as_string(file_path).sha256_text() if FileAccess.file_exists(file_path) else ""
	var value: Dictionary = decode(file_path)
	if not value.is_empty(): blocked = false; return {"ok":true,"data":value,"warning":""}
	recovery = decode(file_path+".bak")
	blocked = not stamp.is_empty() or not recovery.is_empty()
	return {"ok":not blocked,"data":recovery,"warning":("El perfil no se puede leer. Hay una copia recuperable; el archivo original se conserva." if not recovery.is_empty() else "El perfil no se puede leer. Se conserva el archivo; puedes seguir jugando y recuperarlo desde Perfil.") if blocked else ""}

func save(value: Dictionary, restoring: bool = false) -> Dictionary:
	if blocked and not restoring: return {"ok":false,"reason":"El perfil necesita recuperación. La aventura sigue guardándose por separado."}
	if not Model.valid(value): return {"ok":false,"reason":"Datos del perfil no válidos; se conserva la copia anterior."}
	var current: String = FileAccess.get_file_as_string(file_path).sha256_text() if FileAccess.file_exists(file_path) else ""
	if current!=stamp: return {"ok":false,"reason":"Otra instancia ha actualizado el perfil. Vuelve a cargarlo antes de guardar cambios."}
	var text: String = JSON.stringify(value,"",true,true)
	var envelope: String = JSON.stringify({"payload":text,"checksum":text.sha256_text()})
	if envelope.to_utf8_buffer().size()>4*1024*1024: return {"ok":false,"reason":"El perfil supera su capacidad; conserva la aventura y una copia del perfil."}
	var absolute: String = ProjectSettings.globalize_path(file_path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())!=OK: return {"ok":false,"reason":"No se puede crear la carpeta del perfil."}
	if restoring and FileAccess.file_exists(file_path):
		if DirAccess.copy_absolute(absolute,absolute+".damaged-"+str(Time.get_ticks_usec()))!=OK: return {"ok":false,"reason":"No se ha podido conservar el perfil dañado; no se sustituye."}
	var file: FileAccess = FileAccess.open(file_path+".tmp",FileAccess.WRITE)
	if file==null: return {"ok":false,"reason":"No se puede escribir el perfil. La aventura se conserva."}
	file.store_string(envelope); file.flush()
	var error: Error = file.get_error()
	file.close()
	if error!=OK: return {"ok":false,"reason":"Escritura del perfil incompleta; se conserva la copia anterior."}
	if not restoring and FileAccess.file_exists(file_path) and DirAccess.copy_absolute(absolute,absolute+".bak")!=OK: return {"ok":false,"reason":"No se puede conservar la copia del perfil."}
	if DirAccess.rename_absolute(absolute+".tmp",absolute)!=OK: return {"ok":false,"reason":"No se puede sustituir el perfil; se conserva la copia anterior."}
	stamp = envelope.sha256_text(); blocked = false
	return {"ok":true}
