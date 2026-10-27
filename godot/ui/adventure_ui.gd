extends RefCounted

const Challenge = preload("res://core/collection_challenge.gd")
const Card = preload("res://ui/journey_card.gd")
var deploy_panel: PanelContainer
var deploy_label: Label
var start_button: Button
var auto_button: Button
var selected: int = 0
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
	toast_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	toast_text.clip_text = true
	toast_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	toast_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(toast_text)
	toast.hide(); deploy_panel.hide()
	app._apply_preferences.call_deferred()
	app.board.deployment_dragged.connect(func(identity,point):
		if enabled(app) and not app._modal_open(): app._event({"kind":"deploy","member":identity,"destination":point,"at":app.run.revision}))

func refresh(app: Control) -> void:
	if deploy_panel==null: return
	var active: bool = enabled(app) and not app.title_visible and app.run.phase=="battle"
	deploy_panel.visible = active and app.state.get("deployment",false)
	if not active:
		if app.title_visible or not enabled(app): toast.hide(); toast_remaining = 0
		return
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
		app.hint.text = "Despliega en las casillas verdes.\n"+preload("res://ui/concise_copy.gd").objective(app.state)
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
	if app.state.get("deployment",false): app.hint.text = "Elige un aliado y una casilla verde; también puedes arrastrarlo. "+app.input_profile.shortcut("Comenzar","deploy_start")+"."

func tick(_app: Control, delta: float) -> void:
	if toast_remaining>0:
		toast_remaining -= delta
		if toast_remaining<=0: toast.hide()

func input(app: Control, event: InputEventKey) -> bool:
	if not event.pressed or event.echo or app._modal_open() or not enabled(app): return false
	if toast_remaining>0 and app.input_profile.matches(event,"cancel"): toast.hide(); toast_remaining = 0; return true
	if app.input_profile.matches(event,"share") and app.run.phase!="battle": export_card(app); return true
	if app.run.phase!="battle": return false
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
	toast_text.tooltip_text = text
	toast.custom_minimum_size = Vector2(minf(600,app.size.x-48),maxf(76,preload("res://ui/presentation_settings.gd").font_factor(app)*40+28))
	toast.position = Vector2((app.size.x-toast.custom_minimum_size.x)*.5,app.size.y*.5-toast.custom_minimum_size.y*.5)
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
		app._review_text("Resumen de la aventura","Tarjeta guardada en:\n"+ProjectSettings.globalize_path(path)+"\n\nCódigo de reto copiado. Pégalo en Opciones de partida al elegir inicial. El reto fija el inicial y el mapa; tus decisiones pueden cambiar el resultado.")
	else: app._review_text("No se pudo guardar la tarjeta","No se ha podido escribir el PNG. Tu aventura se conserva.")
