extends Control

const Rules = preload("res://core/battle.gd")
const Movement = preload("res://core/movement.gd")
const Store = preload("res://core/save_store.gd")
const Board = preload("res://ui/board.gd")
const Indicators = preload("res://ui/unit_indicators.gd")
const Revision = preload("res://core/movement_revision.gd")
const Qa = preload("res://ui/qa_driver.gd")
const CREAM = Color("eee8ce")
const MUTED = Color("b4c3ac")
const GOLD = Color("eccb7f")
const TYPE_NAMES = {"normal": "Normal", "fighting": "Lucha", "flying": "Volador", "poison": "Veneno", "ground": "Tierra", "rock": "Roca", "bug": "Bicho", "ghost": "Fantasma", "steel": "Acero", "fire": "Fuego", "water": "Agua", "grass": "Planta", "electric": "Eléctrico", "psychic": "Psíquico", "ice": "Hielo", "dragon": "Dragón", "dark": "Siniestro", "fairy": "Hada"}
var rules = Rules.new()
var store
var state: Dictionary = {}
var history: Array = []
var mode = "current"
var pending: Dictionary = {}
var selecting = "auto"
var selected_action = "basic"
var target_id = -1
var ai_clock = 0.0
var qa_dir = ""
var qa_running = false
var muted = false
var reduced_motion = false
var save_warning = ""
var portraits: Dictionary = {}
var buttons: Dictionary = {}
var action_buttons: Dictionary = {}
var action_page: bool = false
var command_panel: PanelContainer
var main_commands: VBoxContainer
var command_heading: Label
var target_panel: PanelContainer
var target_portrait: TextureRect
var actor_hp: ProgressBar
var faces: Dictionary = {}
var direction_buttons: Dictionary = {}
var board
var battle_overlay: Control
var timeline: HBoxContainer
var menu: MenuButton
var details_dialog: AcceptDialog
var details_text: Label
var actor_portrait: TextureRect
var actor_info: Label
var target_info: Label
var actor_indicators: Control
var target_indicators: Control
var heading: Label
var hint: Label
var saved: Label
var actions: VBoxContainer
var directions: HBoxContainer
var new_dialog: ConfirmationDialog
var help_dialog: AcceptDialog
var credits_dialog: AcceptDialog
var seed_input: LineEdit
var composition_input: OptionButton
var mode_input: OptionButton
var variance_input: OptionButton
var sound: AudioStreamPlayer
var combat_feedback: Control
var last_sound_requested: String = ""
const Feedback = preload("res://ui/combat_feedback.gd")
const AUDIO = {"select":preload("res://assets/audio/select.wav"),"hit":preload("res://assets/audio/hit.wav"),"victory":preload("res://assets/audio/victory.wav"),"miss":preload("res://assets/audio/miss.wav"),"immune":preload("res://assets/audio/immune.wav"),"level-up":preload("res://assets/audio/level-up.wav")}

func _ready():
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-dir="): qa_dir = argument.trim_prefix("--qa-dir=")
	qa_running = not qa_dir.is_empty()
	if qa_running: DirAccess.make_dir_recursive_absolute(qa_dir)
	store = Store.new(qa_dir.path_join("ui-save.json") if qa_running else "user://laboratory-save.json")
	for record in rules.data.species: portraits[int(record.id)] = load("res://" + record.animations.Idle.path.get_base_dir() + "/thumbnail.png")
	var face_manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/portraits.json"))
	for record: Dictionary in face_manifest.records: faces[int(record.id)] = load("res://" + record.files[0].target)
	_make_theme()
	_build_interface()
	_build_dialogs()
	sound = AudioStreamPlayer.new()
	sound.volume_db = -15
	add_child(sound)
	combat_feedback = Feedback.new()
	combat_feedback.board = board
	add_child(combat_feedback)
	_refresh()
	_boot()

func _boot():
	if qa_running:
		call_deferred("_run_qa")
	elif FileAccess.file_exists(store.file_path):
		_load_game()
	else:
		new_dialog.popup_centered()

func _make_theme():
	theme = Theme.new()
	theme.default_font = load("res://assets/fonts/AtkinsonHyperlegible-Regular.ttf")
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_disabled_color", "Button", Color("94a8ad"))
	for type in ["Button", "OptionButton"]:
		for entry in ["normal", "hover", "pressed", "disabled", "focus"]:
			var style = StyleBoxFlat.new()
			style.bg_color = Color("164957") if entry == "normal" else (Color("216576") if entry == "hover" else Color("102e3a"))
			style.border_color = GOLD if entry in ["focus", "pressed"] else Color("54634b")
			style.set_border_width_all(2 if entry == "focus" else 1)
			style.set_corner_radius_all(3)
			style.content_margin_left = 12
			style.content_margin_right = 12
			style.content_margin_top = 9
			style.content_margin_bottom = 9
			theme.set_stylebox(entry, type, style)

