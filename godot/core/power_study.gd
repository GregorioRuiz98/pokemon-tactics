extends "res://core/adventure_study.gd"

const Points = preload("res://core/power_points.gd")

func _init() -> void:
	super()
	data.version = 23
	for move: Dictionary in data.moves.values():
		move.loadoutCost = Points.price(move)
		move.cost = 0
		move.permanentStages = true
		var text: String = move.description
		for value: int in range(6): text = text.replace("%d PT"%value,"")
		text = text.replace("Atributos temporales","Atributos durante el combate")
		if not move.get("changes",[]).is_empty(): text = text.replace("tres activaciones","el combate").replace("3 activaciones","el combate")
		move.description = text
	traits.abilities.pressure.description = "Sin efecto con PP de equipamiento."
	traits.abilities.pressure.implemented = false
	traits.abilities.pressure.name = "Presión · sin efecto"
	traits.abilities["anger-point"].description = "Al recibir un crítico gana +2 Ataque, hasta el límite táctico y durante el combate."

func learn(member: Dictionary) -> Array:
	var previous: Array = member.moves.duplicate()
	var added: Array = super.learn(member)
	if data.moves.is_empty() or not data.moves.values()[0].has("loadoutCost"): return added
	member.moves = Points.fit(previous+added,member.level,data.moves)
	return added
