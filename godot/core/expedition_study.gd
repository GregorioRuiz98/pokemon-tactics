extends "res://core/traits_study.gd"

var expansion: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/expedition.json"))
var extra_stones: Dictionary = {}

func _init() -> void:
	super()
	data.species.append_array(expansion.species)
	data.families.append_array(expansion.families)
	data.moves.merge(expansion.moves,true)
	data.evolutions.merge(expansion.evolutions,true)
	data.encounters.merge(expansion.encounters,true)
	extra_stones = expansion.stoneEvolutions.duplicate(true)
	for key: String in data.stoneEvolutions: extra_stones[key] = [data.stoneEvolutions[key].duplicate()]
	species.clear()
	families.clear()
	for record: Dictionary in data.species: species[int(record.id)] = record
	for family: Dictionary in data.families:
		for identity: int in family.members: families[identity] = family
	for identity: String in expansion.moves:
		var move: Dictionary = data.moves[identity]
		move.criticalStages = int(move.get("criticalStages",0))
		move.alwaysCritical = false
		move.neverMiss = move.target=="self" or identity in ["swift","aerial-ace","magical-leaf","feint-attack","shadow-punch"]
		move.contactRange = move.range
		move.approach = 0
		move.pushDistance = 0
		var positive: int = 0
		for change: Dictionary in move.changes: positive += maxi(0,int(change.stages))
		if move.category=="status" and positive>0: move.cost = maxi(move.cost,mini(5,1+positive))
		move.description = move.description.replace("dura el combate.","dura tres activaciones.")
		if move.get("effect")!=null: move.effect.duration = 3
		if move.get("secondary")!=null: move.secondary.duration = 3
	if data.moves.has("transform"):
		data.moves.transform.merge({"kind":"transform","target":"enemy","range":2,"contactRange":2,"cost":3,"description":"Copia forma, tipos, atributos salvo PS, habilidad y cuatro movimientos del objetivo hasta terminar el combate. Conserva sus PS y posición."},true)
	for identity: String in ["recover","soft-boiled","rest"]:
		if data.moves.has(identity): data.moves[identity].merge({"kind":"heal","target":"self","range":0,"cost":4 if identity=="rest" else 3,"description":"Recupera todos sus PS y duerme tres activaciones; 4 PT." if identity=="rest" else "Recupera la mitad de sus PS máximos; 3 PT. Adaptación táctica sin consumo de PP."},true)
	for identity: String in ["roar","whirlwind"]:
		if data.moves.has(identity): data.moves[identity].pushDistance = 1; data.moves[identity].description += " Empuja una casilla si está libre; no expulsa del combate."
	for identity: String in ["fissure","horn-drill","guillotine"]:
		if data.moves.has(identity): data.moves[identity].merge({"power":100,"cost":5,"description":"Adaptación de KO directo: potencia100, 5 PT, precisión original. No causa un KO automático."},true)
	var additions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/expedition-traits.json"))
	traits.species.merge(additions.species,true)
	traits.abilities.merge(additions.abilities,true)
	for move_id: String in additions.contact:
		if move_id not in traits.contact: traits.contact.append(move_id)
	for identity: String in additions.abilities:
		traits.abilities[identity].description = "Pendiente: requiere clima, huida, cambios en combate u otra interacción todavía no adaptada. No produce efectos en esta versión."
	var active_descriptions: Dictionary = {
		"intimidate":"Al desplegarse baja un nivel el Ataque de rivales a seis casillas durante tres activaciones.",
		"poison-point":"Contacto: 30 % de envenenar al atacante si no es inmune.","flame-body":"Contacto: 30 % de quemar al atacante si no es inmune.","effect-spore":"Adaptación: contacto con un rival vivo tiene un 30 % de dormir al atacante durante tres activaciones.",
		"flash-fire":"Inmune a Fuego; al absorberlo obtiene +1 Ataque especial temporal, adaptación táctica.","dry-skin":"Absorbe Agua y recupera 25 % PS; recibe un 25 % más de potencia Fuego. Sin efectos de clima.",
		"tinted-lens":"Duplica el daño de los movimientos resistidos.","technician":"Potencia de movimientos de hasta60 ×1,5.","limber":"Inmune a parálisis.","damp":"Impide movimientos de autodestrucción mientras siga en combate.",
		"vital-spirit":"Impide dormirse.","water-absorb":"Inmune a Agua y recupera un cuarto de sus PS máximos al absorberla.","volt-absorb":"Inmune a Eléctrico y recupera un cuarto de sus PS máximos al absorberlo.",
		"synchronize":"Refleja al atacante el veneno, quemadura o parálisis que le acaba de causar, respetando inmunidades.","no-guard":"Sus movimientos y los dirigidos contra él no fallan.","clear-body":"Impide cambios negativos de atributos del rival.","own-tempo":"Impide confusión.",
		"thick-fat":"Reduce a la mitad la potencia de Fuego y Hielo recibida.","shell-armor":"No recibe golpes críticos.","battle-armor":"No recibe golpes críticos.","skill-link":"Movimientos de2–5 impactos agregados: aplica cinco impactos en lugar de dos.",
		"levitate":"Inmune a movimientos Tierra.","insomnia":"Impide dormirse.","hyper-cutter":"Impide bajadas de Ataque causadas por rivales.","soundproof":"Inmune a los movimientos de sonido adaptados.",
		"lightning-rod":"Inmune a Eléctrico; al recibirlo obtiene +1 Ataque especial temporal. No redirige áreas.","reckless":"Potencia de movimientos con retroceso ×1,2.","iron-fist":"Potencia de puños ×1,2.",
		"serene-grace":"Duplica las probabilidades de efectos secundarios, hasta100 %.","filter":"Reduce un25 % el daño supereficaz.","mold-breaker":"Sus movimientos ignoran las habilidades defensivas del objetivo.","adaptability":"Adapta STAB de1,5 a2 mediante potencia ×4/3.",
		"pressure":"Los movimientos enemigos dirigidos contra él cuestan +1 PT, con máximo5.","immunity":"Impide envenenamiento.","water-veil":"Impide quemaduras.","anger-point":"Al recibir un crítico gana +2 Ataque temporal, límite táctico."
	}
	for identity: String in active_descriptions:
		traits.abilities[identity].description = active_descriptions[identity]
		traits.abilities[identity].implemented = true
	for identity: String in additions.abilities:
		if not traits.abilities[identity].get("implemented",false): traits.abilities[identity].name += " · pendiente"
	data.version = 13

func stone_options(member: Dictionary) -> Array:
	return extra_stones.get(str(int(member.speciesId)),[])