func _label(text: String, font_size: int = 18, color: Color = CREAM) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, callback: Callable, minimum: float = 0) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(minimum, 44)
	button.pressed.connect(callback)
	return button

func _panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("153d50")
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 5
	style.border_color = Color("70a6aa")
	style.set_border_width_all(1)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _clear(container: Node):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _build_interface() -> void:
	# Overlay layout adapted from the Godot skill HUD template; the laboratory
	# already owns state/signals, so it needs no extra manager or autoload.
	board = _make_board()
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.setup(rules.data.species)
	board.tile_selected.connect(_select_tile)
	board.tile_hovered.connect(_hover_tile)
	board.cancelled.connect(_cancel)
	add_child(board)
	var overlay: Control = Control.new()
	battle_overlay = overlay
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var top: MarginContainer = MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_top = 12
	top.offset_right = -18
	overlay.add_child(top)
	var upper: VBoxContainer = VBoxContainer.new()
	upper.add_theme_constant_override("separation", 12)
	top.add_child(upper)
	var header: HBoxContainer = HBoxContainer.new()
	upper.add_child(header)
	header.add_child(_label("POKÉMON / TACTICS", 22, GOLD))
	heading = _label("Laboratorio táctico", 17, MUTED)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(heading)
	saved = _label("Guardado local", 14, MUTED)
	header.add_child(saved)
	menu = MenuButton.new()
	menu.text = "Menú · F1"
	menu.custom_minimum_size = Vector2(110, 44)
	header.add_child(menu)
	var popup: PopupMenu = menu.get_popup()
	for entry: Array in [["Nuevo ensayo", 0], ["Continuar · F8", 1], ["Cómo jugar", 2], ["Equipo y registro", 3]]:
		popup.add_item(entry[0], entry[1])
	popup.add_separator()
	popup.add_check_item("Sonido", 4)
	popup.set_item_checked(popup.get_item_index(4), true)
	popup.add_check_item("Animación", 5)
	popup.set_item_checked(popup.get_item_index(5), true)
	popup.add_item("Créditos", 6)
	popup.add_item("Campaña de Kanto", 7)
	popup.id_pressed.connect(_menu_selected)
	timeline = HBoxContainer.new()
	timeline.alignment = BoxContainer.ALIGNMENT_CENTER
	timeline.add_theme_constant_override("separation", 12)
	upper.add_child(timeline)
	command_panel = _panel()
	_pin(command_panel, overlay, Control.PRESET_CENTER_RIGHT, Vector2(266, 300))
	var command_content: VBoxContainer = VBoxContainer.new()
	command_content.add_theme_constant_override("separation", 8)
	command_panel.add_child(command_content)
	command_heading = _label("ÓRDENES", 24, Color("85dfdd"))
	command_content.add_child(command_heading)
	main_commands = VBoxContainer.new()
	main_commands.add_theme_constant_override("separation", 8)
	command_content.add_child(main_commands)
	buttons["actions"] = _button("Habilidades · A", _open_actions)
	buttons["undo"] = _button("Rectificar movimiento · R", _rectify_movement)
	buttons.undo.add_theme_font_size_override("font_size", 16)
	buttons["finish"] = _button("Orientar y terminar · F", _select_finish)
	for button: Button in [buttons.actions, buttons.undo, buttons.finish]: main_commands.add_child(button)
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	command_content.add_child(actions)
	directions = HBoxContainer.new()
	command_content.add_child(directions)
	for facing: int in Rules.FACINGS:
		var names: Dictionary = {4: "↑", 2: "→", 0: "↓", 6: "←"}
		var full_names: Dictionary = {4: "norte", 2: "este", 0: "sur", 6: "oeste"}
		var button: Button = _button(names[facing], _set_facing.bind(facing), 44)
		button.tooltip_text = "Terminar el turno mirando al " + full_names[facing]
		button.mouse_entered.connect(_preview_facing.bind(facing))
		button.mouse_exited.connect(func(): board.facing_preview = -1)
		directions.add_child(button)
		direction_buttons[facing] = button
	buttons["confirm"] = _button("Sí, atacar", _confirm)
	buttons["cancel"] = _button("Volver · Esc", _cancel)
	command_content.add_child(buttons.confirm)
	command_content.add_child(buttons.cancel)
	var actor_panel: PanelContainer = _panel()
	_pin(actor_panel, overlay, Control.PRESET_BOTTOM_LEFT, Vector2(360, 162))
	var actor_details: VBoxContainer = VBoxContainer.new()
	actor_panel.add_child(actor_details)
	var actor_row: HBoxContainer = HBoxContainer.new()
	actor_row.add_theme_constant_override("separation", 16)
	actor_details.add_child(actor_row)
	actor_portrait = _portrait(Vector2(104, 104))
	actor_row.add_child(actor_portrait)
	var vitals: VBoxContainer = VBoxContainer.new()
	vitals.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actor_row.add_child(vitals)
	actor_info = _label("Elige un ensayo.", 18, GOLD)
	vitals.add_child(actor_info)
	actor_indicators = Indicators.new()
	actor_details.add_child(actor_indicators)
	actor_hp = ProgressBar.new()
	actor_hp.show_percentage = false
	actor_hp.custom_minimum_size.y = 10
	var hp_fill: StyleBoxFlat = StyleBoxFlat.new()
	hp_fill.bg_color = Color("77ca9c")
	var hp_background: StyleBoxFlat = StyleBoxFlat.new()
	hp_background.bg_color = Color("0c2834")
	actor_hp.add_theme_stylebox_override("fill", hp_fill)
	actor_hp.add_theme_stylebox_override("background", hp_background)
	vitals.add_child(actor_hp)
	var message: PanelContainer = _panel()
	_pin(message, overlay, Control.PRESET_CENTER_BOTTOM, Vector2(390, 112))
	hint = _label("Clic en una casilla para moverte.", 16, CREAM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_child(hint)
	target_panel = _panel()
	_pin(target_panel, overlay, Control.PRESET_BOTTOM_RIGHT, Vector2(390, 236))
	var target_row: HBoxContainer = HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 10)
	target_panel.add_child(target_row)
	target_portrait = _portrait(Vector2(80, 80))
	target_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	target_row.add_child(target_portrait)
	var target_scroll: ScrollContainer = ScrollContainer.new()
	target_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	target_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	target_scroll.custom_minimum_size.y = 198
	target_scroll.focus_mode = Control.FOCUS_ALL
	target_row.add_child(target_scroll)
	target_info = _label("", 17)
	target_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_info.custom_minimum_size.x = 250
	target_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var target_details: VBoxContainer = VBoxContainer.new()
	target_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_scroll.add_child(target_details)
	target_indicators = Indicators.new()
	target_details.add_child(target_indicators)
	target_details.add_child(target_info)

