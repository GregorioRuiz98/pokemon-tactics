extends RefCounted

const Previous = preload("res://core/spatial_actions.gd")
const Base = preload("res://core/actions.gd")

class Move extends Previous.Move:
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		if definition.has("weather"):
			var empty: Dictionary = Base.TacticalAction.new(definition,chart).preview(actor,target)
			empty.merge({"staticChance":0.0,"abilityHints":[],"changes":[],"changesSelf":false},true)
			return empty
		var move: Dictionary = definition
		var effective_chart: Dictionary = chart
		if actor.get("ability")=="scrappy" and definition.type in ["normal","fighting"]:
			effective_chart = chart.duplicate(true); effective_chart[definition.type].ghost = 1
		if actor.get("ability")=="rivalry" and actor.get("gender","")!="" and target.get("gender","")!="" and definition.category!="status" and definition.get("fixedMode","")=="":
			move = definition.duplicate(true)
			move.power = maxi(1,int(floor(move.power*(1.25 if actor.gender==target.gender else .75))))
		var hit: Dictionary = Previous.Move.new(move,effective_chart).preview(actor,target)
		if actor.get("ability")=="sniper" and hit.get("criticalMaximum",0)>0: hit.criticalMaximum = maxi(1,int(floor(hit.criticalMaximum*1.5)))
		return hit

static func create(definition: Dictionary, chart: Dictionary) -> Base.TacticalAction:
	return Move.new(definition,chart)
