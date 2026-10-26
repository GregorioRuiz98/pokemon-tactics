extends "res://core/landscape_battle.gd"

const Points = preload("res://core/power_points.gd")
const Restorative = preload("res://core/restorative_tiles.gd")

func _init() -> void:
	super()
	progression = preload("res://core/power_study.gd").new()
	catalog = progression.data
	var chart: Dictionary = profiles[1].library.basic.chart
	profiles.clear()
	for record: Dictionary in catalog.species:
		var pokemon: RefCounted = Profile.new(record,chart,progression)
		var basic: Dictionary = progression.BASIC.duplicate(true)
		basic.merge(progression.spatial_data.moves.basic,true)
		basic.loadoutCost = 0; basic.permanentStages = true
		basic.description = "Golpe neutro. Sin tipo ni STAB."
		pokemon.library.basic = SpatialActions.create(basic,chart)
		for identity: String in catalog.moves: pokemon.library[identity] = SpatialActions.create(catalog.moves[identity],chart)
		profiles[int(record.id)] = pokemon

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = super.member_unit(member,point)
	_set_budget(unit)
	return unit

func _set_budget(unit: Dictionary) -> void:
	unit.moves = Points.fit(unit.moves,unit.level,catalog.moves)
	unit.ppUsed = Points.used(unit.moves,catalog.moves); unit.ppCapacity = Points.capacity(unit.level)
	unit.permanentStages = true; unit.stageTurns = {}; unit.tp = 0; unit.maxTp = 0
	unit.combatEdition = 20

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var state: Dictionary = super.encounter(run,location)
	for unit: Dictionary in state.units: _set_budget(unit)
	state.combatEdition = 20
	Restorative.place(state,self)
	return state

func new_round(state: Dictionary) -> void:
	super.new_round(state)
	state.combatEdition = 20

func cast_plan(state: Dictionary, aim: Dictionary, identity: String = "basic", origin: Dictionary = {}) -> Dictionary:
	# The old engine checks Pressure and recovery uses. Neither is an action cost
	# in this edition. Query a copy, then return a zero-cost plan without RNG.
	var planning: Dictionary = state.duplicate()
	planning.units = state.units.duplicate()
	var current: Dictionary = active(state)
	var actor: Dictionary = current.duplicate()
	if not current.is_empty():
		planning.units[state.units.find(current)] = actor
		actor.tp = 5
		actor.recoveryPP = current.recoveryPP.duplicate()
		for key: String in actor.get("recoveryPP",{}): actor.recoveryPP[key] = 1
	var plan: Dictionary = super.cast_plan(planning,aim,identity,origin)
	if plan.ok: plan.cost = 0
	return plan

func cast(state: Dictionary, aim: Dictionary, identity: String) -> Dictionary:
	var previous: Dictionary = active(state)
	var result: Dictionary = super.cast(state,aim,identity)
	if result.ok:
		var actor: Dictionary = unit_by_id(result.state,int(previous.id))
		actor.recoveryPP = previous.recoveryPP.duplicate(true)
		actor.tp = 0; actor.maxTp = 0
		for index: int in result.state.log.size(): result.state.log[index] = result.state.log[index].replace(" (0 PT)","")
	return result

func _change(unit: Dictionary, change: Dictionary) -> void:
	super._change(unit,change)
	unit.stageTurns.clear()

func finish(state: Dictionary, facing: Variant = null) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	var actor: Dictionary = active(next)
	if actor.is_empty(): return super.finish(state,facing)
	actor.stageTurns.clear()
	if Restorative.cure(next,actor): note(next,actor.name+": estado curado en el manantial.")
	var focus: Dictionary = actor.volatile.get("focus",{}).duplicate(true)
	actor.volatile.erase("focus")
	var result: Dictionary = super.finish(next,facing)
	if result.ok and not focus.is_empty(): unit_by_id(result.state,int(actor.id)).volatile.focus = focus
	return result

func movement_value(state: Dictionary, actor: Dictionary, point: Dictionary, enemy: Dictionary, danger: float) -> float:
	var value: float = super.movement_value(state,actor,point,enemy,danger)
	if (actor.status!=null or actor.volatile.has("confusion")) and Restorative.contains(state,point): value -= 8
	return value