func _make_board() -> Control:
	return Board.new()

func _movement_routes(actor: Dictionary) -> Dictionary:
	return Movement.routes(state.board,Rules.living(state),actor)

func _portrait(dimensions: Vector2) -> TextureRect:
	var image: TextureRect = TextureRect.new()
	image.custom_minimum_size = dimensions
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return image

func _pin(control: Control, parent: Control, preset: int, dimensions: Vector2) -> void:
	parent.add_child(control)
	control.set_anchors_and_offsets_preset(preset)
	control.grow_horizontal = Control.GROW_DIRECTION_BEGIN if preset in [Control.PRESET_CENTER_RIGHT, Control.PRESET_BOTTOM_RIGHT] else Control.GROW_DIRECTION_BOTH
	control.grow_vertical = Control.GROW_DIRECTION_BEGIN if preset != Control.PRESET_CENTER_RIGHT else Control.GROW_DIRECTION_BOTH
	control.offset_left = -dimensions.x - 18 if preset in [Control.PRESET_CENTER_RIGHT, Control.PRESET_BOTTOM_RIGHT] else (18 if preset == Control.PRESET_BOTTOM_LEFT else -dimensions.x / 2)
	control.offset_right = -18 if preset in [Control.PRESET_CENTER_RIGHT, Control.PRESET_BOTTOM_RIGHT] else (18 + dimensions.x if preset == Control.PRESET_BOTTOM_LEFT else dimensions.x / 2)
	control.offset_top = -dimensions.y / 2 if preset == Control.PRESET_CENTER_RIGHT else -dimensions.y - 18
	control.offset_bottom = dimensions.y / 2 if preset == Control.PRESET_CENTER_RIGHT else -18

func _open_actions() -> void:
	if not _player_turn() or _modal_open() or state.acted or not pending.is_empty(): return
	action_page = true
	selecting = "auto"
	_refresh()

func _can_rectify() -> bool:
	return pending.is_empty() and Revision.available(state, history)

func _rectify_movement() -> void:
	if _modal_open() or not _can_rectify(): return
	var result: Dictionary = Revision.rectify(state, history, mode, rules)
	if not result.ok:
		hint.text = result.reason
		return
	combat_feedback.clear()
	state = result.state
	history = result.commands
	pending = {}
	selecting = "auto"
	action_page = false
	selected_action = "basic"
	_save()
	_refresh()
	board.grab_focus()

func _menu_selected(identity: int):
	match identity:
		0: new_dialog.popup_centered()
		1: _load_game()
		2: help_dialog.popup_centered(Vector2i(630, 450))
		3:
			if not state.is_empty():
				var lines: Array[String] = []
				for unit in state.units:
					if unit.team == "ally": lines.append("%s · %d / %d PS · %d PT" % [unit.name, unit.hp, unit.maxHp, unit.tp])
				details_text.text = "\n".join(lines) + "\n\nÚLTIMOS TURNOS\n" + "\n".join(state.log.slice(maxi(0, state.log.size() - 12)))
			details_dialog.popup_centered(Vector2i(660, 500))
		4: _toggle_sound()
		5: _toggle_motion()
		6: credits_dialog.popup_centered(Vector2i(720, 550))
		7: get_tree().change_scene_to_file("res://scenes/campaign.tscn")

