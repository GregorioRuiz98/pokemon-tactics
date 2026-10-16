extends RefCounted

const Base = preload("res://core/actions.gd")

class Move extends Base.TacticalAction:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var result: Dictionary = super.preview(actor,target)
		var kind: String = definition.kind
		if definition.category != "status":
			result = Base.DamageAction.new(definition,chart).preview(actor,target)
			var fixed: String = definition.get("fixedMode","")
			if fixed != "":
				var amount: int = 40 if fixed=="dragon-rage" else (maxi(1,int(target.hp/2.0)) if fixed=="super-fang" else int(actor.get("lastDamage",0))*2)
				result.damage = 0 if result.multiplier==0 else mini(target.hp,amount)
				result.stab = 1
			elif actor.get("heldItem")=="life-orb" and result.damage>0:
				result.damage = mini(target.hp,maxi(1,int(floor(result.damage*1.3+0.5))))
			if kind=="drain": result.heal = mini(actor.maxHp-actor.hp,int(floor(result.damage/2.0)))
		elif kind=="status":
			var effect: Dictionary = definition.effect
			if effect.kind in ["seed","confusion"]:
				var reason: Variant = null
				if effect.kind=="seed" and "grass" in target.types: reason = "Planta es inmune a Drenadoras."
				if target.get("volatile",{}).has(effect.kind): reason = "Ese efecto ya está activo."
				result.statusReason = reason
				if reason==null: result.volatile = effect.duplicate(true)
			else:
				result = Base.StatusAction.new(definition,chart).preview(actor,target)
				if effect.kind=="freeze" and "ice" in target.types:
					result.status = null
					result.statusReason = "Hielo es inmune a congelación."
		elif kind=="guard": result.guard = true
		elif kind=="heal":
			result.heal = mini(actor.maxHp-actor.hp,maxi(1,int(actor.maxHp/2.0)))
			if result.heal==0: result.statusReason = "Ya tiene todos sus PS."
		if result.status!=null and result.status.kind=="confusion":
			if not target.get("volatile",{}).has("confusion"): result.volatile = result.status.duplicate(true)
			result.status = null
		if definition.get("clearStages",false) and result.multiplier!=0: result.clearStages = true
		if definition.get("changes",[]).size()>0 and result.multiplier!=0:
			var affected: Dictionary = actor if definition.get("changesSelf",false) else target
			var changes: Array = definition.changes.filter(func(c):return int(affected.get("stages",{}).get(c.stat,0))!=clampi(int(affected.get("stages",{}).get(c.stat,0))+int(c.stages),-2,2))
			result.changes = changes
			result.changesSelf = definition.get("changesSelf",false)
			if definition.category=="status" and changes.is_empty(): result.statusReason = "Los atributos afectados ya están en su límite."
		return result

static func create(definition: Dictionary, chart: Dictionary) -> Base.TacticalAction:
	return Move.new(definition,chart)
