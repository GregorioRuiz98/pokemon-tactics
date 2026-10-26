extends "res://core/adventure_battle.gd"

const Landscape = preload("res://core/kanto_landscape.gd")

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var state: Dictionary = super.encounter(run,location)
	Landscape.apply(state,location)
	return state