func _build_dialogs():
	new_dialog = ConfirmationDialog.new()
	new_dialog.title = "Nuevo ensayo táctico"
	new_dialog.ok_button_text = "Comenzar"
	new_dialog.cancel_button_text = "Cancelar"
	var fields = VBoxContainer.new()
	fields.custom_minimum_size = Vector2(520, 280)
	fields.add_theme_constant_override("separation", 10)
	new_dialog.add_child(fields)
	fields.add_child(_label("Dos equipos, las mismas reglas del prototipo.\nUna partida anterior se conservará como copia.", 18))
	fields.add_child(_label("Semilla", 16, MUTED))
	seed_input = LineEdit.new()
	seed_input.text = "godot-13"
	seed_input.max_length = 64
	fields.add_child(seed_input)
	composition_input = OptionButton.new()
	composition_input.add_item("Aliados: Bulbasaur, Charmander y Squirtle")
	composition_input.add_item("Aliados: Pikachu, Butterfree y Geodude")
	fields.add_child(composition_input)
	mode_input = OptionButton.new()
	mode_input.add_item("Reglas actuales: PS de campaña y Pirotecnia")
	mode_input.add_item("Ensayo clásico: PS originales y Lanzallamas")
	fields.add_child(mode_input)
	variance_input = OptionButton.new()
	variance_input.add_item("Iniciativa: velocidad ±5 %")
	variance_input.add_item("Iniciativa: velocidad ±10 %")
	fields.add_child(variance_input)
	new_dialog.confirmed.connect(_start_from_dialog)
	add_child(new_dialog)
	help_dialog = AcceptDialog.new()
	help_dialog.title = "Cómo jugar"
	help_dialog.dialog_text = "Un desplazamiento y una acción, en cualquier orden.\nEl menú de órdenes aparece a la derecha en turnos aliados.\n\nClic en casilla azul: mover. Clic en rival: ataque básico.\nHabilidades / A abre los movimientos; 1 a 5 son atajos directos.\nLas habilidades propias se ejecutan al pulsarlas.\nSolo se confirma si puedes dañar o alterar a un aliado.\n\nRectificar movimiento / R devuelve a la casilla anterior,\ncon su orientación y presupuesto. No funciona si ya has\natacado, usado otra acción o terminado el turno.\nNo recupera PS, PT, ataques, estados ni tiradas.\n\nOrientar y terminar / F permite elegir una dirección.\nFlechas y Enter: recorrer / seleccionar casilla.\nClic derecho o Escape: cancelar selección; F8: continuar.\nAliados atravesables; destinos ocupados inválidos.\nGuardado tras cada orden; independiente de la versión web."
	add_child(help_dialog)
	credits_dialog = AcceptDialog.new()
	credits_dialog.title = "Créditos y recursos"
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 450)
	credits_dialog.add_child(scroll)
	var credits = RichTextLabel.new()
	credits.fit_content = true
	credits.custom_minimum_size.x = 640
	credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credits.text = FileAccess.get_file_as_string("res://CREDITS.md") + "\n\n" + Engine.get_license_text() + "\n\nBibliotecas de Godot y atribuciones:\n" + JSON.stringify(Engine.get_copyright_info(), "  ")
	for license in Engine.get_license_info(): credits.text += "\n\n" + license + "\n" + Engine.get_license_info()[license]
	scroll.add_child(credits)
	add_child(credits_dialog)
	details_dialog = AcceptDialog.new()
	details_dialog.title = "Equipo y registro"
	var details_scroll = ScrollContainer.new()
	details_scroll.custom_minimum_size = Vector2(620, 400)
	details_dialog.add_child(details_scroll)
	details_text = _label("", 18)
	details_text.custom_minimum_size.x = 590
	details_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_scroll.add_child(details_text)
	add_child(details_dialog)

func _modal_open() -> bool:
	return new_dialog.visible or help_dialog.visible or credits_dialog.visible or details_dialog.visible or menu.get_popup().visible

func _start_from_dialog():
	var preserved = store.preserve_before_new()
	if not preserved.ok:
		save_warning = preserved.reason
		_refresh()
		return
	combat_feedback.clear()
	mode = "current" if mode_input.selected == 0 else "classic"
	state = rules.create(seed_input.text, 0.05 if variance_input.selected == 0 else 0.1, "starters" if composition_input.selected == 0 else "mixed", mode)
	history = []
	ai_clock = 0
	pending = {}
	selecting = "auto"
	action_page = false
	selected_action = "basic"
	target_id = -1
	_save()
	_refresh()
	board.grab_focus()

