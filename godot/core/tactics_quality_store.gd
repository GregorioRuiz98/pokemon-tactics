extends "res://core/review_store.gd"

# A local receipt certifies bytes that were actually replayed. It is optional:
# missing keys, receipts or mismatches always fall back to full journal replay.
var verified_state: Dictionary = {}
var verified_commands: Array = []
var last_load: Dictionary = {}
static var rule_cache: Dictionary = {}

func prime(rules: RefCounted) -> void:
	var chapter_number: Variant = rules.get("chapter")
	if chapter_number is int and chapter_number>=30: rule_cache[int(chapter_number)-4] = rules

func new_binding(owner_id: String) -> void:
	super.new_binding(owner_id)
	verified_state = {}; verified_commands = []

func _rules(edition: int) -> RefCounted:
	if not rule_cache.has(edition): rule_cache[edition] = preload("res://core/tactics_quality_run.gd").new() if edition==27 else super._rules(edition)
	return rule_cache[edition]

func _read_payload() -> Dictionary:
	var file: FileAccess = FileAccess.open(file_path,FileAccess.READ)
	if file==null or file.get_length()>16*1024*1024: return {"ok":false,"reason":"No se puede leer la campaña. Se conserva el archivo."}
	var text: String = file.get_as_text(); file.close()
	var envelope: Variant = _decode_json(text)
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("checksum") is String or envelope.payload.sha256_text()!=envelope.checksum: return {"ok":false,"reason":"Campaña incompleta o alterada. Se conserva el archivo."}
	var payload: Variant = _decode_json(envelope.payload)
	if not payload is Dictionary: return {"ok":false,"reason":"Contenido no válido. Se conserva el archivo."}
	if not _integer(payload.get("version"),1,27): return {"ok":false,"reason":"Esta campaña necesita otra versión. Se conserva el archivo."}
	if payload.version<26: return {"ok":true,"legacy":true}
	if payload.get("schema")!="kanto-journey" or not _integer(payload.get("startEdition"),12,int(payload.version)) or not payload.get("seed") is String or payload.seed.length()>64 or not _integer(payload.get("starter"),1,7) or int(payload.starter) not in [1,4,7] or not payload.get("commands") is Array or payload.commands.size()>50000 or not payload.get("state") is Dictionary: return {"ok":false,"reason":"Formato incompatible. Se conserva el archivo."}
	return {"ok":true,"payload":payload,"text":text,"checksum":envelope.checksum}

func _key(create: bool = false) -> PackedByteArray:
	var path: String = file_path+".verification-key"
	if FileAccess.file_exists(path):
		var source_key: FileAccess = FileAccess.open(path,FileAccess.READ)
		return source_key.get_buffer(32) if source_key!=null and source_key.get_length()==32 else PackedByteArray()
	if not create: return PackedByteArray()
	var key: PackedByteArray = Crypto.new().generate_random_bytes(32)
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file==null or key.size()!=32: return PackedByteArray()
	file.store_buffer(key); file.flush()
	return key if file.get_error()==OK else PackedByteArray()

func _receipt(expected_stamp: String) -> Dictionary:
	var key: PackedByteArray = _key()
	if key.is_empty(): return {}
	var file: FileAccess = FileAccess.open(file_path+".verified",FileAccess.READ)
	if file==null or file.get_length()<33 or file.get_length()>4*1024*1024: return {}
	var signature: PackedByteArray = file.get_buffer(32)
	var body: PackedByteArray = file.get_buffer(file.get_length()-32)
	if Crypto.new().hmac_digest(HashingContext.HASH_SHA256,key,body)!=signature: return {}
	var value: Variant = bytes_to_var(body)
	if not value is Dictionary or value.get("validator")!="tactics-quality-1" or value.get("stamp")!=expected_stamp or not value.get("state") is Dictionary: return {}
	return value.state

func _write_receipt() -> void:
	if verified_state.is_empty(): return
	var key: PackedByteArray = _key(true)
	if key.is_empty(): return
	var body: PackedByteArray = var_to_bytes({"validator":"tactics-quality-1","stamp":stamp,"state":verified_state})
	var file: FileAccess = FileAccess.open(file_path+".verified.tmp",FileAccess.WRITE)
	if file==null: return
	file.store_buffer(Crypto.new().hmac_digest(HashingContext.HASH_SHA256,key,body)); file.store_buffer(body); file.flush()
	var error: Error = file.get_error(); file.close()
	if error==OK: DirAccess.rename_absolute(ProjectSettings.globalize_path(file_path+".verified.tmp"),ProjectSettings.globalize_path(file_path+".verified"))

func _remember(state: Dictionary, commands: Array) -> void:
	verified_state = state.duplicate(true); verified_commands = commands.duplicate(true)

