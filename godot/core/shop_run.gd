extends "res://core/progression_run.gd"

const ShopBattle = preload("res://core/shop_battle.gd")
var shop_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))

func _init() -> void:
	engine = ShopBattle.new()
	progression.data.moves.merge(shop_data.moves,true)
	# Edition 1/2 keep their original forest reward and economy.
	for location: Dictionary in locations:
		if location.id == "brock": location.leader = true

func create(seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(seed,starter)
	if run.is_empty(): return run
	run.edition = 3
	run.stock = []
	run.rerolls = 0
	run.shopRandom = {"rng":Rng.hash_seed(run.seed+"/shop-v3")}
	for identity: String in shop_data.items: run.bag[identity] = 0
	return run

func ace(run: Dictionary) -> Dictionary:
	var location: Dictionary = locations[int(run.stage)]
	if not location.get("leader",false): return {}
	var result: Dictionary = {}
	for i: int in location.enemies.size():
		var identity: int = location.enemies[i]
		var record: Dictionary = progression.species[identity]
		if record.legendary or record.mythical: continue
		var level: int = progression.data.enemyLevels[int(run.stage)][i]
		if result.is_empty() or level > result.level: result = {"speciesId":identity,"level":level,"origin":location.name+" · Pokémon insignia"}
	return result

func pick(run: Dictionary, table: String) -> int:
	var reward: Dictionary = ace(run)
	if reward.is_empty(): return super.pick(run,table)
	run.captureLevel = reward.level
	return int(reward.speciesId)

func compatible(member: Dictionary, item: String) -> bool:
	if not shop_data.items.has(item): return false
	var record: Dictionary = shop_data.items[item]
	return record.kind == "tm" and record.species.any(func(id):return int(id)==int(member.speciesId))

func reroll_price(run: Dictionary) -> int:
	return int(shop_data.rerollBase)*(int(run.rerolls)+1)

func roll_stock(run: Dictionary, first: bool = false) -> void:
	var machines: Array = []
	var held: Array = []
	for identity: String in shop_data.items:
		var record: Dictionary = shop_data.items[identity]
		if record.kind == "held": held.append(identity)
		elif run.party.any(func(m):return m.hp>0 and compatible(m,identity) and record.move not in m.knownMoves): machines.append(identity)
	var choices: Array = []
	# A dependable coverage option in Charmander's first shop, before Brock.
	if first and run.stage == 0 and run.starter == 4 and "tm-brick-break" in machines:
		choices.append("tm-brick-break")
	elif not machines.is_empty(): choices.append(machines[int(floor(Rng.next(run.shopRandom)*machines.size()))])
	choices.append(held[int(floor(Rng.next(run.shopRandom)*held.size()))])
	var pool: Array = machines+held
	for chosen: String in choices: pool.erase(chosen)
	while choices.size()<3:
		var index: int = int(floor(Rng.next(run.shopRandom)*pool.size()))
		choices.append(pool.pop_at(index))
	run.stock = choices.map(func(id):return {"item":id,"sold":false})

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("at",-1) != input.revision: return fail("Esa opción pertenece a una pantalla anterior.")
	var kind: Variant = command.get("kind")
	if kind in ["reroll","buy-stock","equip","teach"]:
		if input.phase != "shop" and not (kind in ["equip","teach"] and input.phase in ["map","complete"]): return fail("Prepara los objetos fuera del combate y tras reclamar la captura.")
		var run: Dictionary = input.duplicate(true)
		if kind == "reroll":
			var cost: int = reroll_price(run)
			if run.money<cost: return fail("No tienes suficientes pokédolares para renovar las ofertas.")
			run.money -= cost
			run.rerolls += 1
			roll_stock(run)
		elif kind == "buy-stock":
			var slot: Variant = command.get("slot")
			if not (slot is int or slot is float) or slot!=int(slot) or slot<0 or slot>=run.stock.size(): return fail("Oferta no válida.")
			var offer: Dictionary = run.stock[int(slot)]
			var price: int = shop_data.items[offer.item].price
			if offer.sold or run.money<price: return fail("Oferta agotada o dinero insuficiente.")
			run.money -= price
			run.bag[offer.item] += 1
			offer.sold = true
		else:
			var identity: Variant = command.get("member")
			var item: Variant = command.get("item")
			if not (identity is int or identity is float) or identity!=int(identity) or not item is String: return fail("Miembro u objeto no válido.")
			var selected: Dictionary = target(run,int(identity))
			if selected.is_empty() or selected.hp<=0: return fail("Las bajas no pueden usar objetos.")
			if kind == "equip" and item == "":
				if selected.get("heldItem") == null: return fail("No lleva ningún objeto.")
				run.bag[selected.heldItem] += 1
				selected.heldItem = null
			else:
				if not shop_data.items.has(item) or run.bag[item]<=0: return fail("No tienes ese objeto en la bolsa.")
				var record: Dictionary = shop_data.items[item]
				if kind == "teach":
					if not compatible(selected,item) or record.move in selected.knownMoves: return fail("MT incompatible o movimiento ya aprendido.")
					selected.knownMoves.append(record.move)
					if selected.moves.size()<4: selected.moves.append(record.move)
				else:
					if record.kind != "held" or selected.get("heldItem") == item: return fail("Equipable no válido o ya equipado.")
					if selected.get("heldItem") != null: run.bag[selected.heldItem] += 1
					selected.heldItem = item
				run.bag[item] -= 1
		run.revision += 1
		return {"ok":true,"state":run}
	var result: Dictionary = super.transact(input,command)
	if not result.ok: return result
	var run: Dictionary = result.state
	if input.phase == "battle" and run.phase in ["capture","defeat"]:
		for member: Dictionary in run.party:
			if member.hp<=0 and member.get("heldItem") != null:
				run.bag[member.heldItem] += 1
				member.heldItem = null
		if run.phase == "capture":
			var reward: Dictionary = ace(run)
			if not reward.is_empty(): run.reward.origin = reward.origin
	if kind == "capture":
		run.rerolls = 0
		roll_stock(run,true)
	return result
