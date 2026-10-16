extends "res://core/progression.gd"

var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/growth.json"))

func _init() -> void:
	super()
	var shop: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))
	data.moves.merge(shop.moves,true)
	for identity: String in config.evolutionMoves:
		var entry: Dictionary = config.evolutionMoves[identity]
		families[int(identity)].learnset.push_front({"id":entry.move,"level":entry.level,"role":entry.role,"forms":[int(identity)]})
	families[25].learnset.push_front({"id":"iron-tail","level":int(config.ironTailLevel),"role":0,"forms":[25,26]})
	for identity: String in config.adaptedEvolutions: data.evolutions[identity][1] = int(config.adaptedEvolutions[identity])

func _evolve_ready(member: Dictionary, evolved: Array, learned: Array) -> void:
	var requirement: Dictionary = evolution(member)
	while not requirement.is_empty() and member.level>=requirement.level:
		var previous: int = member.speciesId
		member.speciesId = int(requirement.speciesId)
		member.hp = mini(member.hp,stats(int(member.speciesId),int(member.level)).maxHp)
		evolved.append({"from":previous,"to":member.speciesId,"level":member.level})
		learned.append_array(learn(member))
		requirement = evolution(member)

func _receipt(member: Dictionary, before: int, amount: int, learned: Array, evolved: Array) -> Dictionary:
	return {"member":member.id,"name":species[int(member.speciesId)].name,"xp":amount,"before":before,"level":member.level,"learned":learned,"evolutions":evolved}

func award(member: Dictionary, amount: int) -> Dictionary:
	var before: int = member.level
	var learned: Array = []
	var evolved: Array = []
	if member.hp<=0: return _receipt(member,before,0,learned,evolved)
	member.xp += amount
	while member.level<data.levelCap and member.xp>=next_xp(member.level):
		member.xp -= next_xp(member.level)
		member.level += 1
		learned.append_array(learn(member))
		_evolve_ready(member,evolved,learned)
	if member.level==data.levelCap: member.xp = 0
	return _receipt(member,before,amount,learned,evolved)

func candy(member: Dictionary) -> Dictionary:
	var before: int = member.level
	var learned: Array = []
	var evolved: Array = []
	if member.hp<=0 or member.level>=data.levelCap: return _receipt(member,before,0,learned,evolved)
	member.level += 1
	learned.append_array(learn(member))
	_evolve_ready(member,evolved,learned)
	# A purchased level preserves earned partial EXP; neither level nor evolution heals.
	if member.level==data.levelCap: member.xp = 0
	return _receipt(member,before,0,learned,evolved)
