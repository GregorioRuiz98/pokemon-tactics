extends "res://core/tactics_quality_run.gd"

const Collection = preload("res://core/collection_catalog.gd")

func _init(chapter_number: int = 32) -> void:
	super(chapter_number)

func create(campaign_seed: String, starter: int) -> Dictionary:
	if chapter<32: return super.create(campaign_seed,starter)
	if starter<1 or starter>151 or Collection.base_species(starter)!=starter: return {}
	var run: Dictionary = super.create(campaign_seed,starter if starter in [1,4,7] else 1)
	if run.is_empty(): return run
	if starter not in [1,4,7]:
		run.starter = starter
		run.party[0] = progression.create_member(1,starter,"Pueblo Paleta · Oak",5)
		progression.assign(run.party[0],run.seed)
		_genders(run)
		roll_stock(run,true)
	run.collectionAdopted = []
	return run

func collection_offers(run: Dictionary) -> Array:
	if run.get("edition",0)<28 or run.get("phase","")!="shop": return []
	var place: String = locations[int(run.stage)].id
	if place in run.get("collectionAdopted",[]): return []
	var level: int = mini(level_cap(run),maxi(5,int(floor(average_level(run)))))
	var pool: Array[int] = []
	for species: int in range(1,152):
		if species not in Collection.LEGENDS and Collection.minimum_level(species)<=level: pool.append(species)
	var random: Dictionary = {"rng":Rng.hash_seed(run.seed+"/collection/"+place)}
	var offers: Array = []
	for index: int in mini(3,pool.size()):
		var choice: int = int(floor(Rng.next(random)*pool.size()))
		offers.append({"speciesId":pool.pop_at(choice),"level":level,"price":200+10*level})
	return offers

func collection_member(run: Dictionary, species: int, level: int, origin: String) -> Dictionary:
	var member_data: Dictionary = progression.create_member(int(run.nextId),species,origin,level)
	progression.assign(member_data,run.seed)
	var view: Dictionary = run.duplicate(true)
	view.reward = member_data; _genders(view)
	return view.reward

func capture_options(run: Dictionary) -> Array:
	if run.has("legendaryChoices"): return []
	return super.capture_options(run)

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter<32: return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir.")
	var kind: String = command.get("kind","")
	if kind=="upgrade":
		if command.get("edition")!=28 or input.get("edition",1)<12 or input.edition>=28 or input.phase not in ["map","shop","complete","ending"]: return fail("Actualiza entre encuentros.")
		var next: Dictionary = input.duplicate(true)
		if input.edition<27:
			var conversion: Dictionary = preload("res://core/tactics_quality_run.gd").new().transact(input,{"kind":"upgrade","edition":27,"at":input.revision})
			if not conversion.ok: return conversion
			next = conversion.state
		next.edition = 28; next.chapter = 32; next.collectionAdopted = []; next.revision = input.revision+1
		return {"ok":true,"state":next}
	if input.get("edition",0)!=28: return fail("Esta aventura conserva sus reglas anteriores. Actualiza entre encuentros.")
	if kind=="adopt":
		var choices: Array = collection_offers(input).filter(func(candidate):return candidate.speciesId==command.get("species"))
		if choices.is_empty(): return fail("Elige una oferta disponible de reclutamiento.")
		var offer: Dictionary = choices[0]
		if input.money<offer.price: return fail("No tienes suficientes pokédolares.")
		var next: Dictionary = input.duplicate(true)
		var member_data: Dictionary = collection_member(next,int(offer.speciesId),int(offer.level),locations[int(next.stage)].name+" · Reclutamiento")
		if next.party.size()<6: next.party.append(member_data)
		else: next.reserve.append(member_data)
		next.nextId += 1; next.money -= int(offer.price)
		next.collectionAdopted.append(locations[int(next.stage)].id); next.revision += 1
		return {"ok":true,"state":next}
	if kind=="select-recruit":
		var selected: Variant = command.get("species")
		if not (selected is int or selected is float) or selected!=int(selected): return fail("Elige uno de los legendarios de este combate.")
		if input.phase!="capture" or not input.has("legendaryChoices") or int(selected) not in input.legendaryChoices: return fail("Elige uno de los legendarios de este combate.")
		var next: Dictionary = input.duplicate(true)
		next.reward = collection_member(next,int(command.species),mini(75,level_cap(next)),input.reward.origin)
		next.revision += 1
		return {"ok":true,"state":next}
	if kind=="reroll-capture" and input.has("legendaryChoices"): return fail("Elige solo un legendario; esta recompensa no se renueva.")
	var result: Dictionary = super.transact(input,command)
	if not result.ok: return result
	var settled: Dictionary = result.state
	if kind=="battle" and settled.cleared.size()>input.cleared.size():
		var place: String = locations[int(input.stage)].id
		var choices: Array = [144,145,146] if place=="legendary-birds" else [151,150] if place=="legendary-origin" else []
		if not choices.is_empty():
			settled.collectionAfter = settled.phase
			settled.phase = "capture"; settled.legendaryChoices = choices
			settled.reward = collection_member(settled,int(choices[0]),mini(75,level_cap(settled)),locations[int(input.stage)].name)
	if kind=="capture" and input.has("legendaryChoices"):
		settled.phase = input.collectionAfter
		settled.erase("legendaryChoices"); settled.erase("collectionAfter")
	return result
