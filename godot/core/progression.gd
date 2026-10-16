extends RefCounted

var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression.json"))
var species: Dictionary = {}
var families: Dictionary = {}
const STAT_KEYS = {"attack":"attack", "defense":"defense", "specialAttack":"special-attack", "specialDefense":"special-defense", "speed":"speed"}
const STAT_NAMES = {"attack":"Ataque","defense":"Defensa","speed":"Velocidad","specialAttack":"At. especial","specialDefense":"Def. especial"}
const BASIC = {"id":"basic", "name":"Básico", "type":"typeless", "power":25, "cost":0, "range":1, "kind":"damage", "target":"enemy", "accuracy":100, "category":"physical", "secondary":null, "embers":false, "description":"Golpe neutro. Sin tipo, STAB, debilidades ni resistencias; consume la acción y no gasta PT."}

func _init() -> void:
	for record: Dictionary in data.species: species[int(record.id)] = record
	for family: Dictionary in data.families:
		for identity: int in family.members: families[identity] = family

func stats(identity: int, level: int) -> Dictionary:
	var base: Dictionary = species[identity].baseStats
	# Neutral nature, fixed IV 15, EV 0; HP x4 is the explicit tactical adaptation.
	var result: Dictionary = {"maxHp":(int(floor((2 * base.hp + 15) * level / 100.0)) + level + 10) * 4}
	for key: String in STAT_KEYS: result[key] = int(floor((2 * base[STAT_KEYS[key]] + 15) * level / 100.0)) + 5
	return result

func learn(member: Dictionary) -> Array:
	var added: Array = []
	for entry: Dictionary in families[int(member.speciesId)].learnset:
		if member.level >= entry.level and entry.forms.any(func(id):return int(id) == int(member.speciesId)) and entry.id not in member.knownMoves:
			member.knownMoves.append(entry.id)
			added.append(entry.id)
			if member.moves.size() < 4: member.moves.append(entry.id)
	return added

func create_member(identity: int, species_id: int, origin: String, level: int) -> Dictionary:
	var member: Dictionary = {"id":identity, "speciesId":species_id, "origin":origin, "level":level, "xp":0, "hp":stats(species_id,level).maxHp, "training":{}, "knownMoves":[], "moves":[]}
	learn(member)
	return member

func next_xp(level: int) -> int:
	return 40 + level * 10

func award(member: Dictionary, amount: int) -> Dictionary:
	var before: int = member.level
	var learned: Array = []
	member.xp += amount
	while member.level < data.levelCap and member.xp >= next_xp(member.level):
		member.xp -= next_xp(member.level)
		member.level += 1
		learned.append_array(learn(member))
	if member.level == data.levelCap: member.xp = 0
	return {"member":member.id, "name":species[int(member.speciesId)].name, "xp":amount, "before":before, "level":member.level, "learned":learned}

func evolution(member: Dictionary) -> Dictionary:
	var value: Array = data.evolutions.get(str(int(member.speciesId)),[])
	return {} if value.is_empty() else {"speciesId":int(value[0]), "level":int(value[1])}

func roles(member: Dictionary) -> String:
	var family: Dictionary = families[int(member.speciesId)]
	var counts: Array = [0,0]
	for entry: Dictionary in family.learnset:
		if entry.id in member.moves: counts[int(entry.role)] += 1
	return "%s %d · %s %d" % [family.roles[0],counts[0],family.roles[1],counts[1]]
