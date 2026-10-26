extends "res://core/adventure_run.gd"

func _init(chapter_number: int = 26) -> void:
	super(chapter_number)
	if chapter_number<26: return
	engine = preload("res://core/landscape_battle.gd").new()
	progression = engine.progression
	locations = JSON.parse_string(FileAccess.get_file_as_string("res://data/journey-26.json"))
	progression.data.xpRewards = locations.map(func(l):return l.xp)

func _next_legend(run: Dictionary) -> void:
	if not run.get("mainComplete",false): return
	run.finalPath = "psychic" if "legendary-birds" in run.cleared else "birds"
	var id: String = "legendary-origin" if run.finalPath=="psychic" else "legendary-birds"
	# Completing an old psychic ending does not fabricate a bird victory.
	# The remaining birds can still be played after an explicit upgrade.
	if "legendary-origin" in run.cleared and "legendary-birds" not in run.cleared: id = "legendary-birds"; run.finalPath = "birds"
	for index: int in locations.size():
		if locations[index].id==id: run.stage = index

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter<26: return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir.")
	var kind: String = command.get("kind","")
	if kind=="upgrade":
		if command.get("edition")!=22 or input.get("edition",1)<12 or input.get("edition",1)>=22 or input.phase not in ["map","shop","complete","ending"]: return fail("Actualiza entre encuentros. Un combate en curso conserva su mapa.")
		var run: Dictionary = input.duplicate(true)
		if run.edition<21:
			var conversion: Dictionary = preload("res://core/adventure_run.gd").new().transact(input,{"kind":"upgrade","edition":21,"at":input.revision})
			if not conversion.ok: return conversion
			run = conversion.state
		run.edition = 22; run.chapter = 26; run.revision = input.revision+1
		if run.get("mainComplete",false):
			_next_legend(run)
			if not ("legendary-birds" in run.cleared and "legendary-origin" in run.cleared):
				run.phase = "shop"
				run.rerolls = 0
				roll_stock(run,true)
		return {"ok":true,"state":run}
	if kind=="destiny": return fail("Los desafíos se recorren en orden: tres aves, después Mew y Mewtwo.")
	if kind=="continue" and input.phase=="shop" and input.get("mainComplete",false):
		var run: Dictionary = input.duplicate(true)
		_next_legend(run)
		run.phase = "ending" if "legendary-birds" in run.cleared and "legendary-origin" in run.cleared else "map"
		run.revision += 1
		return {"ok":true,"state":run}
	var result: Dictionary = super.transact(input,command)
	if result.ok and kind=="battle" and result.state.phase=="ending":
		var run: Dictionary = result.state
		if not ("legendary-birds" in run.cleared and "legendary-origin" in run.cleared):
			run.phase = "shop"
			run.rerolls = 0
			roll_stock(run,true)
		else: run.finalPath = "psychic"
	return result
