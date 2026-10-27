extends SceneTree

const Game = preload("res://core/collection_run.gd")
const Ledger = preload("res://core/collection_store.gd")
const Catalog = preload("res://core/collection_catalog.gd")
const Trainer = preload("res://core/collection_profile.gd")
const Profiles = preload("res://core/collection_profile_store.gd")
const Challenge = preload("res://core/collection_challenge.gd")
var checks: int = 0
var failures: Array = []
var directory: String
var game: RefCounted

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); print("COLLECTION_FAILED: "+label)

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	call_deferred("run_checks")

func command(run: Dictionary, data: Dictionary) -> Dictionary:
	data = data.duplicate(true); data.at = run.revision
	return game.transact(run,data)

func boss_fixture(species: int, place: String) -> Dictionary:
	var run: Dictionary = game.create("collection-boss-"+str(species),species)
	run.mainComplete = true; run.finalPath = "birds" if place=="legendary-birds" else "psychic"
	run.cleared = game.locations.filter(func(location):return location.id!=place and (place=="legendary-origin" or location.id!="legendary-origin")).map(func(location):return location.id)
	run.stage = game.locations.find(game.locations.filter(func(location):return location.id==place)[0])
	run.phase = "battle"; run.battle = game.engine.encounter(run,game.locations[int(run.stage)])
	var ally: Dictionary = run.battle.units.filter(func(unit):return unit.team=="ally")[0]
	var enemy: Dictionary = run.battle.units.filter(func(unit):return unit.team=="enemy")[0]
	ally.x = 5; ally.y = 5; ally.attack = 10000; ally.hp = ally.maxHp; ally.status = null; ally.ability = "run-away"
	enemy.x = 6; enemy.y = 5; enemy.hp = 1; enemy.defense = 1; enemy.ability = "run-away"
	run.battle.units = [ally,enemy]; run.battle.queue = [ally.id,enemy.id]; run.battle.completed = []
	run.battle.moved = false; run.battle.acted = false; run.battle.deployment = false; run.battle.outcome = "playing"
	for row: Array in run.battle.board: row.fill(0)
	for row: Array in run.battle.heights: row.fill(0)
	run.battleInitial = run.battle.duplicate(true); run.battleCommands = []
	return run

