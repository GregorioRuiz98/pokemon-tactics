extends RefCounted

const Previous = preload("res://core/letsgo_actions.gd")
const Base = preload("res://core/actions.gd")

class Move extends Previous.Move:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		if definition.kind=="focus":
			var focus: Dictionary = Base.TacticalAction.new(definition,chart).preview(actor,target)
			if actor.get("volatile",{}).has("focus"): focus.statusReason = "Foco Energía ya está activo."
			else: focus.focus = true
			return focus
		var result: Dictionary = super.preview(actor,target)
		result.maximumDamage = result.damage
		result.criticalMaximum = result.damage
		if definition.category=="status" or definition.get("fixedMode","")!="" or result.multiplier==0: return result
		# Compute the range before current-HP clipping, so a nearly defeated target
		# cannot turn a guaranteed KO into an artificial low damage roll.
		var durable: Dictionary = target.duplicate(true)
		durable.hp = 1000000000
		var normal: Dictionary = super.preview(actor,durable)
		result.maximumDamage = normal.damage
		var attacker: Dictionary = actor.duplicate(true)
		var defender: Dictionary = durable.duplicate(true)
		var offense: String = "attack" if definition.category=="physical" else "specialAttack"
		var defense: String = "defense" if definition.category=="physical" else "specialDefense"
		if attacker.get("stages",{}).get(offense,0)<0: attacker[offense] = attacker.baseCombatStats[offense]
		if defender.get("stages",{}).get(defense,0)>0: defender[defense] = defender.baseCombatStats[defense]
		var critical: Dictionary = super.preview(attacker,defender)
		result.criticalMaximum = maxi(1,int(floor(critical.damage*1.5)))
		return result

static func create(definition: Dictionary, chart: Dictionary) -> Base.TacticalAction:
	return Move.new(definition,chart)