func _save():
	var result = store.save(state, history, mode)
	save_warning = "" if result.ok else result.reason

func _load_game():
	var result = store.load_game(rules)
	if not result.ok:
		save_warning = result.reason
		_refresh()
		return
	combat_feedback.clear()
	state = result.state
	history = result.commands
	mode = result.mode
	pending = {}
	selecting = "auto"
	action_page = false
	selected_action = "basic"
	target_id = -1
	ai_clock = 0
	save_warning = ""
	_refresh()

func _process(delta):
	if qa_running or state.is_empty() or state.outcome != "playing" or _modal_open(): return
	var actor = Rules.active(state)
	if actor.team == "enemy":
		ai_clock += delta
		if ai_clock >= (0.1 if reduced_motion else 0.45):
			ai_clock = 0
			_commit(rules.choose_command(state))

func _player_turn() -> bool:
	return not state.is_empty() and state.outcome == "playing" and Rules.active(state).team == "ally"

func _refresh():
	_clear(timeline)
	_clear(actions)
	action_buttons.clear()
	board.state = state
	board.available = {}
	board.attackable = {}
	board.route = []
	board.affected = []
	board.forecast_hits = []
	board.facing_preview = -1
	board.reduced_motion = reduced_motion
	menu.get_popup().set_item_disabled(menu.get_popup().get_item_index(1), not FileAccess.file_exists(store.file_path))
	saved.text = "Guardado local" if save_warning.is_empty() else "¡Sin guardar!"
	saved.tooltip_text = save_warning
	saved.add_theme_color_override("font_color", MUTED if save_warning.is_empty() else GOLD)
	command_panel.visible = _player_turn()
	var menu_height: float = minf(size.y - 160,170 + 54 * (rules.profile(Rules.active(state)).actions_for(Rules.active(state)).size() if not state.is_empty() and state.outcome == "playing" else 3)) if action_page else (170 if selecting in ["attack", "finish"] or not pending.is_empty() else 240)
	command_panel.offset_top = -menu_height / 2
	command_panel.offset_bottom = menu_height / 2
	main_commands.visible = pending.is_empty() and selecting == "auto" and not action_page
	actions.visible = action_page and pending.is_empty()
	command_heading.text = "HABILIDADES" if action_page else ("ORIENTACIÓN" if selecting == "finish" else ("CONFIRMAR" if not pending.is_empty() else ("OBJETIVO" if selecting == "attack" else "ÓRDENES")))
	target_panel.visible = false
	actor_indicators.show_unit({})
	target_indicators.show_unit({})
	buttons.actions.disabled = not _player_turn() or state.get("acted", false)
	buttons.undo.disabled = not _can_rectify()
	buttons.undo.tooltip_text = "Vuelve a la casilla anterior. Solo antes de actuar." if not buttons.undo.disabled else "Solo disponible después de moverte y antes de actuar."
	buttons.cancel.visible = action_page or not pending.is_empty() or selecting in ["attack", "finish"]
	buttons.confirm.visible = not pending.is_empty()
	buttons.finish.visible = pending.is_empty()
	directions.visible = selecting == "finish" and pending.is_empty()
	for button in direction_buttons.values(): button.disabled = not _player_turn()
	buttons.finish.disabled = not _player_turn()
	if state.is_empty():
		hint.text = save_warning if not save_warning.is_empty() else "Menú → Nuevo ensayo para comenzar."
		return
	for identity in state.queue:
		var unit = Rules.unit_by_id(state, int(identity))
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var image = TextureRect.new()
		image.texture = portraits[int(unit.speciesId)]
		image.custom_minimum_size = Vector2(32, 32)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(image)
		row.add_child(_label(("▶ " if identity == state.queue[0] else "") + unit.name, 16, GOLD if identity == state.queue[0] else (CREAM if unit.team == "ally" else Color("e5a182"))))
		timeline.add_child(row)
	heading.text = "Ronda %d · %s" % [state.round, "Reglas actuales" if mode == "current" else "Ensayo clásico"]
	heading.tooltip_text = "Semilla: " + state.seed
	if state.outcome != "playing":
		actor_info.text = "VICTORIA\nZona despejada" if state.outcome == "victory" else "DERROTA\nEquipo caído"
		hint.text = save_warning if not save_warning.is_empty() else "Resultado guardado. Menú → Nuevo ensayo para repetir."
		target_info.text = "\n".join(state.log.slice(maxi(0, state.log.size() - 3)))
		board.queue_redraw()
		return
	var actor = Rules.active(state)
	actor_indicators.show_unit(actor)
	actor_portrait.texture = faces[int(actor.speciesId)]
	actor_hp.max_value = actor.maxHp
	actor_hp.value = actor.hp
	actor_info.text = "%s%s\n%d / %d PS\n%d / %d PT\n%s · %s" % [actor.name, " · IA" if actor.team == "enemy" else "", actor.hp, actor.maxHp, actor.tp, actor.maxTp, "Mov. usado" if state.moved else "Mov. %d" % actor.remaining, "Acc. usada" if state.acted else "Acc. lista"]
	if actor.has("abilityName"): actor_info.text += "\n"+actor.abilityName
	for index in rules.profile(actor).actions_for(actor).size():
		var definition = rules.profile(actor).actions_for(actor)[index].definition
		var button = _button("%d · %s\n%d PT · %d cas." % [index + 1, definition.name, definition.cost, definition.range], _select_action.bind(definition.id))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not _player_turn() or state.acted or actor.tp < definition.cost or not pending.is_empty()
		button.toggle_mode = true
		button.button_pressed = definition.id == selected_action and selecting != "finish" and not state.acted
		button.tooltip_text = definition.description
		button.mouse_entered.connect(_preview_self.bind(definition.id))
		actions.add_child(button)
		action_buttons[definition.id] = button
	if _player_turn():
		if not state.moved and selecting == "auto":
			var routes = _movement_routes(actor)
			for identity in routes:
				if routes[identity].cost > 0 and routes[identity].cost <= actor.remaining: board.available[identity] = routes[identity]
		if not state.acted and selecting != "finish":
			for unit in Rules.living(state):
				if rules.attack_plan(state, int(unit.id), {}, selected_action).ok: board.attackable[Movement.key(unit)] = true
	target_info.text = "Pasa el cursor por una unidad\npara ver la previsión.\n\nAzul: puedes moverte.\nMarco coral: puedes atacar."
	hint.text = _default_hint()
	board.queue_redraw()

