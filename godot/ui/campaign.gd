extends "res://ui/laboratory.gd"

const Campaign = preload("res://core/kanto_run.gd")
const Advanced = preload("res://core/roster_run.gd")
const Journey = preload("res://core/climate_run.gd")
const CURRENT_CHAPTER: int = 29
const Art = preload("res://ui/visual_assets.gd")
const RosterPanel = preload("res://ui/roster_panel.gd")
const IsometricBoard = preload("res://ui/climate_board.gd")
const CampaignStore = preload("res://core/climate_store.gd")
const Copy = preload("res://ui/concise_copy.gd")
var kanto_qa_dir: String = ""
var copy_qa_dir: String = ""
var power_qa_dir: String = ""
var sleep_qa_dir: String = ""
var symbols_qa_dir: String = ""
var climate_qa_dir: String = ""
var trainer: RefCounted = preload("res://ui/trainer_session.gd").new()
var trainer_qa_dir: String = ""
var kecleon: RefCounted = preload("res://ui/kecleon_shop.gd").new()
var shop_qa_dir: String = ""
var variety_qa_dir: String = ""
var adventure: RefCounted = preload("res://ui/adventure_ui.gd").new()
var campaign: RefCounted = Advanced.new()
var last_presentation: Dictionary = {}
var spatial_qa_dir: String = ""
var moves_qa_dir: String = ""
var economy_qa_dir: String = ""
var adventure_qa_dir: String = ""
var run: Dictionary = {}
var transactions: Array = []
var travel_root: MarginContainer
var travel_art: Control
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
var camera_dock: MarginContainer
var camera_pad: GridContainer
var camera_compass: Label
var camera_buttons: Dictionary = {}
var title_screen: Control
var title_visible: bool = false
var title_loading: bool = false
var oak_return: Dictionary = {}
var interface_qa_dir: String = ""
var shop_tab: String = "supplies"
var hub_mode: String = "overview"
var member_view: String = "items"
var hub_parts: Dictionary = {}
var shop_sections: Dictionary = {}
var shop_batch: ConfirmationDialog
var batch_busy: bool = false
var action_review: ConfirmationDialog
var accessible_view: RefCounted = preload("res://ui/accessible_view.gd").new()
var practice: RefCounted = preload("res://ui/guided_practice.gd").new()
var last_load_msec: int = 0
var move_library: RefCounted = preload("res://ui/move_library.gd").new()
var options_dialog: AcceptDialog
var options_buttons: Dictionary = {}
var new_seed: String = ""
var seed_options_open: bool = false
var player_qa_dir: String = ""
var input_qa_dir: String = ""
var context_qa_dir: String = ""
var updates_qa_dir: String = ""
var performance_qa_dir: String = ""
var seeds_qa_dir: String = ""
var attack_qa_dir: String = ""
var travel_memory: Dictionary = {}
var travel_phase: String = ""

func _make_theme() -> void:
	super._make_theme()

func _surface() -> StyleBoxFlat:
	return GameSkin.panel()

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
		camera_button.theme_type_variation = "ToolButton"
		camera_button.add_theme_font_size_override("font_size",15)
		camera_bar.add_child(camera_button)
	camera_dock = MarginContainer.new()
	battle_overlay.add_child(camera_dock)
	camera_dock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	camera_dock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	camera_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var camera_stack: VBoxContainer = VBoxContainer.new()
	camera_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camera_stack.add_theme_constant_override("separation",12)
	camera_dock.add_child(camera_stack)
	var camera_row: HBoxContainer = HBoxContainer.new()
	camera_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camera_row.alignment = BoxContainer.ALIGNMENT_END
	camera_stack.add_child(camera_row)
	camera_pad = GridContainer.new()
	camera_pad.columns = 3
	camera_pad.add_theme_constant_override("h_separation",2)
	camera_pad.add_theme_constant_override("v_separation",2)
	camera_row.add_child(camera_pad)
	for entry: Array in [["",""],["up","↑"],["",""],["left","←"],["mode","P"],["right","→"],["",""],["down","↓"],["",""]]:
		if entry[0].is_empty():
			var space: Control = Control.new()
			space.custom_minimum_size = Vector2(40,40)
			space.mouse_filter = Control.MOUSE_FILTER_IGNORE
			camera_pad.add_child(space)
		else:
			var identity: String = entry[0]
			var vectors: Dictionary = {"left":Vector2(48,0),"right":Vector2(-48,0),"up":Vector2(0,48),"down":Vector2(0,-48)}
			var callback: Callable = board.toggle_camera if identity=="mode" else board.pan.bind(vectors[identity])
			var button: Button = _button(entry[1],_camera_order.bind(callback),40)
			button.theme_type_variation = "ToolButton"
			button.add_theme_font_size_override("font_size",16)
			if identity=="mode": button.toggle_mode = true
			camera_pad.add_child(button)
			camera_buttons[identity] = button
	command_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	command_panel.reparent(camera_stack,false)
	board.camera_mode_changed.connect(_camera_labels)
	camera_compass = _label("Cursor isométrico\n↑ −Y ↗   → +X ↘\n← −X ↖   ↓ +Y ↙",13,MUTED)
	camera_compass.position = Vector2(size.x-276,270)
	camera_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_overlay.add_child(camera_compass)
	resized.connect(_refresh)
	accessible_view.setup(self)
	accessible_view.update()
	_input_labels()
	adventure.setup(self)
	adventure.refresh(self)

func _input_labels() -> void:
	super._input_labels()
	if camera_bar!=null:
		for entry: Array in [[3,"Unidad","center"],[5,"Cuadrícula","grid"],[6,"Alturas","heights"]]:
			camera_bar.get_child(entry[0]).text = input_profile.shortcut(entry[1],entry[2])
	_camera_labels()

func _camera_labels() -> void:
	if camera_buttons.is_empty(): return
	camera_buttons.mode.text = input_profile.label("camera_mode")
	camera_buttons.mode.set_pressed_no_signal(board.camera_mode)
	camera_buttons.mode.tooltip_text = input_profile.shortcut("Modo cámara: flechas desplazan la vista; pulsa de nuevo para volver al cursor","camera_mode")
	for identity: String in ["up","down","left","right"]:
		camera_buttons[identity].tooltip_text = "Desplazar cámara · "+input_profile.label("pan_"+identity)

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
		if argument.begins_with("--climate-qa-dir="): climate_qa_dir = argument.trim_prefix("--climate-qa-dir=")
		if argument.begins_with("--symbols-qa-dir="): symbols_qa_dir = argument.trim_prefix("--symbols-qa-dir=")
		if argument.begins_with("--sleep-qa-dir="): sleep_qa_dir = argument.trim_prefix("--sleep-qa-dir=")
		if argument.begins_with("--power-qa-dir="): power_qa_dir = argument.trim_prefix("--power-qa-dir=")
		if argument.begins_with("--copy-qa-dir="): copy_qa_dir = argument.trim_prefix("--copy-qa-dir=")
		if argument.begins_with("--kanto-qa-dir="): kanto_qa_dir = argument.trim_prefix("--kanto-qa-dir=")
		if argument.begins_with("--shop-qa-dir="): shop_qa_dir = argument.trim_prefix("--shop-qa-dir=")
		if argument.begins_with("--variety-qa-dir="): variety_qa_dir = argument.trim_prefix("--variety-qa-dir=")
		if argument.begins_with("--trainer-qa-dir="): trainer_qa_dir = argument.trim_prefix("--trainer-qa-dir=")
		if argument.begins_with("--player-qa-dir="): player_qa_dir = argument.trim_prefix("--player-qa-dir=")
		if argument.begins_with("--adventure-qa-dir="): adventure_qa_dir = argument.trim_prefix("--adventure-qa-dir=")
		if argument.begins_with("--economy-qa-dir="): economy_qa_dir = argument.trim_prefix("--economy-qa-dir=")
		if argument.begins_with("--moves-qa-dir="): moves_qa_dir = argument.trim_prefix("--moves-qa-dir=")
		if argument.begins_with("--spatial-qa-dir="): spatial_qa_dir = argument.trim_prefix("--spatial-qa-dir=")
		if argument.begins_with("--campaign-qa-dir="): campaign_qa_dir = argument.trim_prefix("--campaign-qa-dir=")
		if argument.begins_with("--scale-qa-dir="): scale_qa_dir = argument.trim_prefix("--scale-qa-dir=")
		if argument.begins_with("--roster-qa-dir="): roster_qa_dir = argument.trim_prefix("--roster-qa-dir=")
		if argument.begins_with("--journey-qa-dir="): journey_qa_dir = argument.trim_prefix("--journey-qa-dir=")
		if argument.begins_with("--interface-qa-dir="): interface_qa_dir = argument.trim_prefix("--interface-qa-dir=")
		if argument.begins_with("--input-qa-dir="): input_qa_dir = argument.trim_prefix("--input-qa-dir=")
		if argument.begins_with("--updates-qa-dir="): updates_qa_dir = argument.trim_prefix("--updates-qa-dir=")
		if argument.begins_with("--context-qa-dir="): context_qa_dir = argument.trim_prefix("--context-qa-dir=")
		if argument.begins_with("--performance-qa-dir="): performance_qa_dir = argument.trim_prefix("--performance-qa-dir=")
		if argument.begins_with("--attack-qa-dir="): attack_qa_dir = argument.trim_prefix("--attack-qa-dir=")
		if argument.begins_with("--seeds-qa-dir="): seeds_qa_dir = argument.trim_prefix("--seeds-qa-dir=")
	var test_dir: String = scale_qa_dir if not scale_qa_dir.is_empty() else campaign_qa_dir
	if not roster_qa_dir.is_empty(): test_dir = roster_qa_dir
	if not journey_qa_dir.is_empty(): test_dir = journey_qa_dir
	if not interface_qa_dir.is_empty(): test_dir = interface_qa_dir
	if not input_qa_dir.is_empty(): test_dir = input_qa_dir
	if not context_qa_dir.is_empty(): test_dir = context_qa_dir
	if not updates_qa_dir.is_empty(): test_dir = updates_qa_dir
	if not performance_qa_dir.is_empty(): test_dir = performance_qa_dir
	if not seeds_qa_dir.is_empty(): test_dir = seeds_qa_dir
	if not attack_qa_dir.is_empty(): test_dir = attack_qa_dir
	if not spatial_qa_dir.is_empty(): test_dir = spatial_qa_dir
	if not moves_qa_dir.is_empty(): test_dir = moves_qa_dir
	if not economy_qa_dir.is_empty(): test_dir = economy_qa_dir
	if not adventure_qa_dir.is_empty(): test_dir = adventure_qa_dir
	if not player_qa_dir.is_empty(): test_dir = player_qa_dir
	if not trainer_qa_dir.is_empty(): test_dir = trainer_qa_dir
	if not shop_qa_dir.is_empty(): test_dir = shop_qa_dir
	if not variety_qa_dir.is_empty(): test_dir = variety_qa_dir
	if not kanto_qa_dir.is_empty(): test_dir = kanto_qa_dir
	if not copy_qa_dir.is_empty(): test_dir = copy_qa_dir
	if not power_qa_dir.is_empty(): test_dir = power_qa_dir
	if not sleep_qa_dir.is_empty(): test_dir = sleep_qa_dir
	if not symbols_qa_dir.is_empty(): test_dir = symbols_qa_dir
	if not climate_qa_dir.is_empty(): test_dir = climate_qa_dir
	qa_running = not test_dir.is_empty()
	if qa_running: DirAccess.make_dir_recursive_absolute(test_dir)
	store = CampaignStore.new(test_dir.path_join("campaign-save.json") if qa_running else "user://kanto-save.json")
	trainer.setup(self,test_dir.path_join("trainer-profile.json") if qa_running else "user://trainer-profile.json")
	menu.get_popup().set_item_text(menu.get_popup().get_item_index(0),"Nueva campaña")
	menu.get_popup().set_item_text(menu.get_popup().get_item_index(7),"Laboratorio táctico")
	menu.get_popup().add_separator()
	menu.get_popup().add_item("Pantalla de inicio",8)
	menu.get_popup().add_item("Aprender / salir de práctica",13)
	menu.get_popup().add_item("Reglas tácticas",14)
	menu.get_popup().add_item("Copiar semilla",15)
	menu.get_popup().add_item("Perfil de entrenador",16)
	if "--developer" not in OS.get_cmdline_user_args(): menu.get_popup().remove_item(menu.get_popup().get_item_index(7))
	travel_art = load("res://ui/artwork_slot.gd").new()
	add_child(travel_art)
	travel_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	travel_art.configure("scene_oak",true)
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
	_watch_dialog(campaign_confirm)
	title_screen = load("res://ui/title_screen.gd").new()
	add_child(title_screen)
	title_screen.setup(self)
	title_screen.hide()
	if not climate_qa_dir.is_empty(): _open_title(); call_deferred("_run_climate_qa")
	elif not symbols_qa_dir.is_empty(): _open_title(); call_deferred("_run_symbols_qa")
	elif not sleep_qa_dir.is_empty(): _open_title(); call_deferred("_run_sleep_qa")
	elif not power_qa_dir.is_empty(): _open_title(); call_deferred("_run_power_qa")
	elif not copy_qa_dir.is_empty(): _open_title(); call_deferred("_run_copy_qa")
	elif not kanto_qa_dir.is_empty(): _open_title(); call_deferred("_run_kanto_qa")
	elif not shop_qa_dir.is_empty(): _open_title(); call_deferred("_run_shop_qa")
	elif not variety_qa_dir.is_empty(): _open_title(); call_deferred("_run_variety_qa")
	elif not trainer_qa_dir.is_empty(): _open_title(); call_deferred("_run_trainer_qa")
	elif not player_qa_dir.is_empty(): _open_title(); call_deferred("_run_player_qa")
	elif not economy_qa_dir.is_empty(): _open_title(); call_deferred("_run_economy_qa")
	elif not moves_qa_dir.is_empty(): _open_title(); call_deferred("_run_moves_qa")
	elif not spatial_qa_dir.is_empty(): _open_title(); call_deferred("_run_spatial_qa")
	elif not adventure_qa_dir.is_empty(): _open_title(); call_deferred("_run_adventure_qa")
	elif not attack_qa_dir.is_empty(): _open_title(); call_deferred("_run_attack_qa")
	elif not seeds_qa_dir.is_empty(): _open_title(); call_deferred("_run_seeds_qa")
	elif not performance_qa_dir.is_empty(): _open_title(); call_deferred("_run_performance_qa")
	elif not updates_qa_dir.is_empty(): _open_title(); call_deferred("_run_updates_qa")
	elif not context_qa_dir.is_empty(): _open_title(); call_deferred("_run_context_qa")
	elif not input_qa_dir.is_empty(): _open_title(); call_deferred("_run_input_qa")
	elif not interface_qa_dir.is_empty(): _open_title(); call_deferred("_run_interface_qa")
	elif not journey_qa_dir.is_empty(): call_deferred("_run_journey_qa")
	elif not roster_qa_dir.is_empty(): call_deferred("_run_roster_qa")
	elif not scale_qa_dir.is_empty(): call_deferred("_run_scale_qa")
	elif qa_running: call_deferred("_run_campaign_qa")
	else: _open_title()