func _accept(saved_record: Dictionary, state: Dictionary, edition_rules: RefCounted, cached: bool) -> Dictionary:
	var payload: Dictionary = saved_record.payload
	if state.get("edition")!=payload.version or not equivalent(state,payload.state): return {"ok":false,"reason":"La campaña no coincide con su historial. Se conserva el archivo."}
	stamp = saved_record.text.sha256_text()
	campaign_id = "legacy-"+saved_record.checksum.substr(0,32); trainer_id = ""; profile_events = []; tracker = {"known":false,"kos":0}
	var meta: Variant = payload.get("trainer",{})
	if valid_meta(meta,int(state.revision)):
		campaign_id = meta.campaignId; trainer_id = meta.profileId; profile_events = meta.events.duplicate(true); tracker = meta.tracker.duplicate(true)
	_remember(state,payload.commands)
	if not cached: _write_receipt()
	last_load = {"cached":cached,"orders":payload.commands.size()}
	return {"ok":true,"state":state,"commands":payload.commands,"rules":edition_rules}

func _step(edition_rules: RefCounted, state: Dictionary, command: Variant) -> Dictionary:
	if not command is Dictionary: return {"ok":false,"reason":"Historial no válido. Se conserva el archivo."}
	if command.get("kind")=="upgrade":
		if not _integer(command.get("edition"),int(state.edition)+1,27): return {"ok":false,"reason":"Transición no válida. Se conserva el archivo."}
		edition_rules = _rules(int(command.edition))
	var result: Dictionary = edition_rules.transact(state,command)
	result.rules = edition_rules
	return result

func load_campaign(rules: RefCounted) -> Dictionary:
	prime(rules)
	var saved_record: Dictionary = _read_payload()
	if not saved_record.ok: return saved_record
	if saved_record.get("legacy",false): return super.load_campaign(rules)
	var payload: Dictionary = saved_record.payload
	var cached: Dictionary = _receipt(saved_record.text.sha256_text())
	if not cached.is_empty(): return _accept(saved_record,cached,_rules(int(payload.version)),true)
	var edition_rules: RefCounted = _rules(int(payload.startEdition))
	var state: Dictionary = edition_rules.create(payload.seed,int(payload.starter))
	for command: Variant in payload.commands:
		var result: Dictionary = _step(edition_rules,state,command)
		if not result.ok: return result
		state = result.state; edition_rules = result.rules
	return _accept(saved_record,state,edition_rules,false)

func load_campaign_async(rules: RefCounted, tree: SceneTree, progress: Callable) -> Dictionary:
	prime(rules)
	var saved_record: Dictionary = _read_payload()
	if not saved_record.ok: return saved_record
	if saved_record.get("legacy",false): return super.load_campaign(rules)
	var payload: Dictionary = saved_record.payload
	var cached: Dictionary = _receipt(saved_record.text.sha256_text())
	if not cached.is_empty(): return _accept(saved_record,cached,_rules(int(payload.version)),true)
	var edition_rules: RefCounted = _rules(int(payload.startEdition))
	var state: Dictionary = edition_rules.create(payload.seed,int(payload.starter))
	var deadline: int = Time.get_ticks_usec()+6000
	for index: int in payload.commands.size():
		var result: Dictionary = _step(edition_rules,state,payload.commands[index])
		if not result.ok: return result
		state = result.state; edition_rules = result.rules
		if Time.get_ticks_usec()>=deadline:
			progress.call(index+1,payload.commands.size())
			await tree.process_frame
			deadline = Time.get_ticks_usec()+6000
	return _accept(saved_record,state,edition_rules,false)

func save(state: Dictionary, commands: Array, mode: String) -> Dictionary:
	var certified: bool = false
	if state.get("edition",0)>=26:
		var checkpoint: Dictionary = verified_state
		var count: int = verified_commands.size()
		if checkpoint.is_empty() and commands.is_empty(): checkpoint = _rules(int(state.edition)).create(state.seed,int(state.starter)); count = 0
		if not checkpoint.is_empty() and commands.size()>=count and commands.slice(0,count)==verified_commands:
			var current_rules: RefCounted = _rules(int(checkpoint.edition))
			for command: Variant in commands.slice(count):
				var step: Dictionary = _step(current_rules,checkpoint,command)
				if not step.ok: checkpoint = {}; break
				checkpoint = step.state; current_rules = step.rules
			certified = not checkpoint.is_empty() and equivalent(checkpoint,state)
	var result: Dictionary = super.save(state,commands,mode)
	if result.ok:
		if certified: _remember(state,commands); _write_receipt()
		else: verified_state = {}; verified_commands = []
	return result
