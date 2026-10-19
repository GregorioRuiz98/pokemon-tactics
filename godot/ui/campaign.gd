extends "res://ui/laboratory.gd"

const Campaign = preload("res://core/kanto_run.gd")
const Advanced = preload("res://core/roster_run.gd")
const Journey = preload("res://core/journey_run.gd")
const CURRENT_CHAPTER: int = 22
const RosterPanel = preload("res://ui/roster_panel.gd")
const IsometricBoard = preload("res://ui/isometric_board.gd")
const CampaignStore = preload("res://core/journey_store.gd")
var campaign: RefCounted = Advanced.new()
var last_presentation: Dictionary = {}
var run: Dictionary = {}
var transactions: Array = []
var travel_root: MarginContainer
var travel_content: VBoxContainer
var travel_buttons: Dictionary = {}
var journey_seed: LineEdit
var selected_member: int = 1
var selected_mint: String = "adamant"
var training_choice: OptionButton
var campaign_confirm: ConfirmationDialog
var message: String = ""
var campaign_qa_dir: String = ""
var scale_qa_dir: String = ""
var roster_qa_dir: String = ""
var journey_qa_dir: String = ""
var roster_tab: String = "team"
var roster_offset: int = 0
var roster_swap: int = 1
var roster_panel: RefCounted = RosterPanel.new()
var camera_bar: HBoxContainer
var title_screen: Control
var title_visible: bool = false
var title_loading: bool = false
var oak_return: Dictionary = {}
var interface_qa_dir: String = ""
var shop_tab: String = "supplies"
var shop_sections: Dictionary = {}
var options_dialog: AcceptDialog
var options_buttons: Dictionary = {}
var new_seed: String = "kanto-14"

func _make_theme() -> void:
	super._make_theme()
	for control_type: String in ["Button","OptionButton","MenuButton"]:
		for entry: String in ["normal","hover","pressed","disabled","focus"]:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = Color("1a3d47") if entry=="normal" else (Color("28525c") if entry=="hover" else (Color("2a4c56") if entry=="pressed" else Color("142e37")))
			if entry=="focus": style.draw_center = false
			style.border_color = GOLD if entry in ["focus","pressed"] else Color("49646a")
			style.set_border_width_all(2 if entry=="focus" else 1)
			style.set_corner_radius_all(5)
			style.set_content_margin_all(10)
			theme.set_stylebox(entry,control_type,style)
			theme.set_color("font_pressed_color",control_type,GOLD)
			theme.set_color("font_hover_pressed_color",control_type,GOLD)
			theme.set_color("font_focus_color",control_type,CREAM)
	theme.set_stylebox("panel","PopupMenu",_surface())
	theme.set_stylebox("panel","AcceptDialog",_surface())

func _surface() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("122f39")
	style.border_color = Color("52717a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	style.shadow_color = Color(0.01,0.05,0.07,0.3)
	style.shadow_size = 6
	return style

func _panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_surface())
	return panel

func _ready() -> void:
	rules = campaign.engine
	for record: Dictionary in rules.data.species: faces[int(record.id)] = load("res://" + record.face)
	super._ready()
	camera_bar = HBoxContainer.new()
	camera_bar.position = Vector2(24,122 if run.get("edition",1)>=13 else 106)
	camera_bar.add_theme_constant_override("separation",6)
	battle_overlay.add_child(camera_bar)
	for entry: Array in [["−",func():board.change_zoom(1/1.12)],["+",func():board.change_zoom(1.12)],["Combate",func():board.frame_combat()],["Unidad · C",func():board.focus_active()],["Mapa",func():board.fit_map()],["Cuadrícula · G",func():board.strong_grid = not board.strong_grid; board.queue_redraw()],["Alturas · H",func():board.show_heights = not board.show_heights; board.queue_redraw()]]:
		var camera_button: Button = _button(entry[0],_camera_order.bind(entry[1]),40)
		camera_button.add_theme_font_size_override("font_size",16)
		camera_bar.add_child(camera_button)
	resized.connect(_refresh)

func _camera_order(callback: Callable) -> void:
	callback.call()
	board.grab_focus()

func _make_board() -> Control:
	return IsometricBoard.new()

func _movement_routes(actor: Dictionary) -> Dictionary:
	return rules.movement_routes(state,actor,actor.remaining) if state.get("combatEdition",0)>=11 else super._movement_routes(actor)

func _boot() -> void:
	if not qa_dir.is_empty():
		get_tree().change_scene_to_file.call_deferred("res://scenes/laboratory.tscn")
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--campaign-qa-dir="): campaign_qa_dir = argument.trim_prefix("--campaign-qa-dir=")
		if argument.begins_with("--scale-qa-dir="): scale_qa_dir = argument.trim_prefix("--scale-qa-dir=")
		if argument.begins_with("--roster-qa-dir="): roster_qa_dir = argument.trim_prefix("--roster-qa-dir=")
		if argument.begins_with("--journey-qa-dir="): journey_qa_dir = argument.trim_prefix("--journey-qa-dir=")
		if argument.begins_with("--interface-qa-dir="): interface_qa_dir = argument.trim_prefix("--interface-qa-dir=")
	var test_dir: String = scale_qa_dir if not scale_qa_dir.is_empty() else campaign_qa_dir
	if not roster_qa_dir.is_empty(): test_dir = roster_qa_dir
	if not journey_qa_dir.is_empty(): test_dir = journey_qa_dir
	if not interface_qa_dir.is_empty(): test_dir = interface_qa_dir
	qa_running = not test_dir.is_empty()
	if qa_running: DirAccess.make_dir_recursive_absolute(test_dir)
	store = CampaignStore.new(test_dir.path_join("campaign-save.json") if qa_running else "user://kanto-save.json")
	menu.get_popup().set_item_text(menu.get_popup().get_item_index(0),"Nueva campaña")
	menu.get_popup().set_item_text(menu.get_popup().get_item_index(7),"Laboratorio táctico")
	menu.get_popup().add_separator()
	menu.get_popup().add_item("Pantalla de inicio",8)
	travel_root = MarginContainer.new()
	travel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: travel_root.add_theme_constant_override("margin_" + edge,24)
	add_child(travel_root)
	travel_content = VBoxContainer.new()
	travel_content.add_theme_constant_override("separation",14)
	travel_root.add_child(travel_content)
	campaign_confirm = ConfirmationDialog.new()
	campaign_confirm.title = "Volver al laboratorio de Oak"
	campaign_confirm.dialog_text = "Podrás elegir otro inicial. La campaña anterior se conservará\ncomo copia al comenzar la nueva."
	campaign_confirm.confirmed.connect(_show_oak)
	add_child(campaign_confirm)
	title_screen = load("res://ui/title_screen.gd").new()
	add_child(title_screen)
	title_screen.setup(self)
	title_screen.hide()
	if not interface_qa_dir.is_empty(): _open_title(); call_deferred("_run_interface_qa")
	elif not journey_qa_dir.is_empty(): call_deferred("_run_journey_qa")
	elif not roster_qa_dir.is_empty(): call_deferred("_run_roster_qa")
	elif not scale_qa_dir.is_empty(): call_deferred("_run_scale_qa")
	elif qa_running: call_deferred("_run_campaign_qa")
	else: _open_title()

