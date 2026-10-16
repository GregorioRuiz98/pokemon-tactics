extends "res://core/kanto_pokemon.gd"

const ProgressActions = preload("res://core/progression_actions.gd")
var progression: RefCounted
var library: Dictionary = {}

func _init(record: Dictionary, chart: Dictionary, study: RefCounted) -> void:
	progression = study
	var copy: Dictionary = record.duplicate(true)
	copy.actions = {"current":[study.BASIC], "classic":[study.BASIC]}
	super(copy,chart)
	library.basic = ProgressActions.create(study.BASIC,chart)
	for identity: String in study.data.moves: library[identity] = ProgressActions.create(study.data.moves[identity],chart)

func actions_for(unit: Dictionary) -> Array:
	var result: Array = [library.basic]
	for identity: String in unit.get("moves",[]):
		if library.has(identity) and identity != "basic": result.append(library[identity])
	return result.slice(0,int(unit.get("actionLimit",99)))

func create_unit(identity: int, team: String, point: Dictionary, mode: String) -> Dictionary:
	var unit: Dictionary = super.create_unit(identity,team,point,mode)
	var member: Dictionary = progression.create_member(identity,int(data.id),"",5)
	unit.merge(progression.stats(int(data.id),5),true)
	unit.level = 5
	unit.hp = unit.maxHp
	unit.moves = member.moves
	unit.stages = {}
	unit.baseCombatStats = {}
	for key: String in progression.STAT_KEYS: unit.baseCombatStats[key] = unit[key]
	return unit
