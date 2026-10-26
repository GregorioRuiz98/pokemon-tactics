extends RefCounted

# Presentation queries over the opened campaign. Applying a proposal uses the
# existing atomic loadout order; no learning, combat rule or random draw here.
const Info = preload("res://ui/move_info.gd")
const GUIDES: Dictionary = {
	"bulbasaur":[["Drenador","vine-whip","mega-drain","leech-seed","growth"],["Controlador","sleep-powder","poison-powder","leech-seed","vine-whip"]],
	"charmander":[["Artillero","flamethrower","ember","dragon-pulse","heat-wave"],["Escaramuzador","smokescreen","growl","slash","wing-attack"]],
	"squirtle":[["Tirador","water-pulse","bubble","water-gun","ice-beam"],["Baluarte","withdraw","tail-whip","bubble","protect"]],
	"caterpie":[["Artillero","psybeam","confusion","gust","bug-buzz"],["Controlador","sleep-powder","stun-spore","gust","string-shot"]],
	"weedle":[["Asaltante","twineedle","fury-attack","peck","rage"],["Hostigador","string-shot","poison-sting","twineedle","harden"]],
	"pidgey":[["Escaramuzador","quick-attack","wing-attack","gust","roost"],["Apoyo","gust","sand-attack","mirror-move","roost"]],
	"rattata":[["Duelista","bite","quick-attack","super-fang","focus-energy"],["Debilitador","tail-whip","super-fang","counter","bite"]],
	"pikachu":[["Artillero","thunderbolt","thunder-shock","double-kick","quick-attack"],["Paralizador","thunder-wave","growl","double-team","thunder-shock"]],
	"spearow":[["Asaltante","peck","drill-peck","fury-attack","focus-energy"],["Debilitador","leer","growl","peck","focus-energy"]],
	"nidoran-f":[["Duelista","double-kick","bite","poison-sting","scratch"],["Apoyo","tail-whip","growl","helping-hand","poison-sting"]],
	"nidoran-m":[["Duelista","double-kick","horn-attack","peck","focus-energy"],["Apoyo","leer","helping-hand","poison-sting","focus-energy"]],
	"oddish":[["Drenador","mega-drain","absorb","acid","growth"],["Controlador","sleep-powder","stun-spore","poison-powder","acid"]],
	"bellsprout":[["Hostigador","vine-whip","wrap","acid","growth"],["Controlador","sleep-powder","wrap","growth","vine-whip"]],
	"geodude":[["Vanguardia","rock-throw","rock-slide","earthquake","tackle"],["Baluarte","defense-curl","rock-throw","harden","protect"]],
	"onix":[["Vanguardia","rock-throw","rock-slide","slam","bind"],["Controlador","bind","screech","harden","rock-throw"]]
}

