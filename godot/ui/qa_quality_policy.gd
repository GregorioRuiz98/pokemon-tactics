extends "res://ui/qa_release_policy.gd"

func choose(game: RefCounted, state: Dictionary, final_path: String = "birds") -> Dictionary:
	if state.phase=="battle" and state.battle.get("deployment",false):
		var allies: Array = state.battle.units.filter(func(u):return u.team=="ally")
		var positions: Array = [[5,8],[2,8],[5,10],[2,10],[4,9],[3,9]]
		var offset: int = int((int(state.mapSize)-16)/2.0)
		for index: int in allies.size():
			var point: Dictionary = {"x":positions[index][0]+offset,"y":positions[index][1]+offset}
			if not Flat.same(allies[index],point): return {"kind":"deploy","member":allies[index].id,"destination":point,"at":state.revision}
	return super.choose(game,state,final_path)

# Automated test player only. Uses the same purchases, PC and move slots as a person.
func team_value(game: RefCounted, member: Dictionary, opponents: Array = []) -> float:
	var value: float = super.team_value(game,member,opponents)-member.level*2
	if opponents.is_empty(): return value
	var chart: Dictionary = game.engine.profiles[1].library.basic.chart
	var own_types: Array = game.progression.species[int(member.speciesId)].types
	var adjustment: float = 0
	for foe: Dictionary in opponents:
		var foe_types: Array = game.progression.species[int(foe.speciesId)].types
		var incoming: float = 0
		for kind: String in foe_types:
			var effect: float = 1
			for own: String in own_types: effect *= float(chart[kind].get(own,1))
			incoming = maxf(incoming,effect)
		var coverage: float = 0
		for identity: String in member.knownMoves:
			var move: Dictionary = game.progression.data.moves[identity]
			if move.category=="status": continue
			var effect: float = 1
			for kind: String in foe_types: effect *= float(chart[move.type].get(kind,1))
			coverage = maxf(coverage,effect)
		adjustment += (coverage-1)*25-(incoming-1)*25
	return value+adjustment/opponents.size()

func moves(game: RefCounted, member: Dictionary) -> Array:
	var prepared: Array = super.moves(game,member)
	var support: Array = member.knownMoves.filter(func(id):return game.progression.data.moves[id].kind in ["heal","seed"])
	if support.is_empty(): return prepared
	var useful: String = support[0]
	var options: Array = prepared.filter(func(id):return id!=useful).slice(0,3)+[useful]
	return Points.fit(options,member.level,game.progression.data.moves)

func shop(game: RefCounted, state: Dictionary) -> Dictionary:
	var owned: Array = game.members(state).duplicate()
	var next_locations: Array = game.available(state).filter(func(l):return l.id!="safari")
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
	var destinations: Array = game.available(state).filter(func(l):return l.id!="safari")
	if not destinations.is_empty():
		var goal: int = mini(game.level_cap(state),int(destinations[0].progressionReference.before))
		for member: Dictionary in state.party:
			if member.hp<=0 or member.level>=goal: continue
			var quote: Dictionary = game.training_quote(state,member)
			if quote.ok and state.money>=quote.price+120: return {"kind":"train-xp","member":member.id,"points":quote.points,"price":quote.price}
	return {"kind":"continue"}

func battle(engine: RefCounted, state: Dictionary) -> Dictionary:
	var actor: Dictionary = engine.active(state)
	var ending: Dictionary = {"kind":"finish","facing":engine.choose_facing(state,actor)}
	if state.acted or actor.spatial.effects.has("flinch") or (actor.status!=null and actor.status.kind in ["sleep","freeze"]): return ending
	var enemies: Array = engine.living(state).filter(func(u):return u.team!=actor.team)
	var routes: Array = engine.movement_routes(state,actor,actor.remaining).values() if not state.moved else []
	routes.sort_custom(func(a,b):return origin_value(a.path[-1],enemies)<origin_value(b.path[-1],enemies))
	var origins: Array = [{"x":actor.x,"y":actor.y,"remaining":actor.remaining}]
	for route: Dictionary in routes.slice(0,24):
		if route.cost>0: origins.append({"x":route.path[-1].x,"y":route.path[-1].y,"remaining":actor.remaining-route.cost})
	var best: float = 0
	var order: Dictionary = ending
	for origin: Dictionary in origins:
		var exposure: float = engine.danger_at(state,actor,origin)*0.04
		var grouping: float = engine.living(state).filter(func(u):return u.team==actor.team and u.id!=actor.id and Flat.distance(u,origin)<=1).size()*3.0
		for action: RefCounted in engine.profile(actor).actions_for(actor):
			var definition: Dictionary = action.definition
			var targets: Array = [origin] if definition.target=="self" else engine.living(state).filter(func(u):return u.team==actor.team if definition.target=="friendly" else u.team!=actor.team)
			for target: Dictionary in targets:
				if Flat.distance(origin,target)>int(definition.range)+1: continue
				var aim: Dictionary = {"x":target.x,"y":target.y,"axis":0,"throwFacing":0}
				var plan: Dictionary = engine.cast_plan(state,aim,definition.id,origin)
				if not plan.ok: continue
				var score: float = engine.action_score(state,actor,plan)-exposure-grouping
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