func _open_title() -> void:
	if not oak_return.is_empty():
		run = oak_return.run
		campaign = oak_return.campaign
		rules = campaign.engine
		transactions = oak_return.transactions
		state = run.battle
		oak_return = {}
	combat_feedback.clear()
	ai_clock = 0
	title_visible = true
	_refresh()

func _resume_title() -> void:
	if run.is_empty():
		title_loading = true
		title_screen.refresh()
		title_screen.controls["continue"].text = "Cargando aventura…"
		title_screen.controls["continue"].disabled = true
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		_load_game()
	else:
		title_visible = false
		_refresh()
		if run.phase=="battle": board.grab_focus()

func _new_from_title() -> void:
	if not run.is_empty() or FileAccess.file_exists(store.file_path): campaign_confirm.popup_centered()
	else: _show_oak()

func _title_options() -> void:
	if options_dialog==null:
		options_dialog = AcceptDialog.new()
		options_dialog.title = "Opciones"
		add_child(options_dialog)
		var content: VBoxContainer = VBoxContainer.new()
		content.custom_minimum_size.x = 320
		content.add_theme_constant_override("separation",16)
		options_dialog.add_child(content)
		for entry: Array in [["Sonidos",func(): _toggle_sound()],["Animaciones",func(): _toggle_motion()]]:
			var option: CheckButton = CheckButton.new()
			option.text = entry[0]
			option.button_pressed = not muted if entry[0]=="Sonidos" else not reduced_motion
			option.toggled.connect(func(_value: bool): entry[1].call())
			content.add_child(option)
			options_buttons[entry[0]] = option
		content.add_child(_label("Los controles y el guardado son locales.",16,MUTED))
	options_buttons["Sonidos"].set_pressed_no_signal(not muted)
	options_buttons["Animaciones"].set_pressed_no_signal(not reduced_motion)
	options_dialog.popup_centered()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if title_visible:
			if event.keycode==KEY_ESCAPE and not run.is_empty() and not help_dialog.visible and not credits_dialog.visible and not campaign_confirm.visible and (options_dialog==null or not options_dialog.visible): _resume_title(); get_viewport().set_input_as_handled()
			return
		if run.is_empty() and event.keycode==KEY_ESCAPE: _open_title(); get_viewport().set_input_as_handled(); return
	super._unhandled_key_input(event)

func _run_interface_qa() -> void:
	await get_tree().process_frame
	await load("res://ui/qa_interface.gd").new().run(self,interface_qa_dir)

func _show_oak() -> void:
	if not run.is_empty(): oak_return = {"run":run,"campaign":campaign,"transactions":transactions}
	title_visible = false
	combat_feedback.clear()
	run = {}
	state = {}
	transactions = []
	_refresh()

func _choose_starter(identity: int) -> void:
	var preserved: Dictionary = store.preserve_before_new()
	if not preserved.ok:
		message = preserved.reason
		_refresh()
		return
	campaign = Advanced.new() if campaign_qa_dir.is_empty() else load("res://core/traits_run.gd").new()
	if not scale_qa_dir.is_empty(): campaign = load("res://core/scale_run.gd").new()
	if campaign_qa_dir.is_empty() and scale_qa_dir.is_empty() and roster_qa_dir.is_empty(): campaign = Journey.new(CURRENT_CHAPTER)
	rules = campaign.engine
	run = campaign.create(journey_seed.text,identity)
	oak_return = {}
	_prepare_campaign_assets()
	transactions = []
	selected_member = 1
	roster_tab = "team"
	roster_offset = 0
	roster_swap = 1
	message = ""
	_save()
	_refresh()

func _menu_selected(identity: int) -> void:
	match identity:
		0: campaign_confirm.popup_centered()
		7: get_tree().change_scene_to_file("res://scenes/laboratory.tscn")
		8: _open_title()
		_: super._menu_selected(identity)

func _modal_open() -> bool:
	return title_visible or super._modal_open() or (campaign_confirm != null and campaign_confirm.visible) or (options_dialog!=null and options_dialog.visible)

func _player_turn() -> bool:
	return not run.is_empty() and run.phase == "battle" and super._player_turn()

func _save() -> void:
	if run.is_empty(): return
	var result: Dictionary = store.save(run,transactions,"kanto-14")
	save_warning = "" if result.ok else result.reason

func _load_game() -> void:
	var result: Dictionary = store.load_campaign(campaign)
	title_loading = false
	if not result.ok:
		save_warning = result.reason
		_refresh()
		return
	campaign = result.rules
	title_visible = false
	oak_return = {}
	rules = campaign.engine
	combat_feedback.clear()
	run = result.state
	_prepare_campaign_assets()
	transactions = result.commands
	save_warning = ""
	message = "Campaña recuperada." if run.get("edition",1) >= 12 else "Partida clásica %s: conserva sus reglas. Nueva campaña para usar el PC." % _classic_version()
	pending = {}
	selecting = "auto"
	action_page = false
	selected_action = "basic"
	ai_clock = 0
	_refresh()

func _event(command: Dictionary) -> void:
	if _modal_open(): return
	var result: Dictionary = campaign.transact(run,command)
	if not result.ok:
		message = result.reason
		if _player_turn(): hint.text = message
		else: _refresh()
		return
	if command.kind=="enter": combat_feedback.clear()
	last_presentation = result.get("presentation",{})
	run = result.state
	transactions.append(command.duplicate(true))
	pending = {}
	selected_action = "basic"
	action_page = false
	message = ""
	if command.kind=="revive": message = "Pokémon recuperado con el 50 % de sus PS máximos."
	if command.kind=="mint": message = "Menta aplicada: cambian los modificadores, se conserva la naturaleza original."
	if command.kind=="capsule": message = "Cápsula aplicada: cambia la habilidad normal, sin ocupar el objeto equipado."
	if command.kind=="capture" and run.get("edition",1)>=12:
		message = "Captura enviada al PC: el equipo tiene seis plazas." if run.reserve.any(func(m):return m.id==run.nextId-1) else "Nuevo compañero en el equipo."
	if command.kind=="deposit": message = "Compañero guardado en el PC. Conserva sus PS y su objeto."
	if command.kind=="withdraw": message = "Compañero añadido al equipo. Conserva sus PS y su objeto."
	if command.kind=="swap":
		selected_member = int(command.reserve)
		roster_tab = "team"
		roster_offset = 0
		message = "Intercambio completado, sin curación ni coste."
	state = run.battle
	if command.kind=="enter": _prepare_campaign_assets()
	history = run.battleCommands
	selecting = "finish" if _player_turn() and state.moved and state.acted else "auto"
	_save()
	_refresh()
	if command.kind=="level-up": _play("level-up")
	if run.phase == "battle": board.grab_focus()

func _prepare_campaign_assets() -> void:
	_queue_scrolling(run.get("edition",1)>=13)
	for record: Dictionary in rules.data.species:
		if not faces.has(int(record.id)): faces[int(record.id)] = load("res://"+record.face)
		if run.get("edition",1)>=13: portraits[int(record.id)] = faces[int(record.id)]
	var records: Array = rules.data.species
	if run.get("edition",1)>=13:
		var needed: Array = run.battle.units.map(func(u):return int(u.speciesId)) if not run.battle.is_empty() else run.party.map(func(m):return int(m.speciesId))
		records = records.filter(func(r):return int(r.id) in needed)
	board.setup(records)

