extends RefCounted

const Indicators = preload("res://ui/unit_indicators.gd")

static func unit_text(app: Control, unit: Dictionary) -> String:
	if unit.is_empty(): return "Casilla sin ocupante."
	var active: bool = app.rules.active(app.state).get("id")==unit.id
	var text: String = "%s · Nv. %d · ID %d\n%s%s\nPS %d / %d · PT %d / %d\nTipos: %s\nMovimiento: %d · %s\nOrientación: %s" % [unit.name,unit.get("level",1),unit.id,"Aliado" if unit.team=="ally" else "Rival"," · turno activo" if active else "",unit.hp,unit.maxHp,unit.tp,unit.maxTp,app._type_names(unit.types),unit.remaining,"acción usada" if active and app.state.acted else "acción disponible" if active else "fuera de su activación",{4:"norte",2:"este",0:"sur",6:"oeste"}.get(int(unit.facing),str(unit.facing))]
	if app.state.get("combatEdition",0)>=11: text += " · altura %d" % app.rules.Terrain.height_at(app.state,unit)
	if unit.has("abilityName"): text += "\nHabilidad: "+unit.abilityName+"\n"+unit.get("abilityDescription","")
	for entry: Dictionary in Indicators.entries(unit): text += "\n"+entry.hint
	if app.state.get("combatEdition",0)>=6: text += "\nEstados y etapas: caducan por activaciones propias. Parálisis: mitad de desplazamiento."
	else: text += "\nPartida clásica: conserva las duraciones y efectos de su edición."
	return text

static func forecast(unit: Dictionary, plan: Dictionary) -> String:
	if not plan.ok: return unit.name+"\nNo disponible: "+plan.reason
	var text: String = "%s → %s\nCoste: %d PT · precisión %d %%" % [plan.name,unit.name,plan.cost,plan.accuracy]
	text += "\nDaño normal: %d–%d PS" % [plan.get("damageMin",plan.damage),plan.get("damageMax",plan.damage)]
	if plan.heal: text += "\nCuración: %d PS" % plan.heal
	if plan.get("criticalChance",0)>0: text += "\nCrítico: %.2f %% · %d–%d PS" % [100*plan.criticalChance,plan.criticalMin,plan.criticalMax]
	if maxi(plan.get("damageMax",plan.damage),plan.get("criticalMax",0))>=unit.hp and plan.accuracy>0: text += "\nKO posible; no garantiza acierto ni superar pasivas."
	if plan.get("sturdy",false): text += "\nRobustez puede dejar 1 PS."
	return text

static func tile_text(app: Control, point: Dictionary) -> String:
	if app.state.is_empty(): return "No hay combate abierto."
	var text: String = app.rules.coordinate(point)+" · "+{0:"Suelo",1:"Maleza",2:"Roca",3:"Agua"}.get(int(app.state.board[int(point.y)][int(point.x)]),"Terreno")
	if app.state.get("combatEdition",0)>=11: text += " · altura %d" % app.rules.Terrain.height_at(app.state,point)
	for field: Dictionary in app.state.get("fields",[]):
		if field.x==point.x and field.y==point.y and app.state.get("combatEdition",0)>=18: text += "\n"+preload("res://ui/spatial_interaction.gd").NAMES.get(field.kind,field.kind)+( " · campo del escenario" if field.get("source",1)==0 and int(field.expires)>=999 else " · %d rondas" % maxi(1,int(field.expires)-int(app.state.round)-1))
	if app.state.get("combatEdition",0)>=19:
		var mission: Dictionary = app.state.get("mission",{})
		if mission.get("points",[]).any(func(p):return app.Movement.same(p,point)): text += "\nObjetivo: "+{"secure":"terminal","protect":"proteger a Fuji","escape":"salida"}.get(mission.kind,"")
		for pair: Array in app.state.get("arena",{}).get("portals",[]):
			if app.Movement.same(point,pair[0]) or app.Movement.same(point,pair[1]): text += "\nTransportador: salida en "+app.rules.coordinate(pair[1] if app.Movement.same(point,pair[0]) else pair[0])+"; solo funciona si está libre."
	return text+"\n"+unit_text(app,app._unit_at(point))
