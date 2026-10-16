extends "res://core/pokemon.gd"

func actions_for(unit: Dictionary) -> Array:
	return super.actions_for(unit).slice(0,int(unit.get("actionLimit",99)))
