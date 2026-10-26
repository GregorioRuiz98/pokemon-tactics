extends SceneTree

const Game = preload("res://core/adventure_run.gd")
const CampaignStore = preload("res://core/profile_campaign_store.gd")
const OldStore = preload("res://core/adventure_store.gd")
const Model = preload("res://core/trainer_profile.gd")
const Store = preload("res://core/trainer_store.gd")
var checks: int = 0
var failures: Array[String] = []
var directory: String

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); print("TRAINER_FAIL "+label)

func _initialize() -> void:
	call_deferred("test_all")

func test_all() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	var game: RefCounted = Game.new()
	var model: RefCounted = Model.new()
	var store: RefCounted = Store.new(directory.path_join("trainer-%d.json" % Time.get_ticks_usec()))
	check(store.load_profile().ok and store.save(model.data).ok,"Default profile created offline")
	check(Model.valid(store.load_profile().data),"Profile roundtrip validates")
	var campaign: RefCounted = CampaignStore.new(directory.path_join("trainer-campaign-%d.json" % Time.get_ticks_usec()))
	campaign.new_binding(model.data.id)
	var run: Dictionary = game.create("trainer-domain",1)
	var commands: Array = []
	check(campaign.save(run,commands,"").ok,"Campaign saves a separate stable binding")
	model.observe(campaign.campaign_id,run,campaign.profile_events)
	var snapshot: String = JSON.stringify(run,"",true,true)
	for step: int in 250:
		var command: Dictionary
		if run.phase=="map": command = {"kind":"enter","at":run.revision}
		elif run.phase=="battle" and run.battle.get("deployment",false): command = {"kind":"start-battle","at":run.revision}
		elif run.phase=="battle": command = {"kind":"battle","order":game.engine.choose_command(run.battle),"at":run.revision}
		else: break
		var result: Dictionary = game.transact(run,command)
		check(result.ok,"Natural accepted command "+str(step))
		if not result.ok: break
		var before: Dictionary = run; run = result.state
		var definition: Dictionary = {}
		if command.kind=="battle" and command.order.kind=="attack": definition = game.engine.profile(game.engine.active(before.battle)).action(game.engine.active(before.battle),command.order.actionId).definition
		var signature: String = JSON.stringify(run,"",true,true)
		campaign.record(game.engine,before,run,command,result.get("presentation",{}),definition,game.locations[int(run.stage)])
		check(JSON.stringify(run,"",true,true)==signature,"Achievement projection does not mutate domain or RNG")
		commands.append(command)
		check(campaign.save(run,commands,"").ok,"Accepted order and outbox persist together")
	check(run.phase=="capture","Natural opening wins")
	# Simulate interruption before applying the outbox to the profile.
	var recovered: RefCounted = CampaignStore.new(campaign.file_path)
	var loaded: Dictionary = recovered.load_campaign(game)
	check(loaded.ok and OldStore.equivalent(loaded.state,run),"Replay ignores additive profile metadata")
	check(recovered.campaign_id==campaign.campaign_id and not recovered.profile_events.is_empty(),"Outbox survives campaign-only commit")
	model.observe(recovered.campaign_id,run,recovered.profile_events)
	check(model.data.runs[recovered.campaign_id].battles==1 and model.data.runs[recovered.campaign_id].wins==1,"Interrupted victory reconciles once")
	model.observe(recovered.campaign_id,run,recovered.profile_events)
	check(model.data.runs[recovered.campaign_id].battles==1,"Loading the same outbox never doubles a victory")
	check(model.data.dex==[1] and run.seed=="trainer-domain","Profile registers only demonstrably obtained species")
	var second_id: String = Model.identity()
	model.observe(second_id,game.create("trainer-domain",1),[])
	check(model.data.runs.size()==2,"Same seed in a new campaign still creates a distinct history entry")
	model.abandon(second_id)
	check(model.data.runs[second_id].status=="abandoned" and model.data.runs[campaign.campaign_id].status=="active","Abandoning a run does not affect others")
	var historical: Dictionary = game.create("historical",4)
	historical.revision = 40; historical.medals = ["brock"]; historical.cleared = ["brock"]
	var unlocked: Array = model.observe("historical",historical,[])
	check("first-medal" in unlocked and "fire-starter" in unlocked and not model.data.unlocked.has("clean-gym"),"Retroactivity proves medals and starter, never invents no-KO events")
	check(model.customize("Ada",4,"Explorador de Kanto","leaf"),"Unlocked cosmetics are selectable")
	check(not model.customize("",4,"Campeón de Kanto","champion"),"Invalid name and locked rewards rejected")
	check(not model.customize("Ada",150,"Entrenador","amber"),"Unregistered portrait rejected")
	check(store.save(model.data).ok,"Progression stored outside campaign")
	var contender: RefCounted = Store.new(store.file_path); contender.load_profile()
	model.data.name = "Berta"; model.data.revision += 1
	check(store.save(model.data).ok and not contender.save(model.data).ok,"Concurrent profile write detected")
	var damaged_file: FileAccess = FileAccess.open(store.file_path,FileAccess.WRITE)
	damaged_file.store_string("damaged"); damaged_file.flush(); damaged_file.close()
	var broken: RefCounted = Store.new(store.file_path)
	var fallback: Dictionary = broken.load_profile()
	check(not fallback.ok and not fallback.data.is_empty() and broken.blocked,"Corruption exposes valid backup without overwriting original")
	check(not broken.save(fallback.data).ok and FileAccess.get_file_as_string(store.file_path)=="damaged","Normal saves preserve corrupt file")
	var restoration: Dictionary = broken.save(fallback.data,true)
	if not restoration.ok: print("RESTORATION "+JSON.stringify(restoration))
	var restored: Dictionary = Store.new(store.file_path).load_profile()
	check(restoration.ok and restored.ok,"Explicit recovery preserves damaged copy and restores profile")
	var legacy_path: String = directory.path_join("legacy-trainer-%d.json" % Time.get_ticks_usec())
	var legacy: RefCounted = OldStore.new(legacy_path)
	var initial: Dictionary = game.create("legacy-profile",7)
	check(legacy.save(initial,[],"").ok,"Published campaign without metadata created")
	var adapter: RefCounted = CampaignStore.new(legacy_path)
	check(adapter.load_campaign(game).ok and adapter.campaign_id.begins_with("legacy-"),"Legacy campaign adopts stable identity without resetting")
	var legacy_id: String = adapter.campaign_id
	check(adapter.save(initial,[],"").ok and CampaignStore.new(legacy_path).load_campaign(game).ok,"Binding can persist without any gameplay order")
	adapter.load_campaign(game); check(adapter.campaign_id==legacy_id,"Legacy identity survives binding and reload")
	check(not CampaignStore.valid_meta({"campaignId":"x","profileId":"y","events":[{"revision":1,"flags":["fake"],"species":[]}],"tracker":{"known":true,"kos":0}},1),"Unknown event identifiers rejected")
	check(not Model.valid({"schema":"trainer","version":1}),"Incomplete profile rejected")
	for flag: String in Model.ACHIEVEMENTS:
		check(model.unlock(flag,"fixture") or model.data.unlocked.has(flag),"Each stable achievement can be stored: "+flag)
		check(not model.unlock(flag,"fixture"),"Each achievement unlocks at most once: "+flag)
	check(snapshot!=JSON.stringify(run,"",true,true),"Natural test actually advanced gameplay")
	tactical_probes(game)
	var report: Dictionary = {"checks":checks,"failures":failures,"naturalPhase":run.phase,"profileSchema":1,"campaignEdition":run.edition,"scope":"Natural Route1, separate persistence/outbox, duplicate/recovery/concurrent/legacy cases; cosmetics and retroactivity fixtures."}
	FileAccess.open(directory.path_join("trainer-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report)); quit(0 if failures.is_empty() else 1)

func tactical_fixture(game: RefCounted, move: String) -> Dictionary:
	var run: Dictionary = game.create("trainer-prepared-tactics",1)
	run.phase = "battle"; run.battle = game.engine.encounter(run,game.locations[0])
	run.battle.deployment = false; run.battle.board = []; run.battle.heights = []
	for y: int in 16:
		var row: Array = []; var heights: Array = []
		for x: int in 16: row.append(0); heights.append(0)
		run.battle.board.append(row); run.battle.heights.append(heights)
	var ally: Dictionary = run.battle.units.filter(func(u):return u.team=="ally")[0]
	var enemy: Dictionary = run.battle.units.filter(func(u):return u.team=="enemy")[0]
	ally.x = 3; ally.y = 3; ally.moves = [move]; ally.tp = 5; ally.ability = "no-guard"
	enemy.x = 4; enemy.y = 3; enemy.hp = 500; enemy.maxHp = 500; enemy.ability = "none"
	run.battle.queue = [ally.id,enemy.id]; run.battle.fields = []; run.battle.moved = false; run.battle.acted = false
	return run

func tactical_probes(game: RefCounted) -> void:
	for move: String in ["gust","roar"]:
		var before: Dictionary = tactical_fixture(game,move)
		var actor: Dictionary = game.engine.active(before.battle)
		var target: Dictionary = before.battle.units.filter(func(u):return u.team=="enemy")[0]
		var definition: Dictionary = game.engine.profile(actor).action(actor,move).definition
		var plan: Dictionary = game.engine.cast_plan(before.battle,target,move)
		check(plan.ok,"Prepared tactical action legal: "+move)
		if not plan.ok: continue
		var point: Dictionary = target
		if move=="roar":
			var hits: Array = plan.hits.filter(func(h):return h.targetId==target.id and h.push!=null)
			check(not hits.is_empty(),"Roar has a real displacement destination")
			if hits.is_empty(): continue
			point = hits[0].push
		before.battle.fields.append({"x":point.x,"y":point.y,"kind":"smoke" if move=="gust" else "rocks","expires":999,"source":0,"zone":1,"chance":100})
		var action_command: Dictionary = {"kind":"battle","order":{"kind":"attack","actionId":move,"target":target.id,"aim":{"x":target.x,"y":target.y,"axis":0,"throwFacing":0}},"at":before.revision}
		var result: Dictionary = game.transact(before,action_command)
		check(result.ok,"Prepared tactical action resolves: "+move)
		if not result.ok: continue
		var action_tracker: RefCounted = CampaignStore.new()
		action_tracker.record(game.engine,before,result.state,action_command,result.get("presentation",{}),definition)
		var expected: String = "clear-smoke" if move=="gust" else "trap-push"
		check(action_tracker.profile_events.any(func(e):return expected in e.flags),"Achievement derives from actual zone interaction: "+expected)
	var initial: Dictionary = tactical_fixture(game,"gust")
	var outcome: Dictionary = initial.duplicate(true)
	outcome.phase = "capture"; outcome.revision += 1
	outcome.battle.mission = {"kind":"protect","health":4}
	var command: Dictionary = {"kind":"battle","order":{"kind":"finish"}}
	var tracker: RefCounted = CampaignStore.new(); tracker.tracker = {"known":true,"kos":0}
	tracker.record(game.engine,initial,outcome,command,{}, {},{"leader":true})
	check("clean-gym" in tracker.profile_events[0].flags and "fuji-perfect" in tracker.profile_events[0].flags,"Prepared victory predicates: no KO and intact protection")
	tracker = CampaignStore.new(); tracker.tracker = {"known":false,"kos":0}
	outcome.battle.mission.health = 3
	tracker.record(game.engine,initial,outcome,command,{}, {},{"leader":true})
	check(not tracker.profile_events[0].flags.has("clean-gym") and not tracker.profile_events[0].flags.has("fuji-perfect"),"Unknown historical KO count or damaged protection does not unlock")
	outcome.battle.mission = {"kind":"secure","points":[{"x":1,"y":1},{"x":2,"y":1}],"captured":["1,1","2,1"]}
	tracker = CampaignStore.new(); tracker.record(game.engine,initial,outcome,command,{}, {})
	check("rocket-terminals" in tracker.profile_events[0].flags,"Both terminals required")
	outcome.battle.mission.captured = ["1,1"]
	tracker = CampaignStore.new(); tracker.record(game.engine,initial,outcome,command,{}, {})
	check(not tracker.profile_events[0].flags.has("rocket-terminals"),"Kill-all or incomplete terminals does not claim terminal achievement")
	var model: RefCounted = Model.new()
	for path: String in ["birds","psychic"]:
		var ending: Dictionary = game.create("ending-fixture",1); ending.phase = "ending"; ending.mainComplete = true; ending.finalPath = path
		model.observe(path,ending,[])
		check(model.data.unlocked.has(path) and model.data.unlocked.has("champion"),"Separate completed ending proves achievement: "+path)
