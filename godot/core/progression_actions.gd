extends RefCounted

const Base = preload("res://core/actions.gd")

class StagesAction extends Base.TacticalAction:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var result: Dictionary = super.preview(actor,target)
		var change: Dictionary = definition.statChange
		var current: int = target.get("stages",{}).get(change.stat,0)
		result.statChange = change
		result.statusReason = "Ese atributo ya está en su límite." if current == clampi(current + int(change.stages),-2,2) else null
		return result

class HealingAction extends Base.TacticalAction:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var result: Dictionary = super.preview(actor,target)
		result.heal = mini(target.maxHp - target.hp,maxi(1,int(floor(target.maxHp / 4.0))))
		result.statusReason = "Ya tiene todos sus PS." if result.heal == 0 else null
		return result

class ImpactAction extends Base.DamageAction:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var result: Dictionary = super.preview(actor,target)
		if definition.has("statChange") and result.multiplier != 0:
			var change: Dictionary = definition.statChange
			var current: int = target.get("stages",{}).get(change.stat,0)
			if current != clampi(current + int(change.stages),-2,2): result.statChange = change
		return result

static func create(definition: Dictionary, chart: Dictionary) -> Base.TacticalAction:
	match definition.kind:
		"stages": return StagesAction.new(definition,chart)
		"heal": return HealingAction.new(definition,chart)
	if definition.has("statChange"): return ImpactAction.new(definition,chart)
	return Base.create(definition,chart)
