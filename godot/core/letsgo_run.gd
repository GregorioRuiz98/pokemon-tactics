extends "res://core/growth_run.gd"

const LetsgoBattle = preload("res://core/letsgo_battle.gd")

func _init() -> void:
	super()
	engine = LetsgoBattle.new()
	progression = engine.progression
	shop_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/letsgo-shop.json"))

func create(seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(seed,starter)
	if not run.is_empty():
		run.edition = 5
		run.bag["leaf-stone"] = 0
	return run

func pick(run: Dictionary, table: String) -> int:
	var reward: Dictionary = ace(run)
	if not reward.is_empty():
		run.captureLevel = reward.level
		return int(reward.speciesId)
	var entries: Array = progression.data.encounters[table]
	var special: Array = entries.filter(func(e):return e.special)
	var pool: Array = entries.filter(func(e):return not e.special)
	if not special.is_empty() and Rng.next(run)<0.01: pool = special
	var entry: Dictionary = pool[int(floor(Rng.next(run)*pool.size()))]
	run.captureLevel = int(entry.minLevel)+int(floor(Rng.next(run)*(entry.maxLevel-entry.minLevel+1)))
	return int(entry.speciesId)

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("kind") not in ["buy-stone","stone"]: return super.transact(input,command)
	if command.get("at",-1)!=input.revision or input.phase!="shop": return fail("Usa la Piedra Hoja fuera de combate, en la tienda.")
	var run: Dictionary = input.duplicate(true)
	if command.kind=="buy-stone":
		if run.money<80: return fail("La Piedra Hoja cuesta 80 ₽.")
		run.money -= 80
		run.bag["leaf-stone"] += 1
	else:
		var identity: Variant = command.get("member")
		if not (identity is int or identity is float) or identity!=int(identity): return fail("Miembro no válido.")
		var member_data: Dictionary = target(run,int(identity))
		if member_data.is_empty() or member_data.hp<=0: return fail("Las bajas no pueden evolucionar.")
		var evolution: Array = progression.data.stoneEvolutions.get(str(int(member_data.speciesId)),[])
		if evolution.is_empty() or run.bag["leaf-stone"]<=0: return fail("Necesita Gloom o Weepinbell y una Piedra Hoja.")
		var previous: int = member_data.speciesId
		member_data.speciesId = int(evolution[0])
		var learned: Array = progression.learn(member_data)
		run.lastProgress = [{"member":member_data.id,"name":progression.species[int(member_data.speciesId)].name,"xp":0,"before":member_data.level,"level":member_data.level,"learned":learned,"evolutions":[{"from":previous,"to":member_data.speciesId,"level":member_data.level}]}]
		run.bag["leaf-stone"] -= 1
	run.revision += 1
	return {"ok":true,"state":run}