func _run_attack_qa() -> void:
	await load("res://ui/qa_attack_effects.gd").new().run(self,attack_qa_dir)

func _run_adventure_qa() -> void:
	await load("res://ui/qa_adventure.gd").new().run(self,adventure_qa_dir)

func _run_spatial_qa() -> void:
	await load("res://ui/qa_spatial.gd").new().run(self,spatial_qa_dir)

func _run_economy_qa() -> void:
	await load("res://ui/qa_economy.gd").new().run(self,economy_qa_dir)

func _run_moves_qa() -> void:
	await load("res://ui/qa_moves.gd").new().run(self,moves_qa_dir)

func _run_performance_qa() -> void:
	var script: String = "res://ui/qa_fluency.gd" if "--performance-current" in OS.get_cmdline_user_args() else "res://ui/qa_performance.gd"
	await load(script).new().run(self,performance_qa_dir)

func _run_seeds_qa() -> void:
	await load("res://ui/qa_seeds.gd").new().run(self,seeds_qa_dir)

func _generate_seed() -> String:
	# Independent OS randomness: never advances an existing campaign's PRNG.
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(8)
	if bytes.size()==8: return "kanto-"+bytes.hex_encode()
	return "kanto-%d-%d" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]

func _randomize_seed() -> void:
	if not run.is_empty(): return
	new_seed = _generate_seed()
	if is_instance_valid(journey_seed): journey_seed.text = new_seed; _update_seed_hint()

func _copy_seed() -> void:
	var value: String = run.seed if not run.is_empty() else (journey_seed.text.strip_edges() if is_instance_valid(journey_seed) else new_seed.strip_edges())
	if value.is_empty():
		_randomize_seed()
		value = new_seed
	DisplayServer.clipboard_set(value)
	if travel_buttons.has("copy_seed"): travel_buttons.copy_seed.text = "Copiada"

func _open_title() -> void:
	if practice.active: practice.leave(self); return
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
	_open_presentation()
	options_dialog = presentation_dialog
	options_buttons["Sonidos"] = presentation_dialog.widgets.muted
	options_buttons["Animaciones"] = presentation_dialog.widgets.reducedMotion

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and run.is_empty() and not title_visible and seed_options_open and input_profile.matches(event,"cancel") and not _modal_open():
		_toggle_seed_options(); get_viewport().set_input_as_handled(); return
	super._input(event)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and adventure.input(self,event): get_viewport().set_input_as_handled(); return
	if event is InputEventKey and event.pressed and not event.echo:
		if input_profile.matches(event,"practice") and not super._modal_open() and not campaign_confirm.visible:
			_start_practice(); get_viewport().set_input_as_handled(); return
		if input_profile.matches(event,"glossary") and not super._modal_open() and not campaign_confirm.visible:
			_glossary(); get_viewport().set_input_as_handled(); return
		if input_profile.matches(event,"controls") and not super._modal_open() and not campaign_confirm.visible and (options_dialog==null or not options_dialog.visible):
			_open_controls(); get_viewport().set_input_as_handled(); return
		if title_visible:
			if input_profile.matches(event,"cancel") and not run.is_empty() and not help_dialog.visible and not credits_dialog.visible and not campaign_confirm.visible and (options_dialog==null or not options_dialog.visible) and not controls_dialog.visible: _resume_title(); get_viewport().set_input_as_handled()
			return
		if run.is_empty() and input_profile.matches(event,"cancel") and not _modal_open(): _open_title(); get_viewport().set_input_as_handled(); return
	super._unhandled_key_input(event)

func _run_input_qa() -> void:
	await get_tree().process_frame
	await load("res://ui/qa_input.gd").new().run(self,input_qa_dir)

func _run_updates_qa() -> void:
	await get_tree().process_frame
	await load("res://ui/qa_updates.gd").new().run(self,updates_qa_dir)

func _run_context_qa() -> void:
	await get_tree().process_frame
	await load("res://ui/qa_context.gd").new().run(self,context_qa_dir)

func _run_interface_qa() -> void:
	await get_tree().process_frame
	await load("res://ui/qa_interface.gd").new().run(self,interface_qa_dir)

func _show_oak() -> void:
	if not run.is_empty(): oak_return = {"run":run,"campaign":campaign,"transactions":transactions}
	journey_seed = null
	new_seed = _generate_seed()
	seed_options_open = false
	title_visible = false
	combat_feedback.clear()
	run = {}
	state = {}
	transactions = []
	_refresh()

func _toggle_seed_options() -> void:
	seed_options_open = not seed_options_open
	travel_buttons.seed_panel.visible = seed_options_open
	travel_buttons.seed_options.set_pressed_no_signal(seed_options_open)
	if seed_options_open: journey_seed.grab_focus()
	else: travel_buttons.seed_options.grab_focus()

func _render_seed_options() -> void:
	var toggle: Button = _button("Opciones de partida · semilla o reto",_toggle_seed_options)
	toggle.toggle_mode = true
	toggle.set_pressed_no_signal(seed_options_open)
	toggle.theme_type_variation = "ToolButton"
	travel_content.add_child(toggle)
	travel_buttons.seed_options = toggle
	var panel: VBoxContainer = VBoxContainer.new()
	panel.visible = seed_options_open
	travel_content.add_child(panel)
	travel_buttons.seed_panel = panel
	panel.add_child(_label("Semilla o código de reto.",16,MUTED))
	var seed_row: HBoxContainer = HBoxContainer.new()
	panel.add_child(seed_row)
	if new_seed.strip_edges().is_empty(): new_seed = _generate_seed()
	journey_seed = LineEdit.new()
	journey_seed.text = new_seed
	journey_seed.max_length = 1024
	journey_seed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journey_seed.placeholder_text = "Semilla o código de reto"
	journey_seed.accessibility_name = "Semilla o código de reto; opcional"
	journey_seed.tooltip_text = "Misma semilla y mismas decisiones: mismo azar. Un reto también fija el inicial y el tamaño del mapa."
	journey_seed.text_changed.connect(func(value: String):
		new_seed = value
		travel_buttons.copy_seed.text = "Copiar"
		_update_seed_hint())
	seed_row.add_child(journey_seed)
	travel_buttons.seed = journey_seed
	travel_buttons.random_seed = _button("Generar otra",_randomize_seed)
	seed_row.add_child(travel_buttons.random_seed)
	travel_buttons.copy_seed = _button("Copiar",_copy_seed)
	seed_row.add_child(travel_buttons.copy_seed)
	var hint_label: Label = _label("",16,MUTED)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(hint_label)
	travel_buttons.seed_hint = hint_label
	_update_seed_hint()

