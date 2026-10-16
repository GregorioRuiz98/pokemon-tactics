extends SceneTree
const Campaign = preload("res://core/kanto_run.gd")
const Store = preload("res://core/kanto_store.gd")
var rules: Campaign = Campaign.new()
var run: Dictionary = rules.create("kanto-14",7)
var journal: Array = []
var failures: Array = []
var checks: int = 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
func act(kind: String, extra: Dictionary = {}) -> Dictionary:
	extra.merge({"kind":kind,"at":run.revision},true)
	var result: Dictionary = rules.transact(run,extra)
	if result.ok:
		run = result.state
		journal.append(extra.duplicate(true))
	return result
func _initialize() -> void:
	var directory: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): directory = arg.trim_prefix("--save-dir=")
	act("enter")
	check(not act("heal",{"member":1,"item":"potion"}).ok,"Healing blocked inside combat")
	check(not act("battle",{"order":{"kind":"move"}}).ok,"Malformed move rejected")
	check(not act("battle",{"order":{"kind":"attack","target":{}}}).ok,"Malformed attack rejected")
	for step: int in 160:
		if run.phase != "battle": break
		act("battle",{"order":rules.engine.choose_command(run.battle)})
	check(run.phase == "capture","Reach legitimate first reward")
	act("capture")
	check(run.phase == "shop","Reach shop")
	var hp: int = run.party[0].hp
	check(act("train",{"member":1,"stat":"maxHp"}).ok,"First training")
	check(act("train",{"member":1,"stat":"speed"}).ok,"Second training")
	check(run.money >= 80,"Enough money to distinguish training cap from lack of funds")
	var before: Dictionary = run.duplicate(true)
	check(not act("train",{"member":1,"stat":"attack"}).ok and Store.equivalent(before,run),"Third training rejected without charging")
	check(run.party[0].hp == hp,"Training does not heal")
	act("buy",{"item":"rare-candy"})
	check(act("evolve",{"member":1}).ok,"Evolution consumes candy")
	check(run.party[0].hp == hp and run.bag["rare-candy"] == 0,"Evolution preserves HP and consumes exactly one")
	var dead: Dictionary = run.duplicate(true)
	dead.party[0].hp = 0
	for kind: String in ["heal","evolve","train"]:
		check(not rules.transact(dead,{"kind":kind,"member":1,"item":"potion","stat":"attack","at":dead.revision}).ok,"Dead member rejected: " + kind)
	var path: String = directory.path_join("campaign-edge-save.json")
	var first: Store = Store.new(path)
	check(first.save(run,journal,"").ok,"Save canonical campaign")
	check(first.load_campaign(rules).ok,"Replay training and evolution")
	var second: Store = Store.new(path)
	var alternate: Dictionary = rules.create("another-seed",1)
	check(first.save(alternate,[],"").ok,"Other instance changes save")
	check(not second.save(run,journal,"").ok,"Concurrent overwrite rejected")
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	file.store_string("invalid campaign")
	file.close()
	check(not first.load_campaign(rules).ok and FileAccess.get_file_as_string(path) == "invalid campaign","Invalid save preserved")
	var output: Dictionary = {"checks":checks,"failures":failures}
	file = FileAccess.open(directory.path_join("campaign-edge-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
