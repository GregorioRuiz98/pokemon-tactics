extends "res://core/progression_battle.gd"

const Actions = preload("res://core/actions.gd")
const ProgressActions = preload("res://core/progression_actions.gd")
var shop_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))

class HeldAction extends Actions.TacticalAction:
	var wrapped: Actions.TacticalAction
	func _init(action: Actions.TacticalAction) -> void:
		wrapped = action
		super(action.definition,action.chart)
	func preview(actor: Dictionary, target: Dictionary) -> Dictionary:
		var result: Dictionary = wrapped.preview(actor,target)
		if actor.get("heldItem") == "life-orb" and result.damage > 0:
			result.damage = mini(target.hp,maxi(1,int(floor(result.damage*1.3+0.5))))
			if definition.kind == "drain": result.heal = mini(actor.maxHp-actor.hp,int(floor(result.damage/2.0)))
			if result.damage >= target.hp: result.status = null
		return result

func _init() -> void:
	super()
	progression.data.moves.merge(shop_data.moves,true)
	for identity: int in profiles:
		var profile_data: RefCounted = profiles[identity]
		var chart: Dictionary = profile_data.library.basic.chart
		for move: String in shop_data.moves: profile_data.library[move] = ProgressActions.create(shop_data.moves[move],chart)
		for move: String in profile_data.library: profile_data.library[move] = HeldAction.new(profile_data.library[move])

func member_unit(member: Dictionary, point: Dictionary = {"x":0,"y":0}) -> Dictionary:
	var unit: Dictionary = super.member_unit(member,point)
	unit.heldItem = member.get("heldItem",null)
	return unit

func attack_plan(state: Dictionary, target_id: int, origin: Dictionary = {}, action_id: String = "basic") -> Dictionary:
	var plan: Dictionary = super.attack_plan(state,target_id,origin,action_id)
	if plan.ok and active(state).get("heldItem") == "life-orb" and plan.hits.any(func(hit):return hit.damage>0):
		plan.recoil = maxi(1,int(floor(active(state).maxHp/10.0)))
	return plan

func attack(state: Dictionary, target_id: int, action_id: String = "basic") -> Dictionary:
	var actor: Dictionary = active(state)
	var result: Dictionary = super.attack(state,target_id,action_id)
	if not result.ok or actor.get("heldItem") != "life-orb" or not result.hits.any(func(hit):return hit.hit and hit.damage>0): return result
	var holder: Dictionary = unit_by_id(result.state,int(actor.id))
	var recoil: int = mini(holder.hp,maxi(1,int(floor(holder.maxHp/10.0))))
	holder.hp -= recoil
	result.hits.append({"targetId":holder.id,"hit":true,"damage":recoil,"recoil":true})
	if result.state.outcome != "playing":
		result.state.log.erase("Victoria: zona despejada." if result.state.outcome == "victory" else "Derrota: el equipo ha caído.")
		result.state.outcome = "playing"
	note(result.state,"%s: Vidaesfera, pierde %d PS%s." % [holder.name,recoil," y cae" if holder.hp==0 else ""])
	resolve_casualties(result.state)
	if holder.hp == 0:
		if result.state.outcome == "playing":
			result.state.completed.append(holder.id)
			if result.state.queue.is_empty(): new_round(result.state)
			else: begin_activation(result.state)
	return result
