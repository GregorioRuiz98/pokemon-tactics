extends RefCounted

const Traits = preload("res://core/traits_actions.gd")
const Base = preload("res://core/actions.gd")

class Move extends Traits.Move:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var attacker: Dictionary = actor.duplicate(true)
		var defender: Dictionary = target.duplicate(true)
		var move: Dictionary = definition.duplicate(true)
		var source: String = actor.get("ability","")
		var protection: String = target.get("ability","")
		var hints: Array = []
		if source=="mold-breaker": defender.ability = ""; protection = ""
		if source=="technician" and move.power>0 and move.power<=60: move.power = int(floor(move.power*1.5)); hints.append(actor.abilityName)
		if source=="adaptability" and move.type in actor.types: move.power = int(floor(move.power*4.0/3)); hints.append(actor.abilityName)
		if source=="iron-fist" and "punch" in move.id: move.power = int(floor(move.power*1.2)); hints.append(actor.abilityName)
		if source=="reckless" and move.get("recoil",0)>0: move.power = int(floor(move.power*1.2)); hints.append(actor.abilityName)
		if source=="skill-link" and move.id in ["fury-swipes","fury-attack","pin-missile","bullet-seed","icicle-spear"]: move.power = int(floor(move.power*2.5)); hints.append(actor.abilityName)
		if protection=="thick-fat" and move.type in ["fire","ice"]: move.power = int(floor(move.power*0.5)); hints.append(target.abilityName)
		if protection=="dry-skin" and move.type=="fire": move.power = int(floor(move.power*1.25)); hints.append(target.abilityName)
		if source=="serene-grace":
			if move.get("secondary")!=null: move.secondary.chance = mini(100,int(move.secondary.chance)*2)
			move.changeChance = mini(100,int(move.get("changeChance",0))*2)
		var result: Dictionary = Traits.Move.new(move,chart).preview(attacker,defender)
		if move.id=="rest":
			result.heal = maxi(0,int(actor.maxHp)-int(actor.hp))
			result.statusReason = null
			if result.heal==0: result.statusReason = "Ya tiene todos sus PS."
		result.abilityHints.append_array(hints)
		var immune: bool = (protection=="levitate" and move.type=="ground") or (protection in ["water-absorb","dry-skin"] and move.type=="water") or (protection in ["volt-absorb","lightning-rod"] and move.type=="electric") or (protection=="flash-fire" and move.type=="fire") or (protection=="soundproof" and move.id in ["growl","roar","sing","supersonic","screech","hyper-voice","bug-buzz"])
		if immune and actor.id!=target.id:
			for key: String in ["damage","maximumDamage","criticalMaximum"]: result[key] = 0
			result.multiplier = 0
			result.status = null
			result.changes = []
			result.erase("volatile")
			result.statusReason = "Lo impide "+target.abilityName
			result.absorb = protection if protection in ["water-absorb","dry-skin","volt-absorb","lightning-rod","flash-fire"] else ""
			result.abilityHints.append(target.abilityName)
		if source=="tinted-lens" and result.multiplier>0 and result.multiplier<1:
			for key: String in ["damage","maximumDamage","criticalMaximum"]: result[key] = int(result.get(key,0))*2
		if protection=="filter" and result.multiplier>1:
			for key: String in ["damage","maximumDamage","criticalMaximum"]: result[key] = maxi(1,int(floor(result.get(key,0)*0.75)))
		var status_immunities: Dictionary = {"limber":"paralysis","immunity":"poison","water-veil":"burn","magma-armor":"freeze","insomnia":"sleep","vital-spirit":"sleep"}
		if result.status!=null and result.status.kind==status_immunities.get(protection,""):
			result.status = null
			result.statusReason = "Lo impide "+target.abilityName
		if protection=="own-tempo" and result.get("volatile",{}).get("kind","")=="confusion": result.erase("volatile"); result.statusReason = "Ritmo Propio impide confusión."
		if not result.get("changesSelf",false):
			var original: Array = result.get("changes",[])
			result.changes = original.filter(func(c):return c.stages>=0 or not (protection=="clear-body" or (protection=="hyper-cutter" and c.stat=="attack")))
			if move.category=="status" and not original.is_empty() and result.changes.is_empty(): result.statusReason = "Lo impide "+target.abilityName
		return result

static func create(definition: Dictionary, chart: Dictionary) -> Base.TacticalAction:
	return Move.new(definition,chart)
