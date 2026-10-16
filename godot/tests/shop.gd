extends SceneTree

const Campaign = preload("res://core/shop_run.gd")
const Store = preload("res://core/kanto_store.gd")
var rules: Campaign = Campaign.new()
var failures: Array[String] = []
var checks: int = 0
var run: Dictionary = {}
var journal: Array = []
var directory: String = ""
var probe: Dictionary = {}

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func act(command: Dictionary) -> bool:
	command.at = run.revision
	var before: Dictionary = run.duplicate(true)
	var result: Dictionary = rules.transact(run,command)
	check(Store.equivalent(before,run),"Transaction leaves input unchanged")
	if not result.ok: return false
	run = result.state
	journal.append(command.duplicate(true))
	return true

func controls() -> void:
	run = rules.create("shop-controls",4)
	run.phase = "shop"
	run.money = 1000
	rules.roll_stock(run,true)
	check(run.stock.size()==3 and run.stock[0].item=="tm-brick-break","Three offers and guaranteed early Charmander coverage")
	var offer: String = run.stock[0].item
	check(act({"kind":"buy-stock","slot":0}),"Buy TM")
	check(run.money==920 and run.bag[offer]==1 and run.stock[0].sold,"Purchase one copy into bag")
	check(not act({"kind":"buy-stock","slot":0}),"Sold slot cannot be bought twice")
	check(act({"kind":"teach","member":1,"item":offer}),"Charmander learns compatible TM")
	check("brick-break" in run.party[0].moves and run.bag[offer]==0,"TM consumed, free slot prepared")
	run.bag[offer] = 1
	check(not act({"kind":"teach","member":1,"item":offer}) and run.bag[offer]==1,"Already learned TM does not consume copy")
	run.bag["tm-water-pulse"] = 1
	check(not act({"kind":"teach","member":1,"item":"tm-water-pulse"}) and run.bag["tm-water-pulse"]==1,"Incompatible TM rejected without consumption")
	var rng: int = run.rng
	for cost: int in [25,50,75]:
		var money: int = run.money
		check(rules.reroll_price(run)==cost and act({"kind":"reroll"}),"Escalating reroll accepted")
		check(run.money==money-cost and run.stock.size()==3 and not run.stock.any(func(s):return s.sold),"Reroll charges once and restores three unique slots")
		check(run.stock[0].item!=run.stock[1].item and run.stock[0].item!=run.stock[2].item and run.stock[1].item!=run.stock[2].item,"No duplicate offers")
	check(run.rng==rng,"Shop random draws do not change route capture RNG")
	check(not rules.transact(run,{"kind":"reroll","at":run.revision-1}).ok,"Stale reroll callback cannot charge twice")
	for item: String in ["life-orb","leftovers"]: run.bag[item] = 1
	check(act({"kind":"equip","member":1,"item":"life-orb"}),"Equip Life Orb")
	check(act({"kind":"equip","member":1,"item":"leftovers"}),"Replace one held item")
	check(run.bag["life-orb"]==1 and run.bag.leftovers==0,"Replacing returns previous item to bag")
	check(act({"kind":"equip","member":1,"item":""}) and run.bag.leftovers==1,"Unequip returns item")
	for bad: Dictionary in [{"kind":"buy-stock","slot":0.5},{"kind":"buy-stock","slot":[]},{"kind":"equip","member":1,"item":{}},{"kind":"teach","member":1.2,"item":offer}]: check(not act(bad),"Malformed shop command rejected")
	run.money = 0
	var before: Dictionary = run.duplicate(true)
	check(not act({"kind":"reroll"}) and Store.equivalent(before,run),"Unaffordable reroll changes nothing")
	run.phase = "battle"
	for kind: String in ["equip","teach","reroll","buy-stock"]: check(not act({"kind":kind,"member":1,"item":"life-orb","slot":0}),"No shop operation during battle")
	run.phase = "shop"
	run.party[0].hp = 0
	check(not act({"kind":"equip","member":1,"item":"life-orb"}),"Dead member cannot equip")
	# Four prepared moves stay four when a new TM is learned.
	run.party[0] = rules.progression.create_member(1,4,"QA",40)
	run.bag[offer] = 1
	check(act({"kind":"teach","member":1,"item":offer}) and run.party[0].moves.size()==4 and "brick-break" in run.party[0].knownMoves,"TM goes to library when loadout is full")

func battle_fixture(species_id: int = 4) -> Dictionary:
	var state: Dictionary = rules.engine.encounter(rules.create("orb",4),rules.locations[0])
	var member: Dictionary = rules.progression.create_member(1,species_id,"QA",13)
	member.heldItem = "life-orb"
	state.units[0] = rules.engine.member_unit(member,{"x":2,"y":7})
	state.units[1].x = 3
	state.units[1].y = 7
	state.units[1].facing = 2
	state.queue = [1,10000]
	return state

