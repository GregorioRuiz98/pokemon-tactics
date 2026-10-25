extends RefCounted

const Threat = preload("res://core/threat_query.gd")
const Challenge = preload("res://core/journey_challenge.gd")
const Card = preload("res://ui/journey_card.gd")
var deploy_panel: PanelContainer
var deploy_label: Label
var start_button: Button
var auto_button: Button
var threat_button: Button
var selected: int = 0
var scope: int = 0
var hovered_enemy: int = 0
var threat_job: RefCounted
var threat_cache: Dictionary = {}
var last_revision: int = -1
var last_state: Dictionary = {}
var toast: PanelContainer
var toast_image: TextureRect
var toast_text: Label
var toast_remaining: float = 0
var exporting: bool = false

func enabled(app: Control) -> bool:
	return app.run.get("edition",0)>=21

func setup(app: Control) -> void:
	var stack: Node = app.command_panel.get_parent()
	deploy_panel = app._panel()
	deploy_panel.add_theme_stylebox_override("panel",preload("res://ui/game_skin.gd").panel(Color("81ae91")))
	stack.add_child(deploy_panel)
	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation",10)
	deploy_panel.add_child(body)
	body.add_child(app._label("PREPARACIÓN",19,app.GOLD))
	deploy_label = app._label("Elige un aliado y su casilla.",17)
	deploy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(deploy_label)
	auto_button = app._button("Formación inicial",func():app._event({"kind":"auto-deploy","at":app.run.revision}))
	body.add_child(auto_button)
	start_button = app._button("Comenzar · B",func():app._event({"kind":"start-battle","at":app.run.revision}))
	start_button.theme_type_variation = "PrimaryButton"
	body.add_child(start_button)
	threat_button = app._button("Amenazas · T",func():cycle_threat(app),36)
	threat_button.theme_type_variation = "ToolButton"
	# Share the existing camera stack; do not extend the crowded top toolbar.
	stack.add_child(threat_button)
	stack.move_child(threat_button,1)
	threat_button.tooltip_text = "No / rival bajo el cursor / todos. Alcance geométrico con desplazamiento: no es una intención ni una garantía de impacto."
	toast = app._panel()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	app.add_child(toast)
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(row)
	toast_image = app._portrait(Vector2(48,48))
	toast_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(toast_image)
	toast_text = app._label("",19,app.GOLD)
	toast_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(toast_text)
	toast.hide(); deploy_panel.hide(); threat_button.hide()
	app._apply_preferences.call_deferred()
	app.board.deployment_dragged.connect(func(identity,point):
		if enabled(app) and not app._modal_open(): app._event({"kind":"deploy","member":identity,"destination":point,"at":app.run.revision}))

