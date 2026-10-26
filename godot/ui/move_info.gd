extends RefCounted

# Queries only: definitions belong to the engine of the opened campaign.
const CATEGORIES: Dictionary = {"physical":"Físico","special":"Especial","status":"Estado"}
const TYPES: Dictionary = {"normal":"Normal","fire":"Fuego","water":"Agua","electric":"Eléctrico","grass":"Planta","ice":"Hielo","fighting":"Lucha","poison":"Veneno","ground":"Tierra","flying":"Volador","psychic":"Psíquico","bug":"Bicho","rock":"Roca","ghost":"Fantasma","dragon":"Dragón","dark":"Siniestro","steel":"Acero","fairy":"Hada"}
const Geometry = preload("res://core/spatial_geometry.gd")

static func power(definition: Dictionary) -> String:
	if definition.get("special","") in ["counter","bide","metronome","mirror-move"]: return "Variable"
	if definition.get("fixedMode","")!="": return "Fija" if definition.fixedMode=="dragon-rage" else "Variable"
	if definition.get("category")=="status": return "—"
	return str(int(definition.get("power",0))) if definition.get("power",0)>0 else "Variable"

static func accuracy(definition: Dictionary) -> String:
	if definition.get("target","")=="self": return "Sobre sí mismo"
	if definition.get("neverMiss",false): return "No falla por precisión"
	return "%d %%" % int(definition.get("accuracy",100))

static func area(definition: Dictionary) -> String:
	return definition.get("shapeName","Sobre sí mismo" if definition.get("target")=="self" else "Un objetivo" if definition.get("kind")!="area-damage" else "Área alrededor del objetivo")

static func compact(definition: Dictionary) -> String:
	return "Pot. %s · %d PT · %d cas." % [power(definition),definition.get("cost",0),definition.get("range",0)]

static func summary(definition: Dictionary) -> String:
	var type_name: String = "Sin tipo · sin STAB" if definition.get("id")=="basic" else TYPES.get(definition.get("type",""),"Sin tipo")
	var reach: int = int(definition.get("range",0))
	return "%s · %s\nPotencia: %s · Precisión: %s\nCoste: %d PT · Alcance: %d %s\nÁrea: %s" % [type_name,CATEGORIES.get(definition.get("category",""),"Estado"),power(definition),accuracy(definition),definition.get("cost",0),reach,"casilla" if reach==1 else "casillas",area(definition)]

static func description(definition: Dictionary) -> String:
	var lines: Array[String] = []
	for line: String in definition.get("description","").split("\n"):
		if line.begins_with("Área:"): continue
		lines.append(line.replace(" · PT y alcance tácticos.","").strip_edges())
	var text: String = "\n".join(lines)
	for stat: String in ["specialAttack","specialDefense","accuracy","evasion","attack","defense","speed"]:
		text = text.replace(stat,preload("res://ui/unit_indicators.gd").STATS[stat][1])
	if text==definition.get("name",""):
		text = "Inflige daño físico." if definition.get("category")=="physical" else "Inflige daño especial." if definition.get("category")=="special" else ""
	for effect: String in ["effect","secondary"]:
		var status: Variant = definition.get(effect)
		if not status is Dictionary or not status.has("kind"): continue
		var name_text: String = {"burn":"Quemadura","poison":"Veneno","paralysis":"Parálisis","sleep":"Sueño","freeze":"Congelación","confusion":"Confusión","seed":"Drenadoras"}.get(status.kind,status.kind)
		text += "\n%s: %d %%" % [name_text,status.get("chance",100)]
		if definition.has("shape"): text += " · %d activaciones" % int(definition.get("statusDuration",3))
	for change: Dictionary in definition.get("changes",[]):
		text += "\n%s: %s %s%d" % ["Sobre el usuario" if definition.get("changesSelf",false) else "Sobre el objetivo",preload("res://ui/unit_indicators.gd").STATS[change.stat][1],"+" if change.stages>0 else "",change.stages]
		if definition.get("changeChance",100)<100: text += " · %d %%" % definition.changeChance
	if definition.get("kind")=="drain": text += "\nRecupera PS equivalentes a la mitad del daño causado."
	return text.strip_edges()

static func details(definition: Dictionary) -> String:
	var text: String = summary(definition)+"\n\n"+description(definition)
	match definition.get("fixedMode",""):
		"dragon-rage": text += "\nDaño fijo: 40 PS antes de las restricciones del objetivo."
		"super-fang": text += "\nDaño: la mitad de los PS actuales del objetivo, sujeto a inmunidades."
		"counter":
			if definition.get("special","")!="counter": text += "\nDevuelve el doble del último daño recibido, sujeto a inmunidades."
	match definition.get("special",""):
		"counter": text += "\nDevuelve el doble del daño registrado de la categoría correspondiente a su atacante. Consulta la previsión."
		"bide": text += "\nAcumula daño y lo devuelve según su estado de preparación. Consulta la previsión."
		"metronome": text += "\nLa potencia depende de la técnica sorteada al actuar."
		"mirror-move": text += "\nLa potencia depende del movimiento que se pueda copiar."
	if definition.get("sharedDamageBudget",false): text += "\nReparte un presupuesto de daño entre los objetivos; no aplica impactos completos a cada uno."
	if definition.get("areaScale",1.0)!=1.0: text += "\nEl daño del área se ajusta en la previsión de cada objetivo."
	if definition.get("category")!="status": text += "\nPotencia base y daño en PS son distintos. La previsión aplica estadísticas, tipos, STAB, posición y efectos."
	return text

static func diagram(definition: Dictionary) -> Dictionary:
	if not definition.has("shape"): return {}
	var board: Array = []
	for row: int in 7: board.append([0,0,0,0,0,0,0])
	var actor: Dictionary = {"x":2,"y":3,"facing":2,"id":1}
	var aim: Dictionary = {"x":3,"y":3,"axis":0}
	if definition.get("target")=="self": aim = actor.duplicate()
	return {"actor":actor,"aim":aim,"tiles":Geometry.tiles({"board":board,"units":[],"fields":[]},actor,aim,definition)}
