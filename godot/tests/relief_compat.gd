extends SceneTree

const Store = preload("res://core/relief_store.gd")
const Game = preload("res://core/relief_run.gd")
var directory: String = ""
var checks: int = 0
var failures: Array = []

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	call_deferred("review")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func review() -> void:
	if directory.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	var game: RefCounted = Game.new()
	var state: Dictionary = game.create("invalid-history",1)
	for kind: Variant in [[],{},null,42]:
		var path: String = directory.path_join("invalid-%d.json"%checks)
		var payload: String = JSON.stringify({"version":30,"schema":"kanto-journey","startEdition":30,"seed":state.seed,"starter":1,"state":state,"commands":[{"kind":kind,"at":0}]})
		var text: String = JSON.stringify({"payload":payload,"checksum":payload.sha256_text()})
		FileAccess.open(path,FileAccess.WRITE).store_string(text)
		var loaded: Dictionary = Store.new(path).load_campaign(game)
		check(not loaded.ok,"Invalid typed order rejected: "+str(kind))
		check(FileAccess.get_file_as_string(path)==text,"Original invalid history retained")
	var forecast: String = preload("res://ui/tactical_info.gd").forecast({"name":"Pidgey","hp":30},{"ok":true,"name":"Placaje","cost":1,"accuracy":100,"damage":20,"heal":0})
	check("20" in forecast and "Pidgey" in forecast,"Historical forecast without definition")
	for edition: int in [13,18]:
		var store: RefCounted = Store.new(directory.path_join("probe.json"))
		var old: RefCounted = store._rules(edition)
		var initial: Dictionary = old.create("old-relief-upgrade",4)
		var order: Dictionary = {"kind":"upgrade","edition":30,"at":initial.revision}
		var updated: Dictionary = game.transact(initial,order)
		check(updated.ok and updated.state.rng==initial.rng and updated.state.party.size()==initial.party.size(),"Old upgrade edition "+str(edition))
		if not updated.ok: continue
		var path: String = directory.path_join("mixed-%d.json"%edition)
		var mixed: RefCounted = Store.new(path); mixed.prime(game)
		check(mixed.save(updated.state,[order],"current").ok,"Old mixed journal saved")
		if FileAccess.file_exists(path+".verified"): DirAccess.remove_absolute(path+".verified")
		var loaded: Dictionary = Store.new(path).load_campaign(game)
		check(loaded.ok and Store.equivalent(loaded.get("state",{}),updated.state),"Old mixed cold replay")
	var report: Dictionary = {"checks":checks,"failures":failures,"scope":"RC2 reader/forecast regressions and old-edition upgrade replay; no modal or public-release claim."}
	FileAccess.open(directory.path_join("compatibility.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report)); quit(0 if failures.is_empty() else 1)
