extends "res://core/growth.gd"

func _init() -> void:
	super()
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/letsgo.json"))
	species.clear()
	families.clear()
	for record: Dictionary in data.species: species[int(record.id)] = record
	for family: Dictionary in data.families:
		for identity: int in family.members: families[identity] = family

func roles(member: Dictionary) -> String:
	var family: Dictionary = families[int(member.speciesId)]
	var counts: Array = [0,0]
	for move: String in member.moves:
		var entries: Array = family.learnset.filter(func(e):return e.id==move)
		if not entries.is_empty(): counts[int(entries[0].role)] += 1
	return "%s %d · %s %d" % [family.roles[0],counts[0],family.roles[1],counts[1]]
