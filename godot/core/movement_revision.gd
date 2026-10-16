extends RefCounted

const Rules = preload("res://core/battle.gd")
const Store = preload("res://core/save_store.gd")

static func available(state: Dictionary, commands: Array) -> bool:
	return not state.is_empty() and state.outcome == "playing" and Rules.active(state).team == "ally" and state.moved and not state.acted and not commands.is_empty() and commands[-1].kind == "move"

static func rectify(state: Dictionary, commands: Array, mode: String, rules: Rules) -> Dictionary:
	if not available(state, commands): return {"ok": false, "reason": "Solo puedes rectificar el movimiento antes de actuar o terminar el turno."}
	# Reconstruct before the last move. The move must reproduce the current state
	# exactly: attacks, resources, RNG and any later order can never be rewound.
	var previous: Dictionary = rules.create(state.seed, state.variance, state.composition, mode)
	var kept: Array = commands.slice(0, commands.size() - 1).duplicate(true)
	for command: Dictionary in kept:
		var step: Dictionary = rules.apply_command(previous, command)
		if not step.ok: return {"ok": false, "reason": "El historial no permite rectificar este movimiento."}
		previous = step.state
	var moved: Dictionary = rules.apply_command(previous, commands[-1])
	if not moved.ok or not Store.equivalent(moved.state, state): return {"ok": false, "reason": "El movimiento ya no coincide con la partida actual."}
	var movement_only: Dictionary = state.duplicate(true)
	var actor: Dictionary = Rules.active(movement_only)
	var origin: Dictionary = Rules.active(previous)
	if actor.id != origin.id: return {"ok": false, "reason": "Ese movimiento pertenece a otra activación."}
	for field: String in ["x", "y", "facing", "remaining"]: actor[field] = origin[field]
	movement_only.moved = previous.moved
	movement_only.log = previous.log
	if not Store.equivalent(movement_only, previous): return {"ok": false, "reason": "Ese movimiento tiene consecuencias que no se pueden deshacer."}
	return {"ok": true, "state": previous, "commands": kept}
