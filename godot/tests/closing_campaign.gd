extends SceneTree

const Game = preload("res://core/closing_run.gd")
const Store = preload("res://core/closing_store.gd")
const Trainer = preload("res://core/collection_profile.gd")
const Profiles = preload("res://core/collection_profile_store.gd")
const Catalog = preload("res://core/collection_catalog.gd")
var directory: String = ""
var strategy_path: String = ""
var game: RefCounted
var store: RefCounted
var profile: RefCounted
var profiles: RefCounted
var state: Dictionary = {}
var journal: Array = []
var encounters: Array = []
var checks: int = 0
var failures: Array[String] = []
var started: int = 0
var captures: Array[int] = []
var recruits: Array[int] = []
var recruit_branch: Dictionary = {}
var samples: Array = []
var expected_seen: Array[int] = []

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
		if argument.begins_with("--strategy="): strategy_path = argument.trim_prefix("--strategy=")
	call_deferred("run_campaign")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("CLOSING_FAILED: "+label)

func issue(value: Dictionary) -> bool:
	var order: Dictionary = value.duplicate(true); order.at = int(state.revision)
	var before: Dictionary = state
	var location: Dictionary = game.locations[int(state.stage)]
	var time: int = Time.get_ticks_usec()
	var result: Dictionary = game.transact(state,order)
	samples.append((Time.get_ticks_usec()-time)/1000.0)
	check(result.ok,"Accepted order %d: %s %s"%[journal.size(),order.kind,result.get("reason","")])
	if not result.ok: return false
	state = result.state; journal.append(order)
	var definition: Dictionary = result.get("presentation",{}).get("visualDefinition",{})
	store.record(game.engine,before,state,order,result.get("presentation",{}),definition,location)
	check(state.revision==before.revision+1 and state.money>=0,"Revision and money invariant")
	if order.kind=="enter":
		encounters.append({"location":location.id,"kind":location.get("kind","battle"),"startedOrder":journal.size(),"levels":state.party.map(func(member):return int(member.level)),"cap":game.level_cap(state),"money":state.money})
		for unit: Dictionary in state.get("battle",{}).get("units",[]):
			if int(unit.speciesId) not in expected_seen: expected_seen.append(int(unit.speciesId))
		print("CLOSING_ENTER "+str(location.id))
	if state.cleared.size()>before.cleared.size():
		encounters[-1].rounds = before.get("battle",{}).get("round",0)
		encounters[-1].orders = journal.size()-int(encounters[-1].startedOrder)
		encounters[-1].fainted = state.party.filter(func(member):return member.hp<=0).size()
		check(int(encounters[-1].rounds)<=70,"No stalled encounter: "+str(location.id))
	if order.kind=="capture": captures.append(int(before.reward.speciesId))
	if order.kind=="adopt": recruits.append(int(order.species))
	if order.kind in ["capture","adopt"] or state.cleared.size()>before.cleared.size():
		if not checkpoint(): return false
	return true

func checkpoint(cold: bool = false) -> bool:
	var saved: Dictionary = store.save(state,journal,"current")
	check(saved.ok,"Campaign checkpoint saved")
	if not saved.ok: return false
	profile.observe(store.campaign_id,state,store.profile_events)
	check(profiles.save(profile.data).ok,"Profile checkpoint saved")
	if cold:
		DirAccess.remove_absolute(store.file_path+".verified")
		var reader: RefCounted = Store.new(store.file_path)
		var result: Dictionary = reader.load_campaign(game)
		check(result.ok and Store.equivalent(result.get("state",{}),state),"Cold complete journal replay")
		if not result.ok: return false
		check(not reader.last_load.cached,"Cold replay did not use receipt")
		store = reader
	write_reports()
	return failures.is_empty()

func legendary_reward() -> bool:
	if not state.has("legendaryChoices"): return true
	var selected: int = 145 if 145 in state.legendaryChoices else 150
	return issue({"kind":"select-recruit","species":selected}) and issue({"kind":"capture"})

