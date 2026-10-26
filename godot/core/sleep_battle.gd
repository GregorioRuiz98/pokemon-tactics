extends "res://core/power_battle.gd"

static func asleep(unit: Dictionary) -> bool:
	return unit.get("status") is Dictionary and unit.status.get("kind")=="sleep"

func movement_routes(state: Dictionary, actor: Dictionary, maximum: float = INF) -> Dictionary:
	if asleep(actor): return {}
	return super.movement_routes(state,actor,maximum)

func move(state: Dictionary, destination: Dictionary) -> Dictionary:
	if asleep(active(state)): return {"ok":false,"reason":"Está dormido: no puede moverse ni actuar."}
	return super.move(state,destination)

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var state: Dictionary = super.encounter(run,location)
	state.combatEdition = 21
	return state

func new_round(state: Dictionary) -> void:
	super.new_round(state)
	state.combatEdition = 21