func refresh(app: Control) -> void:
	if deploy_panel==null: return
	var active: bool = enabled(app) and not app.title_visible and app.run.phase=="battle"
	deploy_panel.visible = active and app.state.get("deployment",false)
	threat_button.visible = active
	if not active:
		app.board.threat_cells = {}; threat_job = null; threat_cache.clear(); last_revision = -1
		last_state = {}
		if app.title_visible or not enabled(app): toast.hide(); toast_remaining = 0
		return
	if app.run.revision!=last_revision or not is_same(last_state,app.state):
		last_revision = app.run.revision
		last_state = app.state
		threat_cache.clear(); threat_job = null; app.board.threat_cells = {}
		request_threat(app)
	threat_button.text = "Amenazas: %s · %s" % [["No","Rival","Todas"][scope],app.input_profile.label("threats")]
	if deploy_panel.visible:
		app.command_panel.hide()
		deploy_panel.custom_minimum_size.x = app.command_panel.custom_minimum_size.x
		if selected==0 or app.rules.unit_by_id(app.state,selected).is_empty(): selected = int(app.state.units.filter(func(u):return u.team=="ally")[0].id)
		deploy_label.text = app.rules.unit_by_id(app.state,selected).name+" · elige una casilla verde"
		var chosen: Dictionary = app.rules.unit_by_id(app.state,selected)
		app.actor_title.text = "%s · Nv. %d" % [chosen.name,chosen.level]
		app.actor_portrait.texture = app.faces[int(chosen.speciesId)]
		app.actor_title.tooltip_text = "Aliado seleccionado para desplegar"
		app.actor_info.text = "%d / %d PS\n%d / %d PT\nMov. %d\nPreparación" % [chosen.hp,chosen.maxHp,chosen.tp,chosen.maxTp,app.rules.budget(chosen)]
		app.actor_hp.max_value = chosen.maxHp; app.actor_hp.value = chosen.hp
		app.actor_tp.max_value = chosen.maxTp; app.actor_tp.value = chosen.tp
		app.actor_indicators.show_unit(chosen)
		var fraction: float = float(chosen.hp)/maxi(1,int(chosen.maxHp))
		app.actor_hp.get_theme_stylebox("fill").bg_color = Color("71c5a1") if fraction>.5 else Color("e9c76d") if fraction>.25 else Color("ee997e")
		start_button.text = app.input_profile.shortcut("Comenzar","deploy_start")
		app.board.available = {}
		for point: Dictionary in app.state.arena.deployment: app.board.available[app.rules.Movement.key(point)] = {"path":[point],"cost":0}
		app.hint.text = "Arrastra aliados o elige aliado y casilla. Intercambia posiciones sin coste.\n"+app.state.arena.description
	else:
		var mission: Dictionary = app.state.get("mission",{})
		if mission.get("kind","defeat")!="defeat": app.heading.text += " · "+{"secure":"Terminales %d/%d" % [mission.captured.size(),mission.points.size()],"protect":"Fuji %d · hasta ronda %d" % [mission.health,mission.untilRound],"escape":"Alcanza las salidas"}.get(mission.kind,"")
	if app.run.phase=="battle": app.board.queue_redraw()

func select(app: Control, point: Dictionary) -> bool:
	if not enabled(app) or not app.state.get("deployment",false): return false
	if app._modal_open() or point.is_empty(): return true
	var occupant: Dictionary = app.rules._at(app.state,point)
	if not occupant.is_empty() and occupant.team=="ally": selected = int(occupant.id); refresh(app)
	elif selected>0: app._event({"kind":"deploy","member":selected,"destination":point,"at":app.run.revision})
	return true

func hover(app: Control, point: Dictionary) -> void:
	if not enabled(app) or app.state.is_empty() or point.is_empty(): return
	var unit: Dictionary = app.rules._at(app.state,point)
	if not unit.is_empty() and unit.team=="enemy" and hovered_enemy!=int(unit.id):
		hovered_enemy = int(unit.id)
		if scope==1: request_threat(app)
	if scope>0:
		var count: int = app.board.threat_cells.get(app.rules.Movement.key(point),[]).size()
		app.hint.text += "\n"+("Calculando cobertura…" if threat_job!=null else "Alcance potencial: %d rival(es). El estado y la visión pueden cambiar el ataque real." % count)
	if app.state.get("deployment",false): app.hint.text = "Elige un aliado y una casilla verde; también puedes arrastrarlo. "+app.input_profile.shortcut("Comenzar","deploy_start")+"."

func cycle_threat(app: Control) -> void:
	scope = (scope+1)%3
	request_threat(app); refresh(app)

func request_threat(app: Control) -> void:
	app.board.threat_cells = {}; threat_job = null
	if scope==0 or not enabled(app) or app.state.is_empty(): return
	if scope==1 and not app.rules.living(app.state).any(func(u):return u.team=="enemy" and int(u.id)==hovered_enemy): hovered_enemy = 0
	if scope==1 and hovered_enemy==0:
		for unit: Dictionary in app.state.units:
			if unit.team=="enemy" and unit.hp>0: hovered_enemy = int(unit.id); break
	var identity: int = hovered_enemy if scope==1 else 0
	if threat_cache.has(identity): app.board.threat_cells = threat_cache[identity]; return
	threat_job = Threat.new(); threat_job.start(app.rules,app.state,identity)

func tick(app: Control, delta: float) -> void:
	if toast_remaining>0:
		toast_remaining -= delta
		if toast_remaining<=0: toast.hide()
	if threat_job==null or app._modal_open(): return
	threat_job.advance()
	app.board.threat_cells = threat_job.cells
	if threat_job.complete:
		threat_cache[hovered_enemy if scope==1 else 0] = threat_job.cells
		threat_job = null
		app.hover_context.clear()
		app._hover_tile({"x":app.board.cursor.x,"y":app.board.cursor.y})
	app.board.queue_redraw()