func combat_controls() -> void:
	var state: Dictionary = battle_fixture()
	var actor: Dictionary = state.units[0]
	var target: Dictionary = state.units[1]
	var action: RefCounted = rules.engine.profile(actor).action(actor,"ember")
	var plain: Dictionary = actor.duplicate(true)
	plain.heldItem = null
	var normal: int = action.preview(plain,target).damage
	var boosted: int = action.preview(actor,target).damage
	check(boosted==mini(target.hp,int(floor(normal*1.3+0.5))),"Life Orb preview boosts real damage by 30%")
	var hp: int = actor.hp
	var result: Dictionary = rules.engine.attack(state,10000,"ember")
	check(result.ok and result.hits[0].damage==boosted and result.state.units[0].hp==hp-int(floor(actor.maxHp/10.0)),"Preview matches resolution; one recoil per damaging action")
	check(state.units[0].hp==hp,"Orb resolution leaves source untouched")
	state.units[0].hp = 1
	state.units[1].hp = 999
	result = rules.engine.attack(state,10000,"ember")
	check(result.ok and result.state.units[0].hp==0 and result.state.outcome=="defeat","Recoil can KO holder and end campaign")
	state.units[1].hp = 1
	result = rules.engine.attack(state,10000,"ember")
	check(result.ok and result.state.outcome=="defeat","Simultaneous last KOs count as team defeat")
	check("Victoria: zona despejada." not in result.state.log,"No premature victory message before lethal recoil")
	state = battle_fixture(25)
	state.units[1].types = ["ground"]
	hp = state.units[0].hp
	result = rules.engine.attack(state,10000,"thunder-shock")
	check(result.ok and result.hits[0].damage==0 and result.state.units[0].hp==hp,"Immunity causes no Life Orb recoil")
	state = battle_fixture()
	state.units[1].facing = 6
	var missed: bool = false
	for seed: int in range(50):
		state.rng = seed
		result = rules.engine.attack(state,10000,"ember")
		if not result.hits[0].hit:
			missed = true
			check(result.state.units[0].hp==state.units[0].hp,"Miss causes no Life Orb recoil")
			break
	check(missed,"Real RNG miss tested")
	state = battle_fixture()
	hp = state.units[0].hp
	result = rules.engine.attack(state,10000,"growl")
	check(result.ok and result.state.units[0].hp==hp,"Status action causes no Life Orb recoil")
	state.units[0].heldItem = "leftovers"
	state.units[0].hp = 20
	result = rules.engine.finish(state,4)
	check(result.ok and result.state.units[0].hp==20+int(floor(state.units[0].maxHp/16.0)),"Leftovers heals at end of activation")
	state = battle_fixture()
	state.units[0].moves.append("flame-burst")
	state.units[0].tp = 5
	state.board[6][3] = 0
	var extra: Dictionary = state.units[1].duplicate(true)
	extra.id = 10001
	extra.y = 6
	extra.hp = 999
	extra.facing = 2
	state.units.append(extra)
	state.units[1].hp = 999
	state.queue.append(10001)
	hp = state.units[0].hp
	result = rules.engine.attack(state,10000,"flame-burst")
	check(result.ok and result.hits.filter(func(hit):return not hit.get("recoil",false) and hit.hit and hit.damage>0).size()==2 and result.state.units[0].hp==hp-int(floor(state.units[0].maxHp/10.0)),"Area attack applies Life Orb recoil once for multiple hits")
	state = battle_fixture()
	state.units[0].hp = 1
	state.units[1].hp = 999
	var support: Dictionary = state.units[0].duplicate(true)
	support.id = 2
	support.hp = 50
	support.x = 1
	support.heldItem = null
	state.units.append(support)
	state.queue = [1,2,10000]
	result = rules.engine.attack(state,10000,"ember")
	check(result.ok and result.state.outcome=="playing" and rules.engine.active(result.state).id==2 and not result.state.acted and not result.state.moved,"Recoil KO immediately begins next living unit's activation")
	run = rules.create("fallen-item",4)
	run.phase = "battle"
	run.battle = battle_fixture()
	run.battle.units[0].hp = 1
	run.battle.units[1].hp = 1
	run.party[0].heldItem = "life-orb"
	check(act({"kind":"battle","order":{"kind":"attack","target":10000,"actionId":"ember"}}),"Resolve holder's final KO through campaign")
	check(run.phase=="defeat" and run.party[0].heldItem==null and run.bag["life-orb"]==1,"Fallen holder returns equipment to bag exactly once")
	# Existing mechanics are now reachable through campaign inventory.
	state.units[0].heldItem = "assault-vest"
	check(not rules.engine.attack_plan(state,10000,{},"growl").ok,"Assault Vest blocks support moves")
	state.units[0].heldItem = "heavy-duty-boots"
	check(rules.engine.field_damage(state.units[0],[{"x":2,"y":7,"kind":"embers"}])==0,"Boots prevent ember tile damage")
	var charmander: Dictionary = rules.engine.member_unit(rules.progression.create_member(1,4,"QA",13))
	var onix: Dictionary = rules.engine.member_unit(rules.progression.create_member(2,95,"QA",14))
	check("metal-claw" in charmander.moves,"Garra Metal learned/prepared before Brock")
	var metal: Dictionary = rules.engine.profile(charmander).action(charmander,"metal-claw").preview(charmander,onix)
	var ember: Dictionary = rules.engine.profile(charmander).action(charmander,"ember").preview(charmander,onix)
	charmander.moves.append("brick-break")
	var brick: Dictionary = rules.engine.profile(charmander).action(charmander,"brick-break").preview(charmander,onix)
	probe = {"charmanderLevel":13,"onixLevel":14,"onixHp":onix.hp,"ember":ember.damage,"metalClaw":metal.damage,"brickBreak":brick.damage}
	check(metal.multiplier==2 and brick.multiplier==2 and metal.damage>ember.damage and brick.damage>metal.damage,"Steel and Fighting coverage outperform resisted Fire against Onix")