func run_checks() -> void:
	game = Game.new()
	var legacy: RefCounted = preload("res://core/tactics_quality_run.gd").new()
	check(game.engine.catalog.moves==legacy.engine.catalog.moves,"Accepted move balance unchanged")
	var initial: Dictionary = game.create("collection-tests",1)
	check(initial.edition==28 and initial.startEdition==28,"Versioned campaign28")
	var bases: Array = []
	for species: int in range(1,152):
		check(Catalog.base_species(species)>0,"Family registered: "+str(species))
		check(Catalog.minimum_level(species)>=5 and Catalog.minimum_level(species)<=75,"Recruitment floor: "+str(species))
		var options: Array = Catalog.starter_options([species])
		check(Catalog.base_species(species) in options and (species==Catalog.base_species(species) or species not in options),"Only first form unlocked: "+str(species))
		if Catalog.base_species(species)==species: bases.append(species)
	for species: int in bases:
		var fresh: Dictionary = game.create("fresh-"+str(species),species)
		check(fresh.party.size()==1 and fresh.party[0].speciesId==species and fresh.party[0].level==5,"Fresh level5 starter: "+str(species))
		check(fresh.party[0].moves.size()<=4 and fresh.party[0].xp==0,"No inherited progression: "+str(species))
	check(game.create("invalid",6).is_empty() and game.create("invalid",0).is_empty(),"Evolved and invalid starters rejected")
	var high: Dictionary = initial.duplicate(true); high.phase = "shop"; high.mainComplete = true
	high.cleared = game.locations.filter(func(location):return location.get("leader",false)).map(func(location):return location.id)
	high.party[0] = game.progression.create_member(1,1,"Fixture",75); high.money = 10000
	var offered: Dictionary = {}
	for index: int in 700:
		high.seed = "offers-"+str(index)
		var before: Dictionary = high.duplicate(true)
		var offers: Array = game.collection_offers(high)
		check(offers.size()==3 and offers==game.collection_offers(high) and Ledger.equivalent(high,before),"Pure stable offers: "+str(index))
		var ids: Array = []
		for offer: Dictionary in offers:
			ids.append(offer.speciesId); offered[int(offer.speciesId)] = true
			check(int(offer.speciesId) not in Catalog.LEGENDS and offer.level==75,"Nonlegendary full-level pool")
		check(ids[0]!=ids[1] and ids[0]!=ids[2] and ids[1]!=ids[2],"Three different offers")
	check(offered.size()==146,"All146 nonlegendaries reachable across seeds")
	var low: Dictionary = initial.duplicate(true); low.phase = "shop"; low.money = 999
	for offer: Dictionary in game.collection_offers(low): check(Catalog.minimum_level(int(offer.speciesId))<=5 and offer.level==5,"No premature evolution in early shop")
	var pick: Dictionary = game.collection_offers(low)[0]
	var adopted: Dictionary = command(low,{"kind":"adopt","species":pick.speciesId})
	check(adopted.ok and adopted.state.party.size()==2 and adopted.state.money==low.money-pick.price,"Recruitment charges exact price")
	check(game.collection_offers(adopted.state).is_empty() and not command(adopted.state,{"kind":"adopt","species":pick.speciesId}).ok,"One recruitment per location")
	var poor: Dictionary = low.duplicate(true); poor.money = 0
	check(not command(poor,{"kind":"adopt","species":pick.speciesId}).ok,"No purchase without funds")
	check(not game.transact(low,{"kind":"adopt","species":pick.speciesId,"at":-1}).ok,"Stale order rejected")
	var full: Dictionary = low.duplicate(true)
	for id: int in range(2,7): full.party.append(game.progression.create_member(id,1,"Fixture",5))
	full.nextId = 7
	var pc: Dictionary = command(full,{"kind":"adopt","species":pick.speciesId})
	check(pc.ok and pc.state.party.size()==6 and pc.state.reserve.size()==1 and pc.state.reserve[0].id==7,"Full team sends recruit to PC")
	for place: String in ["legendary-birds","legendary-origin"]:
		for species: int in ([144,145,146] if place=="legendary-birds" else [151,150]):
			var fixture: Dictionary = boss_fixture(1,place)
			var won: Dictionary = command(fixture,{"kind":"battle","order":{"kind":"attack","target":fixture.battle.units[1].id,"actionId":"basic"}})
			check(won.ok and won.state.phase=="capture" and won.state.has("legendaryChoices"),"Real victory transaction offers legend: "+place)
			if not won.ok or not won.state.has("legendaryChoices"): continue
			check(not command(won.state,{"kind":"select-recruit","species":1}).ok and not command(won.state,{"kind":"reroll-capture"}).ok,"Legendary choices cannot escape boss pool")
			var selected: Dictionary = command(won.state,{"kind":"select-recruit","species":species})
			check(selected.ok and selected.state.reward.speciesId==species,"Can choose boss species: "+str(species))
			var replay_command: Dictionary = JSON.parse_string(JSON.stringify({"kind":"select-recruit","species":species,"at":won.state.revision}))
			var replayed: Dictionary = game.transact(won.state,replay_command)
			check(replayed.ok and Ledger.equivalent(replayed.state,selected.state),"Legendary selection survives JSON journal numbers")
			var captured: Dictionary = command(selected.state,{"kind":"capture"})
			check(captured.ok and captured.state.party.size()==2 and captured.state.party[1].speciesId==species and not captured.state.has("legendaryChoices"),"Exactly one boss recruit")
			check(captured.state.phase==("shop" if place=="legendary-birds" else "ending"),"Boss progression preserved")
			check(not command(captured.state,{"kind":"capture"}).ok,"Cannot collect twice")
	await profile_checks(initial,adopted.state,pick)
	await save_checks(initial,bases)
	var report: Dictionary = {"checks":checks,"failures":failures,"starterForms":bases.size(),"recruitableSpecies":offered.size()+5}
	var file: FileAccess = FileAccess.open(directory.path_join("collection-result.json"),FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")); file.close()
	print(JSON.stringify(report)); quit(0 if failures.is_empty() else 1)

func profile_checks(initial: Dictionary, adopted: Dictionary, offer: Dictionary) -> void:
	var old: RefCounted = preload("res://core/trainer_profile.gd").new(); old.data.dex = [6,151]
	old.unlock("first-medal","legacy")
	var profile: RefCounted = Trainer.new(old.data)
	check(profile.data.version==2 and profile.data.id==old.data.id and profile.data.dex==[6,151] and profile.data.seen==[6,151] and profile.data.unlocked.has("first-medal"),"Migration preserves existing collection, identity and achievements")
	var path: String = directory.path_join("profile-"+str(Time.get_ticks_usec())+".json")
	var old_store: RefCounted = preload("res://core/trainer_store.gd").new(path); old_store.load_profile()
	check(old_store.save(old.data).ok,"Legacy profile fixture saved")
	var original: String = FileAccess.get_file_as_string(path)
	var store: RefCounted = Profiles.new(path); store.load_profile()
	check(store.save(profile.data).ok and FileAccess.get_file_as_string(path+".before-v2")==original,"Original profile preserved before migration")
	var decoded_profile: RefCounted = Trainer.new(Profiles.new(path).load_profile().data)
	check(6 in decoded_profile.data.dex and 151 in decoded_profile.starters(),"JSON profile IDs normalized for UI and unlocks")
	profile = Trainer.new()
	var events: Array = [{"revision":1,"flags":[],"species":[],"seen":[150,144,26]}]
	var seen_run: Dictionary = initial.duplicate(true); seen_run.revision = 1
	profile.observe("seen",seen_run,events)
	check(150 in profile.data.seen and 150 not in profile.data.dex and 150 not in profile.starters() and 25 not in profile.starters(),"Seen species never unlock starters")
	events = [{"revision":int(adopted.revision),"flags":[],"species":[offer.speciesId,26,150]}]
	profile.observe("owned",adopted,events)
	check(Catalog.base_species(int(offer.speciesId)) in profile.starters() and 25 in profile.starters() and 150 in profile.starters(),"Obtained forms and legends unlock first forms")
	var count: int = profile.data.unlocked.size()
	check(profile.observe("owned",adopted,events).is_empty() and profile.data.unlocked.size()==count,"Event catchup and achievements idempotent")
	check(profile.data.unlocked.has("first-recruit") and profile.data.unlocked.has("legend-recruit") and Trainer.valid(profile.data),"Collection achievements saved in valid profile")
	for species: int in range(1,152): profile.register_species(species)
	profile.observe("complete",initial,[])
	check(profile.data.dex.size()==151 and profile.data.unlocked.has("dex-complete") and profile.data.unlocked.has("all-oak"),"Full Dex and Oak achievements")
	var corrupt: Dictionary = profile.data.duplicate(true); corrupt.seen = []
	check(not Trainer.valid(corrupt),"Invalid seen/owned inconsistency rejected")
	var future: Dictionary = profile.data.duplicate(true); future.version = 99
	var text: String = JSON.stringify(future); var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"payload":text,"checksum":text.sha256_text()})); file.close()
	var future_bytes: String = FileAccess.get_file_as_string(path)
	var blocked: RefCounted = Profiles.new(path)
	check(not blocked.load_profile().ok and not blocked.save(profile.data).ok and FileAccess.get_file_as_string(path)==future_bytes,"Future profile never overwritten")
	await process_frame

