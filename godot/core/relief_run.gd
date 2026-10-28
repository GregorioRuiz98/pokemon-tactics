extends "res://core/closing_run.gd"

func _init(chapter_number: int = 34) -> void:
	super(chapter_number)
	if chapter_number<34: return
	engine = preload("res://core/relief_battle.gd").new(); progression = engine.progression
	progression.data.xpRewards = locations.map(func(location):return location.xp)

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter<34: return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir.")
	if command.get("kind")=="upgrade":
		if command.get("edition")!=30 or input.get("edition",1)<12 or input.edition>=30 or input.phase not in ["map","shop","complete","ending"]: return fail("Actualiza entre encuentros.")
		var next: Dictionary = input.duplicate(true)
		if input.edition<29:
			var converted: Dictionary = preload("res://core/closing_run.gd").new().transact(input,{"kind":"upgrade","edition":29,"at":input.revision})
			if not converted.ok: return converted
			next = converted.state
		next.edition = 30; next.chapter = 34; next.revision = input.revision+1
		return {"ok":true,"state":next}
	if input.get("edition",0)!=30: return fail("Esta aventura conserva sus mapas anteriores. Actualiza entre encuentros.")
	var projection: Dictionary = input.duplicate(); projection.edition = 29
	var result: Dictionary = super.transact(projection,command)
	if result.ok: result.state.edition = 30; result.state.chapter = 34
	return result
