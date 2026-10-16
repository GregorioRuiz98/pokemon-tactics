extends "res://core/kanto_run.gd"

const ProgressBattle = preload("res://core/progression_battle.gd")
const Study = preload("res://core/progression.gd")
var progression: Study = Study.new()

func _init() -> void:
	engine = ProgressBattle.new()

func create(seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(seed,starter)
	if run.is_empty(): return run
	run.edition = 2
	run.lastProgress = []
	run.captureLevel = 5
	return run

func member(identity: int, species_id: int, origin: String) -> Dictionary:
	return progression.create_member(identity,species_id,origin,5)

func pick(run: Dictionary, table: String) -> int:
	var slots: Array = []
	for entry: Dictionary in engine.catalog.slots:
		if entry.id == table: slots = entry.slots
	var roll: int = int(floor(Rng.next(run)*256))
	for i: int in slots.size():
		roll -= int(engine.catalog.slotWeights[i])
		if roll < 0:
			run.captureLevel = int(slots[i].level)
			return int(slots[i].speciesId)
	return -1

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("at",-1) != input.revision: return fail("Esa opción pertenece a una pantalla anterior.")
	if not command.get("kind") is String: return fail("Orden de campaña no válida.")
	var kind: String = command.kind
	if kind in ["buy","heal"] and not command.get("item") is String: return fail("Objeto no válido.")
	if kind == "train": return fail("Las estadísticas suben con los niveles. No se entrenan con dinero.")
	if kind in ["loadout","evolve"]:
		if input.phase not in ["map","shop","complete"]: return fail("Prepara los movimientos o evoluciona fuera del combate y tras reclamar la captura.")
		var identity: Variant = command.get("member")
		if not (identity is int or identity is float) or identity != int(identity): return fail("Miembro no válido.")
		var run: Dictionary = input.duplicate(true)
		var selected: Dictionary = target(run,int(identity))
		if selected.is_empty() or selected.hp <= 0: return fail("Las bajas no pueden aprender ni evolucionar.")
		if kind == "loadout":
			var moves: Variant = command.get("moves")
			if not moves is Array or moves.size() > 4: return fail("Puedes preparar hasta cuatro movimientos, además del básico neutro.")
			var unique: Array = []
			for move: Variant in moves:
				if not move is String or move not in selected.knownMoves or move in unique or move == "basic": return fail("Movimiento no aprendido o repetido.")
				unique.append(move)
			selected.moves = unique
		else:
			var evolution: Dictionary = progression.evolution(selected)
			if evolution.is_empty(): return fail("Esta especie no tiene otra evolución de Kanto.")
			if selected.level < evolution.level: return fail("Necesita nivel %d y un Caramelo Raro." % evolution.level)
			if run.bag["rare-candy"] <= 0: return fail("Falta un Caramelo Raro.")
			selected.speciesId = evolution.speciesId
			selected.hp = mini(selected.hp,progression.stats(int(selected.speciesId),int(selected.level)).maxHp)
			var learned: Array = progression.learn(selected)
			run.lastProgress = [{"member":selected.id,"name":progression.species[int(selected.speciesId)].name,"xp":0,"before":selected.level,"level":selected.level,"learned":learned,"evolved":true}]
			run.bag["rare-candy"] -= 1
		run.revision += 1
		return {"ok":true,"state":run}
	var result: Dictionary = super.transact(input,command)
	if not result.ok: return result
	var run: Dictionary = result.state
	if input.phase == "battle" and run.phase == "capture":
		run.lastProgress = []
		for survivor: Dictionary in run.party:
			if survivor.hp > 0: run.lastProgress.append(progression.award(survivor,int(progression.data.xpRewards[int(run.stage)])))
		run.reward = progression.create_member(int(run.nextId),int(run.reward.speciesId),run.reward.origin,int(run.captureLevel))
	return result
