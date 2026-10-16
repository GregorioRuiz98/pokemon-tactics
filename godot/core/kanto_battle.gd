extends "res://core/battle.gd"

var catalog: Dictionary
const KantoPokemon = preload("res://core/kanto_pokemon.gd")

func _init() -> void:
	super()
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/kanto-catalog.json"))
	var chart: Dictionary = {}
	for a: int in data.types.size():
		chart[data.types[a]] = {}
		for b: int in data.types.size(): chart[data.types[a]][data.types[b]] = data.typeChart[a][b]
	for record: Dictionary in catalog.species:
		profiles[int(record.id)] = KantoPokemon.new(record, chart)
	data.species = catalog.species

func member_unit(member: Dictionary, point: Dictionary = {"x": 0, "y": 0}) -> Dictionary:
	var unit: Dictionary = profiles[int(member.speciesId)].create_unit(int(member.id), "ally", point, "current")
	for stat: String in member.training: unit[stat] += int(member.training[stat]) * 5
	unit.hp = mini(member.hp, unit.maxHp)
	return unit

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var units: Array = []
	var starts: Array = [{"x": 2, "y": 7}, {"x": 1, "y": 8}, {"x": 3, "y": 8}, {"x": 1, "y": 7}, {"x": 3, "y": 7}, {"x": 2, "y": 8}]
	for member: Dictionary in run.party:
		if member.hp > 0: units.append(member_unit(member, starts[units.size()]))
	for i: int in location.enemies.size():
		units.append(profiles[int(location.enemies[i])].create_unit(10000 + int(run.stage) * 10 + i, "enemy", {"x": 7 + (i % 2) * 2, "y": 2 + (i >> 1)}, "current"))
		units[-1].actionLimit = location.enemyActionLimit
	var battle: Dictionary = {"seed": run.seed + "/" + location.id, "rng": Rng.hash_seed(run.seed + "/" + location.id), "variance": 0.05, "composition": "kanto", "round": 0, "board": location.board.duplicate(true), "fields": [], "units": units, "initiative": [], "queue": [], "completed": [], "moved": false, "acted": false, "outcome": "playing", "log": [], "biome": location.id}
	new_round(battle)
	return battle