func recruitment_branch() -> void:
	if not recruit_branch.is_empty() or state.phase!="shop": return
	var offers: Array = game.collection_offers(state).filter(func(offer):return int(offer.price)<=state.money)
	if offers.is_empty(): return
	var order: Dictionary = {"kind":"adopt","species":int(offers[0].speciesId),"at":int(state.revision)}
	var result: Dictionary = game.transact(state,order)
	check(result.ok,"Recruitment branch accepts real affordable purchase")
	if not result.ok: return
	var branch: RefCounted = Store.new(directory.path_join("recruitment-branch.json")); branch.prime(game); branch.new_binding(profile.data.id)
	branch.profile_events = store.profile_events.duplicate(true)
	branch.record(game.engine,state,result.state,order,{}, {},game.locations[int(state.stage)])
	check(branch.save(result.state,journal+[order],"current").ok,"Recruitment branch saved")
	DirAccess.remove_absolute(branch.file_path+".verified")
	var loaded: Dictionary = Store.new(branch.file_path).load_campaign(game)
	check(loaded.ok and Store.equivalent(loaded.get("state",{}),result.state),"Recruitment branch cold replay")
	var branch_profile: RefCounted = Trainer.new(profile.data)
	branch_profile.observe(branch.campaign_id,result.state,branch.profile_events)
	var first: int = Catalog.base_species(int(order.species))
	check(int(order.species) in branch_profile.data.dex and first in branch_profile.starters(),"Branch recruit unlocks first form")
	recruits.append(int(order.species))
	recruit_branch = {"species":int(order.species),"location":game.locations[int(state.stage)].id,"price":offers[0].price,"revision":int(state.revision),"separateFromMainRun":true}

func write_reports() -> void:
	var data: Dictionary = {"edition":state.edition,"seed":state.seed,"starter":state.starter,"phase":state.phase,"cleared":state.cleared,"medals":state.medals,"orders":journal.size(),"checks":checks,"failures":failures,"captures":captures,"recruits":recruits,"seen":profile.data.seen.size(),"obtained":profile.data.dex.size(),"unlockedStarters":profile.starters(),"achievements":profile.data.unlocked.keys(),"encounters":encounters,"seconds":(Time.get_ticks_msec()-started)/1000.0,"scope":"New current-edition campaign from Oak, using a previously successful legal strategy as scripted input, plus current shop/legend rewards. All orders are executed again; no old state injected. Automated, not human/external hardware testing."}
	data.recruitmentBranch = recruit_branch
	FileAccess.open(directory.path_join("closing-campaign.json"),FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	FileAccess.open(directory.path_join("closing-journal.json"),FileAccess.WRITE).store_string(JSON.stringify({"seed":state.seed,"starter":state.starter,"edition":state.edition,"commands":journal,"expectedState":state},"",true,true))

func run_campaign() -> void:
	if directory.is_empty() or strategy_path.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	game = Game.new(); profile = Trainer.new(); started = Time.get_ticks_msec()
	profiles = Profiles.new(directory.path_join("closing-profile.json")); profiles.load_profile()
	store = Store.new(directory.path_join("closing-save.json")); store.prime(game); store.new_binding(profile.data.id)
	var strategy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(strategy_path))
	state = game.create(strategy.seed,int(strategy.starter))
	check(state.edition==29 and state.party[0].level==5,"Current campaign begins at Oak at5")
	checkpoint()
	for index: int in strategy.commands.size():
		if not failures.is_empty(): break
		if not legendary_reward(): break
		# Separate legal save branch: optional spending cannot invalidate the reference strategy.
		recruitment_branch()
		if not issue(strategy.commands[index]): break
		if index%64==0: await process_frame
	if failures.is_empty(): legendary_reward()
	check(state.phase=="ending" and state.cleared.size()==58 and state.medals.size()==8,"Complete current Kanto and both finals")
	check(145 in captures and 150 in captures and recruits.size()==1,"Current boss choices and shop recruitment exercised")
	check(state.reserve.size()>0 and profile.data.unlocked.has("psychic") and profile.data.unlocked.has("legend-recruit"),"PC and legendary achievements retained")
	check(expected_seen.all(func(species):return species in profile.data.seen),"All encountered species recorded as seen")
	checkpoint(true)
	var recovered: RefCounted = Trainer.new(Profiles.new(profiles.file_path).load_profile().data)
	check(recovered.data.dex==profile.data.dex and recovered.starters()==profile.starters(),"Profile survives separate cold load")
	var missing: RefCounted = Trainer.new()
	missing.observe(store.campaign_id,state,store.profile_events)
	check(missing.data.dex==profile.data.dex and missing.data.seen==profile.data.seen,"Outbox recovers full collection after missing profile writes")
	var unlocked: Dictionary = game.create("closing-next-run",145)
	check(145 in recovered.starters() and unlocked.party[0].speciesId==145 and unlocked.party[0].level==5,"Legendary unlock starts fresh in next run")
	samples.sort()
	var timing: Dictionary = {"orders":samples.size(),"medianMs":samples[int(samples.size()*.5)],"p95Ms":samples[int(samples.size()*.95)],"maxMs":samples[-1],"scope":"Synchronous domain command timings, not FPS or human thinking time."}
	FileAccess.open(directory.path_join("domain-performance.json"),FileAccess.WRITE).store_string(JSON.stringify(timing,"\t"))
	write_reports()
	print("CLOSING_DONE "+JSON.stringify({"checks":checks,"orders":journal.size(),"cleared":state.cleared.size(),"phase":state.phase,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