func heal_team() -> void:
	for entry: Dictionary in run.party:
		if entry.hp<=0: continue
		var member: Dictionary = rules.target(run,int(entry.id))
		while member.hp<rules.engine.member_unit(member).maxHp-10:
			if run.bag.potion==0 and run.money>=40: act({"kind":"buy","item":"potion"})
			if run.bag.potion==0: break
			act({"kind":"heal","member":member.id,"item":"potion"})
			member = rules.target(run,int(entry.id))

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	if directory.is_empty(): quit(1); return
	controls()
	combat_controls()
	var previous: RefCounted = load("res://core/progression_run.gd").new()
	var old_order: Dictionary = {"kind":"enter","at":0}
	var old: Dictionary = previous.transact(previous.create("edition-2",4),old_order)
	var legacy_save: Store = Store.new(directory.path_join("shop-legacy-2.json"))
	check(legacy_save.save(old.state,[old_order],"").ok,"Save edition 2")
	var old_loaded: Dictionary = legacy_save.load_campaign(rules)
	check(old_loaded.ok and old_loaded.state.edition==2 and Store.equivalent(old.state,old_loaded.state),"Edition 2 battle replays without changing RNG or adding shop rules")
	var outcomes: Array = []
	for starter: int in [1,4,7]:
		run = rules.create("kanto-14",starter)
		journal = []
		var archive: Store = Store.new(directory.path_join("shop-%d.json" % starter))
		for step: int in 1500:
			if run.phase in ["complete","defeat"]: break
			match run.phase:
				"map": check(act({"kind":"enter"}),"Enter encounter")
				"battle":
					var order: Dictionary = rules.engine.choose_command(run.battle)
					# One explicit tactical policy: soften Brock's physical attacks before trading blows.
					var active: Dictionary = rules.engine.active(run.battle)
					if starter==4 and run.stage==3 and active.team=="ally" and active.speciesId==4 and not run.battle.acted:
						for enemy: Dictionary in rules.engine.living(run.battle):
							if enemy.team=="enemy" and enemy.stages.get("attack",0)>-2 and rules.engine.attack_plan(run.battle,int(enemy.id),{},"growl").ok:
								order = {"kind":"attack","target":enemy.id,"actionId":"growl"}
								break
					check(act({"kind":"battle","order":order}),"Legal shared battle command")
				"capture":
					if run.stage==3:
						check(run.reward.speciesId==95 and run.reward.level==14 and "insignia" in run.reward.origin,"Brock awards highest-level ace Onix, never forest Weedle")
						check("Medalla Roca" in run.medals,"Badge retained")
					check(archive.save(run,journal,"").ok,"Save pending reward")
					var restored: Dictionary = archive.load_campaign(rules)
					check(restored.ok and Store.equivalent(restored.state,run),"Reward and all campaign RNG replay exactly")
					check(act({"kind":"capture"}),"Claim reward once")
				"shop":
					check(run.stock.size()==3 and run.rerolls==0,"New shop gets three offers and resets reroll price")
					if starter==4 and run.stage==0:
						check(act({"kind":"buy-stock","slot":0}) and act({"kind":"teach","member":1,"item":"tm-brick-break"}),"Buy and prepare early Charmander coverage")
					heal_team()
					check(archive.save(run,journal,"").ok,"Save shop")
					var restored: Dictionary = archive.load_campaign(rules)
					check(restored.ok and Store.equivalent(restored.state,run),"Stock and purchase persist without reroll")
					check(act({"kind":"continue"}),"Continue journey")
		check(run.phase in ["complete","defeat"],"Run finishes within budget")
		outcomes.append({"starter":starter,"phase":run.phase,"cleared":run.cleared.size(),"transactions":journal.size(),"party":run.party.map(func(m):return {"speciesId":m.speciesId,"level":m.level,"hp":m.hp}),"lastLog":run.battle.log.slice(-10)})
	check(outcomes.any(func(outcome):return outcome.phase=="complete"),"Sample still completes and exercises Brock's ace reward")
	var output: Dictionary = {"checks":checks,"probe":probe,"runs":outcomes,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("shop-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
