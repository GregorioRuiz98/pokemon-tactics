extends RefCounted

const NAMES: Dictionary = {"smoke":"Humo · precisión ×0,75 al cruzarlo", "poison":"Gas venenoso", "fire":"Fuego residual", "mud":"Lodo · movimiento +1", "web":"Seda · movimiento +1", "rocks":"Rocas · trampa de un uso", "mist":"Neblina · protege de bajadas", "wall":"Barrera · bloquea paso y visión", "reflect":"Reflejo · daño físico ×0,75", "light-screen":"Pantalla Luz · daño especial ×0,75"}
const SHAPES: Dictionary = {"C0":"cruz cercana", "C1":"cruz", "R1":"anillo", "D2":"rombo", "L2":"línea de 2", "L3":"línea de 3", "L4":"línea de 4", "K2":"cono", "W6":"ola", "F0":"barrido", "F3":"franja", "T4":"abanico", "X5":"aspa", "DAI7":"estrella", "WALL3":"pantalla de 3"}

static func enabled(app: Control) -> bool:
	return not app.state.is_empty() and app.state.get("combatEdition",0)>=18 and app.rules.has_method("cast_plan")

static func aim(app: Control, point: Dictionary) -> Dictionary:
	return {"x":point.x,"y":point.y,"axis":app.spatial_axis,"throwFacing":app.spatial_throw}

static func preview(app: Control, point: Dictionary) -> Dictionary:
	var plan: Dictionary = app._spatial_plan(aim(app,point),app.selected_action)
	app.target_panel.visible = true
	var unit: Dictionary = app._unit_at(point)
	app.target_portrait.visible = not unit.is_empty()
	app.target_indicators.show_unit(unit)
	if not unit.is_empty(): app.target_portrait.texture = app.faces[int(unit.speciesId)]
	app.target_info.text = app.rules.coordinate(point)
	if not plan.ok:
		app.target_info.text += "\n"+plan.reason
		return plan
	var text: String = "%s · %d PT · Pot. %s\n%s · Casillas afectadas: %d" % [plan.name,plan.cost,preload("res://ui/move_info.gd").power(plan.definition),SHAPES.get(plan.shape,"Objetivo"),plan.tiles.size()]
	if plan.field!="": text += "\n"+NAMES.get(plan.field,plan.field)+"\nDura dos rondas completas."
	if plan.get("randomTechnique",false): text += "\nTécnica aleatoria: %d–%d PS previstos." % [plan.damageMin,plan.damageMax]
	for hit: Dictionary in plan.hits:
		var target: Dictionary = app.rules.unit_by_id(app.state,int(hit.targetId))
		text += "\n%s: %d–%d PS · %d %%" % [target.name,hit.damageMin,hit.damageMax,hit.accuracy]
		if hit.get("heal",0)>0: text += " · cura %d" % hit.heal
		if hit.push!=null: text += " → "+app.rules.coordinate(hit.push)
		if hit.status!=null: text += " · "+app._status_name(hit.status.kind)
		if hit.has("randomStatus"): text += " · %d %%: quemadura, hielo o parálisis" % hit.randomStatus.chance
		if hit.get("criticalChance",0)>0: text += " · crítico %.1f %%" % [hit.criticalChance*100]
	if app._friendly_risk(plan): text += "\n¡Alcanza a aliados!"
	if plan.get("recoil",0)>0: text += "\nCoste propio: hasta %d PS." % plan.recoil
	if app.state.get("combatEdition",0)>=19:
		var reactions: Dictionary = {}
		for field: Dictionary in app.state.fields:
			if not plan.tiles.any(func(p):return app.rules.Movement.same(p,field)): continue
			if field.kind=="web" and plan.definition.get("type")=="fire": reactions["Seda → fuego temporal"] = true
			if field.kind=="fire" and plan.definition.get("extinguish",false): reactions["Fuego → lodo temporal"] = true
			if field.kind in ["smoke","poison"] and plan.definition.get("dispel",false): reactions["Dispersa humo y gas"] = true
		for reaction: String in reactions: text += "\nTerreno: "+reaction
	if plan.shape=="WALL3" or plan.definition.get("special","")=="throw": text += "\n%s/%s: girar · Enter: aceptar" % [app.input_profile.label("previous_target"),app.input_profile.label("next_target")]
	app.target_info.text = text
	app.target_info.set_meta("details",text+"\n\n"+preload("res://ui/move_info.gd").details(plan.definition))
	app.board.affected = plan.tiles
	app.board.forecast_hits = plan.hits
	if not plan.approach.is_empty(): app.board.route = plan.approach.path
	return plan

static func select(app: Control, point: Dictionary) -> void:
	if app.state.acted: return
	var plan: Dictionary = preview(app,point)
	if not plan.ok: app.hint.text = plan.reason; return
	var unit: Dictionary = app._unit_at(point)
	var command: Dictionary = {"kind":"attack","target":unit.get("id",0),"aim":aim(app,point),"actionId":app.selected_action}
	var risks: Array[String] = app._action_risks(plan)
	if not risks.is_empty() or app.input_profile.confirmation_mode=="safe":
		app.pending = command
		app._refresh()
		preview(app,point)
		app.hint.text = (" · ".join(risks)+".\n" if not risks.is_empty() else "")+"Confirma para actuar; Esc cancela."
		app.buttons.confirm.text = "Confirmar acción"
		app.buttons.confirm.grab_focus()
	else: app._commit(command)

static func rotate(app: Control, step: int) -> bool:
	if not enabled(app) or app.selecting!="attack": return false
	var definition: Dictionary = app.rules.profile(app.rules.active(app.state)).action(app.rules.active(app.state),app.selected_action).definition
	if definition.get("shape","")=="WALL3": app.spatial_axis = 1-app.spatial_axis
	elif definition.get("special","")=="throw": app.spatial_throw = posmod(app.spatial_throw+step,4)
	else: return false
	app.hover_context.clear()
	app._hover_tile({"x":app.board.cursor.x,"y":app.board.cursor.y})
	app.board.queue_redraw()
	return true
