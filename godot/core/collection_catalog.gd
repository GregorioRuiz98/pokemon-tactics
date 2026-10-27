extends RefCounted

const LEGENDS: Array[int] = [144,145,146,150,151]
static var bases: Dictionary = {}
static var minimums: Dictionary = {}
static var records: Dictionary = {}

static func prepare() -> void:
	if not bases.is_empty(): return
	var evolutions: Dictionary = {}
	for path: String in ["res://data/letsgo.json","res://data/expedition.json"]:
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for entry: Dictionary in catalog.species: records[int(entry.id)] = entry
		for family: Dictionary in catalog.families:
			for species: int in family.members: bases[species] = int(family.members[0])
		evolutions.merge(catalog.evolutions,true)
	var economy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	for species: int in bases: minimums[species] = 5 if bases[species]==species else 75
	for iteration: int in 4:
		for previous: String in evolutions:
			var entry: Array = evolutions[previous]
			minimums[int(entry[0])] = maxi(int(minimums[int(previous)]),int(entry[1]))
		for previous: String in economy.freeEvolutions:
			for entry: Array in economy.freeEvolutions[previous]:
				minimums[int(entry[0])] = maxi(int(minimums[int(previous)]),int(entry[1]))

static func base_species(species: int) -> int:
	prepare()
	return int(bases.get(species,0))

static func record(species: int) -> Dictionary:
	prepare()
	return records.get(species,{})

static func minimum_level(species: int) -> int:
	prepare()
	return int(minimums.get(species,75))

static func starter_options(obtained: Array) -> Array[int]:
	var result: Array[int] = [1,4,7]
	for species: Variant in obtained:
		var first: int = base_species(int(species))
		if first>0 and first not in result: result.append(first)
	result.sort()
	return result
