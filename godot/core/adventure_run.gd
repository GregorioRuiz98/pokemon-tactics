extends "res://core/economy_run.gd"

const NewRules = preload("res://core/adventure_battle.gd")
const Arenas = preload("res://core/adventure_maps.gd")

func _init(chapter_number: int = 25) -> void:
	super(chapter_number)
	if chapter_number<25: return
	engine = NewRules.new()
	progression = engine.progression
	progression.data.xpRewards = locations.map(func(l):return l.xp)

func create(campaign_seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(campaign_seed,starter)
	if chapter>=25 and not run.is_empty(): run.tacticalStats = empty_stats()
	return run

func empty_stats() -> Dictionary:
	return {"battles":0,"orders":0,"kos":0,"rounds":0,"distantMoves":0}

func average_level(run: Dictionary) -> float:
	if run.party.is_empty(): return 0
	var total: float = 0
	for member_data: Dictionary in run.party: total += member_data.level
	return total/run.party.size()

func training_quote(run: Dictionary, member_data: Dictionary) -> Dictionary:
	var quote: Dictionary = super.training_quote(run,member_data)
	if chapter>=25 and quote.ok and average_level(run)-member_data.level>=engine.scenarios.recovery.trainingGap:
		quote.discount = int(engine.scenarios.recovery.trainingDiscountPercent)
		quote.price = int(ceil(quote.price*(100-quote.discount)/100.0))
	return quote

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter<25: return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir.")
	var kind: String = command.get("kind","")
	if kind=="upgrade":
		if command.get("edition")!=21 or input.get("edition",1)<12 or input.get("edition",1)>=21 or input.phase not in ["map","shop","complete","ending"]: return fail("Actualiza entre combates desde una campaña compatible.")
		var run: Dictionary = input.duplicate(true)
		if input.edition<20:
			var conversion: Dictionary = load("res://core/economy_run.gd").new().transact(input,{"kind":"upgrade","edition":20,"at":input.revision})
			if not conversion.ok: return conversion
			run = conversion.state
		run.edition = 21; run.chapter = 25; run.tacticalStats = empty_stats()
		run.revision = input.revision+1
		return {"ok":true,"state":run}
	if kind in ["deploy","auto-deploy","start-battle"]:
		if input.phase!="battle" or not input.battle.get("deployment",false): return fail("No hay un despliegue pendiente.")
		var run: Dictionary = input.duplicate(true)
		if kind=="start-battle": engine.start_battle(run.battle)
		elif kind=="auto-deploy":
			var index: int = 0; var offset: int = int((int(run.mapSize)-16)/2.0)
			for unit: Dictionary in run.battle.units:
				if unit.team!="ally": continue
				unit.x = Arenas.ALLIES[index].x+offset; unit.y = Arenas.ALLIES[index].y+offset; index += 1
		else:
			if not command.get("member") is int and not command.get("member") is float: return fail("Elige un aliado válido.")
			if command.member!=int(command.member): return fail("Miembro no válido.")
			var selected: Dictionary = NewRules.unit_by_id(run.battle,int(command.member))
			var destination: Variant = command.get("destination")
			if selected.is_empty() or selected.team!="ally" or selected.hp<=0 or not destination is Dictionary or not engine._valid_point(run.battle,destination): return fail("Despliegue no válido.")
			if not run.battle.arena.deployment.any(func(p):return engine.Movement.same(p,destination)): return fail("Coloca al equipo dentro de la zona de despliegue.")
			var occupant: Dictionary = engine._at(run.battle,destination)
			if not occupant.is_empty(): occupant.x = selected.x; occupant.y = selected.y
			selected.x = destination.x; selected.y = destination.y
		run.battleInitial = run.battle.duplicate(true)
		run.revision += 1
		return {"ok":true,"state":run}
	if kind in ["battle","rectify"] and input.get("battle",{}).get("deployment",false): return fail("Confirma el despliegue antes de actuar.")
	var result: Dictionary = super.transact(input,command)
	if not result.ok: return result
	var updated: Dictionary = result.state
	if not updated.has("tacticalStats"): updated.tacticalStats = empty_stats()
	if kind=="battle":
		updated.tacticalStats.orders += 1
		for unit: Dictionary in input.battle.units:
			if unit.team!="ally" or unit.hp<=0: continue
			if NewRules.unit_by_id(updated.battle,int(unit.id)).hp<=0: updated.tacticalStats.kos += 1
		if command.order.kind=="move":
			var actor: Dictionary = NewRules.active(input.battle)
			if not NewRules.living(input.battle).any(func(u):return u.team!=actor.team and engine.Movement.distance(u,command.order.destination)<=6): updated.tacticalStats.distantMoves += 1
		if updated.phase in ["capture","ending","defeat"]:
			updated.tacticalStats.battles += 1; updated.tacticalStats.rounds += int(updated.battle.round)
		if updated.phase in ["capture","ending"]:
			var average: float = average_level(input)
			var reward: int = int(locations[int(updated.stage)].xp)
			for original: Dictionary in input.party:
				if not input.battle.units.any(func(u):return u.team=="ally" and u.id==original.id): continue
				var selected: Dictionary = target(updated,int(original.id))
				var percent: int = int(engine.scenarios.recovery.faintedPercent) if selected.hp<=0 else mini(int(engine.scenarios.recovery.maxBonusPercent),maxi(0,int(floor(average-original.level)))*int(engine.scenarios.recovery.behindPerLevelPercent))
				if percent<=0: continue
				var receipt: Dictionary = progression.recovery_award(selected,int(floor(reward*percent/100.0)))
				receipt.reason = "Recuperación · debilitado" if selected.hp<=0 else "Recuperación · rezagado"
				updated.lastProgress.append(receipt)
	return result
