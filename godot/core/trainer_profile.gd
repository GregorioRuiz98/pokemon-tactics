extends RefCounted

const ACHIEVEMENTS: Dictionary = {
	"first-medal":["Primera medalla","Consigue una medalla de gimnasio."],
	"fire-starter":["Contra todo pronóstico","Vence a Brock habiendo elegido a Charmander."],
	"clean-gym":["Equipo intacto","Gana un gimnasio sin aliados debilitados durante ese combate."],
	"trap-push":["Control del terreno","Desplaza a un rival hasta una trampa de rocas que se active."],
	"clear-smoke":["Aire limpio","Dispersa humo con un movimiento compatible de tu equipo."],
	"fuji-perfect":["Rescate impecable","Rescata a Fuji sin perder protección."],
	"rocket-terminals":["Sabotaje","Resuelve la Guarida Rocket activando sus dos terminales."],
	"champion":["Campeón de Kanto","Supera la Liga y vence al rival."],
	"birds":["Guardianes del cielo","Completa el desafío de las aves legendarias."],
	"psychic":["El origen del poder","Completa el desafío de Mew y Mewtwo."]
}
var data: Dictionary = {}

static func identity() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

func _init(value: Dictionary = {}) -> void:
	data = value.duplicate(true) if not value.is_empty() else {"schema":"trainer","version":1,"id":identity(),"name":"Entrenador","portrait":25,"title":"Entrenador","frame":"amber","unlocked":{},"dex":[],"runs":{},"revision":0}

func unlock(key: String, campaign_id: String) -> bool:
	if not ACHIEVEMENTS.has(key) or data.unlocked.has(key): return false
	data.unlocked[key] = {"run":campaign_id,"at":int(Time.get_unix_time_from_system())}
	return true

func observe(campaign_id: String, run: Dictionary, events: Array) -> Array[String]:
	var unlocked: Array[String] = []
	if run.is_empty(): return unlocked
	if not data.runs.has(campaign_id):
		data.runs[campaign_id] = {"seed":run.seed,"starter":run.starter,"edition":run.get("edition",1),"started":int(Time.get_unix_time_from_system()),"cursor":-1,"status":"active","medals":0,"battles":0,"wins":0,"kos":0,"locations":[],"partialHistory":events.is_empty() and run.revision>0}
		if events.is_empty() and run.has("tacticalStats"):
			data.runs[campaign_id].battles = int(run.tacticalStats.battles)
			data.runs[campaign_id].wins = maxi(0,int(run.tacticalStats.battles)-(1 if run.phase=="defeat" else 0))
			data.runs[campaign_id].kos = int(run.tacticalStats.kos)
	var record: Dictionary = data.runs[campaign_id]
	for event: Dictionary in events:
		if int(event.revision)<=int(record.cursor): continue
		for flag: String in event.get("flags",[]):
			if unlock(flag,campaign_id): unlocked.append(flag)
		for species_id: int in event.get("species",[]): register_species(species_id)
		if event.has("outcome"):
			record.battles += 1
			if event.outcome=="victory": record.wins += 1
			record.kos += int(event.get("kos",0))
		record.cursor = int(event.revision)
	# Only facts that the saved snapshot can prove are awarded retroactively.
	register_species(int(run.starter))
	for member: Dictionary in run.party+run.get("reserve",[]): register_species(int(member.speciesId))
	var cleared: Array = run.get("cleared",[])
	for flag: String in ["first-medal" if run.get("medals",[]).size()>0 else "","fire-starter" if int(run.starter)==4 and "brock" in cleared else "","champion" if run.get("mainComplete",false) else "",str(run.get("finalPath","")) if run.phase=="ending" else ""]:
		if unlock(flag,campaign_id): unlocked.append(flag)
	record.cursor = maxi(int(record.cursor),int(run.revision))
	record.medals = maxi(int(record.medals),run.get("medals",[]).size())
	record.locations = cleared.duplicate()
	record.edition = run.get("edition",1)
	if run.phase=="ending": record.status = "completed"
	elif run.phase=="defeat": record.status = "defeated"
	else: record.status = "active"
	data.revision += 1
	return unlocked

func register_species(species_id: int) -> void:
	if species_id>=1 and species_id<=151 and species_id not in data.dex: data.dex.append(species_id); data.dex.sort()

func summary() -> Dictionary:
	var result: Dictionary = {"runs":data.runs.size(),"completed":0,"defeated":0,"wins":0,"battles":0,"kos":0,"bestMedals":0}
	for entry: Dictionary in data.runs.values():
		result.wins += int(entry.wins); result.battles += int(entry.battles); result.kos += int(entry.kos)
		result.bestMedals = maxi(int(result.bestMedals),int(entry.medals))
		if entry.status=="completed": result.completed += 1
		if entry.status=="defeated": result.defeated += 1
	return result

func abandon(campaign_id: String) -> void:
	if data.runs.has(campaign_id) and data.runs[campaign_id].status=="active": data.runs[campaign_id].status = "abandoned"; data.revision += 1

func titles() -> Array:
	var result: Array = ["Entrenador"]
	if data.unlocked.has("first-medal"): result.append("Explorador de Kanto")
	if data.unlocked.has("champion"): result.append("Campeón de Kanto")
	return result

func frames() -> Array:
	return ["amber"]+(["leaf"] if data.unlocked.has("first-medal") else [])+(["champion"] if data.unlocked.has("champion") else [])

func customize(name_text: String, portrait_id: int, title_text: String, frame_id: String) -> bool:
	name_text = name_text.strip_edges()
	if name_text.is_empty() or name_text.length()>24 or "\n" in name_text or "\r" in name_text: return false
	if portrait_id not in [1,4,7,25]+data.dex or title_text not in titles() or frame_id not in frames(): return false
	data.name = name_text; data.portrait = portrait_id; data.title = title_text; data.frame = frame_id; data.revision += 1
	return true

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema")!="trainer" or value.get("version")!=1: return false
	if not value.get("id") is String or value.id.length()!=32 or not value.get("name") is String or value.name.is_empty() or value.name.length()>24: return false
	if not value.get("portrait") is float and not value.get("portrait") is int: return false
	if value.portrait!=int(value.portrait) or value.portrait<1 or value.portrait>151: return false
	if not value.get("title") is String or not value.get("frame") is String or not value.get("revision") is float and not value.get("revision") is int: return false
	if not value.get("unlocked") is Dictionary or not value.get("runs") is Dictionary or not value.get("dex") is Array: return false
	for key: String in value.unlocked:
		if not ACHIEVEMENTS.has(key) or not value.unlocked[key] is Dictionary or not value.unlocked[key].get("run") is String: return false
	for entry: Variant in value.dex:
		if not (entry is int or entry is float) or entry!=int(entry) or entry<1 or entry>151: return false
	for key: String in value.runs:
		var run: Variant = value.runs[key]
		if key.is_empty() or key.length()>96 or not run is Dictionary: return false
		for field: String in ["cursor","starter","medals","battles","wins","kos","started","edition"]:
			if not (run.get(field) is int or run.get(field) is float) or run[field]!=int(run[field]): return false
		if not run.get("seed") is String or not run.get("locations") is Array or run.get("status") not in ["active","completed","defeated","abandoned"]: return false
	return true
