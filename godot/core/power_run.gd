extends "res://core/kanto_journey.gd"

const Points = preload("res://core/power_points.gd")

func _init(chapter_number: int = 27) -> void:
	super(chapter_number)
	if chapter_number<27: return
	engine = preload("res://core/power_battle.gd").new()
	progression = engine.progression
	progression.data.xpRewards = locations.map(func(l):return l.xp)

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter<27: return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir.")
	if command.get("kind")=="upgrade":
		if command.get("edition")!=23 or input.get("edition",1)<12 or input.edition>=23 or input.phase not in ["map","shop","complete","ending"]: return fail("Actualiza entre encuentros.")
		var next: Dictionary = input.duplicate(true)
		if input.edition<22:
			var conversion: Dictionary = preload("res://core/kanto_journey.gd").new().transact(input,{"kind":"upgrade","edition":22,"at":input.revision})
			if not conversion.ok: return conversion
			next = conversion.state
		next.edition = 23; next.chapter = 27; next.revision = input.revision+1
		for owned: Dictionary in next.party+next.reserve: owned.moves = Points.fit(owned.moves,owned.level,progression.data.moves)
		return {"ok":true,"state":next}
	var result: Dictionary = super.transact(input,command)
	if not result.ok: return result
	if command.get("kind")=="loadout":
		var selected: Dictionary = target(result.state,int(command.member))
		var total: int = Points.used(selected.moves,progression.data.moves)
		if total>Points.capacity(selected.level): return fail("Necesita %d PP; capacidad %d."%[total,Points.capacity(selected.level)])
	# Level learning, MT and evolutions may auto-prepare a move in older code.
	# Keep all knowledge, but never bypass the equipment budget.
	for owned: Dictionary in result.state.party+result.state.reserve: owned.moves = Points.fit(owned.moves,owned.level,progression.data.moves)
	return result
