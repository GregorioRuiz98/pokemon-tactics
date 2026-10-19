extends RefCounted

func moves(game: RefCounted, member: Dictionary) -> Array:
	var choices: Array = member.knownMoves.duplicate()
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
	return selected

func move_score(game: RefCounted, member: Dictionary, identity: String) -> float:
	var move: Dictionary = game.progression.data.moves[identity]
	if move.kind=="heal": return 38
	if move.category=="status": return 15 if move.kind=="status" else 5
	return float(move.power)*(1.5 if move.type in game.progression.species[int(member.speciesId)].types else 1.0)/(float(move.cost)+0.8)+float(move.range)*2

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
	if state.party.size()<6 and not reserves.is_empty(): return {"kind":"withdraw","member":reserves[0].id}
	for member: Dictionary in state.party:
		if not reserves.is_empty() and (member.hp==0 or (member.id!=1 and reserves[0].level>member.level+2)):
			return {"kind":"swap","member":member.id,"reserve":reserves[0].id}
		if member.hp==0 and (living.size()<3 or member.level>=living[0].level-3):
			if state.bag.revive>0: return {"kind":"revive","member":member.id}
			if state.money>=230: return {"kind":"buy","item":"revive"}
	for member: Dictionary in living:
		if member.level<12: continue
		var prepared: Array = moves(game,member)
		if prepared!=member.moves: return {"kind":"loadout","member":member.id,"moves":prepared}
	var destinations: Array = game.available(state).filter(func(n):return not n.get("optional",false))
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
	for member: Dictionary in living.slice(0,3):
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
