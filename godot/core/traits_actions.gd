extends RefCounted

const Tactical = preload("res://core/tactics_actions.gd")
const Base = preload("res://core/actions.gd")

class Move extends Tactical.Move:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var attacker: Dictionary = actor.duplicate(true)
		var defender: Dictionary = target.duplicate(true)
		var move: Dictionary = definition.duplicate(true)
		var source: String = actor.get("ability","")
		var hints: Array[String] = []
		if move.category!="status" and move.get("fixedMode","")=="":
			var types: Dictionary = {"overgrow":"grass","blaze":"fire","torrent":"water","swarm":"bug"}
			if types.get(source,"")==move.type and actor.hp*3<=actor.maxHp:
				move.power = int(floor(move.power*1.5))
				hints.append(actor.get("abilityName",source))
			if source=="guts" and actor.status!=null and move.category=="physical":
				attacker.attack = maxi(1,int(floor(attacker.attack*1.5)))
				attacker.baseCombatStats.attack = maxi(1,int(floor(attacker.baseCombatStats.attack*1.5)))
				if actor.status.kind=="burn": attacker.status = null
				hints.append(actor.get("abilityName",source))
		# Sturdy may prevent the KO, so let secondary-effect preview see a survivor.
		if target.get("ability")=="sturdy" and target.hp==target.maxHp: defender.hp = 1000000000
		var result: Dictionary = Tactical.Move.new(move,chart).preview(attacker,defender)
		result.damage = mini(target.hp,result.damage)
		if target.get("ability")=="shield-dust" and move.category!="status" and actor.id!=target.id:
			if result.status!=null or result.has("volatile") or (not result.get("changesSelf",false) and not result.get("changes",[]).is_empty()): hints.append(target.get("abilityName","Polvo Escudo"))
			result.status = null
			result.erase("volatile")
			if not result.get("changesSelf",false): result.changes = []
		if target.get("ability")=="keen-eye" and not result.get("changesSelf",false):
			var changes: Array = result.get("changes",[])
			if changes.any(func(c):return c.stat=="accuracy" and c.stages<0): hints.append(target.get("abilityName","Vista Lince"))
			result.changes = changes.filter(func(c):return c.stat!="accuracy" or c.stages>=0)
			if move.category=="status" and not changes.is_empty() and result.changes.is_empty(): result.statusReason = "Vista Lince impide bajar la precisión."
		result.abilityHints = hints
		return result

static func create(definition: Dictionary, chart: Dictionary) -> Base.TacticalAction:
	return Move.new(definition,chart)
