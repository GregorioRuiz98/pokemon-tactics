extends "res://core/expedition_battle.gd"

const RECOVERY: Array[String] = ["roost","recover","soft-boiled","rest"]

func _init() -> void:
	super()
	progression.traits.abilities.pressure.description += " El básico neutro está exento."
	for identity: String in RECOVERY:
		catalog.moves[identity].description += " Recuperación limitada a 5 usos por combate; se restablecen al iniciar otro encuentro."

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = super.member_unit(member,point)
	unit.recoveryPP = {}
	for identity: String in RECOVERY: unit.recoveryPP[identity] = 5
	return unit

func encounter(run: Dictionary, location: Dictionary) -> Dictionary:
	var state: Dictionary = super.encounter(run,location)
	if not location.get("finale",false): return state
	var kits: Dictionary = {144:["ice-beam","gust","reflect","roost"],145:["thunderbolt","drill-peck","light-screen","roost"],146:["flamethrower","air-slash","solar-beam","roost"],150:["psychic","swift","recover","amnesia"],151:["confusion","mega-punch","amnesia","barrier"]}
	for unit: Dictionary in state.units:
		if unit.team!="enemy": continue
		var known: Array = progression.create_member(int(unit.id),int(unit.speciesId),location.name,int(unit.level)).knownMoves
		unit.moves = kits[int(unit.speciesId)].filter(func(identity):return identity in known)
	return state

func new_round(state: Dictionary) -> void:
	super.new_round(state)
	state.combatEdition = 17

func attack_plan(state: Dictionary, target_id: int, origin: Dictionary = {}, action_id: String = "basic") -> Dictionary:
	var actor: Dictionary = active(state)
	if action_id in RECOVERY and not actor.is_empty() and int(actor.get("recoveryPP",{}).get(action_id,0))<=0: return {"ok":false,"reason":"No quedan usos de recuperación para este movimiento en este combate."}
	# The mandatory neutral attack must remain usable with zero PT, including Pressure.
	if action_id=="basic" and unit_by_id(state,target_id).get("ability")=="pressure":
		var preview: Dictionary = state.duplicate(true)
		unit_by_id(preview,target_id).ability = ""
		return super.attack_plan(preview,target_id,origin,action_id)
	return super.attack_plan(state,target_id,origin,action_id)

func attack(state: Dictionary, target_id: int, action_id: String = "basic") -> Dictionary:
	var result: Dictionary = super.attack(state,target_id,action_id)
	if result.ok and action_id in RECOVERY:
		var actor: Dictionary = unit_by_id(result.state,int(active(state).id))
		actor.recoveryPP[action_id] -= 1
		note(result.state,"%s: %d / 5 usos de recuperación." % [actor.name,actor.recoveryPP[action_id]])
	return result
