extends "res://core/power_run.gd"

func _init(chapter_number: int = 28) -> void:
	super(chapter_number)
	if chapter_number<28: return
	engine = preload("res://core/sleep_battle.gd").new()
	progression = engine.progression
	progression.data.xpRewards = locations.map(func(l):return l.xp)

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter<28 or command.get("kind")!="upgrade": return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir.")
	if command.get("edition")!=24 or input.get("edition",1)<12 or input.edition>=24: return fail("Versión de corrección no válida.")
	var next: Dictionary = input.duplicate(true)
	if input.edition<23:
		var conversion: Dictionary = preload("res://core/power_run.gd").new().transact(input,{"kind":"upgrade","edition":23,"at":input.revision})
		if not conversion.ok: return conversion
		next = conversion.state
	next.edition = 24; next.chapter = 28; next.revision = input.revision+1
	if not next.get("battle",{}).is_empty():
		next.battle.combatEdition = 21
		# Keep the full campaign journal. Movement undo starts at this checkpoint,
		# rather than replaying old, previously legal sleeping moves with new rules.
		next.battleInitial = next.battle.duplicate(true)
		next.battleCommands = []
	return {"ok":true,"state":next}
