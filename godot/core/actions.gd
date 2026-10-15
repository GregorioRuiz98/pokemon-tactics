class_name LabActions
extends RefCounted

class TacticalAction extends RefCounted:
	var definition: Dictionary
	var chart: Dictionary
	func _init(data: Dictionary, types: Dictionary):
		definition = data
		chart = types
	func preview(_actor: Dictionary, _target: Dictionary) -> Dictionary:
		return {"damage": 0, "heal": 0, "multiplier": 1, "stab": 1, "category": "status", "guard": false, "status": null, "statusReason": null}
	func multiplier(target: Dictionary) -> float:
		var result = 1.0
		for type in target.types: result *= chart[definition.type][type]
		return result
	func immunity(target: Dictionary, kind: String):
		if kind == "poison" and ("poison" in target.types or "steel" in target.types): return "Inmune al veneno por su tipo."
		if kind == "burn" and "fire" in target.types: return "Inmune a quemadura por su tipo."
		if kind == "paralysis" and "electric" in target.types: return "Inmune a parálisis por su tipo."
		if target.status != null: return "Ya tiene un estado principal."
		return null

class DamageAction extends TacticalAction:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var result = super.preview(actor, target)
		var scale = multiplier(target)
		var stab = 1.5 if definition.type in actor.types else 1.0
		var physical = definition.category == "physical"
		var attack = actor.attack * (0.5 if actor.status != null and actor.status.kind == "burn" else 1.0) if physical else actor.specialAttack
		var defense = target.defense if physical else target.specialDefense * (1.5 if target.heldItem == "assault-vest" else 1.0)
		var raw = maxf(5, 12 + attack * 0.18 - defense * 0.1) * (definition.power / 40.0)
		var damage = 0 if scale == 0 else mini(target.hp, maxi(1, int(floor(raw * scale * stab * (0.5 if target.guarded else 1.0) + 0.5))))
		var secondary = definition.get("secondary")
		var reason = ("Inmune al movimiento." if scale == 0 else immunity(target, secondary.kind)) if secondary != null else null
		result.merge({"damage": damage, "multiplier": scale, "stab": stab, "category": definition.category, "statusReason": reason, "status": secondary.duplicate(true) if secondary != null and reason == null and damage < target.hp else null}, true)
		return result

class DrainAction extends DamageAction:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var result = super.preview(actor, target)
		result.heal = mini(actor.maxHp - actor.hp, int(floor(result.damage / 2.0)))
		return result

class StatusAction extends TacticalAction:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var result = super.preview(actor, target)
		var type_immune = definition.type == "electric" and multiplier(target) == 0
		var powder_immune = definition.get("powder", false) and "grass" in target.types
		var reason = "Inmune al movimiento eléctrico." if type_immune else ("Los tipos Planta son inmunes al polvo." if powder_immune else immunity(target, definition.effect.kind))
		result.status = definition.effect.duplicate(true) if reason == null else null
		result.statusReason = reason
		result.multiplier = 0 if type_immune else 1
		return result

class GuardAction extends TacticalAction:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var result = super.preview(actor, target)
		result.guard = true
		return result

static func create(data: Dictionary, chart: Dictionary) -> TacticalAction:
	match data.kind:
		"drain": return DrainAction.new(data, chart)
		"status", "area-status": return StatusAction.new(data, chart)
		"guard": return GuardAction.new(data, chart)
	return DamageAction.new(data, chart)
