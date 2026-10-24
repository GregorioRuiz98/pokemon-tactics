extends "res://ui/qa_journey_policy.gd"

func shop(game: RefCounted, state: Dictionary) -> Dictionary:
	var living: Array = state.party.filter(func(m):return m.hp>0)
	var reserves: Array = state.reserve.filter(func(m):return m.hp>0)
	reserves.sort_custom(func(a,b):return a.level>b.level)
	if state.party.size()<6 and not reserves.is_empty(): return {"kind":"withdraw","member":reserves[0].id}
	for member: Dictionary in state.party:
		if not reserves.is_empty() and (member.hp==0 or (member.id!=1 and reserves[0].level>member.level+3)): return {"kind":"swap","member":member.id,"reserve":reserves[0].id}
		if member.hp==0 and living.size()<4:
			if state.bag.revive>0: return {"kind":"revive","member":member.id}
			if state.money>=190: return {"kind":"buy","item":"revive"}
	for member: Dictionary in living:
		var options: Array = game.progression.free_evolutions(member).filter(func(e):return member.level>=int(e[1]))
		if not options.is_empty(): return {"kind":"evolve-free","member":member.id,"species":options[0][0]}
		var prepared: Array = moves(game,member)
		if prepared!=member.moves: return {"kind":"loadout","member":member.id,"moves":prepared}
		var missing: int = game.progression.member_stats(member).maxHp-int(member.hp)
		if missing<15: continue
		var preferred: String = "max-potion" if missing>300 else ("hyper-potion" if missing>140 else ("super-potion" if missing>65 else "potion"))
		for item: String in [preferred,"hyper-potion","super-potion","potion","max-potion"]:
			if state.bag.get(item,0)>0: return {"kind":"heal","item":item,"member":member.id}
		if state.money>=game.consumables[preferred].price: return {"kind":"buy","item":preferred}
	var destinations: Array = game.available(state).filter(func(n):return not n.get("optional",false))
	if not destinations.is_empty():
		var goal: int = mini(game.level_cap(state),int(destinations[0].progressionReference.before))
		for member: Dictionary in living:
			if member.level>=goal: continue
			var quote: Dictionary = game.training_quote(state,member)
			if quote.ok and state.money>=quote.price+120: return {"kind":"train-xp","member":member.id,"points":quote.points,"price":quote.price}
	return {"kind":"continue"}
