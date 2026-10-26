extends RefCounted

# Equipment budget, never a battle resource. Same table for both teams.
static func capacity(level: int) -> int:
	return mini(20,10+int(maxi(0,level-5)/5.0))

static func price(move: Dictionary) -> int:
	if move.get("id")=="basic": return 0
	var area: bool = move.get("shape","U") not in ["U","S1","S2","S3","S4","S5"]
	var value: int = 1
	if move.get("category")=="status":
		var positive: int = 0
		for change: Dictionary in move.get("changes",[]): positive += maxi(0,int(change.stages))
		value = 3 if positive>=2 else 2 if positive>0 else 1
		if move.get("kind")=="focus": value = 3
		if move.get("kind")=="heal" or move.get("special","") in ["mirror-move","mimic","substitute","bide"]: value = 3
		if move.get("special","") in ["metronome","transform"]: value = 4
		if move.get("field","")!="": value = 2
		var status: Dictionary = move.get("effect",{}) if move.get("effect") is Dictionary else {}
		if status.get("kind","") in ["sleep","freeze"]: value = 3
	else:
		var power: int = int(move.get("power",0))
		value = 4 if power>=110 else 3 if power>=90 else 2 if power>=60 else 1
		if move.get("fixedMode","")!="" or move.get("special","") in ["counter"]: value = 3
		if move.get("alwaysCritical",false) or move.get("kind")=="drain": value += 1
		var secondary: Dictionary = move.get("secondary",{}) if move.get("secondary") is Dictionary else {}
		if secondary.get("kind","") in ["sleep","freeze","paralysis","confusion"] and secondary.get("chance",0)>=30: value += 1
		if move.get("range",0)>=4: value += 1
	if area: value += 1
	# Recoil, charge turns and self-KO remain real disadvantages.
	if move.get("selfKO",false) or move.get("charge",false): value -= 1
	return clampi(value,1,5)

static func used(moves: Array, catalog: Dictionary) -> int:
	var total: int = 0
	for identity: String in moves: total += int(catalog[identity].loadoutCost)
	return total

static func fit(moves: Array, level: int, catalog: Dictionary) -> Array:
	var result: Array = []
	for identity: String in moves:
		if result.size()<4 and used(result,catalog)+int(catalog[identity].loadoutCost)<=capacity(level): result.append(identity)
	return result