static func tags(move: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if move.get("spatialArea",false): result.append("Área")
	if move.get("field","")!="": result.append("Zona")
	if move.get("pushDistance",0)>0: result.append("Empuje")
	if move.get("pullDistance",0)>0: result.append("Atracción")
	if move.get("approach",0)>0 or move.get("shape")=="DASH": result.append("Acercamiento")
	if move.get("dispel",false): result.append("Disipa")
	if move.get("kind") in ["heal","drain"] or (move.get("effect") is Dictionary and move.effect.get("kind")=="seed"): result.append("Curación")
	if move.get("kind")=="guard" or move.get("special","") in ["protect","wide-guard"]: result.append("Protección")
	if move.get("effect")!=null or move.get("secondary")!=null or not move.get("changes",[]).is_empty() or move.get("special","") in ["bound","taunt","encore","disable","yawn"]: result.append("Control")
	if move.get("alwaysCritical",false) or move.get("criticalStages",0)>0: result.append("Crítico")
	return result

static func matches(move: Dictionary, filter: int) -> bool:
	var features: Array[String] = tags(move)
	match filter:
		1: return "Área" in features
		2: return "Zona" in features
		3: return "Empuje" in features or "Atracción" in features or "Acercamiento" in features
		4: return "Control" in features
		5: return "Curación" in features or "Protección" in features or "Disipa" in features
	return true

static func function_key(move: Dictionary) -> String:
	return str(move.get("type",""))+"/"+str(move.get("shape","S1"))+"/"+str(move.get("category",""))

static func score(move: Dictionary, mode: int, preferred: Array) -> float:
	var value: float = 0.0
	var features: Array[String] = tags(move)
	if move.get("category")!="status": value += 25+minf(120,float(move.get("power",0)))*.12
	else: value += 8 if mode==0 else 38
	value += minf(4,float(move.get("range",0)))*2-float(move.get("cost",0))*2
	if not features.is_empty(): value += 5
	if mode==1 and ("Zona" in features or "Control" in features or "Protección" in features or "Curación" in features or "Disipa" in features): value += 14
	var priority: int = preferred.find(move.get("id"))
	if priority>=0: value += 60-priority*7
	return value

static func propose(study: RefCounted, member: Dictionary, mode: int) -> Dictionary:
	var family: Dictionary = study.families[int(member.speciesId)]
	var guide: Array = GUIDES.get(family.id,[["Ofensivo"],["Apoyo y control"]])[mode]
	var preferred: Array = guide.slice(1)
	var choices: Array = member.knownMoves.filter(func(id):return study.data.moves.has(id) and not study.data.moves[id].get("selfKO",false))
	var selected: Array[String] = []
	var functions: Dictionary = {}
	while selected.size()<4 and not choices.is_empty():
		var best: String = ""; var best_score: float = -INF
		for identity: String in choices:
			var definition: Dictionary = study.data.moves[identity]
			var value: float = score(definition,mode,preferred)-float(functions.get(function_key(definition),0))*20
			if value>best_score or (is_equal_approx(value,best_score) and identity<best): best_score = value; best = identity
		selected.append(best); choices.erase(best)
		var key: String = function_key(study.data.moves[best]); functions[key] = int(functions.get(key,0))+1
	var features: Array[String] = []
	for identity: String in selected:
		for feature: String in tags(study.data.moves[identity]):
			if feature not in features: features.append(feature)
	return {"name":guide[0],"moves":selected,"features":features,"mode":mode}

static func learning(study: RefCounted, member: Dictionary, cap: int) -> Array:
	var next: Dictionary = {}
	for entry: Dictionary in study.families[int(member.speciesId)].learnset:
		if entry.id in member.knownMoves or entry.level<=member.level or not entry.forms.any(func(id):return int(id)==int(member.speciesId)): continue
		if not next.has(entry.id) or entry.level<next[entry.id].level: next[entry.id] = entry.duplicate(true)
	var entries: Array = next.values()
	entries.sort_custom(func(a,b):return a.level<b.level if a.level!=b.level else a.id<b.id)
	return entries.slice(0,3).map(func(e):return {"id":e.id,"level":int(e.level),"lockedByCap":e.level>cap,"tags":tags(study.data.moves[e.id])})

static func improvement(study: RefCounted, member: Dictionary, identity: String) -> String:
	if identity in member.knownMoves: return "Ya aprendido"
	var move: Dictionary = study.data.moves[identity]
	var equipped: Array = member.moves.map(func(id):return study.data.moves[id])
	for feature: String in tags(move):
		if not equipped.any(func(d):return feature in tags(d)): return "Añade: "+feature.to_lower()
	if move.get("category")!="status" and not equipped.any(func(d):return d.get("category")!="status" and d.type==move.type): return "Añade cobertura de tipo "+Info.TYPES.get(move.type,move.type)
	return "Alternativa de "+Info.TYPES.get(move.type,move.type)

static func team_summary(app: Control) -> String:
	var lines: Array[String] = []
	var coverage: Dictionary = {}
	for member: Dictionary in app.run.party:
		if member.hp<=0: continue
		var features: Array[String] = []
		for identity: String in member.moves:
			for feature: String in tags(app.campaign.progression.data.moves[identity]):
				if feature not in features: features.append(feature)
		for feature: String in features: coverage[feature] = true
		lines.append(app.campaign.progression.species[int(member.speciesId)].name+": "+(", ".join(features) if not features.is_empty() else "ataques individuales"))
	var absent: Array[String] = []
	for feature: String in ["Área","Zona","Empuje","Atracción","Disipa","Curación"]:
		if not coverage.has(feature): absent.append(feature)
	return "HERRAMIENTAS PREPARADAS\n"+"\n".join(lines)+"\n\nSin preparar: "+(", ".join(absent) if not absent.is_empty() else "todas las funciones indicadas están cubiertas")+".\n\nCombina libremente los movimientos aprendidos. Las áreas pueden alcanzar aliados; consulta la previsión."
