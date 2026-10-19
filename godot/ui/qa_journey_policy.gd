extends RefCounted

func moves(game: RefCounted, member: Dictionary) -> Array:
	var choices: Array = member.knownMoves.filter(func(id):return not game.progression.data.moves[id].get("selfKO",false))
	choices.sort_custom(func(a,b):return move_score(game,member,a)>move_score(game,member,b))
	var selected: Array = []
	var types: Array = []
	for identity: String in choices:
		var move: Dictionary = game.progression.data.moves[identity]
		if move.category=="status" or move.type in types: continue
		selected.append(identity)
		types.append(move.type)
		if selected.size()==3: break
	for identity: String in choices:
		if selected.size()==4: break
		if identity not in selected: selected.append(identity)
	for identity: String in ["roost","recover","soft-boiled"]:
		if identity in choices and identity not in selected:
			if selected.size()==4: selected.pop_back()
			selected.append(identity)
			break
	return selected

func move_score(game: RefCounted, member: Dictionary, identity: String) -> float:
	var move: Dictionary = game.progression.data.moves[identity]
	if move.kind=="heal": return 38
	if move.category=="status": return 15 if move.kind=="status" else 5
	return float(move.power)*(1.5 if move.type in game.progression.species[int(member.speciesId)].types else 1.0)/(float(move.cost)*0.3+1.0)+float(move.range)*2

func choose(game: RefCounted, state: Dictionary, final_path: String = "birds") -> Dictionary:
	var order: Dictionary = {"at":state.revision}
	match state.phase:
		"battle": order.merge({"kind":"battle","order":game.engine.choose_command(state.battle)})
		"capture": order.kind = "capture"
		"map": order.kind = "enter"
		"complete":
			if state.mainComplete and state.chapter>=21 and state.finalPath=="": order.merge({"kind":"destiny","path":final_path})
			else:
				var choices: Array = game.available(state)
				if choices.is_empty(): return {}
				order.merge({"kind":"travel","location":choices[0].id})
		"shop": order.merge(shop(game,state))
		_: return {}
	return order

func shop(game: RefCounted, state: Dictionary) -> Dictionary:
	var living: Array = state.party.filter(func(m):return m.hp>0)
	living.sort_custom(func(a,b):return a.level>b.level if a.level!=b.level else a.id<b.id)
	# Preserve the previously verified opening policy before evaluating the new zones.
	if state.stage<4:
		for member: Dictionary in living:
			if member.hp<game.progression.member_stats(member).maxHp-10:
				if state.bag.potion>0: return {"kind":"heal","item":"potion","member":member.id}
				if state.money>=40: return {"kind":"buy","item":"potion"}
		return {"kind":"continue"}
	var reserves: Array = state.reserve.filter(func(m):return m.hp>0)
	reserves.sort_custom(func(a,b):return a.level>b.level)
	var league: bool = state.get("chapter",0)>=20 and state.medals.size()==8
	if league:
		var preparation: Dictionary = league_team(game,state)
		if not preparation.is_empty(): return preparation
	if league and not living.is_empty():
		for member: Dictionary in state.party:
			if member.hp==0 and member.level>=living[0].level-5:
				if state.bag.revive>0: return {"kind":"revive","member":member.id}
				if state.money>=230: return {"kind":"buy","item":"revive"}
	if state.party.size()<6 and not reserves.is_empty(): return {"kind":"withdraw","member":reserves[0].id}
	for member: Dictionary in state.party:
		if not league and not reserves.is_empty() and (member.hp==0 or (member.id!=1 and reserves[0].level>member.level+2)):
			return {"kind":"swap","member":member.id,"reserve":reserves[0].id}
		if member.hp==0 and (living.size()<3 or member.level>=living[0].level-3):
			if state.bag.revive>0: return {"kind":"revive","member":member.id}
			if state.money>=230: return {"kind":"buy","item":"revive"}
	for member: Dictionary in living:
		if member.level<12: continue
		var prepared: Array = moves(game,member)
		if prepared!=member.moves: return {"kind":"loadout","member":member.id,"moves":prepared}
	var destinations: Array = game.available(state).filter(func(n):return not n.get("optional",false))
	if destinations.is_empty() and state.get("finalPath","")!="": destinations = game.available(state).filter(func(n):return n.get("path","")==state.finalPath)
	var goal: int = 5
	if not destinations.is_empty():
		var next: Dictionary = destinations[0]
		var team: Array = next.get("team",[])
		if next.has("rivalTeams"): team = next.rivalTeams[0]
		if not team.is_empty():
			for member: Dictionary in team: goal = maxi(goal,int(member.level))
		else:
			for entry: Dictionary in game.progression.data.encounters.get(next.captureTable,[]):
				if not entry.special: goal = maxi(goal,int(entry.maxLevel))
	goal = mini(goal,game.level_cap(state))
	for member: Dictionary in living.slice(0,6 if league else 3):
		if member.level<goal:
			if state.bag["rare-candy"]>0: return {"kind":"level-up","member":member.id}
			if state.money>=125: return {"kind":"buy","item":"rare-candy"}
	for member: Dictionary in living:
		var missing: int = game.progression.member_stats(member).maxHp-int(member.hp)
		if missing<15: continue
		var preferred: String = "max-potion" if missing>300 else ("hyper-potion" if missing>140 else ("super-potion" if missing>65 else "potion"))
		for item: String in [preferred,"hyper-potion","super-potion","potion","max-potion"]:
			if state.bag.get(item,0)>0: return {"kind":"heal","item":item,"member":member.id}
		if state.money>=game.consumables[preferred].price: return {"kind":"buy","item":preferred}
	return {"kind":"continue"}

func league_team(game: RefCounted, state: Dictionary) -> Dictionary:
	var owned: Array = game.members(state).duplicate()
	owned.sort_custom(func(a,b):return a.level>b.level if a.level!=b.level else a.id<b.id)
	var wanted: Array = []
	for alternatives: Array in [[121],[130,129,18],[26],[65],[71,70,45],[112]]:
		for species: int in alternatives:
			var options: Array = owned.filter(func(m):return int(m.speciesId)==species and m.id not in wanted)
			if options.is_empty(): continue
			wanted.append(options[0].id)
			break
	for identity: int in wanted:
		var member: Dictionary = game.target(state,identity)
		if member.hp==0:
			if state.bag.revive>0: return {"kind":"revive","member":identity}
			if state.money>=230: return {"kind":"buy","item":"revive"}
		if state.reserve.any(func(m):return m.id==identity):
			var replaced: Array = state.party.filter(func(m):return m.id not in wanted)
			if member.hp>0 and not replaced.is_empty(): return {"kind":"swap","member":replaced[0].id,"reserve":identity}
		if member.hp>0 and member.speciesId==70:
			if state.bag.get("leaf-stone",0)>0: return {"kind":"use-evolution","item":"leaf-stone","member":identity,"species":71}
			if state.money>=180: return {"kind":"buy","item":"leaf-stone"}
	return {}
