extends "res://core/gym_study.gd"

const TraitRng = preload("res://core/seeded_rng.gd")
var traits: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/traits.json"))

func _init() -> void:
	super()
	data.version = 10
	# Legacy Graveler/Golem records lack the movement field; repair only this edition.
	for record: Dictionary in data.species:
		if not record.has("movement"): record.movement = species[74].movement

func abilities(identity: int) -> Array:
	return traits.species[str(identity)]

func ability(member: Dictionary) -> String:
	var options: Array = abilities(int(member.speciesId))
	for option: Dictionary in options:
		if option.slot==member.get("abilitySlot",1): return option.id
	return options[0].id

func assign(member: Dictionary, seed: String) -> void:
	if member.get("traitsAssigned",false): return
	var rng: Dictionary = {"rng":TraitRng.hash_seed(seed+"/traits/"+str(int(member.id)))}
	var choices: Array = traits.natures.keys()
	member.nature = choices[int(floor(TraitRng.next(rng)*choices.size()))]
	member.mint = null
	var options: Array = abilities(int(member.speciesId))
	member.abilitySlot = options[int(floor(TraitRng.next(rng)*options.size()))].slot
	member.traitsAssigned = true

func effective_nature(member: Dictionary) -> String:
	return member.mint if member.get("mint")!=null else member.get("nature","hardy")

func member_stats(member: Dictionary) -> Dictionary:
	var result: Dictionary = stats(int(member.speciesId),int(member.level))
	var nature: Dictionary = traits.natures[effective_nature(member)]
	if nature.up!="": result[nature.up] = maxi(1,int(floor(result[nature.up]*1.1)))
	if nature.down!="": result[nature.down] = maxi(1,int(floor(result[nature.down]*0.9)))
	return result

func nature_text(member: Dictionary) -> String:
	var nature: Dictionary = traits.natures[effective_nature(member)]
	var text: String = "Naturaleza: "+traits.natures[member.get("nature","hardy")].name
	if member.get("mint")!=null: text += " · Menta "+nature.name
	return text+(" · +10 %% %s / −10 %% %s" % [STAT_NAMES[nature.up],STAT_NAMES[nature.down]] if nature.up!="" else " · neutra")

func mintable() -> Array:
	return traits.natures.keys().filter(func(id):return traits.natures[id].up!="" or id=="serious")

func mint_changes(member: Dictionary, identity: String) -> bool:
	var before: Dictionary = traits.natures[effective_nature(member)]
	var after: Dictionary = traits.natures[identity]
	return before.up!=after.up or before.down!=after.down

func next_slot(member: Dictionary) -> int:
	var options: Array = abilities(int(member.speciesId))
	return 0 if options.size()<2 else int(options[1].slot if member.get("abilitySlot",1)==options[0].slot else options[0].slot)
