extends "res://core/roster_run.gd"

const ExpandedBattle = preload("res://core/expedition_battle.gd")
var chapter: int = 17
var evolution_items: Dictionary = {"leaf-stone":"Piedra Hoja","fire-stone":"Piedra Fuego","water-stone":"Piedra Agua","thunder-stone":"Piedra Trueno","moon-stone":"Piedra Lunar","link-cable":"Cable Vínculo"}

func _init(chapter_number: int = 17) -> void:
	super()
	chapter = chapter_number
	engine = load("res://core/finale_battle.gd").new() if chapter>=21 else ExpandedBattle.new()
	progression = engine.progression
	var route_path: String = "res://data/journey-%d.json" % mini(chapter,21)
	locations = JSON.parse_string(FileAccess.get_file_as_string(route_path))
	progression.data.xpRewards = locations.map(func(location):return location.xp)
	shop_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/expedition-shop.json"))
	consumables["hyper-potion"] = {"name":"Hiperpoción","price":120,"heal":200}
	consumables["max-potion"] = {"name":"Poción Máxima","price":200,"heal":100000}
	for key: String in evolution_items: consumables[key] = {"name":evolution_items[key],"price":80,"heal":0}

func create(campaign_seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(campaign_seed,starter)
	if run.is_empty(): return run
	run.edition = chapter-4
	run.startEdition = chapter-4
	run.chapter = chapter
	run.flags = []
	run.finalPath = ""
	run.mainComplete = false
	_fill_bag(run)
	return run

func _fill_bag(run: Dictionary) -> void:
	for key: String in consumables:
		if not run.bag.has(key): run.bag[key] = 0
	for key: String in shop_data.items:
		if not run.bag.has(key): run.bag[key] = 0

func available(run: Dictionary) -> Array:
	return locations.filter(func(location):return location.id not in run.cleared and location.requires.all(func(flag):return flag in run.cleared or flag in run.get("flags",[])) and (not location.has("requiresAny") or location.requiresAny.any(func(flag):return flag in run.cleared or flag in run.get("flags",[]))) and (not location.has("path") or location.path==run.get("finalPath","")))

func ace(run: Dictionary) -> Dictionary:
	var location: Dictionary = locations[mini(int(run.stage),locations.size()-1)]
	if not location.get("leader",false): return {}
	var result: Dictionary = {}
	for member_data: Dictionary in location.team:
		var record: Dictionary = progression.species[int(member_data.speciesId)]
		if record.legendary or record.mythical: continue
		if result.is_empty() or member_data.level>=result.level: result = {"speciesId":member_data.speciesId,"level":member_data.level,"origin":location.name+" · Pokémon insignia"}
	return result

func gym_limit(run: Dictionary, after_victory: bool = false) -> Dictionary:
	var last: Dictionary = {"level":14,"leader":"Brock","speciesId":95}
	for index: int in locations.size():
		var location: Dictionary = locations[index]
		if not location.get("leader",false): continue
		var insignia: Dictionary = ace({"stage":index})
		last = {"level":int(insignia.level),"leader":location.name,"speciesId":int(insignia.speciesId)}
		if location.id not in run.cleared and not (after_victory and index==run.stage): return last
	if chapter>=20:
		return {"level":75 if run.get("mainComplete",false) else 65,"leader":"Desafío legendario" if run.get("mainComplete",false) else "Liga y rival","speciesId":150 if run.get("mainComplete",false) else 6}
	return last

func pick(run: Dictionary, _table: String) -> int:
	var location: Dictionary = locations[int(run.stage)]
	if location.get("finale",false): run.captureLevel = 1; return 19
	var insignia: Dictionary = ace(run)
	if not insignia.is_empty(): run.captureLevel = insignia.level; return int(insignia.speciesId)
	var entries: Array = progression.data.encounters[location.captureTable]
	var pool: Array = entries.filter(func(e):return not e.special)
	var special: Array = entries.filter(func(e):return e.special)
	if not special.is_empty() and Rng.next(run)<0.01: pool = special
	var entry: Dictionary = pool[int(floor(Rng.next(run)*pool.size()))]
	run.captureLevel = mini(level_cap(run),int(entry.minLevel)+int(floor(Rng.next(run)*(entry.maxLevel-entry.minLevel+1))))
	return int(entry.speciesId)

func _grant(run: Dictionary, location: Dictionary) -> void:
	for flag: String in location.get("grants",[]):
		if flag not in run.flags: run.flags.append(flag)
	if location.has("medal") and location.medal not in run.medals: run.medals.append(location.medal)
	if location.id=="champion": run.mainComplete = true

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir la orden.")
	var kind: Variant = command.get("kind")
	if kind=="upgrade":
		if command.get("edition")!=chapter-4: return fail("La transición no corresponde a esta versión instalada.")
		if input.get("edition",1)<12 or input.get("edition",1)>=chapter-4 or input.phase not in ["map","shop","complete"]: return fail("Continúa la expansión desde el mapa, tienda o final del tramo; conserva las reglas de un combate en curso.")
		var run: Dictionary = input.duplicate(true)
		run.startEdition = run.get("startEdition",run.edition)
		run.edition = chapter-4
		run.chapter = chapter
		if not run.has("flags"): run.flags = []
		if not run.has("finalPath"): run.finalPath = ""
		if not run.has("mainComplete"): run.mainComplete = false
		for location: Dictionary in locations:
			if location.id in run.cleared: _grant(run,location)
		_fill_bag(run)
		# Completed older chapters need a preparation stop before stronger encounters.
		if chapter>=19 and run.phase=="complete": run.phase = "shop"
		if run.phase=="complete":
			var choices: Array = available(run).filter(func(n):return not n.get("optional",false))
			if not choices.is_empty(): run.stage = locations.find(choices[0]); run.phase = "map"
		run.revision += 1
		return {"ok":true,"state":run}
	if kind=="travel":
		if input.phase not in ["map","complete"]: return fail("Termina antes el combate, captura y tienda.")
		var choices: Array = available(input).filter(func(n):return n.id==command.get("location"))
		if choices.is_empty(): return fail("Ese destino está bloqueado o ya superado.")
		var run: Dictionary = input.duplicate(true)
		run.stage = locations.find(choices[0])
		run.phase = "map"
		run.revision += 1
		return {"ok":true,"state":run}
	if kind=="continue":
		if input.phase!="shop": return fail("Resuelve primero la captura y la tienda.")
		var run: Dictionary = input.duplicate(true)
		var possible: Array = available(run)
		var choices: Array = possible.filter(func(n):return not n.get("optional",false))
		if choices.is_empty() and locations.any(func(n):return not n.get("optional",false) and not n.get("finale",false) and n.id not in run.cleared):
			var connected: Array = possible.filter(func(n):return locations[int(run.stage)].id in n.requires)
			choices = connected if not connected.is_empty() else possible
		if chapter>=21 and locations[int(run.stage)].get("finale",false): choices = possible.filter(func(n):return n.id==locations[int(run.stage)].id)
		run.phase = "complete" if choices.is_empty() else "map"
		if not choices.is_empty(): run.stage = locations.find(choices[0])
		run.revision += 1
		return {"ok":true,"state":run}
	if kind=="enter":
		if input.phase!="map" or not available(input).any(func(n):return n.id==locations[int(input.stage)].id): return fail("No se cumplen los requisitos de ese encuentro, o ya está superado.")
		if locations[int(input.stage)].get("kind","")=="story":
			var run: Dictionary = input.duplicate(true)
			var location: Dictionary = locations[int(run.stage)]
			run.cleared.append(location.id)
			_grant(run,location)
			run.phase = "shop"
			run.lastProgress = []
			run.rerolls = 0
			roll_stock(run,true)
			run.revision += 1
			return {"ok":true,"state":run}
	if kind=="destiny":
		if chapter<21 or not input.get("mainComplete",false) or input.get("finalPath","")!="" or input.phase!="complete" or command.get("path") not in ["birds","psychic"]: return fail("Elige un desafío una sola vez, después de la Liga y su tienda.")
		var run: Dictionary = input.duplicate(true)
		run.finalPath = command.path
		var choices: Array = available(run).filter(func(n):return n.get("path","")==run.finalPath)
		if choices.is_empty(): return fail("Ese desafío todavía no está disponible.")
		run.stage = locations.find(choices[0])
		run.phase = "shop"
		run.rerolls = 0
		roll_stock(run,true)
		run.revision += 1
		return {"ok":true,"state":run}
	if kind=="buy" and command.get("item") in ["hyper-potion","max-potion"]+evolution_items.keys():
		var item: String = command.item
		if input.phase!="shop" or input.money<consumables[item].price: return fail("Compra el objeto en la tienda con dinero suficiente.")
		var run: Dictionary = input.duplicate(true)
		run.money -= consumables[item].price
		run.bag[item] += 1
		run.revision += 1
		return {"ok":true,"state":run}
	if kind=="use-evolution" or (kind=="heal" and command.get("item") in ["hyper-potion","max-potion"]):
		if input.phase!="shop": return fail("Usa el objeto en la tienda, fuera del combate.")
		var identity: Variant = command.get("member")
		if not (identity is int or identity is float) or identity!=int(identity): return fail("Miembro no válido.")
		var run: Dictionary = input.duplicate(true)
		var selected: Dictionary = target(run,int(identity))
		var item: Variant = command.get("item")
		if selected.is_empty() or selected.hp<=0 or not item is String or run.bag.get(item,0)<=0: return fail("Necesita un Pokémon en pie y ese objeto en la bolsa.")
		if kind=="heal":
			var maximum: int = progression.member_stats(selected).maxHp
			if selected.hp>=maximum: return fail("Ya tiene todos sus PS.")
			selected.hp = mini(maximum,int(selected.hp)+int(consumables[item].heal))
		else:
			var options: Array = progression.stone_options(selected).filter(func(o):return o[1]==item and o[0]==command.get("species"))
			if options.is_empty(): return fail("Ese objeto no corresponde a la evolución elegida.")
			selected.speciesId = int(options[0][0])
			selected.hp = mini(selected.hp,progression.member_stats(selected).maxHp)
			progression.learn(selected)
		run.bag[item] -= 1
		run.revision += 1
		return {"ok":true,"state":run}
	var result: Dictionary = super.transact(input,command)
	if result.ok and kind=="battle" and input.phase=="battle" and result.state.phase=="capture":
		var location: Dictionary = locations[int(input.stage)]
		_grant(result.state,location)
		result.state.money += maxi(0,int(location.money)-150)
		if location.get("finale",false): result.state.phase = "ending"; result.state.reward = {}
	return result