func _queue_scrolling(expanded: bool) -> void:
	var wrapper: ScrollContainer
	if timeline.get_parent() is ScrollContainer:
		wrapper = timeline.get_parent()
	elif expanded:
		var parent: Node = timeline.get_parent()
		var index: int = timeline.get_index()
		parent.remove_child(timeline)
		wrapper = ScrollContainer.new()
		wrapper.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		wrapper.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		parent.add_child(wrapper)
		parent.move_child(wrapper,index)
		wrapper.add_child(timeline)
	if wrapper!=null: wrapper.custom_minimum_size.y = 48 if expanded else 32
	if camera_bar!=null: camera_bar.position.y = 122 if expanded else 106

func _upgrade_campaign() -> void:
	var replacement: RefCounted = Journey.new(CURRENT_CHAPTER)
	var command: Dictionary = {"kind":"upgrade","edition":CURRENT_CHAPTER-4,"at":run.revision}
	var result: Dictionary = replacement.transact(run,command)
	if not result.ok: message = result.reason; _refresh(); return
	var backup: Dictionary = store.preserve_before_new()
	if not backup.ok: message = backup.reason; _refresh(); return
	campaign = replacement
	rules = campaign.engine
	run = result.state
	transactions.append(command)
	_prepare_campaign_assets()
	message = "Versión actualizada. Final, equipo y diario conservados; copia anterior guardada." if run.phase=="ending" else "Aventura ampliada. Equipo, objetos, PS y diario conservados; copia de la partida anterior guardada."
	_save()
	_refresh()

func _commit(command: Dictionary) -> void:
	var before: Dictionary = state
	var revision: int = run.revision
	var plan: Dictionary = rules.attack_plan(state,int(command.target),{},command.get("actionId","basic")) if command.kind == "attack" else {}
	_event({"kind":"battle","order":command,"at":revision})
	if run.revision == revision: return
	if command.kind == "attack": combat_feedback.present(before,plan,last_presentation.get("hits",[]))
	if not last_presentation.get("abilityEvents",[]).is_empty(): combat_feedback.present_abilities(state,last_presentation.abilityEvents,command.kind!="attack")
	var leveled: bool = run.get("lastProgress",[]).any(func(entry):return entry.level > entry.before)
	_play(("level-up" if leveled else "victory") if state.outcome == "victory" else (combat_feedback.last_sound if command.kind == "attack" else "select"))

func _rectify_movement() -> void:
	if not pending.is_empty() or not _player_turn(): return
	_event({"kind":"rectify","at":run.revision})

func _refresh() -> void:
	if title_screen!=null:
		title_screen.visible = title_visible
		if title_visible:
			board.hide()
			battle_overlay.hide()
			travel_root.hide()
			title_screen.refresh()
			return
	if travel_root == null:
		super._refresh()
		if timeline.get_parent() is ScrollContainer: timeline.get_parent().scroll_horizontal = 0
		return
	if camera_bar!=null: camera_bar.visible = not run.is_empty() and run.phase=="battle" and run.get("edition",1)>=11
	var fighting: bool = not run.is_empty() and run.phase == "battle"
	board.visible = fighting
	battle_overlay.visible = fighting
	travel_root.visible = not fighting
	if fighting:
		state = run.battle
		history = run.battleCommands
		mode = "current"
		super._refresh()
		var location_name: String = ["Ruta 1","Ruta 2","Bosque Verde","Brock"][int(run.stage)] if run.get("edition",1) == 1 else campaign.locations[int(run.stage)].name
		heading.text = "%s · ronda %d%s" % [location_name,state.round," · clásica 0.14" if run.get("edition",1) == 1 else ""]
		heading.add_theme_font_size_override("font_size",15)
		var active: Dictionary = rules.active(state)
		if active.has("level"):
			actor_info.text = "Nv. %d · " % active.level + actor_info.text
			actor_info.tooltip_text = campaign.progression.roles(active)
			if active.has("abilityDescription"): actor_info.tooltip_text += "\n"+active.natureText+"\n"+active.abilityDescription
		if run.get("edition",1)>=11:
			board.track_turn()
			actor_info.tooltip_text += "\nAltura %d · subir cuesta +1; salto terrestre máximo 1." % rules.Terrain.height_at(state,active)
			for direction: int in direction_buttons: direction_buttons[direction].text = {4:"↗",2:"↘",0:"↙",6:"↖"}[direction]
		else:
			for direction: int in direction_buttons: direction_buttons[direction].text = {4:"↑",2:"→",0:"↓",6:"←"}[direction]
		_layout_battle_hud()
		var fraction: float = float(active.hp)/maxi(1,int(active.maxHp))
		actor_hp.get_theme_stylebox("fill").bg_color = Color("71c5a1") if fraction>0.5 else (Color("e9c76d") if fraction>0.25 else Color("ee997e"))
		for action_button: Button in action_buttons.values(): action_button.add_theme_font_size_override("font_size",16)
	else: _render_travel()

func _layout_battle_hud() -> void:
	var narrow: bool = size.x<1150
	var actor_width: float = 300 if narrow else 360
	var target_width: float = 330 if narrow else 390
	var actor_panel: Control = actor_portrait.get_parent().get_parent().get_parent()
	actor_panel.offset_right = 18+actor_width
	actor_portrait.custom_minimum_size = Vector2(72,72) if narrow else Vector2(104,104)
	actor_info.add_theme_font_size_override("font_size",16 if narrow else 18)
	target_panel.offset_left = -18-target_width
	target_portrait.custom_minimum_size = Vector2(56,56) if narrow else Vector2(80,80)
	target_info.custom_minimum_size.x = 200 if narrow else 250
	target_info.add_theme_font_size_override("font_size",15 if narrow else 17)
	var middle_left: float = 30+actor_width
	var middle_right: float = size.x-30-target_width
	var middle: float = (middle_left+middle_right)/2
	var width: float = minf(390,middle_right-middle_left)
	hint.get_parent().offset_left = middle-size.x/2-width/2
	hint.get_parent().offset_right = middle-size.x/2+width/2

func _show_plan(unit: Dictionary, plan: Dictionary) -> void:
	super._show_plan(unit,plan)
	if plan.ok and plan.has("heightDifference"): target_info.text += "\nDesnivel del objetivo: %+d · sin bonificación de daño." % plan.heightDifference

func _hover_tile(point: Dictionary) -> void:
	super._hover_tile(point)
	if not point.is_empty() and state.get("combatEdition",0)>=11 and not _modal_open(): hint.text += "\nAltura %d · rueda: zoom · botón central: cámara." % rules.Terrain.height_at(state,point)

func _travel_button(key: String, text: String, parent: Node, command: Dictionary) -> Button:
	command.at = run.revision
	var button: Button = _button(text,_event.bind(command))
	travel_buttons[key] = button
	parent.add_child(button)
	return button

