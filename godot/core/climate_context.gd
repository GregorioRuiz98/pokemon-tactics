extends RefCounted

const Flat = preload("res://core/movement.gd")
const Geometry = preload("res://core/spatial_geometry.gd")
const AURAS: Dictionary = {"cloud-nine":3,"neutralizing-gas":2,"illuminate":2,"magnet-pull":2,"pressure":2,"arena-trap":1}
const WEATHER_NAMES: Dictionary = {"clear":"Despejado","sun":"Sol","rain":"Lluvia","sand":"Tormenta de arena"}

static func native(unit: Dictionary) -> String:
	return unit.get("nativeAbility",unit.get("ability",""))

static func near(state: Dictionary, source: Dictionary, point: Dictionary, radius: int) -> bool:
	return source.hp>0 and Flat.distance(source,point)<=radius and Geometry.visible(state,source,point)

static func ability(state: Dictionary, unit: Dictionary) -> String:
	var identity: String = native(unit)
	if identity=="neutralizing-gas": return identity
	for source: Dictionary in state.units:
		if source.id!=unit.id and native(source)=="neutralizing-gas" and near(state,source,unit,2): return ""
	return identity

static func aura(state: Dictionary, unit: Dictionary, identity: String, allied: bool = false) -> bool:
	for source: Dictionary in state.units:
		if (source.team==unit.team if allied else true) and native(source)==identity and ability(state,source)==identity and near(state,source,unit,AURAS[identity]): return true
	return false

static func weather(state: Dictionary, unit: Dictionary) -> String:
	return "clear" if aura(state,unit,"cloud-nine") else state.get("weather",{}).get("kind","clear")

static func materialize(state: Dictionary) -> void:
	for unit: Dictionary in state.units:
		if not unit.has("nativeAbility"): unit.nativeAbility = unit.get("ability","")
	for unit: Dictionary in state.units:
		unit.ability = ability(state,unit)
		unit.climateWeather = weather(state,unit)
		unit.climateLight = aura(state,unit,"illuminate",true)

static func restore(state: Dictionary) -> void:
	for unit: Dictionary in state.units:
		unit.ability = native(unit)
		unit.erase("climateWeather"); unit.erase("climateLight")

static func planning(state: Dictionary, origin: Dictionary = {}) -> Dictionary:
	var copy: Dictionary = state.duplicate()
	copy.units = state.units.map(func(u):return u.duplicate(true))
	if not origin.is_empty() and not copy.queue.is_empty():
		for unit: Dictionary in copy.units:
			if unit.id==copy.queue[0]: unit.merge(origin,true)
	materialize(copy)
	return copy

static func gender(campaign_seed: String, member: Dictionary, rates: Dictionary) -> String:
	var rate: int = int(rates.get(str(int(member.speciesId)),-1))
	if rate<0: return ""
	var roll: int = preload("res://core/seeded_rng.gd").hash_seed(campaign_seed+"/gender/"+str(int(member.id)))%8
	return "female" if roll<rate else "male"

static func gender_symbol(unit: Dictionary) -> String:
	return {"female":"♀","male":"♂"}.get(unit.get("gender",""),"—")

static func label(state: Dictionary) -> String:
	var value: Dictionary = state.get("weather",{})
	var name_text: String = WEATHER_NAMES.get(value.get("kind","clear"),"Despejado")
	return name_text+(" · hasta R.%d"%[int(value.expires)-1] if value.get("kind","clear")!="clear" else "")
