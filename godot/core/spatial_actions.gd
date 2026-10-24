extends RefCounted

const Previous = preload("res://core/expedition_actions.gd")
const Base = preload("res://core/actions.gd")

class Move extends Previous.Move:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var adjusted: Dictionary = definition.duplicate(true)
		var attacker: Dictionary = actor.duplicate(true)
		if definition.id=="facade" and actor.status!=null: adjusted.power *= 2
		if definition.id=="foul-play": attacker.attack = target.attack; attacker.baseCombatStats.attack = target.baseCombatStats.attack
		if actor.get("spatial",{}).get("effects",{}).has("help") and definition.category!="status": adjusted.power = int(floor(adjusted.power*1.5))
		if definition.get("pierceGuard",false):
			target = target.duplicate(true)
			target.guarded = false
		var result: Dictionary = Previous.Move.new(adjusted,chart).preview(attacker,target)
		if definition.get("healTarget",false): result.heal = mini(target.maxHp-target.hp,maxi(1,int(target.maxHp/2.0))); result.statusReason = null
		if definition.get("healTarget",false) and result.heal<=0: result.statusReason = "Ya tiene todos sus PS."
		if definition.get("special","")=="haze": result.clearStages = true
		return result

static func create(definition: Dictionary, chart: Dictionary) -> Base.TacticalAction:
	return Move.new(definition,chart)