func input(app: Control, event: InputEventKey) -> bool:
	if not event.pressed or event.echo or app._modal_open() or not enabled(app): return false
	if toast_remaining>0 and app.input_profile.matches(event,"cancel"): toast.hide(); toast_remaining = 0; return true
	if app.input_profile.matches(event,"share") and app.run.phase!="battle": export_card(app); return true
	if app.run.phase!="battle": return false
	if app.input_profile.matches(event,"threats"): cycle_threat(app); return true
	if app.state.get("deployment",false) and app.input_profile.matches(event,"deploy_start"):
		app._event({"kind":"start-battle","at":app.run.revision}); return true
	return false

func present(app: Control, command: Dictionary, previous: Dictionary) -> void:
	if not enabled(app): return
	var species: int = 0; var text: String = ""
	if app.run.phase=="capture" and previous.phase=="battle":
		species = int(app.run.reward.speciesId)
		text = "¡"+app.rules.profiles[species].data.name+" quiere unirse!"
		if app.run.medals.size()>previous.medals.size(): text = "¡Medalla conseguida! · "+text
	elif command.kind=="capture":
		species = int(previous.reward.speciesId); text = "¡"+app.rules.profiles[species].data.name+" se une a la aventura!"
	for entry: Dictionary in (app.run.get("lastProgress",[]) if previous.get("lastProgress",[])!=app.run.get("lastProgress",[]) else []):
		if not entry.get("evolutions",[]).is_empty() and command.kind in ["battle","train-xp","evolve-free"]:
			species = int(entry.evolutions[-1].to); text = "¡Ha evolucionado a "+app.rules.profiles[species].data.name+"!"
	if species==0: return
	toast_image.texture = app.faces[species]; toast_text.text = text
	toast.custom_minimum_size = Vector2(minf(600,app.size.x-48),76)
	toast.position = Vector2((app.size.x-toast.custom_minimum_size.x)*.5,app.size.y*.5-38)
	toast.size = toast.custom_minimum_size
	toast.show(); toast_remaining = maxf(2.2,float(app.input_profile.preferences.resultSeconds))
	app.accessible_view.announce(text)

func export_card(app: Control, output_path: String = "", copy_code: bool = true) -> void:
	if exporting or app.run.is_empty() or not enabled(app): return
	exporting = true
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(960,640)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	app.add_child(viewport)
	var card: Control = Card.new()
	card.theme = app.theme; card.size = Vector2(960,640)
	var code: String = Challenge.encode(app.run)
	card.summary = {"title":app.campaign.locations[int(app.run.stage)].name+" · "+{"defeat":"Fin de la aventura","ending":"Desafío completado","complete":"Liga completada"}.get(app.run.phase,"Aventura en curso"),"stats":app.run.get("tacticalStats",app.campaign.empty_stats()),"medals":app.run.medals.size(),"team":[],"seed":app.run.seed,"starter":app.run.starter,"width":app.run.mapSize,"code":code}
	for member: Dictionary in app.run.party:
		card.summary.team.append({"name":app.rules.profiles[int(member.speciesId)].data.name,"level":member.level,"hp":member.hp})
		card.portraits.append(app.faces[int(member.speciesId)])
	viewport.add_child(card)
	await RenderingServer.frame_post_draw
	var path: String = output_path if not output_path.is_empty() else "user://resumen-"+str(card.summary.seed).sha256_text().substr(0,8)+".png"
	var result: Error = viewport.get_texture().get_image().save_png(path)
	viewport.queue_free(); exporting = false
	if result==OK:
		if copy_code: DisplayServer.clipboard_set(code)
		app._review_text("Resumen de la aventura","Tarjeta guardada en:\n"+ProjectSettings.globalize_path(path)+"\n\nCódigo de reto copiado. Pégalo en el campo de semilla de Oak: fija semilla, inicial, tamaño y edición. Las decisiones durante la aventura pueden cambiar los resultados.")
	else: app._review_text("No se pudo guardar la tarjeta","No se ha podido escribir el PNG. Tu aventura se conserva.")