func save_checks(_initial: Dictionary, bases: Array) -> void:
	for species: int in [25,133,144,150,151]:
		var run: Dictionary = game.create("save-"+str(species),species)
		var path: String = directory.path_join("starter-%d-%d.json"%[species,Time.get_ticks_usec()])
		var store: RefCounted = Ledger.new(path); store.prime(game); store.new_binding("test-profile")
		check(store.save(run,[],"kanto-14").ok,"Save unlocked starter: "+str(species))
		if FileAccess.file_exists(path+".verified"): DirAccess.remove_absolute(path+".verified")
		var cold: RefCounted = Ledger.new(path); var loaded: Dictionary = cold.load_campaign(game)
		check(loaded.ok and Ledger.equivalent(loaded.state,run) and not cold.last_load.cached,"Cold replay starter: "+str(species))
		var warm: RefCounted = Ledger.new(path); loaded = warm.load_campaign(game)
		check(loaded.ok and warm.last_load.cached,"Certified reload starter: "+str(species))
		check(Challenge.decode(Challenge.encode(run)).get("starter")==species,"Share code preserves species: "+str(species))
	for species: int in [0,6,152]:
		var invalid: Dictionary = {"edition":28,"seed":"test","starter":species,"mapSize":16}
		check(Challenge.decode("KT35:"+Marshalls.utf8_to_base64(JSON.stringify(invalid))).is_empty(),"Invalid challenge starter: "+str(species))
	check(bases.size()>70 and Challenge.decode("KT35:garbage").is_empty(),"Challenge input rejected")
	var old_rules: RefCounted = preload("res://core/tactics_quality_run.gd").new()
	var original: Dictionary = old_rules.create("upgrade-collection",4)
	var cmd: Dictionary = {"kind":"upgrade","edition":28,"at":original.revision}
	var result: Dictionary = game.transact(original,cmd)
	check(result.ok and result.state.party==original.party and result.state.rng==original.rng,"Upgrade preserves old party and RNG")
	var file_path: String = directory.path_join("migration-"+str(Time.get_ticks_usec())+".json")
	var journal: RefCounted = Ledger.new(file_path); journal.prime(game)
	check(journal.save(result.state,[cmd],"kanto-14").ok,"Mixed old/new journal saved")
	var reader: RefCounted = Ledger.new(file_path); var recovered: Dictionary = reader.load_campaign(game)
	check(recovered.ok and Ledger.equivalent(recovered.state,result.state),"Mixed edition journal replayed")
	await process_frame
