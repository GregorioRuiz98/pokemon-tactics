extends "res://core/scale_run.gd"

const TEAM_LIMIT: int = 6

func create(campaign_seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(campaign_seed,starter)
	if not run.is_empty():
		run.edition = 12
		run.reserve = []
	return run

func members(run: Dictionary) -> Array:
	return run.party + run.get("reserve",[])

func target(run: Dictionary, identity: int) -> Dictionary:
	for member_data: Dictionary in members(run):
		if member_data.id == identity: return member_data
	return {}

func member_index(collection: Array, identity: Variant) -> int:
	if not (identity is int or identity is float) or identity != int(identity): return -1
	for index: int in collection.size():
		if collection[index].id == identity: return index
	return -1

func roll_stock(run: Dictionary, first: bool = false) -> void:
	# Shop compatibility includes owned reserves, without deploying or awarding EXP to them.
	var view: Dictionary = run.duplicate(true)
	view.party = members(run)
	super.roll_stock(view,first)
	run.stock = view.stock
	run.shopRandom = view.shopRandom

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("at",-1) != input.revision: return fail("Esa opción pertenece a una pantalla anterior.")
	var kind: Variant = command.get("kind")
	if kind in ["deposit","withdraw","swap"]:
		if input.phase not in ["map","shop","complete"]: return fail("Usa el PC fuera del combate, después de reclamar la captura.")
		var run: Dictionary = input.duplicate(true)
		if kind == "deposit":
			var index: int = member_index(run.party,command.get("member"))
			if index < 0: return fail("Ese Pokémon no está en el equipo.")
			var member_data: Dictionary = run.party[index]
			if member_data.hp > 0 and run.party.filter(func(m):return m.hp>0).size() == 1:
				return fail("Mantén al menos un Pokémon en pie en el equipo.")
			run.reserve.append(run.party.pop_at(index))
		elif kind == "withdraw":
			var index: int = member_index(run.reserve,command.get("member"))
			if index < 0: return fail("Ese Pokémon no está en el PC.")
			if run.party.size() >= TEAM_LIMIT: return fail("El equipo tiene seis plazas. Intercambia un compañero con el PC.")
			run.party.append(run.reserve.pop_at(index))
		else:
			var active_index: int = member_index(run.party,command.get("member"))
			var reserve_index: int = member_index(run.reserve,command.get("reserve"))
			if active_index < 0 or reserve_index < 0: return fail("Elige un Pokémon del equipo y otro del PC.")
			var outgoing: Dictionary = run.party[active_index]
			var incoming: Dictionary = run.reserve[reserve_index]
			if outgoing.hp>0 and incoming.hp<=0 and run.party.filter(func(m):return m.hp>0).size()==1:
				return fail("El intercambio debe dejar algún Pokémon en pie en el equipo.")
			run.party[active_index] = incoming
			run.reserve[reserve_index] = outgoing
		run.revision += 1
		return {"ok":true,"state":run}
	var result: Dictionary = super.transact(input,command)
	if result.ok and kind == "capture" and result.state.party.size() > TEAM_LIMIT:
		result.state.reserve.append(result.state.party.pop_back())
	return result
