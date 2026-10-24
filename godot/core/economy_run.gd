extends "res://core/spatial_run.gd"

const BattleRules = preload("res://core/economy_battle.gd")
const RETIRED: Array[String] = ["rare-candy","leaf-stone","fire-stone","water-stone","thunder-stone","moon-stone","link-cable"]

func _init(chapter_number: int = 24) -> void:
	super(chapter_number)
	if chapter_number<24: return
	engine = BattleRules.new()
	progression = engine.progression
	locations = JSON.parse_string(FileAccess.get_file_as_string("res://data/journey-24.json"))
	progression.data.xpRewards = locations.map(func(location):return location.xp)
	for item: String in RETIRED: consumables.erase(item)

func create(campaign_seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(campaign_seed,starter)
	if chapter>=24 and not run.is_empty():
		for item: String in RETIRED: run.bag[item] = 0
		run.captureRerolls = 0
	return run

func training_quote(run: Dictionary, member_data: Dictionary) -> Dictionary:
	if member_data.is_empty(): return {"ok":false,"reason":"Elige un Pokémon."}
	if run.phase!="shop" or member_data.hp<=0: return {"ok":false,"reason":"Entrena en la tienda con un Pokémon en pie."}
	if member_data.level>=level_cap(run): return {"ok":false,"reason":"Límite actual: nivel %d." % level_cap(run)}
	var points: int = maxi(0,progression.member_next_xp(member_data)-int(member_data.xp))
	var rate: int = int(progression.economy.trainingExpPerDollar)
	var cost: int = int(ceil(float(points)/rate))
	return {"ok":true,"points":points,"price":cost,"rate":rate,"level":member_data.level,"xp":member_data.xp}

func capture_options(run: Dictionary) -> Array:
	if run.phase!="capture" or run.reward.is_empty() or not ace(run).is_empty(): return []
	var table: String = locations[int(run.stage)].captureTable
	return progression.data.encounters[table].filter(func(e):return not e.special and int(e.speciesId)!=int(run.reward.speciesId) and not progression.species[int(e.speciesId)].legendary and not progression.species[int(e.speciesId)].mythical)

func capture_price(run: Dictionary) -> int:
	return int(progression.economy.captureRerollBase)*(int(run.get("captureRerolls",0))+1)

func pick(run: Dictionary, table: String) -> int:
	var species_id: int = super.pick(run,table)
	if chapter>=24 and ace(run).is_empty() and not locations[int(run.stage)].get("finale",false):
		var location: Dictionary = locations[int(run.stage)]
		run.captureLevel = mini(level_cap(run),int(location.captureMinLevel)+int(floor(Rng.next(run)*(int(location.captureMaxLevel)-int(location.captureMinLevel)+1))))
	return species_id

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter<24: return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir.")
	var kind: Variant = command.get("kind")
	if kind in ["level-up","use-evolution","stone","buy-stone"] or (kind=="buy" and command.get("item") in RETIRED): return fail("Caramelos, piedras y cables retirados: usa entrenamiento por EXP o evolución gratuita en la ficha.")
	if kind in ["train-xp","evolve-free"]:
		var identity: Variant = command.get("member")
		if not (identity is int or identity is float) or identity!=int(identity): return fail("Miembro no válido.")
		var run: Dictionary = input.duplicate(true)
		var selected: Dictionary = target(run,int(identity))
		if selected.is_empty() or selected.hp<=0: return fail("Necesita un Pokémon en pie.")
		if kind=="train-xp":
			var quote: Dictionary = training_quote(run,selected)
			if not quote.ok: return fail(quote.reason)
			if command.get("price")!=quote.price or command.get("points")!=quote.points: return fail("El precio o la EXP han cambiado; revisa el entrenamiento.")
			if run.money<quote.price: return fail("No tienes suficientes pokédolares.")
			progression.gym_cap = level_cap(run)
			run.money -= int(quote.price)
			run.lastProgress = [progression.award(selected,int(quote.points))]
		else:
			if run.phase not in ["map","shop","complete"]: return fail("Evoluciona fuera de combate y tras aceptar la captura.")
			var choices: Array = progression.free_evolutions(selected).filter(func(e):return e[0]==command.get("species"))
			if choices.is_empty() or selected.level<int(choices[0][1]): return fail("No alcanza el nivel mínimo de esa evolución.")
			var previous: int = selected.speciesId
			selected.speciesId = int(choices[0][0])
			selected.hp = mini(selected.hp,progression.member_stats(selected).maxHp)
			var learned: Array = progression.learn(selected)
			run.lastProgress = [{"member":selected.id,"name":progression.species[int(selected.speciesId)].name,"xp":0,"before":selected.level,"level":selected.level,"hpGain":0,"learned":learned,"evolutions":[{"from":previous,"to":selected.speciesId,"level":selected.level}]}]
		run.revision += 1
		return {"ok":true,"state":run}
	if kind=="reroll-capture":
		var choices: Array = capture_options(input)
		var cost: int = capture_price(input)
		if choices.is_empty(): return fail("Esta recompensa no permite otro sorteo; las insignias son fijas.")
		if input.money<cost: return fail("No tienes suficientes pokédolares para repetir el sorteo.")
		var run: Dictionary = input.duplicate(true)
		var entry: Dictionary = choices[int(floor(Rng.next(run)*choices.size()))]
		run.reward = progression.create_member(int(run.nextId),int(entry.speciesId),run.reward.origin,int(run.reward.level))
		progression.assign(run.reward,run.seed+"/capture-reroll/"+str(int(run.get("captureRerolls",0))+1))
		run.money -= cost
		run.captureRerolls = int(run.get("captureRerolls",0))+1
		run.revision += 1
		return {"ok":true,"state":run}
	var result: Dictionary = super.transact(input,command)
	if not result.ok: return result
	if kind=="upgrade":
		var old_study: RefCounted = load("res://core/spatial_study.gd").new()
		for member_data: Dictionary in members(result.state):
			var old_needed: int = old_study.next_xp(int(member_data.level))
			var fraction: float = clampf(float(member_data.xp)/maxi(1,old_needed),0,0.999999)
			member_data.xp = int(floor(fraction*progression.member_next_xp(member_data))) if member_data.level<100 else 0
		var refund: int = 0
		for item: String in RETIRED:
			refund += int(result.state.bag.get(item,0))*(25 if item=="rare-candy" else 80)
			result.state.bag[item] = 0
		result.state.money += refund
		result.state.economyRefund = refund
		result.state.captureRerolls = 0
	if (kind=="battle" and result.state.phase=="capture") or kind=="capture": result.state.captureRerolls = 0
	return result