func _update_seed_hint() -> void:
	var value: String = journey_seed.text.strip_edges()
	var text: String = "Una semilla admite hasta 64 caracteres."
	if value.begins_with("KT") and ":" in value:
		var challenge: Dictionary = preload("res://core/climate_challenge.gd").decode(value)
		text = "Código incompleto o incompatible. Comprueba que lo has pegado entero." if challenge.is_empty() else "Reto con %s · mapa %d×%d. Al comenzar se usará este inicial." % [rules.profiles[int(challenge.starter)].data.name,challenge.mapSize,challenge.mapSize]
	travel_buttons.seed_hint.text = text

func _run_player_qa() -> void:
	await load("res://ui/qa_player.gd").new().run(self,player_qa_dir)

func _run_trainer_qa() -> void:
	await load("res://ui/qa_trainer.gd").new().run(self,trainer_qa_dir)

func _run_shop_qa() -> void:
	await load("res://ui/qa_kecleon.gd").new().run(self,shop_qa_dir)

func _run_variety_qa() -> void:
	await load("res://ui/qa_variety.gd").new().run(self,variety_qa_dir)

func _run_kanto_qa() -> void:
	await load("res://ui/qa_kanto.gd").new().run(self,kanto_qa_dir)

func _run_climate_qa() -> void:
	await load("res://ui/qa_climate.gd").new().run(self,climate_qa_dir)

func _run_symbols_qa() -> void:
	await load("res://ui/qa_symbols.gd").new().run(self,symbols_qa_dir)

func _run_sleep_qa() -> void:
	await load("res://ui/qa_sleep.gd").new().run(self,sleep_qa_dir)

func _run_power_qa() -> void:
	await load("res://ui/qa_power.gd").new().run(self,power_qa_dir)

func _run_copy_qa() -> void:
	await load("res://ui/qa_copy.gd").new().run(self,copy_qa_dir)

func _choose_starter(identity: int) -> void:
	var challenge: Dictionary = {}
	var requested_seed: String = journey_seed.text.strip_edges()
	if requested_seed.begins_with("KT") and ":" in requested_seed:
		challenge = load("res://core/climate_challenge.gd").decode(requested_seed)
		if challenge.is_empty(): _review_text("Código de reto no válido","Comprueba que has pegado el código completo. Este reto debe ser compatible con la aventura actual. Tu partida guardada se conserva."); return
		requested_seed = challenge.seed; identity = int(challenge.starter)
	elif requested_seed.length()>64:
		_review_text("Semilla demasiado larga","Usa hasta 64 caracteres o pega un código de reto completo. Tu partida guardada se conserva."); return
	if requested_seed.is_empty(): requested_seed = _generate_seed()
	var preserved: Dictionary = store.preserve_before_new()
	if not preserved.ok:
		message = preserved.reason
		_refresh()
		return
	new_seed = requested_seed
	journey_seed.text = new_seed
	campaign = Advanced.new() if campaign_qa_dir.is_empty() else load("res://core/traits_run.gd").new()
	if not scale_qa_dir.is_empty(): campaign = load("res://core/scale_run.gd").new()
	if campaign_qa_dir.is_empty() and scale_qa_dir.is_empty() and roster_qa_dir.is_empty(): campaign = Journey.new(int(challenge.edition)+4 if not challenge.is_empty() else 24 if "--compat-economy" in OS.get_cmdline_user_args() else 25 if "--compat-adventure" in OS.get_cmdline_user_args() else 26 if "--compat-kanto" in OS.get_cmdline_user_args() else 27 if "--compat-power" in OS.get_cmdline_user_args() else 28 if "--compat-sleep" in OS.get_cmdline_user_args() else CURRENT_CHAPTER)
	rules = campaign.engine
	run = campaign.create(new_seed,identity)
	trainer.begin_new(self)
	oak_return = {}
	_prepare_campaign_assets()
	transactions = []
	if not challenge.is_empty() and int(challenge.mapSize)!=int(run.mapSize):
		var command: Dictionary = {"kind":"map-size","size":int(challenge.mapSize),"at":run.revision}
		var resized_run: Dictionary = campaign.transact(run,command)
		if resized_run.ok: run = resized_run.state; transactions.append(command)
	selected_member = 1
	roster_tab = "team"
	roster_offset = 0
	roster_swap = 1
	message = ""
	_save()
	_refresh()

func _menu_selected(identity: int) -> void:
	if practice.active and identity in [0,1,7]: hint.text = practice.instruction(self); return
	match identity:
		0: campaign_confirm.popup_centered()
		7: get_tree().change_scene_to_file("res://scenes/laboratory.tscn")
		8: _open_title()
		13: _start_practice()
		14: _glossary()
		15: _copy_seed()
		16: trainer.open(self)
		_: super._menu_selected(identity)

func _modal_open() -> bool:
	if trainer.dialog!=null and trainer.dialog.visible: return true
	if action_review!=null and action_review.visible: return true
	if batch_busy or (shop_batch!=null and shop_batch.visible): return true
	return title_visible or super._modal_open() or (campaign_confirm != null and campaign_confirm.visible) or (options_dialog!=null and options_dialog.visible)

func _player_turn() -> bool:
	return not run.is_empty() and run.phase == "battle" and not run.battle.get("deployment",false) and super._player_turn()

func _save() -> void:
	if run.is_empty(): return
	var result: Dictionary = store.save(run,transactions,"kanto-14")
	save_warning = "" if result.ok else result.reason
	if result.ok: trainer.sync(self)

func _load_game() -> void:
	if practice.active: hint.text = "Sal de la práctica para recuperar tu aventura."; return
	var started: int = Time.get_ticks_msec()
	var result: Dictionary = store.load_campaign(campaign)
	last_load_msec = Time.get_ticks_msec()-started
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
	trainer.signature = ""
	trainer.sync(self)
	save_warning = ""
	message = "Campaña recuperada." if run.get("edition",1) >= 12 else "Partida clásica %s: conserva sus reglas. Nueva campaña para usar el PC." % _classic_version()
	pending = {}
	selecting = "auto"
	action_page = false
	selected_action = "basic"
	ai_clock = 0
	if run.edition==23 and "--compat-power" not in OS.get_cmdline_user_args():
		_upgrade_campaign(28)
		return
	_refresh()

func _event(command: Dictionary, from_batch: bool = false) -> void:
	if batch_busy and not from_batch: return
	if _modal_open() and not (from_batch and batch_busy): return
	if not practice.allowed(self,command): message = practice.instruction(self); hint.text = message; return
	var previous: Dictionary = run
	var result: Dictionary = campaign.transact(run,command)
	if not result.ok:
		practice.observe(self,"blocked",command)
		message = result.reason
		accessible_view.announce("Orden no aceptada: "+message)
		if _player_turn(): hint.text = practice.instruction(self)+"\n"+message if practice.active else message
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
	if command.kind=="buy" and _simple_hub() and campaign.consumables.has(command.item): message = "Compra completada: "+campaign.consumables[command.item].name+"."
	if command.kind=="revive": message = "Pokémon recuperado con el 50 % de sus PS máximos."
	if command.kind=="mint": message = "Menta aplicada."
	if command.kind=="capsule": message = "Habilidad cambiada."
	if command.kind=="capture" and run.get("edition",1)>=12:
		message = "Captura enviada al PC: el equipo tiene seis plazas." if run.reserve.any(func(m):return m.id==run.nextId-1) else "Nuevo compañero en el equipo."
	if command.kind=="deposit": message = "Guardado en el PC."
	if command.kind=="withdraw": message = "Añadido al equipo."
	if command.kind=="swap":
		selected_member = int(command.reserve)
		roster_tab = "team"
		roster_offset = 0
		message = "Intercambio completado."
	state = run.battle
	if command.kind=="enter": _prepare_campaign_assets()
	history = run.battleCommands
	selecting = "finish" if _player_turn() and state.moved and state.acted else "auto"
	trainer.prepare(self,previous,command,result)
	_save()
	_refresh()
	adventure.present(self,command,previous)
	kecleon.present(self,command)
	practice.observe(self,"accepted",command)
	if command.kind in ["level-up","train-xp","evolve-free"]: _play("level-up")
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

func _upgrade_campaign(target_chapter: int = CURRENT_CHAPTER) -> void:
	var replacement: RefCounted = Journey.new(target_chapter)
	var command: Dictionary = {"kind":"upgrade","edition":target_chapter-4,"at":run.revision}
	var result: Dictionary = replacement.transact(run,command)
	if not result.ok: message = result.reason; _refresh(); return
	var backup: Dictionary = store.preserve_before_new()
	if not backup.ok: message = backup.reason; _refresh(); return
	campaign = replacement
	rules = campaign.engine
	run = result.state
	transactions.append(command)
	_prepare_campaign_assets()
	message = "Progresión actualizada; niveles y PS conservados. Objetos retirados: +%d ₽ devueltos. Copia anterior guardada." % run.get("economyRefund",0) if run.edition>=20 else ("Versión actualizada. Final, equipo y diario conservados; copia anterior guardada." if run.phase=="ending" else "Aventura ampliada. Equipo, objetos, PS y diario conservados; copia de la partida anterior guardada.")
	if run.edition>=23: message = "PP de equipamiento activados. Revisa las ranuras; todos los movimientos aprendidos se conservan. Copia anterior guardada."
	if run.edition>=24: message = "Corrección del sueño aplicada. Progreso y combate conservados; copia anterior guardada."
	if run.edition>=25: message = "Climas y habilidades activados. Equipo y progreso conservados; copia anterior guardada."
	_save()
	_refresh()

func _commit(command: Dictionary) -> void:
	var before: Dictionary = state
	var revision: int = run.revision
	var plan: Dictionary = _command_plan(state,command)
	var definition: Dictionary = _attack_definition(before,command)
	_event({"kind":"battle","order":command,"at":revision})
	if run.revision == revision: return
	_remember_result(before,command,last_presentation.get("hits",[]))
	var leveled: bool = run.get("lastProgress",[]).any(func(entry):return entry.level > entry.before)
	_present_combat(before,command,plan,last_presentation.get("hits",[]),last_presentation.get("visualDefinition",definition),("level-up" if leveled else "victory") if state.outcome=="victory" else "")
	if state.get("combatEdition",0)>=19 and command.get("kind")=="attack":
		for event: Dictionary in state.get("tacticalEvents",[]):
			combat_feedback.marks.append({"point":{"x":event.x,"y":event.y},"kind":"terrain","text":event.text,"color":Color("b3e0bb"),"offset":24})
		combat_feedback.queue_redraw()
	if not last_presentation.get("abilityEvents",[]).is_empty(): combat_feedback.present_abilities(state,last_presentation.abilityEvents,command.kind!="attack")

func _rectify_movement() -> void:
	if not pending.is_empty() or not _player_turn(): return
	_event({"kind":"rectify","at":run.revision})

