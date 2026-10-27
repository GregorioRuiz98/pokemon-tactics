extends "res://core/sleep_run.gd"

const Climate = preload("res://core/climate_context.gd")

func _init(chapter_number: int = 29) -> void:
	super(chapter_number)
	if chapter_number<29: return
	engine = preload("res://core/climate_battle.gd").new(); progression = engine.progression
	progression.data.xpRewards = locations.map(func(l):return l.xp)
	for identity: String in progression.climate.moves:
		var move: Dictionary = progression.data.moves[identity]
		shop_data.items["tm-"+identity] = {"name":"MT · "+move.name,"kind":"tm","move":identity,"price":80,"species":progression.climate.compatible[identity],"description":move.description}

func _genders(run: Dictionary) -> void:
	var owned_members: Array = run.party+run.reserve
	if not run.reward.is_empty(): owned_members.append(run.reward)
	for owned: Dictionary in owned_members:
		if not owned.has("gender"): owned.gender = Climate.gender(run.seed,owned,progression.climate.genderRates)

func create(campaign_seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(campaign_seed,starter)
	if chapter>=29 and not run.is_empty(): _genders(run)
	return run

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter<29: return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir.")
	if command.get("kind")=="upgrade":
		if command.get("edition")!=25 or input.get("edition",1)<12 or input.edition>=25 or input.phase not in ["map","shop","complete","ending"]: return fail("Actualiza climas y habilidades entre encuentros.")
		var next: Dictionary = input.duplicate(true)
		if input.edition<24:
			var conversion: Dictionary = preload("res://core/sleep_run.gd").new().transact(input,{"kind":"upgrade","edition":24,"at":input.revision})
			if not conversion.ok: return conversion
			next = conversion.state
		next.edition = 25; next.chapter = 29; next.revision = input.revision+1
		_genders(next); _fill_bag(next)
		for owned: Dictionary in next.party+next.reserve:
			var prepared: Array = owned.moves.duplicate()
			progression.learn(owned); owned.moves = prepared
		return {"ok":true,"state":next}
	var result: Dictionary = super.transact(input,command)
	if not result.ok: return result
	_genders(result.state)
	if command.get("kind")=="enter": result.state.erase("pickupReward")
	if command.get("kind")=="battle" and input.phase=="battle" and result.state.cleared.size()>input.cleared.size():
		result.state.erase("pickupReward")
		var battle: Dictionary = result.state.battle
		var collectors: Array = battle.units.filter(func(u):return u.team=="ally" and u.hp>0 and Climate.ability(battle,u)=="pickup")
		if not collectors.is_empty():
			# Separate, deterministic loot stream; cannot reroll by loading/revisiting.
			var roll: Dictionary = {"rng":Rng.hash_seed(input.seed+"/pickup/"+str(input.stage))}
			if Rng.next(roll)<.25:
				result.state.bag.potion += 1; result.state.pickupReward = "potion"
				preload("res://core/battle.gd").note(battle,"Recogida: una Poción añadida a la bolsa.")
	return result
