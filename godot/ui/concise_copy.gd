extends RefCounted

# Presentation only; stories and rules stored in historical editions stay intact.
static func destination(location: Dictionary) -> String:
	if location.has("medal"): return "Recompensa: "+str(location.medal)+"."
	return {
		"ss-anne":"Consigue Corte.","rocket-hideout":"Recupera el Scope Silph.",
		"pokemon-tower":"Descubre qué protege la Torre.","fuji-rescue":"Rescata al Sr. Fuji.",
		"safari":"Consigue Surf y Fuerza.","silph-giovanni":"Libera Silph S. A.",
		"cerulean-rival":"Tu rival te espera.","tower-rival":"Tu rival te espera.",
		"silph-rival":"Tu rival te espera.","league-rival":"Tu rival te espera.",
		"champion":"La última prueba de la Liga.",
		"legendary-birds":"Articuno · Zapdos · Moltres","legendary-origin":"Mew · Mewtwo"
	}.get(str(location.id),"")

static func objective(state: Dictionary) -> String:
	var mission: Dictionary = state.get("mission",{})
	match mission.get("kind","defeat"):
		"secure": return "Termina un turno sobre cada terminal o derrota a los rivales."
		"protect": return "Protege a Fuji hasta la ronda %d o derrota a los rivales." % mission.get("untilRound",4)
		"escape": return "Lleva a todos los aliados en pie a las salidas o derrota a los rivales."
	return "Derrota a los rivales."

static func tactical_rules(edition: int) -> String:
	var text: String = "TURNOS\nMovimiento + acción, en cualquier orden. Puedes atravesar aliados, pero no ocupar su casilla.\nRectificar: solo el movimiento, antes de actuar o terminar.\nCuatro movimientos + básico neutro de 0 PT. Las áreas pueden alcanzar aliados."
	if edition>=6: text += "\n\nPOSICIÓN Y ESTADOS\nFrente: mitad baja del daño. Costado: mitad alta. Espalda: máximo y +1 etapa crítica. La posición no cambia la precisión.\nEstados y atributos temporales. Parálisis: mitad de movimiento."
	text += "\n\nAVENTURA\nLos PS persisten. Medicina fuera de combate; el PC no cura. Perder un combate termina la aventura, incluso con reservas."
	if edition>=20: text += "\nEntrenar compra la EXP pendiente del nivel. Evoluciones de piedra/intercambio: elección gratuita al nivel mínimo indicado."
	if edition>=8: text += "\nEl próximo gimnasio fija el nivel máximo; la EXP sobrante no se acumula."
	if edition>=22: text += "\n\nTERRENO\nObstáculos sólidos: bloquean paso y visión. Subir un nivel de altura cuesta +1 movimiento; saltos mayores requieren rodear o volar."
	if edition>=23:
		text = text.replace("Cuatro movimientos + básico neutro de 0 PT.","Cuatro movimientos, limitados por PP al equipar, + básico gratuito. Usarlos no gasta puntos.")
		text = text.replace("Estados y atributos temporales.","Estados temporales; atributos durante el combate.")
		text += "\nManantial: cura estados y confusión al terminar el turno; ambos bandos, sin curar PS."
	return text
