extends SceneTree

const Game = preload("res://core/closing_run.gd")
const Legacy = preload("res://core/collection_run.gd")
const Ledger = preload("res://core/closing_store.gd")
const Share = preload("res://core/closing_challenge.gd")
var checks: int = 0
var failures: Array[String] = []
var directory: String

func _initialize() -> void:
	for value: String in OS.get_cmdline_user_args():
		if value.begins_with("--save-dir="): directory = value.trim_prefix("--save-dir=")
	call_deferred("run_checks")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); print("CLOSING_RULE_FAILED: "+label)

func run_checks() -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	var game: RefCounted = Game.new()
	var old: RefCounted = Legacy.new()
	var legacy: Dictionary = old.create("frozen-counter",1); legacy.phase = "shop"
	var before: Array = old.collection_offers(legacy)
	legacy.party[0].level = 20
	check(before!=old.collection_offers(legacy),"Reproduced original counter changing when party level changes")
	var initial: Dictionary = game.create("frozen-counter",1)
	check(initial.edition==29 and initial.startEdition==29,"New campaign edition29")
	check(game.engine.catalog.moves==old.engine.catalog.moves and game.locations==old.locations,"Move balance and scenarios preserved")
	var fixture: Dictionary = initial.duplicate(true); fixture.phase = "shop"; fixture.money = 10000
	game.prepare_counter(fixture)
	var original: Dictionary = fixture.duplicate(true)
	var offers: Array = game.collection_offers(fixture)
	check(offers.size()==3 and offers==before,"Same arrival formula and prices")
	for level: int in [6,10,14]:
		fixture.party[0].level = level
		check(game.collection_offers(fixture)==offers,"Level training cannot renew offers for free: "+str(level))
	fixture.party.append(game.progression.create_member(2,149,"Fixture",75)); fixture.nextId = 3
	check(game.collection_offers(fixture)==offers,"Party and PC management cannot renew counter")
	var query: Array = game.collection_offers(fixture); query.clear()
	check(game.collection_offers(fixture)==offers,"UI cannot mutate frozen offers")
	fixture = original.duplicate(true)
	var purchase: Dictionary = {"kind":"adopt","species":int(offers[0].speciesId),"at":fixture.revision}
	var bought: Dictionary = game.transact(fixture,purchase)
	check(bought.ok and bought.state.party.size()==2 and bought.state.money==fixture.money-offers[0].price,"Frozen quote recruits at listed price")
	check(game.collection_offers(bought.state).is_empty() and Ledger.equivalent(fixture,original),"One purchase and input purity")
	var prior: Dictionary = old.create("upgrade-counter",4)
	var transition: Dictionary = {"kind":"upgrade","edition":29,"at":prior.revision}
	var upgraded: Dictionary = game.transact(prior,transition)
	check(upgraded.ok and upgraded.state.party==prior.party and upgraded.state.rng==prior.rng,"Explicit upgrade preserves party and RNG")
	var path: String = directory.path_join("upgrade-%d.json"%Time.get_ticks_usec())
	var journal: RefCounted = Ledger.new(path); journal.prime(game)
	check(journal.save(upgraded.state,[transition],"current").ok,"Mixed edition journal saved")
	DirAccess.remove_absolute(path+".verified")
	var loaded: Dictionary = Ledger.new(path).load_campaign(game)
	check(loaded.ok and Ledger.equivalent(loaded.get("state",{}),upgraded.state),"Mixed edition cold replay")
	for species: int in [1,25,133,145,150]:
		var run: Dictionary = game.create("closing-share",species)
		var decoded: Dictionary = Share.decode(Share.encode(run))
		check(decoded.get("edition")==29 and decoded.get("starter")==species,"New share code roundtrip: "+str(species))
		check(not game.transact(run,{"kind":"adopt","species":1,"at":-1}).ok,"Stale command rejected")
		var starter_path: String = directory.path_join("starter-%d-%d.json"%[species,Time.get_ticks_usec()])
		var starter_store: RefCounted = Ledger.new(starter_path); starter_store.prime(game)
		check(starter_store.save(run,[],"current").ok,"New-edition starter saved")
		DirAccess.remove_absolute(starter_path+".verified")
		var restored: Dictionary = Ledger.new(starter_path).load_campaign(game)
		check(restored.ok and Ledger.equivalent(restored.get("state",{}),run),"New-edition starter cold replay")
	check(Share.decode(preload("res://core/collection_challenge.gd").encode(prior)).get("edition")==28,"Previous share code keeps previous rules")
	check(Share.decode("KT36:garbage").is_empty(),"Malformed share code rejected")
	var report: Dictionary = {"checks":checks,"failures":failures,"edition":29,"numericalCombatChanges":false,"legacyCounterReproduced":true}
	FileAccess.open(directory.path_join("closing-rules.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report)); quit(0 if failures.is_empty() else 1)