func _render_travel() -> void:
	if is_instance_valid(journey_seed): new_seed = journey_seed.text
	_clear(travel_content)
	travel_buttons.clear()
	var header: HBoxContainer = HBoxContainer.new()
	travel_content.add_child(header)
	var title: Label = _label("ELIGE A TU COMPAÑERO" if run.is_empty() else "KANTO / TU AVENTURA",24,GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	if not run.is_empty(): header.add_child(_label("%d ₽" % run.money,22,GOLD))
	var home: Button = _button("Inicio",_open_title)
	header.add_child(home)
	travel_buttons.home = home
	header.add_child(_button("Ayuda",func(): help_dialog.popup_centered(Vector2i(630,450))))
	var classic: String = ""
	if not run.is_empty() and run.get("edition",1)<12: classic = "Clásica %s: conserva sus reglas. Nueva campaña para usar el PC." % _classic_version()
	var status: Label = _label(save_warning if not save_warning.is_empty() else (message if not message.is_empty() else (classic if not classic.is_empty() else ("Guardado automático local · Revivir disponible en tienda" if run.get("edition",1)>=9 else "Guardado automático local · bajas definitivas"))),17,MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	travel_content.add_child(status)
	if run.get("edition",1)>=12 and run.get("edition",1)<CURRENT_CHAPTER-4 and run.get("phase","") in ["map","shop","complete","ending"]:
		var upgrade: Button = _button("Actualizar versión · conservar final" if run.phase=="ending" else "Continuar aventura · ampliar Kanto",_upgrade_campaign)
		upgrade.tooltip_text = "Conserva equipo, PS, objetos y diario. Guarda una copia antes de adoptar la expansión; no transforma un combate en curso."
		travel_content.add_child(upgrade)
		travel_buttons.upgrade = upgrade
	if not run.is_empty() and run.get("edition",1)>=8:
		var limit: Dictionary = campaign.gym_limit(run)
		var limit_label: Label = _label("Límite Nv. %d · %s (%s). Al alcanzar el límite no se acumula EXP." % [limit.level,limit.leader,rules.profiles[int(limit.speciesId)].data.name],17,GOLD)
		limit_label.name = "GymLevelCap"
		limit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		travel_content.add_child(limit_label)
	if run.is_empty():
		travel_content.add_child(_label("Pueblo Paleta · Laboratorio de Oak",30,GOLD))
		travel_content.add_child(_label("Elige un inicial de nivel 5. Gana EXP, aprende y combina cuatro movimientos\nmás el básico neutro. Oak te entrega dos pociones y 120 ₽.",20))
		journey_seed = LineEdit.new()
		journey_seed.text = new_seed
		journey_seed.max_length = 64
		journey_seed.placeholder_text = "Semilla de la campaña"
		travel_content.add_child(journey_seed)
		var choices: HBoxContainer = HBoxContainer.new()
		choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
		travel_content.add_child(choices)
		for id: int in [1,4,7]:
			var panel: PanelContainer = _panel()
			panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			choices.add_child(panel)
			var content: VBoxContainer = VBoxContainer.new()
			content.alignment = BoxContainer.ALIGNMENT_CENTER
			content.add_theme_constant_override("separation",20)
			panel.add_child(content)
			var image: TextureRect = _portrait(Vector2(160,160))
			image.texture = faces[id]
			image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			content.add_child(image)
			var label: Label = _label(rules.profiles[id].data.name + "\n" + _type_names(rules.profiles[id].data.types),24,GOLD)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(label)
			var button: Button = _button("Elegir a " + rules.profiles[id].data.name,_choose_starter.bind(id))
			content.add_child(button)
			travel_buttons["starter" + str(id)] = button
		return
	var progress: HBoxContainer = HBoxContainer.new()
	if run.get("edition",1)>=11 and run.phase=="map" and run.cleared.is_empty():
		travel_content.add_child(_label("Ensayo de escala · %d×%d · vista isométrica y alturas" % [run.mapSize,run.mapSize],20,GOLD))
		var sizes: HBoxContainer = HBoxContainer.new()
		travel_content.add_child(sizes)
		for width: int in [16,24]:
			var pick: Button = _travel_button("size_"+str(width),"%d×%d%s" % [width,width," · recomendado" if width==16 else " · comparación"],sizes,{"kind":"map-size","size":width})
			pick.disabled = run.mapSize==width
		travel_content.add_child(_label("Subir: +1 movimiento por nivel; salto terrestre máximo 1. Voladores ignoran desniveles.\nAltura limita alcance y línea de visión; no aumenta el daño. Eliminar rivales sigue siendo el objetivo.",16,MUTED))
	travel_content.add_child(progress)
	if run.get("edition",1)>=13:
		progress.add_child(_label("Medallas %d / 8 · Lugares superados %d / %d · Equipo %d / 6 · PC %d" % [run.medals.size(),run.cleared.size(),campaign.locations.size(),run.party.size(),run.reserve.size()],19,GOLD))
	else:
		for index: int in campaign.locations.size():
			var label: Label = _label(("✓ " if index < run.stage else ("▶ " if index == run.stage else "· ")) + ["Ruta 1","Ruta 2","Bosque Verde","Brock"][index],20,GOLD if index == run.stage else MUTED)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			progress.add_child(label)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",18)
	travel_content.add_child(body)
	var left: PanelContainer = _panel()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	var left_column: VBoxContainer = VBoxContainer.new()
	left_column.add_theme_constant_override("separation",12)
	left.add_child(left_column)
	var story_scroll: ScrollContainer = ScrollContainer.new()
	story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	story_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(story_scroll)
	var narrative: VBoxContainer = VBoxContainer.new()
	narrative.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narrative.add_theme_constant_override("separation",18)
	story_scroll.add_child(narrative)
	var footer: VBoxContainer = VBoxContainer.new()
	left_column.add_child(footer)
	var location: Dictionary = campaign.locations[mini(int(run.stage),campaign.locations.size()-1)]
	var heading_text: String = location.name
	if run.phase == "capture": heading_text = "¡Un nuevo compañero!"
	elif run.phase == "shop": heading_text = "Tienda · prepara tu equipo"
	elif run.phase == "complete": heading_text = "Medalla Roca conseguida"
	elif run.phase == "defeat": heading_text = "El equipo ha caído"
	if run.get("edition",1)>=13 and run.phase=="complete": heading_text = "Liga y rival superados" if run.get("mainComplete",false) else "Tramo completado"
	if run.phase=="ending": heading_text = "Final · guardianes de Kanto" if run.finalPath=="birds" else "Final · el origen de Mewtwo"
	var chapter: Label = _label(heading_text,28,GOLD)
	chapter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative.add_child(chapter)
	var text: Label = _label(location.story,20)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative.add_child(text)
	match run.phase:
		"map":
			_travel_button("enter",("Visitar " if location.get("kind","")=="story" else "Entrar en ") + location.name,narrative,{"kind":"enter"})
			text.text += "\n\nVisita narrativa: abre caminos y tienda, sin captura ni curación." if location.get("kind","")=="story" else "\n\nUn combate por ubicación. Al ganar: captura local, tienda y siguiente tramo. Los PS no se restauran entre encuentros."
		"capture":
			var image: TextureRect = _portrait(Vector2(160,160))
			image.texture = faces[int(run.reward.speciesId)]
			narrative.add_child(image)
			text.text = "%s\nOrigen: %s\n\nLa captura ya está sorteada y guardada. Cargar no cambia el resultado. Se admiten duplicados en esta muestra." % [rules.profiles[int(run.reward.speciesId)].data.name + (" · Nv. %d" % run.reward.level if run.reward.has("level") else ""),run.reward.origin]
			var capture_text: String = "Dar la bienvenida al equipo"
			if run.get("edition",1)>=12 and run.party.size()>=6: capture_text = "Enviar al PC · equipo completo"
			_travel_button("capture",capture_text,narrative,{"kind":"capture"})
		"shop":
			text.text = "Dinero: %d ₽\nPociones: %d · Superpociones: %d · Caramelos Raros: %d\n\nUn Caramelo evoluciona una etapa sin requisito de nivel. No cura. Entrenar añade +5; máximo dos compras por Pokémon.\n\nSelecciona un miembro a la derecha para usar objetos o entrenar." % [run.money,run.bag.potion,run.bag["super-potion"],run.bag["rare-candy"]]
			if run.get("edition",1) >= 2:
				text.text = "Dinero: %d ₽\nPociones: %d · Superpociones: %d · Caramelos Raros: %d\n\nLas estadísticas crecen al subir de nivel. La EXP se gana con victorias.\n\nEvolución: nivel requerido + un Caramelo Raro. No cura ni da niveles. Preparar movimientos es gratis." % [run.money,run.bag.potion,run.bag["super-potion"],run.bag["rare-candy"]]
			if run.get("edition",1) >= 3:
				text.text = "Dinero: %d ₽\nPociones: %d · Superpociones: %d · Caramelos: %d\nNivel mínimo + Caramelo para evolucionar; no cura.\nCompra MT/equipo y úsalo con un miembro a la derecha." % [run.money,run.bag.potion,run.bag["super-potion"],run.bag["rare-candy"]]
				if run.get("edition",1)>=4: text.text = "Dinero: %d ₽\nPociones: %d · Superpociones: %d · Caramelos: %d\nCaramelo: +1 nivel. Evolución automática al alcanzar el nivel.\nCompra y usa objetos con un miembro a la derecha." % [run.money,run.bag.potion,run.bag["super-potion"],run.bag["rare-candy"]]
				if run.get("edition",1)>=7: text.text += "\nAl subir de nivel recuperas tantos PS como aumenten tus PS máximos."
				if run.get("edition",1)>=9: text.text += "\nRevivir: %d en bolsa · 150 ₽ · recupera al debilitado con el 50 %% de sus PS." % run.bag.revive
				shop_sections = _shop_panels(narrative)
				_render_stock(shop_sections.gear)
			var consumables: Dictionary = campaign.consumables if run.get("edition",1)>=4 else Campaign.ITEMS
			var shop_parent: Node = shop_sections.get("supplies",narrative) if run.get("edition",1)>=3 else narrative
			if run.get("edition",1)>=12:
				text.text = "Prepara al equipo antes de seguir. Compra aquí y usa los objetos desde la ficha del Pokémon."
				var stock_grid: GridContainer = GridContainer.new()
				stock_grid.columns = 2
				stock_grid.add_theme_constant_override("h_separation",8)
				stock_grid.add_theme_constant_override("v_separation",8)
				shop_parent.add_child(stock_grid)
				shop_parent = stock_grid
			for item: String in consumables:
				var destination: Node = shop_sections.traits if item=="ability-capsule" and run.get("edition",1)>=12 else shop_parent
				var label: String = "%s\n%d ₽ · bolsa %d" % [consumables[item].name,consumables[item].price,run.bag.get(item,0)] if run.get("edition",1)>=12 else "Comprar %s · %d ₽" % [consumables[item].name,consumables[item].price]
				var button: Button = _travel_button("buy_"+item,label,destination,{"kind":"buy","item":item})
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				if run.get("edition",1)>=12: button.add_theme_font_size_override("font_size",16)
				button.disabled = run.money < consumables[item].price
				if item=="revive": button.tooltip_text = "Recupera a un Pokémon debilitado con el 50 % de sus PS máximos. Solo en la tienda; consume una unidad de la bolsa."
			if run.get("edition",1)>=10: _render_mint_shop(shop_sections.get("traits",narrative))
			if run.get("edition",1)>=5 and run.get("edition",1)<13:
				var stone: Button = _travel_button("buy_leaf-stone","Comprar Piedra Hoja · 80 ₽",narrative,{"kind":"buy-stone"})
				stone.disabled = run.money<80
				stone.tooltip_text = "Evoluciona Gloom y Weepinbell. No cura ni sube niveles."
			_travel_button("continue","Seguir viaje" if run.get("edition",1)>=13 or run.stage < 3 else "Cerrar el tramo",footer,{"kind":"continue"})
		"complete": text.text = "Has vencido a Geodude y Onix. Conservas tu equipo, dinero, objetos y bajas.\n\nLa muestra termina en Brock. Las siguientes rutas, Liga y legendarios pertenecen a otros sprints."
		"defeat": text.text = ("Todo el equipo se ha debilitado. La campaña ha terminado; Revivir solo se puede usar en la tienda, si llegas con algún compañero en pie." if run.get("edition",1)>=9 else "Las bajas son definitivas. Esta campaña ha terminado y queda guardada para consultar el equipo.") + "\n\nPuedes comenzar de nuevo con otro inicial o semilla."
	if run.get("edition",1)>=12:
		if run.phase in ["map","shop"]: text.text += "\n\nGestiona Equipo y PC a la derecha. Cambiar compañeros es gratis y conserva sus PS; solo los desplegados ganan EXP."
		elif run.phase=="defeat": text.text += "\nLas reservas del PC tampoco permiten continuar tras perder un combate."
	if run.get("edition",1)>=13:
		if run.phase=="complete": text.text = "Conservas equipo, objetos, dinero y progreso. Has completado el contenido principal de este tramo. Puedes recorrer los desvíos pendientes."
		if run.phase in ["map","complete"]: _render_destinations(narrative)
		if run.phase=="complete" and run.mainComplete and run.chapter>=21 and run.finalPath=="":
			text.text = "Has vencido al Alto Mando y al rival. Elige un único desafío final; las dos rutas son excluyentes y no conceden capturas legendarias."
			for path: String in ["birds","psychic"]: _travel_button("destiny_"+path,"Articuno, Zapdos y Moltres" if path=="birds" else "Mew y Mewtwo",narrative,{"kind":"destiny","path":path})
		if run.phase=="ending": text.text = "Has completado la Liga, vencido al rival y superado tu desafío legendario. Tu equipo y el diario quedan guardados para consultar esta aventura. Ningún legendario se incorpora al PC."
	if run.get("edition",1) >= 2 and run.phase in ["capture","shop"]:
		var summary: Label = _label(_progress_summary(),17,GOLD)
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		narrative.add_child(summary)
	var right: PanelContainer = _panel()
	right.custom_minimum_size.x = 470
	body.add_child(right)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var team: VBoxContainer = VBoxContainer.new()
	team.custom_minimum_size.x = 430
	team.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team.add_theme_constant_override("separation",14)
	scroll.add_child(team)
	if run.get("edition",1)>=12:
		roster_panel.render(self,team)
	else:
		team.add_child(_label("TU EQUIPO · %d / 6 vivos" % run.party.filter(func(m):return m.hp > 0).size(),22,GOLD))
		var grid: GridContainer = GridContainer.new()
		grid.columns = 2
		team.add_child(grid)
		for member: Dictionary in run.party:
			var unit: Dictionary = rules.member_unit(member)
			var button: Button = _button("%s\n%d / %d PS%s" % [unit.name + (" · Nv. %d" % member.level if member.has("level") else ""),unit.hp,unit.maxHp,("\nDEBILITADO" if run.get("edition",1)>=9 else " · BAJA") if unit.hp == 0 else ""],_select_member.bind(int(member.id)),205)
			button.toggle_mode = true
			button.button_pressed = member.id == selected_member
			grid.add_child(button)
	var selected: Dictionary = campaign.target(run,selected_member)
	if selected.is_empty(): return
	var unit: Dictionary = rules.member_unit(selected)
	var profile_row: HBoxContainer = HBoxContainer.new()
	profile_row.add_theme_constant_override("separation",12)
	team.add_child(profile_row)
	var image: TextureRect = _portrait(Vector2(64,64))
	image.texture = faces[int(selected.speciesId)]
	profile_row.add_child(image)
	var info: Label = _label("%s · %s\nOrigen: %s\nAtaque %d / %d · Defensa %d / %d · Velocidad %d" % [unit.name,_type_names(unit.types),selected.origin,unit.attack,unit.specialAttack,unit.defense,unit.specialDefense,unit.speed],17)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_row.add_child(info)
	var modern_shop: bool = run.get("edition",1)>=12 and run.phase=="shop"
	if run.get("edition",1)>=10 and not modern_shop: _render_traits(team,selected)
	if run.get("edition",1)>=3 and not modern_shop: _render_inventory(team,selected)
	if run.get("edition",1) >= 2 and run.phase != "shop":
		_render_moves(team,selected)
	if run.phase == "shop":
		var use_parent: Node = team
		if modern_shop:
			team.add_child(_label("USAR CON %s" % unit.name.to_upper(),17,GOLD))
			var use_grid: GridContainer = GridContainer.new()
			use_grid.columns = 2
			use_grid.add_theme_constant_override("h_separation",8)
			use_grid.add_theme_constant_override("v_separation",8)
			team.add_child(use_grid)
			use_parent = use_grid
		if run.get("edition",1)>=9:
			var revive_text: String = "Revivir · 50 %% PS\n%d en bolsa" % run.bag.revive if modern_shop else "Usar Revivir · 50 %% PS · bolsa: %d" % run.bag.revive
			var revive: Button = _travel_button("revive",revive_text,use_parent,{"kind":"revive","member":selected_member})
			if modern_shop: revive.add_theme_font_size_override("font_size",16); revive.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			revive.disabled = selected.hp!=0 or run.bag.revive<=0
			revive.tooltip_text = "Solo debilitados: vuelve con %d / %d PS. Conserva nivel, EXP y movimientos; el equipable recuperado permanece en la bolsa." % [maxi(1,int(floor(unit.maxHp/2.0))),unit.maxHp]
		for item: String in (["potion","super-potion","hyper-potion","max-potion"] if run.get("edition",1)>=13 else ["potion","super-potion"]):
			var record: Dictionary = campaign.consumables[item] if run.get("edition",1)>=13 else Campaign.ITEMS[item]
			var heal_text: String = "Usar %s · +%d PS" % [record.name,record.heal] if item!="max-potion" else "Usar Poción Máxima · todos los PS"
			if modern_shop: heal_text = "%s\n%d en bolsa" % [record.name,run.bag[item]]
			var button: Button = _travel_button("heal_"+item,heal_text,use_parent,{"kind":"heal","item":item,"member":selected_member})
			button.tooltip_text = "Recupera %d PS, hasta el máximo. Solo fuera de combate." % record.heal if item!="max-potion" else "Recupera todos los PS actuales; no revive."
			if modern_shop: button.add_theme_font_size_override("font_size",16); button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.disabled = selected.hp <= 0 or selected.hp >= unit.maxHp or run.bag[item] <= 0
		if run.get("edition",1)>=4:
			var candy: Button = _travel_button("level-up","Usar Caramelo Raro · +1 nivel",team,{"kind":"level-up","member":selected_member})
			candy.disabled = selected.hp<=0 or selected.level>=campaign.progression.data.levelCap or run.bag["rare-candy"]<=0
			candy.tooltip_text = "Conserva EXP parcial y PS actuales. La evolución ocurre automáticamente al alcanzar su nivel."
			if run.get("edition",1)>=7: candy.tooltip_text = "Conserva EXP parcial. Recupera el aumento de PS máximos, incluida la evolución automática al subir de nivel."
			if run.get("edition",1)>=8:
				var cap: int = campaign.level_cap(run)
				candy.disabled = candy.disabled or selected.level>=cap
				candy.tooltip_text += " Límite actual: nivel %d. No se puede usar al alcanzarlo; la EXP parcial se descarta al llegar al límite." % cap
			var automatic: Dictionary = campaign.progression.evolution(selected)
			var evolution_label: Label = _label("Evolución automática: %s · Nv. %d" % [rules.profiles[int(automatic.speciesId)].data.name,automatic.level] if not automatic.is_empty() else "Sin otra evolución de Kanto",17,MUTED)
			evolution_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			team.add_child(evolution_label)
			if run.get("edition",1)>=13: _render_evolution_options(team,selected)
			if run.get("edition",1)>=5 and run.get("edition",1)<13 and campaign.progression.data.stoneEvolutions.has(str(int(selected.speciesId))):
				evolution_label.text = "Evolución con Piedra Hoja · bolsa: %d" % run.bag["leaf-stone"]
				var stone: Button = _travel_button("stone","Usar Piedra Hoja",team,{"kind":"stone","member":selected_member})
				stone.disabled = selected.hp<=0 or run.bag["leaf-stone"]<=0
			if modern_shop: _render_traits(team,selected); _render_inventory(team,selected)
			_render_moves(team,selected)
			return
		var evolve: Button = _travel_button("evolve","Evolucionar · 1 Caramelo Raro",team,{"kind":"evolve","member":selected_member})
		evolve.disabled = selected.hp <= 0 or not Campaign.EVOLUTIONS.has(int(selected.speciesId)) or run.bag["rare-candy"] <= 0
		if run.get("edition",1) >= 2:
			var requirement: Dictionary = campaign.progression.evolution(selected)
			evolve.text = "Sin otra evolución de Kanto" if requirement.is_empty() else "Evolucionar · Nv. %d + 1 Caramelo" % requirement.level
			evolve.disabled = selected.hp <= 0 or requirement.is_empty() or selected.level < requirement.level or run.bag["rare-candy"] <= 0
			_render_moves(team,selected)
			return
		training_choice = OptionButton.new()
		for stat: String in Campaign.STATS: training_choice.add_item(Campaign.STATS[stat])
		team.add_child(training_choice)
		var count: int = 0
		for amount: Variant in selected.training.values(): count += int(amount)
		var train: Button = _button("Entrenar +5 · 80 ₽ · %d / 2" % count,_train.bind(int(run.revision)))
		team.add_child(train)
		travel_buttons.train = train
		train.disabled = selected.hp <= 0 or count >= 2 or run.money < 80

func _select_member(identity: int) -> void:
	selected_member = identity
	_refresh()

func _shop_panels(parent: VBoxContainer) -> Dictionary:
	if run.get("edition",1)<12: return {"supplies":parent,"gear":parent,"traits":parent}
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation",8)
	parent.add_child(tabs)
	var result: Dictionary = {}
	for entry: Array in [["supplies","Objetos"],["gear","MT y equipo"],["traits","Rasgos"]]:
		var button: Button = _button(entry[1],_shop_page.bind(entry[0]))
		button.toggle_mode = true
		button.button_pressed = shop_tab==entry[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",16)
		tabs.add_child(button)
		travel_buttons["shop_"+entry[0]] = button
		var section: VBoxContainer = VBoxContainer.new()
		section.add_theme_constant_override("separation",10)
		section.visible = shop_tab==entry[0]
		parent.add_child(section)
		result[entry[0]] = section
	return result

func _shop_page(tab: String) -> void:
	shop_tab = tab
	_refresh()
	travel_buttons["shop_"+tab].grab_focus.call_deferred()

func _roster_page(tab: String, page: int) -> void:
	roster_tab = tab
	roster_offset = page
	if tab=="pc" and not run.reserve.is_empty(): selected_member = int(run.reserve[clampi(page*6,0,run.reserve.size()-1)].id)
	_refresh()

func _run_roster_qa() -> void:
	await get_tree().process_frame
	await load("res://ui/qa_roster.gd").new().run(self,roster_qa_dir)

func _run_journey_qa() -> void:
	await get_tree().process_frame
	await load("res://ui/qa_journey.gd").new().run(self,journey_qa_dir)

func _render_destinations(parent: VBoxContainer) -> void:
	var choices: Array = campaign.available(run)
	if choices.is_empty(): return
	parent.add_child(_label("DESTINOS DISPONIBLES",20,GOLD))
	for destination: Dictionary in choices:
		var button: Button = _travel_button("travel_"+destination.id,("Desvío · " if destination.get("optional",false) else "Historia · ")+destination.name,parent,{"kind":"travel","location":destination.id})
		button.disabled = run.phase=="map" and destination.id==campaign.locations[int(run.stage)].id
		button.tooltip_text = destination.story

func _render_evolution_options(parent: VBoxContainer, member: Dictionary) -> void:
	for option: Array in campaign.progression.stone_options(member):
		var item: String = option[1]
		var button: Button = _travel_button("evolution_"+str(int(option[0])),"Evolucionar a %s · %s · bolsa %d" % [rules.profiles[int(option[0])].data.name,campaign.evolution_items[item],run.bag[item]],parent,{"kind":"use-evolution","member":member.id,"item":item,"species":option[0]})
		button.disabled = member.hp<=0 or run.bag[item]<=0
		button.tooltip_text = "Consume el objeto, conserva PS actuales y EXP. No cura ni revive; aprende los movimientos de la nueva forma que correspondan a su nivel."

func _render_mint_shop(parent: VBoxContainer) -> void:
	var study: RefCounted = campaign.progression
	parent.add_child(_label("MENTAS · modificadores de naturaleza",20,GOLD))
	var choices: Array = study.mintable()
	var picker: OptionButton = OptionButton.new()
	picker.name = "MintPicker"
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for identity: String in choices: picker.add_item("Menta %s · bolsa: %d" % [study.traits.natures[identity].name,run.bag["mint-"+identity]])
	picker.select(choices.find(selected_mint))
	picker.item_selected.connect(func(index: int): selected_mint = choices[index]; _refresh())
	parent.add_child(picker)
	var buy: Button = _travel_button("buy_mint","Comprar Menta %s · %d ₽" % [study.traits.natures[selected_mint].name,study.traits.mintPrice],parent,{"kind":"buy","item":"mint-"+selected_mint})
	buy.disabled = run.money<int(study.traits.mintPrice)
	buy.tooltip_text = "Una menta de un uso. Elige su efecto y comprueba los atributos en la ficha antes de aplicarla."

func _render_traits(parent: VBoxContainer, member: Dictionary) -> void:
	var study: RefCounted = campaign.progression
	var identity: String = study.ability(member)
	var nature: Label = _label(study.nature_text(member),17,GOLD)
	nature.name = "NatureSummary"
	nature.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(nature)
	var passive: Label = _label("Habilidad: "+study.traits.abilities[identity].name,18,GOLD)
	passive.name = "AbilitySummary"
	passive.tooltip_text = study.traits.abilities[identity].description
	passive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(passive)
	if run.phase!="shop": return
	var before: Dictionary = study.member_stats(member)
	var copy: Dictionary = member.duplicate(true)
	copy.mint = selected_mint
	var after: Dictionary = study.member_stats(copy)
	var lines: Array[String] = []
	for key: String in study.STAT_KEYS:
		if before[key]!=after[key]: lines.append("%s %d → %d" % [study.STAT_NAMES[key],before[key],after[key]])
	var preview: Label = _label("Menta %s: %s" % [study.traits.natures[selected_mint].name,", ".join(lines) if not lines.is_empty() else "los valores redondeados no cambian a este nivel"],16,MUTED)
	preview.name = "MintPreview"
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(preview)
	var mint: Button = _travel_button("use_mint","Usar Menta %s · bolsa: %d" % [study.traits.natures[selected_mint].name,run.bag["mint-"+selected_mint]],parent,{"kind":"mint","member":member.id,"nature":selected_mint})
	mint.disabled = member.hp<=0 or run.bag["mint-"+selected_mint]<=0 or not study.mint_changes(member,selected_mint)
	var next: int = study.next_slot(member)
	copy.abilitySlot = next
	var next_ability: String = study.ability(copy)
	var capsule: Button = _travel_button("use_capsule","Usar Cápsula Habilidad · bolsa: %d\n" % run.bag["ability-capsule"]+(study.traits.abilities[next_ability].name if next!=0 else "Una sola habilidad normal"),parent,{"kind":"capsule","member":member.id})
	capsule.disabled = member.hp<=0 or next==0 or run.bag["ability-capsule"]<=0
	capsule.tooltip_text = study.traits.abilities[next_ability].description if next!=0 else "No se consume en especies con una única habilidad normal. Las habilidades ocultas requieren Parche Habilidad, reservado para después."

func _train(revision: int) -> void:
	_event({"kind":"train","stat":Campaign.STATS.keys()[training_choice.selected],"member":selected_member,"at":revision})

func _run_campaign_qa() -> void:
	await load("res://ui/qa_campaign.gd").new().run(self,campaign_qa_dir)

func _progress_summary() -> String:
	var lines: Array[String] = []
	for entry: Dictionary in run.get("lastProgress",[]):
		var text: String = "%s: +%d EXP" % [entry.name,entry.xp]
		if entry.level > entry.before: text += " · Nv. %d → %d" % [entry.before,entry.level]
		if entry.get("hpGain",0)>0: text += " · +%d PS" % entry.hpGain
		if entry.get("xpDiscarded",0)>0: text += " · %d EXP no acumulada (límite)" % entry.xpDiscarded
		for evolution: Dictionary in entry.get("evolutions",[]): text += " · %s → %s" % [rules.profiles[int(evolution.from)].data.name,rules.profiles[int(evolution.to)].data.name]
		if not entry.learned.is_empty(): text += " · aprende " + ", ".join(entry.learned.map(func(id):return campaign.progression.data.moves[id].name))
		lines.append(text)
	return "\n".join(lines)

func _render_moves(parent: VBoxContainer, member: Dictionary) -> void:
	var study: RefCounted = campaign.progression
	var at_cap: bool = run.get("edition",1)>=8 and member.level>=campaign.level_cap(run)
	var experience: Label = _label("Nv. %d · Límite alcanzado · EXP detenida" % member.level if at_cap else "Nv. %d · EXP %d / %d" % [member.level,member.xp,study.next_xp(member.level)],20,GOLD)
	experience.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(experience)
	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = study.next_xp(member.level)
	bar.value = member.xp
	bar.show_percentage = false
	bar.custom_minimum_size.y = 9
	parent.add_child(bar)
	var roles: Label = _label(study.roles(member),17,MUTED)
	roles.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roles.tooltip_text = "Número de movimientos preparados de cada rol; no concede estadísticas adicionales."
	parent.add_child(roles)
	parent.add_child(_label("Básico neutro fijo · 0 PT · sin STAB\nMOVIMIENTOS · %d / 4 · cambiar es gratis" % member.moves.size(),17,GOLD))
	for identity: String in member.knownMoves:
		var definition: Dictionary = study.data.moves[identity]
		var button: CheckButton = CheckButton.new()
		button.text = "%s · %s · %d PT" % [definition.name,TYPE_NAMES.get(definition.type,definition.type),definition.cost]
		button.button_pressed = identity in member.moves
		button.disabled = run.phase not in ["map","shop","complete"] or member.hp <= 0 or (member.moves.size() >= 4 and not button.button_pressed)
		button.tooltip_text = definition.description + " Quita uno para preparar otro si tienes cuatro."
		button.toggled.connect(_toggle_move.bind(int(member.id),identity,int(run.revision)))
		parent.add_child(button)
		travel_buttons["move_"+identity] = button
	var pending_moves: Array = []
	for entry: Dictionary in study.families[int(member.speciesId)].learnset:
		if run.get("edition",1)>=5 and (entry.level<=member.level or not entry.forms.any(func(id):return int(id)==int(member.speciesId))): continue
		if entry.id not in member.knownMoves:
			pending_moves.append("%s · Nv. %d%s" % [study.data.moves[entry.id].name,entry.level," · tras evolucionar" if not entry.forms.any(func(id):return int(id)==int(member.speciesId)) else ""])
	var pending_label: Label = _label("Próximos: " + "; ".join(pending_moves.slice(0,3)),16,MUTED)
	pending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(pending_label)

func _toggle_move(enabled: bool, member_id: int, identity: String, revision: int) -> void:
	var member: Dictionary = campaign.target(run,member_id)
	var moves: Array = member.moves.duplicate()
	if enabled: moves.append(identity)
	else: moves.erase(identity)
	_event({"kind":"loadout","member":member_id,"moves":moves,"at":revision})

func _default_hint() -> String:
	var classic: String = ""
	if not run.is_empty() and run.get("edition",1)<11: classic = "Clásica %s: menú → Nueva campaña para mapas isométricos y alturas.\n" % _classic_version()
	return classic + super._default_hint()

func _classic_version() -> String:
	return {1:"0.14",2:"0.14.1",3:"0.14.2",4:"0.14.3",5:"0.14.4",6:"0.14.5",7:"0.14.6",8:"0.14.7",9:"0.14.8",10:"0.14.9",11:"0.15"}.get(int(run.get("edition",1)),"0.14")

func _run_scale_qa() -> void:
	await get_tree().process_frame
	await load("res://ui/qa_scale.gd").new().run(self,scale_qa_dir)

func _render_stock(parent: VBoxContainer) -> void:
	parent.add_child(_label("OFERTAS · MT Y EQUIPO",21,GOLD))
	var cost: int = campaign.reroll_price(run)
	var reroll: Button = _travel_button("reroll","Renovar 3 ofertas · %d ₽" % cost,parent,{"kind":"reroll"})
	reroll.disabled = run.money<cost
	reroll.tooltip_text = "Renovaciones: 25, 50, 75… ₽ por visita. Cada oferta tiene una copia; renovar repone tres. Las compras van a la bolsa."
	for i: int in run.stock.size():
		var offer: Dictionary = run.stock[i]
		var item: Dictionary = campaign.shop_data.items[offer.item]
		var card: PanelContainer = _panel()
		parent.add_child(card)
		var content: VBoxContainer = VBoxContainer.new()
		card.add_child(content)
		var buy: Button = _travel_button("stock_"+str(i),"%s · %s" % [item.name,"AGOTADO" if offer.sold else "%d ₽" % item.price],content,{"kind":"buy-stock","slot":i})
		buy.disabled = offer.sold or run.money<item.price
		var description: String = item.description
		if item.kind == "tm":
			var names: Array[String] = []
			for member: Dictionary in (campaign.members(run) if run.get("edition",1)>=12 else run.party):
				if member.hp>0 and campaign.compatible(member,offer.item) and item.move not in member.knownMoves:
					var species_name: String = rules.profiles[int(member.speciesId)].data.name
					if species_name not in names: names.append(species_name)
			var move: Dictionary = campaign.progression.data.moves[item.move]
			description = "%s · %d PT · alcance %d%s\nPuede aprender: %s" % [TYPE_NAMES.get(move.type,move.type),move.cost,move.range," · potencia %d" % move.power if move.power>0 else "",", ".join(names) if not names.is_empty() else "ningún Pokémon disponible"]
			buy.tooltip_text = move.description.replace("speed","Velocidad").replace("defense","Defensa").replace("attack","Ataque") + " " + item.description
		else: buy.tooltip_text = item.description
		var label: Label = _label(description,16,MUTED)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(label)

func _render_inventory(parent: VBoxContainer, member: Dictionary) -> void:
	var held: Variant = member.get("heldItem")
	parent.add_child(_label("Objeto: " + (campaign.shop_data.items[held].name if held != null else "ninguno") + " · 1 / Pokémon",18,GOLD))
	var allowed: bool = member.hp>0 and run.phase in ["map","shop","complete"]
	if held != null:
		var remove: Button = _travel_button("unequip","Guardar objeto en la bolsa",parent,{"kind":"equip","member":member.id,"item":""})
		remove.disabled = not allowed
	for identity: String in campaign.shop_data.items:
		if run.bag[identity]<=0: continue
		var item: Dictionary = campaign.shop_data.items[identity]
		var teach: bool = item.kind == "tm"
		var available: bool = allowed and (campaign.compatible(member,identity) and item.move not in member.knownMoves if teach else held != identity)
		var label: String = "%s %s · bolsa %d" % ["Aprender" if teach else "Equipar",item.name,run.bag[identity]]
		var button: Button = _travel_button("use_"+identity,label,parent,{"kind":"teach" if teach else "equip","member":member.id,"item":identity})
		button.disabled = not available
		button.tooltip_text = item.description + (" Ya aprendido o incompatible." if teach and not available else "")
