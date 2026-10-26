extends RefCounted

static func refresh_battle(app: Control) -> void:
	var unit: Dictionary = app.rules.active(app.state)
	if unit.is_empty(): return
	if app.state.get("deployment",false):
		var selected: Dictionary = app.rules.unit_by_id(app.state,int(app.adventure.selected))
		if not selected.is_empty(): unit = selected
	app.actor_tp.hide()
	app.actor_info.text = app.actor_info.text.replace("%d / %d PT\n" % [unit.tp,unit.maxTp],"")
	app.actor_info.tooltip_text = "PP equipados: %d / %d · sin gasto al actuar" % [unit.ppUsed,unit.ppCapacity]
	if unit.has("abilityDescription"): app.actor_info.tooltip_text += "\n"+unit.natureText+"\n"+unit.abilityDescription
