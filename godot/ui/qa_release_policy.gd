extends "res://ui/qa_adventure_policy.gd"

# Test player only: uses public commands, no injected units, HP, XP or rewards.
const Points = preload("res://core/power_points.gd")
const Flat = preload("res://core/movement.gd")

func moves(game: RefCounted, member: Dictionary) -> Array:
	return Points.fit(super.moves(game,member),member.level,game.progression.data.moves)

func choose(game: RefCounted, state: Dictionary, final_path: String = "birds") -> Dictionary:
	if state.phase=="battle" and not state.battle.get("deployment",false):
		var actor: Dictionary = game.engine.active(state.battle)
		if actor.team=="ally": return {"kind":"battle","order":battle(game.engine,state.battle),"at":state.revision}
	if state.phase in ["map","complete"]:
		var destinations: Array = game.available(state)
		if destinations.is_empty(): return {}
		if game.locations[int(state.stage)].id!=destinations[0].id or state.phase=="complete":
			return {"kind":"travel","location":destinations[0].id,"at":state.revision}
	return super.choose(game,state,final_path)

func battle(engine: RefCounted, state: Dictionary) -> Dictionary:
	var actor: Dictionary = engine.active(state)
	var ending: Dictionary = {"kind":"finish","facing":engine.choose_facing(state,actor)}
	if state.acted or actor.spatial.effects.has("flinch") or (actor.status!=null and actor.status.kind in ["sleep","freeze"]): return ending
	var enemies: Array = engine.living(state).filter(func(u):return u.team!=actor.team)
	var routes: Array = engine.movement_routes(state,actor,actor.remaining).values() if not state.moved else []
	routes.sort_custom(func(a,b):return origin_value(a.path[-1],enemies)<origin_value(b.path[-1],enemies))
	var origins: Array = [{"x":actor.x,"y":actor.y,"remaining":actor.remaining}]
	for route: Dictionary in routes.slice(0,12):
		if route.cost>0: origins.append({"x":route.path[-1].x,"y":route.path[-1].y,"remaining":actor.remaining-route.cost})
	var best: float = 0
	var order: Dictionary = ending
	for origin: Dictionary in origins:
		for action: RefCounted in engine.profile(actor).actions_for(actor):
			var definition: Dictionary = action.definition
			var targets: Array = [origin] if definition.target=="self" else engine.living(state).filter(func(u):return u.team==actor.team if definition.target=="friendly" else u.team!=actor.team)
			for target: Dictionary in targets:
				if Flat.distance(origin,target)>int(definition.range)+1: continue
				var aim: Dictionary = {"x":target.x,"y":target.y,"axis":0,"throwFacing":0}
				var plan: Dictionary = engine.cast_plan(state,aim,definition.id,origin)
				if not plan.ok: continue
				var score: float = engine.action_score(state,actor,plan)
				for hit: Dictionary in plan.hits:
					var victim: Dictionary = engine.unit_by_id(state,int(hit.targetId))
					if victim.team!=actor.team and hit.damage>=victim.hp: score += 25
					if victim.team!=actor.team and hit.damage>0: score += (1.0-float(victim.hp)/victim.maxHp)*12
				if not Flat.same(actor,origin): score -= .1
				if score>best:
					best = score
					order = {"kind":"attack","actionId":definition.id,"aim":aim,"target":target.get("id",actor.id)} if Flat.same(actor,origin) else {"kind":"move","destination":{"x":origin.x,"y":origin.y}}
	if best>0: return order
	return engine.choose_command(state)

func origin_value(point: Dictionary, enemies: Array) -> float:
	var best: float = INF
	for enemy: Dictionary in enemies:
		var distance: int = Flat.distance(point,enemy)
		var side: String = preload("res://core/battle.gd").attack_side(point,enemy)
		best = minf(best,distance-(.35 if side=="back" else .15 if side=="side" else 0.0))
	return best

func team_value(game: RefCounted, member: Dictionary, opponents: Array = []) -> float:
	var base: Dictionary = game.progression.species[int(member.speciesId)].baseStats
	var offense: float = maxf(base.attack,base["special-attack"])
	var value: float = member.level*5+offense*.15+(base.hp+base.defense+base["special-defense"])*.025
	if member.id==1: value += 12
	if member.knownMoves.all(func(id):return game.progression.data.moves[id].category=="status"): value -= 80
	var chart: Dictionary = game.engine.profiles[1].library.basic.chart
	if not opponents.is_empty():
		var matchups: float = 0
		for foe: Dictionary in opponents:
			var types: Array = game.progression.species[int(foe.speciesId)].types
			var best_effect: float = 1
			for identity: String in member.knownMoves:
				var technique: Dictionary = game.progression.data.moves[identity]
				if technique.category=="status": continue
				var multiplier: float = 1
				for type_name: String in types: multiplier *= float(chart[technique.type].get(type_name,1))
				best_effect = maxf(best_effect,multiplier)
			matchups += (best_effect-1)*25
		value += matchups/opponents.size()
	return value

func shop(game: RefCounted, state: Dictionary) -> Dictionary:
	var owned: Array = game.members(state).duplicate()
	var next_locations: Array = game.available(state)
	var opponents: Array = next_locations[0].get("team",[]) if not next_locations.is_empty() else []
	owned.sort_custom(func(a,b):return team_value(game,a,opponents)>team_value(game,b,opponents) if team_value(game,a,opponents)!=team_value(game,b,opponents) else a.id<b.id)
	var wanted: Array = owned.slice(0,6).map(func(m):return m.id)
	for identity: int in wanted:
		var member: Dictionary = game.target(state,identity)
		if member.hp==0:
			if state.bag.revive>0: return {"kind":"revive","member":identity}
			if state.money>=game.consumables.revive.price: return {"kind":"buy","item":"revive"}
		if member.hp>0 and state.reserve.any(func(m):return m.id==identity):
			if state.party.size()<6: return {"kind":"withdraw","member":identity}
			var replaceable: Array = state.party.filter(func(m):return m.id not in wanted)
			if not replaceable.is_empty(): return {"kind":"swap","member":replaceable[-1].id,"reserve":identity}
	# Once the chosen six are in the team, preserve medicine before optional XP.
	for member: Dictionary in state.party:
		if member.hp<=0: continue
		var options: Array = game.progression.free_evolutions(member).filter(func(e):return member.level>=int(e[1]))
		if not options.is_empty(): return {"kind":"evolve-free","member":member.id,"species":options[0][0]}
		var prepared: Array = moves(game,member)
		if prepared!=member.moves: return {"kind":"loadout","member":member.id,"moves":prepared}
		var missing: int = int(game.progression.member_stats(member).maxHp-member.hp)
		if missing<10: continue
		var preferred: String = "max-potion" if missing>300 else "hyper-potion" if missing>140 else "super-potion" if missing>65 else "potion"
		for item: String in [preferred,"hyper-potion","super-potion","potion","max-potion"]:
			if state.bag.get(item,0)>0: return {"kind":"heal","item":item,"member":member.id}
		for item: String in [preferred,"super-potion","potion"]:
			if state.money>=game.consumables[item].price: return {"kind":"buy","item":item}
	var destinations: Array = game.available(state)
	if not destinations.is_empty():
		var goal: int = mini(game.level_cap(state),int(destinations[0].progressionReference.before))
		for member: Dictionary in state.party:
			if member.hp<=0 or member.level>=goal: continue
			var quote: Dictionary = game.training_quote(state,member)
			if quote.ok and state.money>=quote.price+120: return {"kind":"train-xp","member":member.id,"points":quote.points,"price":quote.price}
	return {"kind":"continue"}