func _refresh() -> void:
	if title_screen!=null:
		title_screen.visible = title_visible
		if title_visible:
			adventure.refresh(self)
			board.hide()
			battle_overlay.hide()
			travel_root.hide()
			travel_art.hide()
			title_screen.refresh()
			trainer.update_title(self)
			accessible_view.request_update(true)
			return
	if travel_root == null:
		super._refresh()
		if timeline.get_parent() is ScrollContainer: timeline.get_parent().scroll_horizontal = 0
		return
	if camera_bar!=null: camera_bar.visible = not run.is_empty() and run.phase=="battle" and run.get("edition",1)>=11
	if camera_pad!=null: camera_pad.visible = camera_bar.visible
	if camera_compass!=null: camera_compass.visible = camera_bar.visible
	var fighting: bool = not run.is_empty() and run.phase == "battle"
	board.visible = fighting
	battle_overlay.visible = fighting
	travel_root.visible = not fighting
	travel_art.visible = not fighting
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
			actor_info.tooltip_text = "Básico neutro · 0 PT"
			if active.has("abilityDescription"): actor_info.tooltip_text += "\n"+active.natureText+"\n"+active.abilityDescription
		if run.get("edition",1)>=11:
			board.track_turn()
			actor_info.tooltip_text += "\nAltura %d · subir cuesta +1; salto terrestre máximo 1." % rules.Terrain.height_at(state,active)
			for direction: int in direction_buttons: direction_buttons[direction].text = {4:"↗",2:"↘",0:"↙",6:"↖"}[direction]
		else:
			for direction: int in direction_buttons: direction_buttons[direction].text = {4:"↑",2:"→",0:"↓",6:"←"}[direction]
		_layout_battle_hud()
		if practice.active:
			heading.text = "PRÁCTICA AISLADA · ninguna orden se guarda en tu aventura"
			hint.text = practice.instruction(self)
			if practice.step==9: buttons.undo.disabled = false; buttons.undo.text = input_profile.shortcut("Explicar bloqueo","rectify")
		actor_title.text = "%s · Nv. %d" % [active.name,active.get("level",1)]
		actor_title.tooltip_text = "Turno rival" if active.team=="enemy" else "Tu equipo · unidad en turno"
		actor_info.text = "%d / %d PS\n%d / %d PT\n%s\n%s" % [active.hp,active.maxHp,active.tp,active.maxTp,"Mov. usado" if state.moved else "Mov. %d" % active.remaining,"Acc. usada" if state.acted else "Acc. lista"]
		actor_info.set_meta("base_color",CREAM)
		if actor_info.get_theme_color("font_color")!=CREAM: actor_info.add_theme_color_override("font_color",CREAM)
		var fraction: float = float(active.hp)/maxi(1,int(active.maxHp))
		actor_hp.get_theme_stylebox("fill").bg_color = Color("71c5a1") if fraction>0.5 else (Color("e9c76d") if fraction>0.25 else Color("ee997e"))
		for action_button: Button in action_buttons.values(): action_button.add_theme_font_size_override("font_size",16)
	else:
		_render_travel()
		_simplify_hub()
	accessible_view.request_update(true)
	adventure.refresh(self)
	if fighting and run.get("edition",0)>=25: preload("res://ui/climate_hud.gd").refresh(self)
	if state.get("combatEdition",0)>=20: preload("res://ui/power_copy.gd").refresh_battle(self)
	if adventure.enabled(self) and run.phase!="battle" and not travel_buttons.has("share_journey"):
		var share: Button = _button(input_profile.shortcut("Reto","share"),func():adventure.export_card(self))
		share.theme_type_variation = "ToolButton"
		share.tooltip_text = "Guardar tarjeta del equipo y copiar código de reto reproducible."
		travel_content.get_child(0).add_child(share)
		travel_buttons.share_journey = share

func _layout_battle_hud() -> void:
	if camera_dock!=null:
		camera_dock.offset_left = -350 if get_window().size.x<1150 or load("res://ui/presentation_settings.gd").font_factor(self)>1.2 else -310
		camera_dock.offset_right = -18
		camera_dock.offset_top = 122
		camera_dock.offset_bottom = 122
	if camera_compass!=null: camera_compass.position.x = size.x-276
	var factor: float = load("res://ui/presentation_settings.gd").font_factor(self)
	var narrow: bool = get_window().size.x<1150 or factor>1.2
	var camera_cell: float = maxf(48,ceilf(16*factor+32))
	for button: Button in camera_buttons.values(): button.custom_minimum_size.x = camera_cell
	board.minimap_right = camera_cell*3+4+18+128
	board.reserved_right = 386 if narrow else 350
	board.extra_bottom = 60 if factor>1.2 else -24
	var header: Node = heading.get_parent()
	header.get_child(0).visible = factor<=1.2
	saved.visible = factor<=1.2 or not save_warning.is_empty()
	menu.custom_minimum_size.x = 230 if factor>1.2 else 110
	if factor>1.2:
		buttons.undo.text = input_profile.shortcut("Rectificar","rectify")
		buttons.finish.text = input_profile.shortcut("Orientar","finish")
	if camera_bar!=null:
		for index: int in camera_bar.get_child_count():
			var camera_button: Button = camera_bar.get_child(index)
			var short_names: Array = ["−","+","Combate","Unidad","Mapa","Cuad.","Alt."]
			if factor>1.2: camera_button.text = short_names[index]
			var shortcut_action: String = {0:"zoom_out",1:"zoom_in",3:"center",5:"grid",6:"heights"}.get(index,"")
			camera_button.tooltip_text = input_profile.shortcut(["Alejar","Acercar","Centrar combate","Centrar unidad","Vista completa","Cuadrícula","Alturas"][index],shortcut_action) if not shortcut_action.is_empty() else ["","","Centrar combate","","Vista completa","",""][index]
			camera_button.custom_minimum_size.x = maxf(60,camera_button.text.length()*16*factor*0.6+36)
	if camera_compass!=null: camera_compass.visible = false
	command_panel.custom_minimum_size.x = 330 if narrow else 292
	var camera_height: float = 3*maxf(44,theme.default_font.get_height(roundi(16*factor))+20)+4
	var menu_overhead: float = 2*theme.default_font.get_height(roundi(18*factor))+72
	var ability_height: float = action_buttons.size()*(2*theme.default_font.get_height(roundi(16*factor))+20)+maxi(0,action_buttons.size()-1)*6
	var threat_height: float = maxf(44,theme.default_font.get_height(roundi(18*factor))+20)+12 if run.get("edition",0)>=21 else 0.0
	actions_scroll.custom_minimum_size.y = minf(ability_height,maxf(120,size.y-122-camera_height-12-menu_overhead-18-threat_height)) if action_page else 0.0
	var menu_paper: StyleBoxFlat = command_panel.get_theme_stylebox("panel")
	if not menu_paper.has_meta("field_menu"):
		menu_paper = GameSkin.panel(Color("7c9696"))
		menu_paper.bg_color = GameSkin.PAPER
		menu_paper.set_meta("field_menu",true)
		command_panel.add_theme_stylebox_override("panel",menu_paper)
	var high_contrast: bool = input_profile.preferences.highContrast
	var paper_color: Color = Color.BLACK if high_contrast else GameSkin.PAPER
	if menu_paper.bg_color!=paper_color: menu_paper.bg_color = paper_color
	var heading_color: Color = Color.WHITE if high_contrast else GameSkin.INK
	if command_heading.get_theme_color("font_color")!=heading_color: command_heading.add_theme_color_override("font_color",heading_color)
	command_heading.set_meta("base_color",GameSkin.INK)
	for button: Button in [buttons.actions,buttons.undo,buttons.finish,buttons.cancel]+action_buttons.values():
		if button.theme_type_variation!="FieldCommandButton": button.theme_type_variation = "FieldCommandButton"
	var actor_width: float = 330 if narrow else 380
	var target_width: float = 390
	var actor_panel: Control = actor_portrait.get_parent().get_parent().get_parent()
	actor_panel.offset_right = 18+actor_width
	actor_panel.offset_top = -250 if factor>1.2 else -196
	if factor>1.2:
		actor_info.text = actor_info.text.replace("\n"+rules.active(state).get("abilityName",""),"") if not state.is_empty() else actor_info.text
	actor_portrait.custom_minimum_size = Vector2(56,56) if narrow else Vector2(80,80)
	actor_info.add_theme_font_size_override("font_size",16 if narrow else 18)
	target_panel.offset_left = -18-target_width
	target_panel.offset_top = -250 if factor>1.2 else -196
	target_portrait.custom_minimum_size = Vector2(40,40) if narrow else Vector2(80,80)
	target_info.custom_minimum_size.x = 200 if narrow else 250
	target_info.add_theme_font_size_override("font_size",15 if narrow else 17)
	var middle_left: float = 30+actor_width
	var middle_right: float = size.x-30-target_width
	var middle: float = (middle_left+middle_right)/2
	var width: float = minf(390,middle_right-middle_left)
	hint.get_parent().offset_left = middle-size.x/2-width/2
	hint.get_parent().offset_right = middle-size.x/2+width/2
	hint.get_parent().offset_top = -250 if factor>1.2 else -196
	# Three information regions share one battle dock, without separate boxes.
	for panel: PanelContainer in [actor_panel,hint.get_parent(),target_panel]:
		if not panel.has_meta("battle_dock"):
			var clear: StyleBoxFlat = StyleBoxFlat.new()
			clear.bg_color = Color(0,0,0,0)
			clear.set_content_margin_all(12)
			panel.add_theme_stylebox_override("panel",clear)
			panel.set_meta("battle_dock",true)
	battle_chrome.configure(board.play_area(),280 if factor>1.2 else 204,high_contrast)
	board.queue_redraw()

func _show_plan(unit: Dictionary, plan: Dictionary) -> void:
	super._show_plan(unit,plan)
	if plan.ok and plan.has("heightDifference"): target_info.text += "\nDesnivel del objetivo: %+d · sin bonificación de daño." % plan.heightDifference

func _hover_tile(point: Dictionary) -> bool:
	if not super._hover_tile(point): return false
	if input_profile.preferences.accessibleMode: accessible_view.request_update()
	if practice.active:
		if not point.is_empty() and not state.is_empty() and not Movement.same(rules.active(state),point): practice.observe(self,"cursor")
		hint.text = practice.instruction(self)
	if not point.is_empty() and state.get("combatEdition",0)>=11 and not _modal_open(): hint.text += "\nAltura %d · rueda: zoom · botón central: cámara." % rules.Terrain.height_at(state,point)
	adventure.hover(self,point)
	if not point.is_empty() and preload("res://core/restorative_tiles.gd").contains(state,point): hint.text += "\nManantial: cura estados al terminar aquí; no recupera PS."
	return true

func _select_tile(point: Dictionary) -> void:
	if adventure.select(self,point): return
	super._select_tile(point)

