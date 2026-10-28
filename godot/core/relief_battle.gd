extends "res://core/tactics_quality_battle.gd"

const Relief = preload("res://core/relief_maps.gd")
var initial_positions: Dictionary = {}

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = super.member_unit(member,initial_positions.get(int(member.id),point))
	unit.combatEdition = 25
	return unit

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var layout: Dictionary = Relief.design(location.id)
	var offset: int = int((int(run.mapSize)-16)/2.0)
	initial_positions = {}
	var index: int = 0
	for member: Dictionary in run.party:
		if member.hp<=0: continue
		initial_positions[int(member.id)] = Relief.point(layout.allies[index],offset); index += 1
	for enemy: int in layout.enemies.size(): initial_positions[10000+int(run.stage)*10+enemy] = Relief.point(layout.enemies[enemy],offset)
	var state: Dictionary = super.encounter(run,location)
	initial_positions = {}
	Relief.apply(state,location.id)
	Restorative.place(state,self)
	state.combatEdition = 25
	return state

func new_round(state: Dictionary) -> void:
	super.new_round(state)
	state.combatEdition = 25