func _default_hint() -> String:
	if not save_warning.is_empty(): return save_warning
	if not _player_turn(): return "Turno rival…"
	if selecting == "finish": return "Elige hacia dónde mirar: clic en el tablero o una flecha del menú."
	if selecting == "attack": return "%s: elige objetivo. Esc vuelve al básico." % rules.profile(Rules.active(state)).action(Rules.active(state), selected_action).definition.name
	if state.acted and state.moved: return "Turno listo. Elige una dirección para terminar."
	return "Clic en casilla: mover. Clic en rival: básico. Habilidades y fin de turno en el menú."

func _select_movement():
	if not _player_turn() or _modal_open(): return
	_cancel()

func _select_action(identity: String):
	if not _player_turn() or _modal_open() or state.acted or not pending.is_empty(): return
	var action = rules.profile(Rules.active(state)).action(Rules.active(state), identity)
	if action == null or Rules.active(state).tp < action.definition.cost: return
	action_page = false
	selected_action = identity
	selecting = "auto" if identity == "basic" else "attack"
	_refresh()
	board.grab_focus()
	if action.definition.target == "self": _select_tile(Rules.active(state))

func _unit_at(point: Dictionary) -> Dictionary:
	for unit in Rules.living(state):
		if Movement.same(unit, point): return unit
	return {}

func _friendly_risk(plan: Dictionary) -> bool:
	return plan.hits.any(func(hit): return Rules.unit_by_id(state, int(hit.targetId)).team == "ally" and (hit.damage > 0 or hit.status != null))

