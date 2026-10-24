extends "res://core/journey_run.gd"

const Battle = preload("res://core/kanto_battle.gd")

func _init(chapter_number: int = 23) -> void:
	super(chapter_number)
	if chapter_number<23: return
	engine = load("res://core/spatial_battle.gd").new()
	progression = engine.progression
	progression.data.xpRewards = locations.map(func(location):return location.xp)

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter>=23 and command.get("kind")=="rectify" and input.get("battle",{}).get("movementLocked",false): return fail("Ese movimiento ha activado una zona y sus consecuencias no se pueden rectificar.")
	var result: Dictionary = super.transact(input,command)
	if chapter>=23 and result.ok and command.get("kind")=="battle" and command.get("order",{}).get("kind")=="attack":
		var original: Dictionary = Battle.active(input.battle)
		var actor: Dictionary = Battle.unit_by_id(result.state.battle,int(original.id))
		var identity: String = actor.spatial.lastMove
		if engine.catalog.moves.has(identity): result.presentation.visualDefinition = engine.catalog.moves[identity].duplicate(true)
	if chapter>=23 and result.ok and command.get("kind")=="battle" and input.phase=="battle" and result.state.phase in ["capture","ending"] and result.state.battle.get("payDay",false): result.state.money += 25
	return result
