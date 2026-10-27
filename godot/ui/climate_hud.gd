extends RefCounted

const Context = preload("res://core/climate_context.gd")

static func refresh(app: Control) -> void:
	app.heading.text += " · "+Context.label(app.state)
	var actor: Dictionary = app.rules.active(app.state)
	if actor.is_empty(): return
	app.actor_title.text += " "+Context.gender_symbol(actor)
	if Context.ability(app.state,actor)=="" and Context.native(actor)!="": app.actor_info.text += "\nHabilidad anulada por Gas Reactivo"
	if actor.climate.get("forewarn","")!="": app.actor_info.tooltip_text += "\nAlerta: "+app.rules.catalog.moves.get(actor.climate.forewarn,{"name":"Básico"}).name
	if app.state.get("deployment",false):
		for entry: Dictionary in app.rules.entry_preview(app.state): app.hint.text += "\n%s · Calco → %s"%[entry.name,entry.ability]
	var point: Dictionary = {"x":app.board.cursor.x,"y":app.board.cursor.y}
	var unit: Dictionary = app.rules._at(app.state,point)
	if not unit.is_empty():
		var ability: String = Context.ability(app.state,unit)
		app.target_info.tooltip_text = unit.abilityDescription+"\nSexo: "+Context.gender_symbol(unit)
		if ability=="" and Context.native(unit)!="": app.target_info.tooltip_text += "\nAnulada por Gas Reactivo."
