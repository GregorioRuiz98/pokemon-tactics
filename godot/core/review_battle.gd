extends "res://core/climate_battle.gd"

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = super.member_unit(member,point)
	unit.combatEdition = 23
	return unit

func new_round(state: Dictionary) -> void:
	super.new_round(state)
	state.combatEdition = 23

func action_score(state: Dictionary, target: Dictionary, plan: Dictionary) -> float:
	if not plan.ok: return 0
	var actor: Dictionary = active(state)
	var scored: Dictionary = plan.duplicate(true)
	var attributes: float = 0
	for hit: Dictionary in scored.hits:
		var victim: Dictionary = unit_by_id(state,int(hit.targetId))
		var affected: Dictionary = actor if hit.get("changesSelf",false) else victim
		for change: Dictionary in hit.get("changes",[]):
			var before: int = int(affected.stages.get(change.stat,0))
			var delta: int = clampi(before+int(change.stages),-2,2)-before
			var useful: bool = (affected.team==actor.team and delta>0) or (affected.team!=actor.team and delta<0)
			attributes += absi(delta)*4*(1 if useful else -2)
		hit.changes = []
		if hit.guard and victim.guarded: hit.guard = false
		if hit.heal>0:
			var recipient: Dictionary = victim if plan.definition.get("healTarget",false) else actor
			hit.heal = mini(int(hit.heal),int(recipient.maxHp-recipient.hp))
	var value: float = super.action_score(state,target,scored)+attributes
	if plan.get("field","")!="" and not plan.tiles.is_empty():
		var already_covered: bool = plan.tiles.all(func(p):return state.fields.any(func(f):return f.kind==plan.field and Movement.same(f,p) and int(f.expires)>state.round+1))
		if already_covered and plan.hits.all(func(h):return h.damage==0 and h.heal==0): return 0
	return value