func _travel_button(key: String, text: String, parent: Node, command: Dictionary) -> Button:
	command.at = run.revision
	var button: Button = _button(text,_travel_command.bind(command))
	if command.kind in ["enter","continue","capture","final-path"]: button.theme_type_variation = "PrimaryButton"
	travel_buttons[key] = button
	parent.add_child(button)
	return button

func _simple_hub() -> bool:
	return not run.is_empty() and run.get("edition",1)>=12

func _art_banner(parent: VBoxContainer, identity: String) -> void:
	var local_scene: bool = run.get("edition",0)>=22 and run.phase=="map"
	var banner: Control = load("res://ui/kanto_vignette.gd" if local_scene else "res://ui/artwork_slot.gd").new()
	if local_scene: banner.location = campaign.locations[int(run.stage)].id; banner.clip_contents = true
	banner.custom_minimum_size.y = 108
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(banner)
	banner.configure(identity)
	hub_parts.art_banner = banner

func _scene_art() -> String:
	if run.is_empty(): return "scene_oak"
	if hub_mode=="team" and roster_tab=="pc": return "scene_pc"
	if run.phase=="ending": return "scene_ending_birds" if run.finalPath=="birds" else "scene_ending_origin"
	return {"shop":"scene_shop","capture":"scene_capture","defeat":"scene_defeat"}.get(run.phase,"scene_travel")

func _item_picture(button: Button, identity: String) -> void:
	button.icon = Art.item_icon(identity)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width",24)

func _art_symbol(identity: String) -> TextureRect:
	var symbol: TextureRect = _portrait(Vector2(24,24))
	symbol.texture = Art.icon(identity)
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return symbol

func _build_hub_navigation() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	travel_content.add_child(row)
	for entry: Array in [["overview","Comprar" if run.phase=="shop" else "Viaje"],["team","Equipo y bolsa" if run.phase=="shop" else "Equipo / PC"]]:
		var button: Button = _button(entry[1],_set_hub_mode.bind(entry[0]))
		button.theme_type_variation = "TabButton"
		button.toggle_mode = true
		button.button_pressed = hub_mode==entry[0]
		row.add_child(button)
		travel_buttons["hub_"+entry[0]] = button
	var limit: Dictionary = campaign.gym_limit(run)
	row.add_child(_art_symbol("badge"))
	var progress: Label = _label("%d medallas · Límite Nv. %d" % [run.get("medals",[]).size(),limit.level],16,MUTED)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(progress)
	if run.phase in ["capture","shop"] and not _progress_summary().is_empty():
		var summary: Button = _button("Resumen",func(): _review_text("Último combate",_progress_summary()))
		summary.theme_type_variation = "ToolButton"
		row.add_child(summary)
		travel_buttons.summary = summary
	if run.phase=="map" and run.cleared.is_empty():
		var sizes: HBoxContainer = HBoxContainer.new()
		travel_content.add_child(sizes)
		sizes.add_child(_label("Tamaño del mapa",16,MUTED))
		for width: int in [16,24]:
			var pick: Button = _travel_button("size_"+str(width),"%d×%d" % [width,width],sizes,{"kind":"map-size","size":width})
			pick.theme_type_variation = "ToolButton"
			pick.disabled = run.mapSize==width

func _set_hub_mode(value: String) -> void:
	hub_mode = value
	if value=="overview": roster_tab = "team"; roster_offset = 0
	_refresh()
	call_deferred("_focus_travel_button","hub_"+value)