func _show_plan(unit: Dictionary, plan: Dictionary):
	target_indicators.show_unit(unit)
	target_panel.visible = true
	target_portrait.texture = faces[int(unit.speciesId)]
	target_info.text = "%s · %d / %d PS\n%s" % [unit.name + (" · Nv. %d" % unit.level if unit.has("level") else ""), unit.hp, unit.maxHp, _type_names(unit.types)]
	if unit.has("abilityName"):
		target_info.text += " · "+unit.abilityName
		target_info.tooltip_text = unit.natureText+"\n"+unit.abilityDescription
	if unit.status != null: target_info.text += " · " + _status_name(unit.status.kind)
	if not plan.ok:
		target_info.text += "\n\n" + plan.reason
		return
	if _friendly_risk(plan): target_info.text = "¡PELIGRO: alcanza a aliados!\n" + target_info.text
	if plan.has("damageMin"):
		var span: String = str(plan.damageMin) if plan.damageMin==plan.damageMax else "%d–%d" % [plan.damageMin,plan.damageMax]
		target_info.text += "\n\n%s · %d PT\n%s PS · %d %% de precisión" % [plan.name,plan.cost,span,plan.accuracy]
		if plan.criticalChance>0:
			target_info.text += "\nCrítico garantizado ×1,5" if plan.criticalChance==1 else "\nCrítico: %.2f %% · %d–%d PS" % [plan.criticalChance*100,plan.criticalMin,plan.criticalMax]
		if not plan.get("approach",{}).is_empty(): target_info.text += "\nSe acerca a %s · %d mov." % [Rules.coordinate(plan.approach.destination),plan.approach.cost]
		if plan.get("focus",false): target_info.text += "\nCrítico +2 etapas · 3 activaciones"
	else: target_info.text += "\n\n%s · %d PT\n%d PS · %d %% · ×%s" % [plan.name, plan.cost, plan.damage, plan.accuracy, str(plan.multiplier)]
	if plan.category != "status": target_info.text += "\nSTAB ×%s · tipos ×%s" % [str(plan.stab),str(plan.multiplier)]
	if plan.get("statChange") != null: target_info.text += "\n%s: %s%d etapas" % [{"attack":"Ataque","defense":"Defensa","speed":"Velocidad"}.get(plan.statChange.stat,plan.statChange.stat),"+" if plan.statChange.stages > 0 else "",plan.statChange.stages]
	if plan.side != null: target_info.text += " · " + {"front": "frente", "flank": "flanco", "rear": "espalda"}[plan.side]
	if plan.heal: target_info.text += "\nRecupera %d PS" % plan.heal
	if plan.get("recoil",0)>0: target_info.text += "\nCoste propio previsto: −%d PS" % plan.recoil
	for change: Dictionary in plan.get("changes",[]): target_info.text += "\n%s: %s%d etapas%s" % [Indicators.STATS[change.stat][1],"+" if change.stages>0 else "",change.stages," propias" if plan.get("changesSelf",false) else ""]
	if plan.has("volatile"): target_info.text += "\n%s: %d %% · %d turnos" % [_status_name(plan.volatile.kind),plan.volatile.chance,plan.volatile.duration]
	if plan.get("clearStages",false): target_info.text += "\nElimina las etapas de atributos del objetivo."
	if plan.get("sturdy",false): target_info.text += "\nRobustez puede dejarlo en 1 PS."
	if plan.get("staticChance",0)>0: target_info.text += "\nElec. Estática: 30 % al contacto."
	var passive_hints: Array = plan.get("abilityHints",[])+plan.get("accuracyHints",[])
	if not passive_hints.is_empty(): target_info.text += "\nHabilidad: "+", ".join(passive_hints)
	if plan.guard: target_info.text += "\nProtege hasta su próximo turno."
	if plan.status != null: target_info.text += "\n%s: %d %% · %d turnos" % [_status_name(plan.status.kind), plan.status.chance, plan.status.duration]
	if plan.push != null: target_info.text += "\nEmpuja a " + Rules.coordinate(plan.push)
	elif plan.pushReason != null: target_info.text += "\n" + plan.pushReason
	for hit in plan.hits:
		if hit.targetId != unit.id: target_info.text += "\n%s: %d PS · %d %%" % [Rules.unit_by_id(state, int(hit.targetId)).name, hit.damage, hit.accuracy]
	if not plan.embers.is_empty(): target_info.text += "\nDeja ascuas en el área."
	board.affected = plan.tiles
	board.forecast_hits = plan.hits
	if not plan.get("approach",{}).is_empty(): board.route = plan.approach.path

func _hover_tile(point: Dictionary):
	if state.is_empty() or _modal_open() or not pending.is_empty(): return
	board.route = []
	board.affected = []
	board.forecast_hits = []
	board.facing_preview = -1
	hint.text = _default_hint()
	if point.is_empty(): return
	var unit = _unit_at(point)
	if _player_turn() and selecting == "finish":
		if not Movement.same(Rules.active(state), point): board.facing_preview = Movement.facing_from(Rules.active(state), point)
		return
	if not unit.is_empty():
		target_id = int(unit.id)
		target_panel.visible = true
		target_portrait.texture = faces[int(unit.speciesId)]
		if _player_turn() and not state.acted:
			_show_plan(unit, rules.attack_plan(state, int(unit.id), {}, selected_action))
		else:
			target_indicators.show_unit(unit)
			target_info.text = "%s · %d / %d PS\n%s\n%d PT · velocidad %d\n%s" % [unit.name, unit.hp, unit.maxHp, _type_names(unit.types), unit.tp, unit.speed, _status_name(unit.status.kind) if unit.status != null else "Sin estado"]
			if unit.has("abilityName"):
				target_info.text += "\n"+unit.abilityName
				target_info.tooltip_text = unit.natureText+"\n"+unit.abilityDescription
	elif board.available.has(Movement.key(point)):
		target_panel.visible = false
		var route = board.available[Movement.key(point)]
		board.route = route.path
		hint.text = "%s · coste %d. Clic para desplazarte. Puedes atravesar aliados." % [Rules.coordinate(point), route.cost]
	else:
		target_panel.visible = false
		var terrain = int(state.board[int(point.y)][int(point.x)])
		hint.text = "%s · %s\n%s" % [Rules.coordinate(point), {0: "Suelo", 1: "Maleza", 2: "Roca", 3: "Agua"}[terrain], "Fuera del alcance de movimiento." if _player_turn() else "Inspección del terreno."]

