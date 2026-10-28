extends SceneTree

const Store = preload("res://core/relief_store.gd")
const Game = preload("res://core/relief_run.gd")
var directory: String = ""

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	call_deferred("review")

func review() -> void:
	if directory.is_empty(): quit(2); return
	var source_path: String = directory.path_join("natural-save.json")
	var source: String = FileAccess.get_file_as_string(source_path)
	var envelope: Dictionary = JSON.parse_string(source)
	var payload: Dictionary = JSON.parse_string(envelope.payload)
	# A fresh path has no key or receipt. Preserve the original simulation save.
	var path: String = directory.path_join("cold-replay-%d.json"%Time.get_ticks_usec())
	FileAccess.open(path,FileAccess.WRITE).store_string(source)
	var store: RefCounted = Store.new(path)
	var started: int = Time.get_ticks_msec()
	var result: Dictionary = store.load_campaign(Game.new())
	var failures: Array = []
	if not result.ok: failures.append(result.get("reason","Load failed"))
	elif not Store.equivalent(result.state,payload.state) or result.commands!=payload.commands: failures.append("Full journal/state mismatch")
	if store.last_load.get("cached",true): failures.append("Cold replay used a receipt")
	if FileAccess.get_file_as_string(source_path)!=source: failures.append("Original simulation save changed")
	var report: Dictionary = {"failures":failures,"orders":payload.commands.size(),"edition":payload.version,"phase":payload.state.phase,"cached":store.last_load.get("cached",true),"stateHash":JSON.stringify(result.get("state",{}),"",true,true).sha256_text(),"payloadChecksum":envelope.checksum,"seconds":(Time.get_ticks_msec()-started)/1000.0,"scope":"Full legal journal replay from a fresh path without certificate/key; original save preserved. Not a new played campaign."}
	FileAccess.open(directory.path_join("full-cold-replay.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report)); quit(0 if failures.is_empty() else 1)
