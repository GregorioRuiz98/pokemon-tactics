extends RefCounted

const EngineRules = preload("res://core/kanto_battle.gd")
const Revision = preload("res://core/movement_revision.gd")
const Rng = preload("res://core/seeded_rng.gd")
const EVOLUTIONS = {1:2,2:3,4:5,5:6,7:8,8:9,10:11,11:12,13:14,14:15,16:17,17:18,19:20,25:26}
const ITEMS = {"potion": {"name":"Poción", "price":40, "heal":40}, "super-potion":{"name":"Superpoción", "price":90, "heal":100}, "rare-candy":{"name":"Caramelo Raro", "price":100, "heal":0}}
const STATS = {"maxHp":"PS máximos", "attack":"Ataque", "defense":"Defensa", "specialAttack":"At. especial", "specialDefense":"Def. especial", "speed":"Velocidad"}
var engine: EngineRules = EngineRules.new()
var locations: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/kanto-route.json"))

func create(seed: String, starter: int) -> Dictionary:
	if starter not in [1,4,7]: return {}
	seed = seed.strip_edges().substr(0,64)
	if seed.is_empty(): seed = "kanto-14"
	return {"seed":seed,"starter":starter,"rng":Rng.hash_seed(seed),"revision":0,"stage":0,"phase":"map","party":[member(1,starter,"Pueblo Paleta · Oak")],"nextId":2,"money":120,"bag":{"potion":2,"super-potion":0,"rare-candy":0},"medals":[],"cleared":[],"reward":{},"battle":{},"battleInitial":{},"battleCommands":[]}

func member(identity: int, species_id: int, origin: String) -> Dictionary:
	var unit: Dictionary = engine.profiles[species_id].create_unit(identity,"ally",{"x":0,"y":0},"current")
	return {"id":identity,"speciesId":species_id,"hp":unit.maxHp,"origin":origin,"training":{}}

func target(run: Dictionary, identity: int) -> Dictionary:
	for entry: Dictionary in run.party:
		if entry.id == identity: return entry
	return {}

func pick(run: Dictionary, table: String) -> int:
	var slots: Array = []
	for entry: Dictionary in engine.catalog.slots:
		if entry.id == table: slots = entry.slots
	var roll: int = int(floor(Rng.next(run) * 256))
	for i: int in slots.size():
		roll -= int(engine.catalog.slotWeights[i])
		if roll < 0: return int(slots[i].speciesId)
	return -1

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if not command.get("kind") is String: return fail("Orden de campaña no válida.")
	if command.get("at",-1) != input.revision: return fail("Esa opción pertenece a una pantalla anterior.")
	var run: Dictionary = input.duplicate(true)
	var kind: String = command.get("kind","")
	match kind:
		"enter":
			if run.phase != "map" or run.party.filter(func(m): return m.hp > 0).size() not in range(1,7): return fail("No puedes entrar en ese encuentro.")
			run.battle = engine.encounter(run,locations[int(run.stage)])
			run.battleInitial = run.battle.duplicate(true)
			run.battleCommands = []
			run.phase = "battle"
		"battle":
			if run.phase != "battle" or not command.get("order") is Dictionary: return fail("No hay un combate activo.")
			var order: Dictionary = command.order
			if order.get("kind") == "move":
				if not order.get("destination") is Dictionary: return fail("Destino no válido.")
				for axis: String in ["x","y"]:
					var value: Variant = order.destination.get(axis)
					if not (value is int or value is float) or value != floor(float(value)): return fail("Coordenada no válida.")
			elif order.get("kind") == "attack":
				if not (order.get("target") is int or order.get("target") is float) or not order.get("actionId","basic") is String: return fail("Ataque no válido.")
			elif order.get("kind") == "finish":
				if not (order.get("facing") is int or order.get("facing") is float) or order.facing != int(order.facing) or int(order.facing) not in EngineRules.FACINGS: return fail("Orientación no válida.")
			else: return fail("Orden táctica desconocida.")
			var result: Dictionary = engine.apply_command(run.battle,command.order)
			if not result.ok: return result
			run.battle = result.state
			run.battleCommands.append(command.order.duplicate(true))
			if run.battle.outcome != "playing":
				for unit: Dictionary in run.battle.units:
					if unit.team == "ally": target(run,int(unit.id)).hp = unit.hp
				if run.battle.outcome == "defeat": run.phase = "defeat"
				else:
					var location: Dictionary = locations[int(run.stage)]
					run.cleared.append(location.id)
					run.money += 150
					if location.id == "brock": run.medals.append("Medalla Roca")
					run.reward = member(int(run.nextId),pick(run,location.captureTable),location.captureOrigin)
					run.phase = "capture"
		"rectify":
			if run.phase != "battle": return fail("No hay movimiento para rectificar.")
			var result: Dictionary = Revision.rectify(run.battle,run.battleCommands,"current",engine,run.battleInitial)
			if not result.ok: return result
			run.battle = result.state
			run.battleCommands = result.commands
		"capture":
			if run.phase != "capture" or run.reward.is_empty(): return fail("La captura ya está resuelta.")
			run.party.append(run.reward)
			run.nextId += 1
			run.reward = {}
			run.phase = "shop"
		"buy":
			var item: String = command.get("item","")
			if run.phase != "shop" or not ITEMS.has(item) or run.money < ITEMS[item].price: return fail("Compra no disponible o dinero insuficiente.")
			run.money -= ITEMS[item].price
			run.bag[item] += 1
		"heal", "evolve", "train":
			if not (command.get("member") is int or command.get("member") is float): return fail("Miembro no válido.")
			var selected: Dictionary = target(run,int(command.get("member",-1)))
			if run.phase != "shop" or selected.is_empty() or selected.hp <= 0: return fail("Solo puedes mejorar o curar miembros vivos en la tienda.")
			if kind == "heal":
				var item: String = command.get("item","")
				if item not in ["potion","super-potion"] or run.bag[item] <= 0 or selected.hp >= engine.member_unit(selected).maxHp: return fail("No necesita ese objeto o no queda ninguno.")
				selected.hp = mini(engine.member_unit(selected).maxHp,selected.hp + ITEMS[item].heal)
				run.bag[item] -= 1
			elif kind == "evolve":
				if not EVOLUTIONS.has(int(selected.speciesId)) or run.bag["rare-candy"] <= 0: return fail("No puede evolucionar o falta un Caramelo Raro.")
				selected.speciesId = EVOLUTIONS[int(selected.speciesId)]
				selected.hp = mini(selected.hp,engine.member_unit(selected).maxHp)
				run.bag["rare-candy"] -= 1
			else:
				var stat: String = command.get("stat","")
				var count: int = 0
				for value: Variant in selected.training.values(): count += int(value)
				if not STATS.has(stat) or count >= 2 or run.money < 80: return fail("Entrenamiento limitado a dos compras por Pokémon; cuesta 80.")
				selected.training[stat] = selected.training.get(stat,0) + 1
				run.money -= 80
		"continue":
			if run.phase != "shop": return fail("Completa primero la captura y la tienda.")
			run.stage += 1
			run.phase = "complete" if run.stage == locations.size() else "map"
		_:
			return fail("Orden de campaña desconocida.")
	run.revision += 1
	return {"ok":true,"state":run}

static func fail(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