func _build_member_navigation(parent: VBoxContainer) -> void:
	var tabs: GridContainer = GridContainer.new()
	tabs.columns = 2 if load("res://ui/presentation_settings.gd").font_factor(self)>1.25 else 4
	tabs.add_theme_constant_override("h_separation",6)
	tabs.add_theme_constant_override("v_separation",6)
	parent.add_child(tabs)
	for entry: Array in [["profile","Ficha"],["items","Objetos"],["moves","Movimientos"],["traits","Rasgos"]]:
		var button: Button = _button(entry[1],_set_member_view.bind(entry[0]))
		button.theme_type_variation = "TabButton"
		button.toggle_mode = true
		button.button_pressed = member_view==entry[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",16)
		tabs.add_child(button)
		travel_buttons["detail_"+entry[0]] = button

func _set_member_view(value: String) -> void:
	member_view = value
	_refresh()
	call_deferred("_focus_travel_button","detail_"+value)

func _hub_group(parent: VBoxContainer, key: String) -> VBoxContainer:
	var group: VBoxContainer = VBoxContainer.new()
	group.add_theme_constant_override("separation",12)
	parent.add_child(group)
	hub_parts[key] = group
	return group

func _simplify_hub() -> void:
	if kecleon.using_scene(self): _apply_preferences.call_deferred(); return
	if not _simple_hub(): return
	var managing: bool = hub_mode=="team"
	travel_buttons.hub_overview.button_pressed = not managing
	travel_buttons.hub_team.button_pressed = managing
	hub_parts.shop.visible = not managing
	hub_parts.team.visible = managing or run.phase!="shop"
	for key: String in ["details","roster_tabs","roster_manage"]:
		if hub_parts.has(key): hub_parts[key].visible = managing
	for key: String in ["profile","items","moves","traits"]:
		if hub_parts.has(key): hub_parts[key].visible = key==member_view
	var owned: bool = false
	for key: String in travel_buttons:
		var item: String = ""
		if key.begins_with("heal_"): item = key.trim_prefix("heal_")
		elif key=="revive": item = "revive"
		elif key=="level-up": item = "rare-candy"
		elif key=="use_capsule": item = "ability-capsule"
		elif key.begins_with("evolution_"):
			# Compatibility and stock are already validated by the existing control.
			travel_buttons[key].visible = not travel_buttons[key].disabled
		if not item.is_empty():
			travel_buttons[key].visible = run.bag.get(item,0)>0
			if item in ["potion","super-potion","hyper-potion","max-potion","rare-candy","revive"]: owned = owned or travel_buttons[key].visible
	if hub_parts.has("items") and run.phase=="shop" and not owned and not run.bag.values().any(func(count):return int(count)>0) and not hub_parts.has("empty_bag"):
		hub_parts.empty_bag = _label("La bolsa está vacía.",17,MUTED)
		hub_parts.items.add_child(hub_parts.empty_bag)
	if travel_buttons.has("use_batch"): travel_buttons.use_batch.visible = owned
	if travel_buttons.has("batch"): travel_buttons.batch.visible = shop_tab in (["supplies"] if run.get("edition",1)>=20 else ["supplies","evolution"])
	_apply_preferences.call_deferred()

func _render_travel() -> void:
	var phase: String = run.get("phase","oak")
	var memory: Dictionary = FocusMemory.capture(travel_root,travel_buttons)
	if phase!=travel_phase:
		travel_memory = {}; travel_phase = phase
		hub_mode = "overview"
		member_view = "items" if phase=="shop" and run.get("edition",1)<20 else "profile"
		if kecleon.available(self): shop_tab = "gear"; kecleon.arrive()
	elif memory.inside: travel_memory = memory
	travel_art.configure(_scene_art(),true)
	call_deferred("_restore_travel_focus")
	if is_instance_valid(journey_seed): new_seed = journey_seed.text
	_clear(travel_content)
	hub_parts.clear()
	travel_buttons.clear()
	var header: HBoxContainer = HBoxContainer.new()
	travel_content.add_child(header)
	var title: Label = _label("ELIGE A TU COMPAÑERO" if run.is_empty() else "KANTO / TU AVENTURA",24,GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	if not run.is_empty():
		header.add_child(_art_symbol("money"))
		header.add_child(_label("%d ₽" % run.money,22,GOLD))
	var home: Button = _button("Inicio",_open_title)
	home.theme_type_variation = "ToolButton"
	header.add_child(home)
	travel_buttons.home = home
	var help_button: Button = _button("Ayuda",func(): help_dialog.popup_centered(Vector2i(630,450)))
	help_button.theme_type_variation = "ToolButton"
	header.add_child(help_button)
	if kecleon.using_scene(self):
		title.text = "Tienda Kecleon"
		kecleon.render(self,travel_content)
		return
	if _simple_hub():
		title.text = "Tienda" if run.phase=="shop" else "Viaje por Kanto"
		_build_hub_navigation()
	var classic: String = ""
	if not run.is_empty() and run.get("edition",1)<12: classic = "Esta aventura conserva sus reglas originales. Puedes continuarla o empezar una nueva con las funciones actuales."
	var status: Label = _label(save_warning if not save_warning.is_empty() else (message if not message.is_empty() else (classic if not classic.is_empty() else ("Guardado automático local · Revivir disponible en tienda" if run.get("edition",1)>=9 else "Guardado automático local · bajas definitivas"))),17,MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	travel_content.add_child(status)
	if run.is_empty():
		status.text = save_warning if not save_warning.is_empty() else message
		status.visible = not status.text.is_empty()
	if _simple_hub():
		status.text = save_warning if not save_warning.is_empty() else message
		status.visible = not status.text.is_empty()
	if not _simple_hub() and input_profile.preferences.tutorialHints and phase in ["map","shop","capture"]:
		var guide: Label = _label({"map":"Siguiente paso: revisa el equipo y entra en el encuentro. Los PS se conservan.","shop":"Objetos fuera de combate: recupera PS, compra niveles hasta el límite y revisa el PC. El PC no cura.","capture":"La recompensa pendiente debe resolverse antes de seguir. Aprender movimientos no los prepara automáticamente."}[phase],17)
		guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		travel_content.add_child(guide)
	if run.get("edition",1)>=12 and run.get("edition",1)<CURRENT_CHAPTER-4 and run.get("phase","") in ["map","shop","complete","ending"]:
		var upgrade: Button = _button("Actualizar climas y habilidades" if CURRENT_CHAPTER>=29 else "Aplicar corrección de sueño" if run.get("edition",0)==23 else "Actualizar a PP de equipamiento" if CURRENT_CHAPTER>=27 else "Actualizar Kanto · mapas y dos desafíos" if CURRENT_CHAPTER>=26 else "Actualizar versión · conservar final" if run.phase=="ending" else "Actualizar aventura táctica",_upgrade_campaign)
		upgrade.tooltip_text = "Conserva equipo, nivel, PS y progreso con una copia previa. Los objetos retirados se reembolsan. El combate pendiente conserva sus reglas."
		if CURRENT_CHAPTER>=25: upgrade.tooltip_text = "Añade mapas propios y encadena las tres aves antes de Mew y Mewtwo. Conserva victorias, equipo, PS y progreso con una copia previa. Los combates pendientes terminan con sus reglas actuales."
		if CURRENT_CHAPTER>=27: upgrade.tooltip_text = "PP al equipar, usos sin gasto y atributos durante el combate. Conserva movimientos aprendidos; los que excedan el presupuesto se desequipan en orden inverso. Copia previa automática."
		if run.get("edition",0)==23: upgrade.tooltip_text = "Impide moverse mientras duerme. Conserva combate, mapa, equipo y RNG con copia previa."
		if CURRENT_CHAPTER>=29: upgrade.tooltip_text = "Añade climas, habilidades y sexo de los Pokémon. Conserva equipo, PS, EXP, dinero y diario; copia previa. Solo entre encuentros."
		travel_content.add_child(upgrade)
		travel_buttons.upgrade = upgrade
	if not run.is_empty() and run.get("edition",1)>=8 and not _simple_hub():
		var limit: Dictionary = campaign.gym_limit(run)
		var limit_label: Label = _label("Límite Nv. %d · %s (%s). Al alcanzar el límite no se acumula EXP." % [limit.level,limit.leader,rules.profiles[int(limit.speciesId)].data.name],17,GOLD)
		limit_label.name = "GymLevelCap"
		limit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		travel_content.add_child(limit_label)
	if run.is_empty():
		travel_content.add_child(_label("Pueblo Paleta · Laboratorio de Oak",30,GOLD))
		travel_content.add_child(_label("Tu aventura empieza con un compañero de nivel 5. ¿A quién eliges?",20))
		_render_seed_options()
		var choices: HBoxContainer = HBoxContainer.new()
		choices.add_theme_constant_override("separation",16)
		choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
		travel_content.add_child(choices)
		for id: int in [1,4,7]:
			var panel: PanelContainer = _panel()
			panel.add_theme_stylebox_override("panel",GameSkin.panel({1:Color("86bd84"),4:Color("eb9670"),7:Color("8ac6db")}[id]))
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
			button.theme_type_variation = "PrimaryButton"
			content.add_child(button)
			travel_buttons["starter" + str(id)] = button
		_apply_preferences.call_deferred()
		return
	var progress: HBoxContainer = HBoxContainer.new()
	if run.get("edition",1)>=11 and run.phase=="map" and run.cleared.is_empty() and not _simple_hub():
		travel_content.add_child(_label("Ensayo de escala · %d×%d · vista isométrica y alturas" % [run.mapSize,run.mapSize],20,GOLD))
		var sizes: HBoxContainer = HBoxContainer.new()
		travel_content.add_child(sizes)
		for width: int in [16,24]:
			var pick: Button = _travel_button("size_"+str(width),"%d×%d%s" % [width,width," · recomendado" if width==16 else " · comparación"],sizes,{"kind":"map-size","size":width})
			pick.disabled = run.mapSize==width
		travel_content.add_child(_label("Subir: +1 movimiento por nivel; salto terrestre máximo 1. Voladores ignoran desniveles.\nAltura limita alcance y línea de visión; no aumenta el daño. Eliminar rivales sigue siendo el objetivo.",16,MUTED))
	travel_content.add_child(progress)
	progress.visible = not _simple_hub()
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
	hub_parts.shop = left
	var left_column: VBoxContainer = VBoxContainer.new()
	left_column.add_theme_constant_override("separation",12)
	left.add_child(left_column)
	var story_scroll: ScrollContainer = ScrollContainer.new()
	story_scroll.set_meta("scroll_id","story")
	story_scroll.follow_focus = true
	story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	story_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(story_scroll)
	var narrative: VBoxContainer = VBoxContainer.new()
	narrative.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narrative.add_theme_constant_override("separation",18)
	story_scroll.add_child(narrative)
	var footer: VBoxContainer = VBoxContainer.new()
	if _simple_hub(): travel_content.add_child(footer)
	else: left_column.add_child(footer)
	var location: Dictionary = campaign.locations[mini(int(run.stage),campaign.locations.size()-1)]
	var heading_text: String = location.name
	if run.phase == "capture": heading_text = "¡Un nuevo compañero!"
	elif run.phase == "shop": heading_text = "Tienda · prepara tu equipo"
	elif run.phase == "complete": heading_text = "Medalla Roca conseguida"
	elif run.phase == "defeat": heading_text = "El equipo ha caído"
	if run.get("edition",1)>=13 and run.phase=="complete": heading_text = "Liga y rival superados" if run.get("mainComplete",false) else "Tramo completado"
	if run.phase=="ending": heading_text = "Final · guardianes de Kanto" if run.finalPath=="birds" else "Final · el origen de Mewtwo"
	var chapter: Label = _label(heading_text,28,GOLD)
	if _simple_hub(): _art_banner(narrative,_scene_art())
	chapter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chapter.visible = not (_simple_hub() and run.phase=="shop")
	narrative.add_child(chapter)
	var text: Label = _label(location.story,20)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative.add_child(text)
	match run.phase:
		"map":
			_travel_button("enter",("Visitar " if location.get("kind","")=="story" else "Entrar en ") + location.name,footer if _simple_hub() else narrative,{"kind":"enter"})
			text.text += "\n\nVisita narrativa: abre caminos y tienda, sin captura ni curación." if location.get("kind","")=="story" else "\n\nUn combate por ubicación. Al ganar: captura local, tienda y siguiente tramo. Los PS no se restauran entre encuentros."
		"capture":
			var image: TextureRect = _portrait(Vector2(160,160))
			image.texture = faces[int(run.reward.speciesId)]
			narrative.add_child(image)
			text.text = "%s\nOrigen: %s\n\nLa captura ya está sorteada y guardada. Cargar no cambia el resultado. Se admiten duplicados en esta muestra." % [rules.profiles[int(run.reward.speciesId)].data.name + (" · Nv. %d" % run.reward.level if run.reward.has("level") else ""),run.reward.origin]
			var capture_text: String = "Dar la bienvenida al equipo"
			if run.get("edition",1)>=12 and run.party.size()>=6: capture_text = "Enviar al PC · equipo completo"
			if run.get("edition",1)>=20: load("res://ui/economy_menu.gd").capture(self,narrative)
			_travel_button("capture",capture_text,footer if _simple_hub() else narrative,{"kind":"capture"})
		"shop":
			if run.get("edition",1)>=4:
				var batch: Button = _button("Comprar varias…",_open_batch)
				batch.theme_type_variation = "ToolButton"
				narrative.add_child(batch)
				travel_buttons.batch = batch
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
				stock_grid.columns = 3 if _simple_hub() and load("res://ui/presentation_settings.gd").font_factor(self)<=1.25 else 2
				stock_grid.add_theme_constant_override("h_separation",8)
				stock_grid.add_theme_constant_override("v_separation",8)
				shop_parent.add_child(stock_grid)
				shop_parent = stock_grid
			if run.get("edition",1)>=20: load("res://ui/economy_menu.gd").shop(self,shop_sections.evolution)
			for item: String in consumables:
				var destination: Node = shop_sections.traits if item=="ability-capsule" and run.get("edition",1)>=12 else shop_parent
				if _simple_hub() and (item=="rare-candy" or (run.get("edition",1)>=13 and campaign.evolution_items.has(item))): destination = shop_sections.evolution
				var label: String = "%s\n%d ₽ · tienes %d" % [consumables[item].name,consumables[item].price,run.bag.get(item,0)] if run.get("edition",1)>=12 else "Comprar %s · %d ₽" % [consumables[item].name,consumables[item].price]
				var button: Button = _travel_button("buy_"+item,label,destination,{"kind":"buy","item":item})
				if _simple_hub(): _item_picture(button,item)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				if run.get("edition",1)>=12: button.add_theme_font_size_override("font_size",16)
				button.disabled = run.money < consumables[item].price
				if item=="revive": button.tooltip_text = "Recupera a un Pokémon debilitado con el 50 % de sus PS máximos. Solo en la tienda; consume una unidad de la bolsa."
			if run.get("edition",1)>=10: _render_mint_shop(shop_sections.get("traits",narrative))
			if run.get("edition",1)>=5 and run.get("edition",1)<13:
				var stone: Button = _travel_button("buy_leaf-stone","Comprar Piedra Hoja · 80 ₽",shop_sections.evolution if _simple_hub() else narrative,{"kind":"buy-stone"})
				stone.disabled = run.money<80
				stone.tooltip_text = "Evoluciona Gloom y Weepinbell. No cura ni sube niveles."
			_travel_button("continue","Seguir viaje" if run.get("edition",1)>=13 or run.stage < 3 else "Cerrar el tramo",footer,{"kind":"continue"})
		"complete": text.text = "Has conseguido la Medalla Roca. Conservas tu equipo, dinero y objetos.\n\nHas completado el recorrido disponible en esta aventura. Puedes consultar tu equipo o comenzar una nueva."
		"defeat": text.text = ("Todo el equipo se ha debilitado. La campaña ha terminado; Revivir solo se puede usar en la tienda, si llegas con algún compañero en pie." if run.get("edition",1)>=9 else "Las bajas son definitivas. Esta campaña ha terminado y queda guardada para consultar el equipo.") + "\n\nPuedes comenzar de nuevo con otro inicial o semilla."
	if run.get("edition",1)>=12:
		if run.phase in ["map","shop"]: text.text += "\n\nGestiona Equipo y PC a la derecha. Cambiar compañeros es gratis y conserva sus PS; solo los desplegados ganan EXP."
		elif run.phase=="defeat": text.text += "\nLas reservas del PC tampoco permiten continuar tras perder un combate."
	if _simple_hub():
		if run.phase=="shop": text.text = ""
		elif run.phase=="map": text.text = Copy.destination(location)
		elif run.phase=="capture": text.text = "%s · Nv. %d\n%s" % [rules.profiles[int(run.reward.speciesId)].data.name,run.reward.level,run.reward.origin]
		elif run.phase=="defeat": text.text = "Fuji ha caído. Fin de la aventura." if run.get("battle",{}).get("mission",{}).get("kind")=="protect" and run.battle.mission.health<=0 else "Fin de la aventura. Las reservas no permiten continuar."
		text.visible = not text.text.is_empty()
	if run.get("edition",1)>=13:
		if run.phase=="complete": text.text = "Quedan desvíos por explorar." if not campaign.available(run).is_empty() else "Tramo completado."
		if run.phase in ["map","complete"]: _render_destinations(narrative)
		if run.phase=="complete" and run.mainComplete and run.chapter>=21 and run.finalPath=="" and run.get("edition",1)<22:
			text.text = "Has vencido al Alto Mando y al rival. Elige un único desafío final; las dos rutas son excluyentes y no conceden capturas legendarias."
			for path: String in ["birds","psychic"]: _travel_button("destiny_"+path,"Articuno, Zapdos y Moltres" if path=="birds" else "Mew y Mewtwo",narrative,{"kind":"destiny","path":path})
		if run.phase=="ending": text.text = "¡Aventura completada!"
		if run.get("edition",0)>=22 and run.get("mainComplete",false):
			text.text = "Siguiente: Mew y Mewtwo." if "legendary-birds" in run.cleared else "Siguiente: Articuno, Zapdos y Moltres."
			if run.phase=="ending": text.text = "¡Aventura completada!"
			text.visible = true
	if run.get("edition",1) >= 2 and run.phase in ["capture","shop"]:
		var summary: Label = _label(_progress_summary(),17,GOLD)
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		narrative.add_child(summary)
		if _simple_hub(): summary.hide()
	var right: PanelContainer = _panel()
	right.custom_minimum_size.x = 360 if _simple_hub() else 470
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub_parts.team = right
	body.add_child(right)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_meta("scroll_id","team")
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var team_row: HBoxContainer = HBoxContainer.new()
	team_row.add_theme_constant_override("separation",24)
	right.add_child(team_row)
	team_row.add_child(scroll)
	var team: VBoxContainer = VBoxContainer.new()
	team.custom_minimum_size.x = 320 if _simple_hub() else 430
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
	if _simple_hub():
		hub_parts.roster = team
		var detail_scroll: ScrollContainer = ScrollContainer.new()
		detail_scroll.set_meta("scroll_id","member_details")
		detail_scroll.follow_focus = true
		detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		team_row.add_child(detail_scroll)
		hub_parts.details = detail_scroll
		team = VBoxContainer.new()
		team.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		team.add_theme_constant_override("separation",12)
		detail_scroll.add_child(team)
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
	var identity: VBoxContainer = VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_row.add_child(identity); identity.add_child(info)
	preload("res://ui/move_symbols.gd").type_badges(identity,unit.types)
	if selected.has("gender"): identity.add_child(_label("Sexo: "+preload("res://core/climate_context.gd").gender_symbol(selected),16,MUTED))
	if _simple_hub():
		info.text = "%s · Nv. %d\n%d / %d PS" % [unit.name,selected.level,unit.hp,unit.maxHp]
		_build_member_navigation(team)
		var profile: VBoxContainer = _hub_group(team,"profile")
		profile.add_child(_label("Ataque %d · At. especial %d\nDefensa %d · Def. especial %d\nVelocidad %d" % [unit.attack,unit.specialAttack,unit.defense,unit.specialDefense,unit.speed],17))
		profile.add_child(_label("EXP %d / %d" % [selected.xp,load("res://ui/economy_menu.gd").needed(self,selected)],17))
		if run.get("edition",1)>=20:
			if run.phase=="shop": load("res://ui/economy_menu.gd").training(self,profile,selected)
			load("res://ui/economy_menu.gd").evolutions(self,profile,selected)
		var next_form: Dictionary = campaign.progression.evolution(selected)
		if not next_form.is_empty(): profile.add_child(_label("%s · Nv. %d" % [rules.profiles[int(next_form.speciesId)].data.name,next_form.level],17,GOLD))
		profile.add_child(_label("Origen: "+selected.origin,16,MUTED))
	var modern_shop: bool = run.get("edition",1)>=12 and run.phase=="shop"
	if run.get("edition",1)>=10 and not modern_shop: _render_traits(_hub_group(team,"traits") if _simple_hub() else team,selected)
	if run.get("edition",1)>=3 and not modern_shop: _render_inventory(_hub_group(team,"items") if _simple_hub() else team,selected)
	if run.get("edition",1) >= 2 and run.phase != "shop":
		_render_moves(_hub_group(team,"moves") if _simple_hub() else team,selected)
	if run.phase == "shop":
		var detail_root: VBoxContainer = team
		if _simple_hub(): team = _hub_group(detail_root,"items")
		var use_parent: Node = team
		if modern_shop:
			team.add_child(_label("Bolsa",19,GOLD))
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
			if modern_shop: heal_text = "Usar %s\nTienes %d" % [record.name,run.bag[item]]
			var button: Button = _travel_button("heal_"+item,heal_text,use_parent,{"kind":"heal","item":item,"member":selected_member})
			if _simple_hub(): _item_picture(button,item)
			button.tooltip_text = "Recupera %d PS, hasta el máximo. Solo fuera de combate." % record.heal if item!="max-potion" else "Recupera todos los PS actuales; no revive."
			if modern_shop: button.add_theme_font_size_override("font_size",16); button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.disabled = selected.hp <= 0 or selected.hp >= unit.maxHp or run.bag[item] <= 0
		if run.get("edition",1)>=4:
			if run.get("edition",1)>=20:
				if not _simple_hub(): load("res://ui/economy_menu.gd").training(self,team,selected)
			else:
				var candy: Button = _travel_button("level-up","Usar Caramelo Raro · +1 nivel",team,{"kind":"level-up","member":selected_member})
				candy.disabled = selected.hp<=0 or selected.level>=campaign.progression.data.levelCap or run.bag["rare-candy"]<=0
				candy.tooltip_text = "Conserva EXP parcial y PS actuales. La evolución ocurre automáticamente al alcanzar su nivel."
				if run.get("edition",1)>=7: candy.tooltip_text = "Conserva EXP parcial. Recupera el aumento de PS máximos, incluida la evolución automática al subir de nivel."
				if run.get("edition",1)>=8:
					var cap: int = campaign.level_cap(run)
					candy.disabled = candy.disabled or selected.level>=cap
					candy.tooltip_text += " Límite actual: nivel %d. No se puede usar al alcanzarlo; la EXP parcial se descarta al llegar al límite." % cap
			var automatic: Dictionary = campaign.progression.evolution(selected)
			var evolution_label: Label = _label("Evolución automática: %s · Nv. %d" % [rules.profiles[int(automatic.speciesId)].data.name,automatic.level] if not automatic.is_empty() else "Sin evolución disponible",17,MUTED)
			evolution_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			team.add_child(evolution_label)
			if _simple_hub(): evolution_label.hide()
			if run.get("edition",1)>=13 and run.get("edition",1)<20: _render_evolution_options(team,selected)
			if run.get("edition",1)>=5 and run.get("edition",1)<13 and campaign.progression.data.stoneEvolutions.has(str(int(selected.speciesId))):
				evolution_label.text = "Evolución con Piedra Hoja · bolsa: %d" % run.bag["leaf-stone"]
				var stone: Button = _travel_button("stone","Usar Piedra Hoja",team,{"kind":"stone","member":selected_member})
				stone.disabled = selected.hp<=0 or run.bag["leaf-stone"]<=0
			if modern_shop:
				_render_traits(_hub_group(detail_root,"traits") if _simple_hub() else team,selected)
				_render_inventory(team,selected)
			if _simple_hub():
				var use_batch: Button = _button("Usar varias…",_open_batch.bind("use"))
				use_batch.theme_type_variation = "ToolButton"
				team.add_child(use_batch)
				travel_buttons.use_batch = use_batch
			_render_moves(_hub_group(detail_root,"moves") if _simple_hub() else team,selected)
			return
		var evolve: Button = _travel_button("evolve","Evolucionar · 1 Caramelo Raro",team,{"kind":"evolve","member":selected_member})
		evolve.disabled = selected.hp <= 0 or not Campaign.EVOLUTIONS.has(int(selected.speciesId)) or run.bag["rare-candy"] <= 0
		if run.get("edition",1) >= 2:
			var requirement: Dictionary = campaign.progression.evolution(selected)
			evolve.text = "Sin evolución disponible" if requirement.is_empty() else "Evolucionar · Nv. %d + 1 Caramelo" % requirement.level
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

func _review_dialog() -> void:
	if action_review==null:
		action_review = load("res://ui/action_review.gd").new()
		add_child(action_review)
		action_review.setup(self)
		_watch_dialog(action_review)

func _review_text(label: String, text: String, definition: Dictionary = {}) -> void:
	_review_dialog()
	action_review.review(label,text,Callable(),definition)

func _member_summary(identity: int) -> String:
	var member: Dictionary = campaign.target(run,identity)
	if member.is_empty(): return "Miembro ya no disponible."
	var unit: Dictionary = rules.member_unit(member)
	var held: Variant = member.get("heldItem")
	return "%s · Nv. %d\nPS %d/%d · %s\nObjeto: %s\nPreparados: %s" % [unit.name,member.level,unit.hp,unit.maxHp,_type_names(unit.types),campaign.shop_data.items[held].name if held!=null else "ninguno",", ".join(member.moves.map(func(id):return campaign.progression.data.moves[id].name))]

func _review_swap(outgoing: int, incoming: int, revision: int) -> void:
	_review_dialog()
	var command: Dictionary = {"kind":"swap","member":outgoing,"reserve":incoming,"at":revision}
	action_review.review("Cambiar equipo","SALE\n"+_member_summary(outgoing)+"\n\nENTRA\n"+_member_summary(incoming)+"\nSin curación ni coste. Se conservan los objetos.",func(): _event(command))

func _review_loadout(identity: int, moves: Array, description: String, definition: Dictionary = {}) -> void:
	_review_dialog()
	var revision: int = int(run.revision)
	if run.get("edition",0)>=23:
		var points: GDScript = preload("res://core/power_points.gd")
		var selected: Dictionary = campaign.target(run,identity)
		var used: int = points.used(moves,campaign.progression.data.moves)
		if used>points.capacity(selected.level): _review_text("PP insuficientes","Equipar requiere %d PP; capacidad %d." % [used,points.capacity(selected.level)]); return
		description += "\nPP equipados: %d / %d" % [used,points.capacity(selected.level)]
	var names: String = ", ".join(moves.map(func(id):return campaign.progression.data.moves[id].name))
	action_review.review("Preparar movimientos",_member_summary(identity)+"\n\nNUEVO: "+names+"\n"+description+"\nBásico neutro conservado.",func(): _event({"kind":"loadout","member":identity,"moves":moves,"at":revision}),definition)

func _open_batch(context: String = "buy") -> void:
	if run.phase!="shop" or batch_busy or run.get("edition",1)<4: return
	if shop_batch==null:
		shop_batch = load("res://ui/shop_batch.gd").new()
		add_child(shop_batch)
		shop_batch.setup(self)
		_watch_dialog(shop_batch)
	if _simple_hub() and context=="buy":
		var item_id: String = "rare-candy" if shop_tab=="evolution" else "potion"
		for index: int in shop_batch.item.item_count:
			if shop_batch.item.get_item_metadata(index)==item_id: shop_batch.item.select(index)
	elif _simple_hub() and context=="use":
		shop_batch.quantity.value = 1
		for index: int in shop_batch.item.item_count:
			if run.bag.get(shop_batch.item.get_item_metadata(index),0)>0: shop_batch.item.select(index); break
	shop_batch.open(context)

func _select_member(identity: int) -> void:
	if _simple_hub(): hub_mode = "team"
	selected_member = identity
	_refresh()

func _restore_travel_focus() -> void:
	if _modal_open() or not travel_root.visible: return
	var fallback: String = "starter1" if run.is_empty() else ("enter" if run.phase=="map" else ("continue" if run.phase=="shop" else "home"))
	FocusMemory.restore(travel_root,travel_buttons,travel_memory,fallback)

func _default_focus() -> void:
	if title_visible: title_screen.refresh()
	elif travel_root!=null and travel_root.visible: _restore_travel_focus()
	else: super._default_focus()

func _cycle_panel(backwards: bool = false) -> void:
	if kecleon.using_scene(self): _set_hub_mode("team"); return
	if travel_root==null or not travel_root.visible: super._cycle_panel(backwards); return
	var focused: Control = get_viewport().gui_get_focus_owner()
	var member: Control = travel_buttons.get("roster_team")
	if focused==member:
		if _simple_hub():
			hub_mode = "overview"; roster_tab = "team"; roster_offset = 0
			_refresh()
		var target: Control = travel_buttons.get("continue",travel_buttons.get("enter",travel_buttons.home))
		if FocusMemory.eligible(target): target.grab_focus.call_deferred()
	else:
		if _simple_hub(): hub_mode = "team"; _simplify_hub()
		if FocusMemory.eligible(member): member.grab_focus()

func _shop_panels(parent: VBoxContainer) -> Dictionary:
	if run.get("edition",1)<12: return {"supplies":parent,"gear":parent,"traits":parent}
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation",8)
	parent.add_child(tabs)
	var result: Dictionary = {}
	for entry: Array in ([["supplies","Medicina"],["evolution","Entrenar" if run.get("edition",1)>=20 else "Evolución"],["gear","MT y equipo"],["traits","Rasgos"]] if _simple_hub() else [["supplies","Objetos"],["gear","MT y equipo"],["traits","Rasgos"]]):
		var button: Button = _button(entry[1],_shop_page.bind(entry[0]))
		button.theme_type_variation = "TabButton"
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
	call_deferred("_focus_travel_button","shop_"+tab)

func _focus_travel_button(key: String) -> void:
	var target: Control = travel_buttons.get(key)
	if FocusMemory.eligible(target): target.grab_focus()

func _roster_page(tab: String, page: int) -> void:
	if _simple_hub(): hub_mode = "team"
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
	if _simple_hub() and run.phase=="map": choices = choices.filter(func(destination):return destination.id!=campaign.locations[int(run.stage)].id)
	if choices.is_empty(): return
	parent.add_child(_label("Otros destinos" if _simple_hub() else "DESTINOS DISPONIBLES",20,GOLD))
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
	parent.add_child(_label("Mentas",20,GOLD))
	var choices: Array = study.mintable()
	var picker: OptionButton = OptionButton.new()
	picker.name = "MintPicker"
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for identity: String in choices: picker.add_item(preload("res://ui/mint_info.gd").caption(study,identity)+" · tienes %d" % run.bag["mint-"+identity])
	picker.select(choices.find(selected_mint))
	picker.item_selected.connect(func(index: int): selected_mint = choices[index]; _refresh())
	parent.add_child(picker)
	travel_buttons.mint_picker = picker
	parent.add_child(_label(preload("res://ui/mint_info.gd").details(study,selected_mint),17,GOLD))
	var buy: Button = _travel_button("buy_mint","Comprar Menta %s · %d ₽" % [study.traits.natures[selected_mint].name,study.traits.mintPrice],parent,{"kind":"buy","item":"mint-"+selected_mint})
	if _simple_hub(): _item_picture(buy,"mint-"+selected_mint)
	buy.disabled = run.money<int(study.traits.mintPrice)
	buy.tooltip_text = preload("res://ui/mint_info.gd").details(study,selected_mint)+"\nUn uso."

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
	var has_mint: bool = true
	if _simple_hub():
		var owned: Array = study.mintable().filter(func(key):return run.bag.get("mint-"+key,0)>0)
		has_mint = not owned.is_empty()
		if has_mint:
			if hub_mode=="team" and member_view=="traits" and selected_mint not in owned: selected_mint = owned[0]
			var picker: OptionButton = OptionButton.new()
			picker.name = "OwnedMintPicker"
			for key: String in owned: picker.add_item(preload("res://ui/mint_info.gd").caption(study,key)+" · tienes %d" % run.bag["mint-"+key])
			picker.select(maxi(0,owned.find(selected_mint)))
			picker.item_selected.connect(func(index: int): selected_mint = owned[index]; _refresh())
			parent.add_child(picker)
			travel_buttons.use_mint_picker = picker
		else: parent.add_child(_label("No tienes mentas en la bolsa.",16,MUTED))
	if has_mint: parent.add_child(_label(preload("res://ui/mint_info.gd").details(study,selected_mint),16,GOLD))
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
	preview.visible = has_mint
	parent.add_child(preview)
	var mint: Button = _travel_button("use_mint","Usar Menta %s · bolsa: %d" % [study.traits.natures[selected_mint].name,run.bag["mint-"+selected_mint]],parent,{"kind":"mint","member":member.id,"nature":selected_mint})
	mint.disabled = member.hp<=0 or run.bag["mint-"+selected_mint]<=0 or not study.mint_changes(member,selected_mint)
	mint.visible = has_mint
	var next: int = study.next_slot(member)
	copy.abilitySlot = next
	var next_ability: String = study.ability(copy)
	var capsule: Button = _travel_button("use_capsule","Usar Cápsula Habilidad · bolsa: %d\n" % run.bag["ability-capsule"]+(study.traits.abilities[next_ability].name if next!=0 else "Una sola habilidad normal"),parent,{"kind":"capsule","member":member.id})
	capsule.disabled = member.hp<=0 or next==0 or run.bag["ability-capsule"]<=0
	capsule.tooltip_text = study.traits.abilities[next_ability].description if next!=0 else "No tiene otra habilidad normal."

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
		if not entry.learned.is_empty(): text += " · nuevos movimientos: " + ", ".join(entry.learned.map(func(id):return campaign.progression.data.moves[id].name))
		lines.append(text)
	return "\n".join(lines)

func _render_moves(parent: VBoxContainer, member: Dictionary) -> void:
	var study: RefCounted = campaign.progression
	var at_cap: bool = run.get("edition",1)>=8 and member.level>=campaign.level_cap(run)
	var experience: Label = _label("Nv. %d · Límite alcanzado · EXP detenida" % member.level if at_cap else "Nv. %d · EXP %d / %d" % [member.level,member.xp,load("res://ui/economy_menu.gd").needed(self,member)],20,GOLD)
	experience.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(experience)
	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = load("res://ui/economy_menu.gd").needed(self,member)
	bar.value = member.xp
	bar.show_percentage = false
	bar.custom_minimum_size.y = 9
	parent.add_child(bar)
	var roles: Label = _label(study.roles(member),17,MUTED)
	roles.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roles.tooltip_text = "Número de movimientos preparados de cada rol; no concede estadísticas adicionales."
	if run.get("edition",0)<21: parent.add_child(roles)
	else: roles.queue_free()
	parent.add_child(_label("MOVIMIENTOS · %d / 4\nBásico neutro · 0 PT" % member.moves.size(),17,GOLD))
	if run.get("edition",0)>=23: parent.get_child(parent.get_child_count()-1).text = "MOVIMIENTOS · %d / 4\nPP equipados: %d / %d · básico gratuito" % [member.moves.size(),preload("res://core/power_points.gd").used(member.moves,study.data.moves),preload("res://core/power_points.gd").capacity(member.level)]
	move_library.render(self,parent,member)
	if run.get("edition",0)>=21:
		var entries: Array = preload("res://ui/tactical_loadouts.gd").learning(study,member,campaign.level_cap(run))
		var lines: Array[String] = []
		for entry: Dictionary in entries:
			lines.append("%s · Nv. %d%s%s" % [study.data.moves[entry.id].name,entry.level," · después del límite actual" if entry.lockedByCap else ""," · "+" / ".join(entry.tags) if not entry.tags.is_empty() else ""])
		var future: Label = _label("Próximos: "+("; ".join(lines) if not lines.is_empty() else "sin nuevos movimientos por nivel en esta forma"),16,MUTED)
		future.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; parent.add_child(future)
		return
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
	if practice.active: return practice.instruction(self)
	var classic: String = ""
	if not run.is_empty() and run.get("edition",1)<11: classic = "Esta aventura conserva sus reglas originales.\n"
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
		if _simple_hub():
			buy.icon = Art.icon("tm" if item.kind=="tm" else "held")
			buy.expand_icon = true
			buy.add_theme_constant_override("icon_max_width",24)
		buy.disabled = offer.sold or run.money<item.price
		var description: String = item.description
		if item.kind == "tm":
			var names: Array[String] = []
			for member: Dictionary in (campaign.members(run) if run.get("edition",1)>=12 else run.party):
				if member.hp>0 and campaign.compatible(member,offer.item) and item.move not in member.knownMoves:
					var species_name: String = rules.profiles[int(member.speciesId)].data.name
					if species_name not in names: names.append(species_name)
			var move: Dictionary = campaign.progression.data.moves[item.move]
			description = preload("res://ui/move_info.gd").summary(move)+"\nPuede aprender: "+(", ".join(names) if not names.is_empty() else "ningún Pokémon disponible")
			buy.tooltip_text = preload("res://ui/move_info.gd").details(move)
		else: buy.tooltip_text = item.description
		var label: Label = _label(description,16,MUTED)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(label)
		if item.kind=="tm":
			var definition: Dictionary = campaign.progression.data.moves[item.move]
			var detail: Button = _button("Ver movimiento",_review_text.bind(definition.name,preload("res://ui/move_info.gd").details(definition),definition))
			detail.theme_type_variation = "ToolButton"
			content.add_child(detail)
			travel_buttons["stock_detail_"+str(i)] = detail

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
		button.tooltip_text = (preload("res://ui/move_info.gd").details(campaign.progression.data.moves[item.move]) if teach else item.description) + (" Ya aprendido o incompatible." if teach and not available else "")

func _process(delta: float) -> void:
	if not qa_running: trainer.tick(self,delta)
	if practice.active: return
	if not qa_running: adventure.tick(self,delta)
	if not run.is_empty() and run.get("battle",{}).get("deployment",false): return
	super._process(delta)

func _start_practice() -> void:
	practice.begin(self)

func _select_action(identity: String) -> void:
	super._select_action(identity)
	practice.observe(self,"select")

func _cancel() -> void:
	super._cancel()
	practice.observe(self,"cancel")

func _inspect() -> void:
	super._inspect()
	if tactical_reader.visible: practice.observe(self,"inspect")

func _glossary() -> void:
	_review_text("Reglas tácticas",preload("res://ui/player_copy.gd").glossary(int(run.get("edition",21))))

func _travel_command(command: Dictionary) -> void:
	if command.kind=="destiny":
		_review_dialog()
		action_review.review("Elegir desafío legendario", "Esta elección fija el final alternativo de esta campaña: %s. El otro desafío quedará fuera de esta aventura. Los legendarios no son reclutables.\nPuedes cancelar para conservar ambas posibilidades." % ("las tres aves" if command.path=="birds" else "Mew y Mewtwo"),func(): _event(command))
	else: _event(command)
