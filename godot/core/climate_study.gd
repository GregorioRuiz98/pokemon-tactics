extends "res://core/power_study.gd"

const Climate = preload("res://core/climate_context.gd")
var climate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/climate.json"))

func _init() -> void:
	super()
	data.version = 25
	data.moves.merge(climate.moves,true)
	for identity: String in climate.compatible: climate.compatible[identity] = climate.compatible[identity].map(func(dex):return int(dex))
	var weather_abilities: Dictionary = {"sunny-day":["chlorophyll","leaf-guard"],"rain-dance":["swift-swim","hydration","dry-skin"],"sandstorm":["sand-veil"]}
	for family: Dictionary in data.families:
		for identity: String in weather_abilities:
			var forms: Array = family.members.filter(func(dex):return int(dex) in climate.compatible[identity] and abilities(int(dex)).any(func(a):return a.id in weather_abilities[identity]))
			if not forms.is_empty():
				var index: int = 0
				while index<family.learnset.size() and int(family.learnset[index].level)<=15: index += 1
				family.learnset.insert(index,{"id":identity,"level":15,"forms":forms})
	for identity: String in climate.abilities:
		var entry: Dictionary = traits.abilities[identity]
		entry.name = entry.name.replace(" · pendiente","").replace(" · sin efecto","")
		entry.description = climate.abilities[identity]
		entry.implemented = true; entry.available = true

func assign(member: Dictionary, campaign_seed: String) -> void:
	super.assign(member,campaign_seed)
	if not member.has("gender"): member.gender = Climate.gender(campaign_seed,member,climate.genderRates)

func roles(_member: Dictionary) -> String:
	return ""
