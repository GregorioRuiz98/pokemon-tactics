class_name LabPokemon
extends RefCounted

const Actions = preload("res://core/actions.gd")
var data: Dictionary
var kits: Dictionary = {}

func _init(record: Dictionary, chart: Dictionary):
	data = record
	for mode in ["classic", "current"]:
		kits[mode] = []
		for definition in record.actions[mode]: kits[mode].append(Actions.create(definition, chart))

func actions_for(unit: Dictionary) -> Array:
	return kits.current if unit.get("ruleset", 6) >= 14 else kits.classic

func action(unit: Dictionary, identity: String):
	for entry in actions_for(unit):
		if entry.definition.id == identity: return entry
	return null

func create_unit(identity: int, team: String, point: Dictionary, mode: String) -> Dictionary:
	var stats = data.baseStats
	var hp = int(floor(35 + stats.hp / 3.0 + 0.5)) * (2 if mode == "current" else 1)
	var profile = "fly" if "flying" in data.types else ("swim" if "water" in data.types else ("grass" if "grass" in data.types else "ground"))
	var unit = {"x": point.x, "y": point.y, "id": identity, "speciesId": data.id, "heldItem": null, "name": data.name, "team": team, "types": data.types.duplicate(), "budget": data.movement, "remaining": data.movement, "facing": 4 if team == "ally" else 0, "maxHp": hp, "hp": hp, "attack": stats.attack, "defense": stats.defense, "specialAttack": stats["special-attack"], "specialDefense": stats["special-defense"], "speed": stats.speed, "range": kits.classic[0].definition.range, "profile": profile, "tp": 2, "maxTp": 5, "status": null, "guarded": false}
	if mode == "current": unit.ruleset = 14
	return unit
