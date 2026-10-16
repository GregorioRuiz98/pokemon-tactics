extends "res://core/letsgo_study.gd"

var tactical: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tactics.json"))

func _init() -> void:
	super()
	data.version = 6
	for identity: String in data.moves:
		var move: Dictionary = data.moves[identity]
		move.criticalStages = 1 if identity in tactical.highCritical else 0
		move.alwaysCritical = identity in tactical.alwaysCritical
		move.neverMiss = identity in tactical.neverMiss or move.target=="self"
		move.contactRange = move.range
		move.approach = int(tactical.approach.get(identity,0))
		move.pushDistance = int(tactical.push.get(identity,0))
		move.range += move.approach
		move.cost = maxi(move.cost,int(tactical.moveCosts.get(identity,0)))
		if identity=="skull-bash": move.changesSelf = true
		var positive: int = 0
		for change: Dictionary in move.changes: positive += maxi(0,int(change.stages))
		if move.category=="status" and positive>0: move.cost = maxi(move.cost,mini(5,1+positive))
		if identity=="focus-energy":
			move.kind = "focus"
			move.changes = []
			move.cost = 3
			move.description = "Foco Energía: +2 etapas de crítico durante tres activaciones, 3 PT. No modifica la precisión."
		else:
			move.description = move.description.replace("Sin bonificación de crítico en esta muestra.","")
			move.description = move.description.replace("Etapas:","Etapas temporales:").replace("dura el combate.","dura tres activaciones del afectado.")
			if positive>0: move.description += " Coste de mejora: %d PT." % move.cost
		if move.alwaysCritical: move.description += " Adaptación táctica: crítico garantizado, %d PT." % move.cost
		elif move.criticalStages>0: move.description += " +1 etapa de crítico."
		if move.approach>0: move.description += " Se acerca hasta %d puntos de movimiento, que se descuentan del presupuesto restante, incluso si falla. Cuenta como movimiento; no atraviesa enemigos ni termina sobre unidades. No se puede rectificar tras atacar." % move.approach
		if move.pushDistance>0: move.description += " Empuja una casilla si acierta y el destino está libre y es transitable; no añade daño por choque."
		if move.get("effect")!=null: move.effect.duration = int(tactical.duration)
		if move.get("secondary")!=null: move.secondary.duration = int(tactical.duration)
