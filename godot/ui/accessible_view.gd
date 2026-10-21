extends RefCounted

const Info = preload("res://ui/tactical_info.gd")
var app: Control
var panel: PanelContainer
var text: Label
var last_message: String = ""
var message_count: int = 0
var notice: String = ""
var update_queued: bool = false
var controls_dirty: bool = true
var last_context: Array = []

func setup(owner_app: Control) -> void:
	app = owner_app
	panel = app._panel()
	panel.position = Vector2(24,185)
	panel.custom_minimum_size = Vector2(510,210)
	app.battle_overlay.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	panel.add_child(column)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480,160)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	text = app._label("",17)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.focus_mode = Control.FOCUS_ALL
	scroll.add_child(text)
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	row.add_child(app._button("Ficha de unidad",app._inspect))
	row.add_child(app._button("Último resultado",app._last_result))
	panel.hide()

func request_update(controls_changed: bool = false) -> void:
	if controls_changed:
		controls_dirty = true
		last_context.clear()
	if update_queued: return
	update_queued = true
	update.call_deferred()

func describe(node: Node) -> void:
	if node is BaseButton and not node.has_meta("semantic_manual"):
		if node is Button and node.accessibility_name!=node.text: node.accessibility_name = node.text
		var description: String = node.tooltip_text
		if node.disabled and description.is_empty(): description = "No disponible en la fase o selección actual."
		if node.accessibility_description!=description: node.accessibility_description = description
	elif node is LineEdit:
		var name_text: String = node.placeholder_text if not node.placeholder_text.is_empty() else "Buscar / editar texto"
		if node.accessibility_name!=name_text: node.accessibility_name = name_text
	elif node is SpinBox and node.accessibility_name!="Cantidad; usa flechas o escribe el valor": node.accessibility_name = "Cantidad; usa flechas o escribe el valor"
	for child: Node in node.get_children(): describe(child)

func update() -> void:
	update_queued = false
	if app==null or not app.is_inside_tree(): return
	if controls_dirty:
		describe(app)
		controls_dirty = false
	panel.visible = app.input_profile.preferences.accessibleMode and not app.state.is_empty() and app.board.visible
	app.board.accessibility_live = AccessibilityServer.LIVE_POLITE if panel.visible else AccessibilityServer.LIVE_OFF
	app.board.accessibility_description = "Tablero táctico. Flechas: casilla. Enter: aceptar. Escape: cancelar. "+app.input_profile.label("inspect")+": lista de unidades y detalle. "+app.input_profile.label("result")+": último resultado. Reasignación en Controles."
	if not panel.visible:
		last_context.clear()
		if app.board.accessibility_name!="Tablero táctico": app.board.accessibility_name = "Tablero táctico"
		return
	var context: Array = [app.board.cursor,app.selected_action,app.selecting,app.state.get("moved",false),app.state.get("acted",false),app.save_warning]
	if context==last_context and notice.is_empty(): return
	last_context = context
	var point: Dictionary = {"x":app.board.cursor.x,"y":app.board.cursor.y}
	if point.x<0 or point.y<0 or point.x>=app.board.dimensions().x or point.y>=app.board.dimensions().y: return
	var message: String = Info.tile_text(app,point)
	var actor: Dictionary = app.rules.active(app.state)
	message = "Turno: "+actor.name+".\n"+message
	if app._player_turn():
		var target: Dictionary = app._unit_at(point)
		if app.selecting=="finish": message += "\nOrientación: flechas eligen; Enter termina. Escape vuelve."
		elif not target.is_empty() and not app.state.acted:
			var plan: Dictionary = app.rules.attack_plan(app.state,int(target.id),{},app.selected_action)
			message += "\n"+Info.forecast(target,plan)
			if plan.ok:
				message += "\nSTAB ×%s; eficacia ×%s." % [plan.stab,plan.multiplier]
				var risks: Array[String] = app._action_risks(plan)
				if not risks.is_empty(): message += "\nRiesgo: "+"; ".join(risks)
		elif app.board.available.has(app.Movement.key(point)): message += "\nMovimiento legal. Coste %d." % app.board.available[app.Movement.key(point)].cost
		else: message += "\nNo es destino de movimiento legal; ocupación, alcance o movimiento usado."
	else: message += "\nInspección: no es turno aliado."
	if not app.save_warning.is_empty(): message += "\nAviso de guardado: "+app.save_warning
	if not notice.is_empty(): message = notice+"\n"+message; notice = ""
	text.text = message
	# Only the focused board is a live region. The visible copy has no second live stream.
	if message!=last_message:
		last_message = message
		message_count += 1
		app.board.accessibility_name = message
	text.accessibility_name = message
	text.accessibility_description = "Copia textual consultable; el tablero conserva el cursor lógico."

func announce(message: String) -> void:
	if not app.input_profile.preferences.accessibleMode: return
	notice = message
	request_update()

func probe() -> Dictionary:
	return {"engine":Engine.get_version_info(),"os":OS.get_name(),"osVersion":OS.get_version(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"dpi":DisplayServer.screen_get_dpi(),"supported":app.get_tree().is_accessibility_supported(),"enabled":app.get_tree().is_accessibility_enabled(),"readerAudibleTest":"pending","humanReaderTest":"pending"}
