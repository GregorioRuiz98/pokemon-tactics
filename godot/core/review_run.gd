extends "res://core/climate_run.gd"

func _init(chapter_number: int = 30) -> void:
	super(chapter_number)
	if chapter_number<30: return
	engine = preload("res://core/review_battle.gd").new(); progression = engine.progression
	progression.data.xpRewards = locations.map(func(l):return l.xp)

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter<30 or command.get("kind")!="upgrade": return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir.")
	if command.get("edition")!=26 or input.get("edition",1)<12 or input.edition>=26 or input.phase not in ["map","shop","complete","ending"]: return fail("Actualiza entre encuentros.")
	var next: Dictionary = input.duplicate(true)
	if input.edition<25:
		var conversion: Dictionary = preload("res://core/climate_run.gd").new().transact(input,{"kind":"upgrade","edition":25,"at":input.revision})
		if not conversion.ok: return conversion
		next = conversion.state
	next.edition = 26; next.chapter = 30; next.revision = input.revision+1
	return {"ok":true,"state":next}
