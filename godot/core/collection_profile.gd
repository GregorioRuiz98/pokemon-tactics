extends RefCounted

const Legacy = preload("res://core/trainer_profile.gd")
const Collection = preload("res://core/collection_catalog.gd")
const ACHIEVEMENTS: Dictionary = {
	"first-recruit":["Nuevo compañero","Recluta un Pokémon después de empezar la aventura."],
	"new-starter":["Una nueva aventura","Empieza con una especie desbloqueada que no sea un inicial de Oak."],
	"legend-recruit":["Amistad legendaria","Recluta un Pokémon legendario o mítico."],
	"dex-10":["Coleccionista","Obtén 10 especies."],
	"dex-25":["Investigador","Obtén 25 especies."],
	"dex-50":["Naturalista","Obtén 50 especies."],
	"dex-100":["Experto de Kanto","Obtén 100 especies."],
	"dex-complete":["Maestro de la Pokédex","Obtén las 151 especies de Kanto."],
	"all-oak":["Compañeros de Oak","Obtén a Bulbasaur, Charmander y Squirtle."],
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
	data = value.duplicate(true) if not value.is_empty() else Legacy.new().data
	if data.get("version",1)==1:
		data.version = 2
		data.dex = unique_species(data.dex)
		data.seen = data.dex.duplicate()
	# JSON numbers arrive as floats; canonical IDs must match integer UI/domain IDs.
	data.dex = unique_species(data.dex)
	data.seen = unique_species(data.seen)

static func unique_species(values: Array) -> Array:
	var result: Array = []
	for entry: Variant in values:
		if (entry is int or entry is float) and entry==int(entry) and int(entry)>=1 and int(entry)<=151 and int(entry) not in result: result.append(int(entry))
	result.sort()
	return result

func starters() -> Array[int]:
	return Collection.starter_options(data.dex)

func see(species: int) -> void:
	if species>=1 and species<=151 and species not in data.seen: data.seen.append(species); data.seen.sort()

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
		for species_id: int in event.get("species",[]):
			register_species(species_id)
			if unlock("first-recruit",campaign_id): unlocked.append("first-recruit")
		if event.get("seen") is Array:
			for species: Variant in event.seen:
				if (species is int or species is float) and species==int(species): see(int(species))
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
	for unit: Dictionary in run.get("battle",{}).get("units",[]): see(int(unit.speciesId))
	var collection_flags: Array[String] = []
	if int(run.starter) not in [1,4,7]: collection_flags.append("new-starter")
	if data.dex.any(func(species):return int(species) in Collection.LEGENDS): collection_flags.append("legend-recruit")
	if [1,4,7].all(func(species):return species in data.dex): collection_flags.append("all-oak")
	for threshold: int in [10,25,50,100,151]:
		if data.dex.size()>=threshold: collection_flags.append("dex-complete" if threshold==151 else "dex-"+str(threshold))
	for pair: Array in [["legendary-birds","birds"],["legendary-origin","psychic"]]:
		if pair[0] in cleared: collection_flags.append(pair[1])
	for flag: String in collection_flags:
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
	see(species_id)
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
	if not value is Dictionary or value.get("version")!=2: return false
	var previous: Dictionary = value.duplicate(true)
	previous.version = 1
	if not previous.get("unlocked") is Dictionary: return false
	for key: Variant in previous.unlocked.keys():
		if not key is String or not ACHIEVEMENTS.has(key): return false
		if not previous.unlocked[key] is Dictionary or not previous.unlocked[key].get("run") is String: return false
		if not Legacy.ACHIEVEMENTS.has(key): previous.unlocked.erase(key)
	if not Legacy.valid(previous): return false
	if value.revision<0 or value.revision!=int(value.revision) or "\n" in value.name or "\r" in value.name: return false
	if value.has("notifications") and not value.notifications is bool: return false
	if not value.get("seen") is Array: return false
	for field: String in ["dex","seen"]:
		if unique_species(value[field]).size()!=value[field].size(): return false
	if not value.dex.all(func(species):return species in value.seen): return false
	return true
