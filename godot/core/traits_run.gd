extends "res://core/revive_run.gd"

const TraitBattle = preload("res://core/traits_battle.gd")

func _init() -> void:
	super()
	engine = TraitBattle.new()
	progression = engine.progression
	consumables["ability-capsule"] = {"name":"Cápsula Habilidad","price":int(progression.traits.capsulePrice),"heal":0}

func create(seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(seed,starter)
	if not run.is_empty():
		run.edition = 10
		progression.assign(run.party[0],run.seed)
		run.bag["ability-capsule"] = 0
		for nature: String in progression.mintable(): run.bag["mint-"+nature] = 0
	return run

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("at",-1)!=input.revision: return fail("Esa opción pertenece a una pantalla anterior.")
	if not command.get("kind") is String: return fail("Orden de campaña no válida.")
	var item: Variant = command.get("item","")
	var buy: bool = command.kind=="buy" and item is String and (item.begins_with("mint-") or item=="ability-capsule")
	if buy or command.kind in ["mint","capsule"]:
		if input.phase!="shop": return fail("Compra y usa mentas y cápsulas en la tienda, fuera de combate.")
		var run: Dictionary = input.duplicate(true)
		if buy:
			var mint: bool = item.begins_with("mint-")
			if mint and item.trim_prefix("mint-") not in progression.mintable(): return fail("Menta no válida.")
			var price: int = progression.traits.mintPrice if mint else progression.traits.capsulePrice
			if run.money<price: return fail("No tienes suficientes pokédolares: cuesta %d ₽." % price)
			run.money -= price
			run.bag[item] += 1
		else:
			var identity: Variant = command.get("member")
			if not (identity is int or identity is float) or identity!=int(identity): return fail("Miembro no válido.")
			var selected: Dictionary = target(run,int(identity))
			if selected.is_empty() or selected.hp<=0: return fail("Solo puedes modificar a un Pokémon que siga en pie.")
			if command.kind=="mint":
				var nature: Variant = command.get("nature")
				if not nature is String or nature not in progression.mintable(): return fail("Menta no válida.")
				if run.bag["mint-"+nature]<=0: return fail("No queda esa menta en la bolsa.")
				if not progression.mint_changes(selected,nature): return fail("Ya tiene esos modificadores; la menta no se consume.")
				selected.mint = nature
				run.bag["mint-"+nature] -= 1
			else:
				var slot: int = progression.next_slot(selected)
				if slot==0: return fail("Esta especie solo tiene una habilidad normal; la cápsula no se consume.")
				if run.bag["ability-capsule"]<=0: return fail("Falta una Cápsula Habilidad.")
				selected.abilitySlot = slot
				run.bag["ability-capsule"] -= 1
		run.revision += 1
		return {"ok":true,"state":run}
	var result: Dictionary = super.transact(input,command)
	if result.ok and input.phase=="battle" and result.state.phase=="capture": progression.assign(result.state.reward,result.state.seed)
	if result.ok and command.kind=="battle":
		if not result.has("presentation"): result.presentation = {}
		result.presentation.abilityEvents = result.state.battle.get("abilityEvents",[])
	return result