func _preview_self(identity: String):
	if not _player_turn() or _modal_open() or not pending.is_empty() or state.acted: return
	var actor = Rules.active(state)
	var definition = rules.profile(actor).action(actor, identity).definition
	if definition.target == "self": _show_plan(actor, rules.attack_plan(state, int(actor.id), {}, identity))

func _select_tile(point: Dictionary):
	if state.is_empty() or _modal_open() or not pending.is_empty(): return
	_hover_tile(point)
	if not _player_turn(): return
	var actor = Rules.active(state)
	if selecting == "finish":
		if not Movement.same(actor, point): _set_facing(Movement.facing_from(actor, point))
		return
	var unit = _unit_at(point)
	if not unit.is_empty():
		if state.acted: return
		var plan = rules.attack_plan(state, int(unit.id), {}, selected_action)
		if not plan.ok:
			hint.text = plan.reason
			return
		var command = {"kind": "attack", "target": unit.id, "actionId": selected_action}
		if _friendly_risk(plan):
			pending = command
			_refresh()
			_show_plan(unit, plan)
			hint.text = "También alcanza a aliados. Confirma el ataque o pulsa Esc."
			buttons.confirm.grab_focus()
		else: _commit(command)
	elif selecting == "auto" and not state.moved:
		var result = rules.move(state, {"x": point.x, "y": point.y})
		if result.ok: _commit({"kind": "move", "destination": {"x": point.x, "y": point.y}})
		else: hint.text = result.reason

func _select_finish():
	if not _player_turn() or _modal_open() or not pending.is_empty(): return
	selecting = "finish"
	action_page = false
	_refresh()
	board.grab_focus()

func _preview_facing(facing: int):
	if _player_turn() and pending.is_empty(): board.facing_preview = facing

func _set_facing(facing: int):
	if not _player_turn() or _modal_open() or not pending.is_empty(): return
	_commit({"kind": "finish", "facing": facing})

func _cancel():
	if _modal_open(): return
	pending = {}
	selecting = "auto"
	action_page = false
	selected_action = "basic"
	_refresh()
	board.grab_focus()

func _confirm():
	if pending.is_empty() or not _player_turn() or _modal_open(): return
	_commit(pending.duplicate(true))

func _commit(command: Dictionary):
	var before: Dictionary = state
	var plan: Dictionary = rules.attack_plan(state,int(command.target),{},command.get("actionId","basic")) if command.kind == "attack" else {}
	var result = rules.apply_command(state, command)
	if not result.ok:
		hint.text = result.reason
		return
	state = result.state
	history.append(command.duplicate(true))
	pending = {}
	action_page = false
	selected_action = "basic"
	selecting = "finish" if _player_turn() and state.moved and state.acted else "auto"
	_save() # Persist accepted orders before presentation or sound.
	_refresh()
	board.grab_focus()
	if command.kind == "attack": combat_feedback.present(before,plan,result.get("hits",[]))
	_play("victory" if state.outcome == "victory" else (combat_feedback.last_sound if command.kind == "attack" else "select"))

func _play(name: String):
	last_sound_requested = name
	if muted or qa_running or not AUDIO.has(name): return
	sound.stream = AUDIO[name]
	sound.play()

func _toggle_sound():
	muted = not muted
	menu.get_popup().set_item_checked(menu.get_popup().get_item_index(4), not muted)
	if muted: sound.stop()

func _toggle_motion():
	reduced_motion = not reduced_motion
	board.reduced_motion = reduced_motion
	menu.get_popup().set_item_checked(menu.get_popup().get_item_index(5), not reduced_motion)

func _status_name(kind: String) -> String:
	return {"burn":"Quemadura","poison":"Veneno","paralysis":"Parálisis","sleep":"Sueño","freeze":"Congelación","confusion":"Confusión","seed":"Drenadoras"}.get(kind,kind)

func _type_names(types: Array) -> String:
	return " / ".join(types.map(func(type): return TYPE_NAMES.get(type, type)))

func _unhandled_key_input(event):
	if not event is InputEventKey or not event.pressed or event.echo: return
	if _modal_open(): return
	match event.keycode:
		KEY_ESCAPE: _cancel()
		KEY_M: _select_movement()
		KEY_A: _open_actions()
		KEY_R: _rectify_movement()
		KEY_F: _select_finish()
		KEY_F8: _load_game()
		KEY_F1: menu.show_popup()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			if not _player_turn(): return
			var index = event.keycode - KEY_1
			var entries = rules.profile(Rules.active(state)).actions_for(Rules.active(state))
			if index < entries.size(): _select_action(entries[index].definition.id)
		_: return
	get_viewport().set_input_as_handled()

func _run_qa():
	await Qa.new().run(self, qa_dir)
