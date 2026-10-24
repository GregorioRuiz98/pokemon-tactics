extends Control

const SpatialInput = preload("res://ui/spatial_interaction.gd")
var spatial_axis: int = 0
var spatial_throw: int = 0

const GameSkin = preload("res://ui/game_skin.gd")
const GameButton = preload("res://ui/game_button.gd")
const Rules = preload("res://core/battle.gd")
const Movement = preload("res://core/movement.gd")
const Store = preload("res://core/save_store.gd")
const Board = preload("res://ui/board.gd")
const Indicators = preload("res://ui/unit_indicators.gd")
const Revision = preload("res://core/movement_revision.gd")
const Qa = preload("res://ui/qa_driver.gd")
const InputProfile = preload("res://ui/input_profile.gd")
const FocusMemory = preload("res://ui/focus_memory.gd")
var input_profile: RefCounted
var tactical_reader: AcceptDialog
var recent_result: String = "Todavía no hay un resultado en esta sesión; consulta el registro guardado."
var presentation_dialog: AcceptDialog
var font_update_queued: bool = false
var hover_context: Array = []
var actions_scroll: ScrollContainer
var controls_dialog: AcceptDialog
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
var facing_choice: int = -1
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
var actor_title: Label
var actor_tp: ProgressBar
var actor_hp: ProgressBar
var faces: Dictionary = {}
var direction_buttons: Dictionary = {}
var board
var battle_chrome: Control
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
var combat_sound: Node
var combat_feedback: Control
var last_sound_requested: String = ""
const Feedback = preload("res://ui/combat_feedback.gd")
const AUDIO = {"select":preload("res://assets/audio/select.wav"),"hit":preload("res://assets/audio/hit.wav"),"victory":preload("res://assets/audio/victory.wav"),"miss":preload("res://assets/audio/miss.wav"),"immune":preload("res://assets/audio/immune.wav"),"level-up":preload("res://assets/audio/level-up.wav")}

func _ready():
	var preferences_path: String = "user://controls.json"
	for argument: String in OS.get_cmdline_user_args():
		if argument.contains("qa-dir="): preferences_path = argument.get_slice("=",1).path_join("controls-%d.json" % Time.get_ticks_usec())
	input_profile = InputProfile.new(preferences_path)
	muted = input_profile.preferences.muted
	reduced_motion = input_profile.preferences.reducedMotion
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
	controls_dialog = load("res://ui/controls_dialog.gd").new()
	add_child(controls_dialog)
	controls_dialog.setup(self,input_profile)
	for dialog: Window in [new_dialog,help_dialog,credits_dialog,details_dialog,controls_dialog,menu.get_popup()]: _watch_dialog(dialog)
	get_window().focus_exited.connect(func(): input_profile.held.clear(); board.cancel_pointer())
	tactical_reader = load("res://ui/tactical_reader.gd").new()
	add_child(tactical_reader)
	tactical_reader.setup(self)
	_watch_dialog(tactical_reader)
	_input_labels()
	sound = AudioStreamPlayer.new()
	sound.volume_db = -15
	add_child(sound)
	combat_sound = preload("res://ui/combat_audio.gd").new()
	add_child(combat_sound)
	combat_feedback = Feedback.new()
	combat_feedback.board = board
	add_child(combat_feedback)
	combat_feedback.attack_effect.cue_requested.connect(_play_attack_cue)
	combat_feedback.attack_effect.cancelled.connect(combat_sound.stop)
	_apply_preferences()
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
	GameSkin.install(theme)

func _label(text: String, font_size: int = 18, color: Color = CREAM) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, callback: Callable, minimum: float = 0) -> Button:
	var button: Button = GameButton.new()
	button.text = text
	button.custom_minimum_size = Vector2(minimum, 44)
	button.pressed.connect(callback)
	return button

func _panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GameSkin.panel())
	return panel

func _clear(container: Node):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _build_interface() -> void:
	# Overlay layout adapted from the Godot skill HUD template; the laboratory
	# already owns state/signals, so it needs no extra manager or autoload.
	board = _make_board()
	board.input_profile = input_profile
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.setup(rules.data.species)
	board.tile_selected.connect(_select_tile)
	board.tile_hovered.connect(_hover_tile)
	board.cancelled.connect(_cancel)
	board.facing_changed.connect(_preview_facing)
	board.facing_accepted.connect(func():
		if selecting=="finish": _set_facing(facing_choice))
	add_child(board)
	var overlay: Control = Control.new()
	battle_overlay = overlay
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	battle_chrome = load("res://ui/battle_frame.gd").new()
	battle_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(battle_chrome)
	battle_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	menu.theme_type_variation = "ToolButton"
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
	popup.add_item("Controles", 9)
	popup.add_item("Presentación y accesibilidad",12)
	popup.add_item("Inspeccionar unidad · I",10)
	popup.add_item("Último resultado · L",11)
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
	command_heading = _label("ÓRDENES", 18, GOLD)
	command_content.add_child(command_heading)
	main_commands = VBoxContainer.new()
	main_commands.add_theme_constant_override("separation", 8)
	command_content.add_child(main_commands)
	buttons["actions"] = _button("Habilidades · A", _open_actions)
	buttons["undo"] = _button("Rectificar movimiento · R", _rectify_movement)
	buttons.undo.add_theme_font_size_override("font_size", 16)
	buttons["finish"] = _button("Orientar y terminar · F", _select_finish)
	for button: Button in [buttons.actions, buttons.undo, buttons.finish]:
		button.theme_type_variation = "CommandButton"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		main_commands.add_child(button)
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	actions_scroll = ScrollContainer.new()
	actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	actions_scroll.follow_focus = true
	command_content.add_child(actions_scroll)
	actions_scroll.add_child(actions)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	directions = HBoxContainer.new()
	command_content.add_child(directions)
	for facing: int in Rules.FACINGS:
		var names: Dictionary = {4: "↑", 2: "→", 0: "↓", 6: "←"}
		var full_names: Dictionary = {4: "norte", 2: "este", 0: "sur", 6: "oeste"}
		var button: Button = _button(names[facing], _set_facing.bind(facing), 44)
		button.tooltip_text = "Terminar el turno mirando al " + full_names[facing]
		button.mouse_entered.connect(_preview_facing.bind(facing))
		button.toggle_mode = true
		directions.add_child(button)
		direction_buttons[facing] = button
	buttons["confirm"] = _button("Sí, atacar", _confirm)
	buttons["cancel"] = _button("Volver · Esc", _cancel)
	buttons.confirm.theme_type_variation = "PrimaryButton"
	buttons.cancel.theme_type_variation = "CommandButton"
	command_content.add_child(buttons.confirm)
	command_content.add_child(buttons.cancel)
	var actor_panel: PanelContainer = _panel()
	_pin(actor_panel, overlay, Control.PRESET_BOTTOM_LEFT, Vector2(360, 162))
	var actor_details: VBoxContainer = VBoxContainer.new()
	actor_panel.add_child(actor_details)
	actor_title = _label("EN TURNO", 16, GOLD)
	actor_details.add_child(actor_title)
	var actor_row: HBoxContainer = HBoxContainer.new()
	actor_row.add_theme_constant_override("separation", 16)
	actor_details.add_child(actor_row)
	actor_portrait = _portrait(Vector2(80, 80))
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
	actor_tp = ProgressBar.new()
	actor_tp.show_percentage = false
	actor_tp.custom_minimum_size.y = 6
	var tp_fill: StyleBoxFlat = StyleBoxFlat.new()
	tp_fill.bg_color = Color("78b5d6")
	actor_tp.add_theme_stylebox_override("fill",tp_fill)
	actor_tp.add_theme_stylebox_override("background",hp_background)
	vitals.add_child(actor_tp)
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
	target_scroll.custom_minimum_size.y = 148
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
	_focus_actions.call_deferred()

func _focus_actions() -> void:
	if _modal_open() or not action_page: return
	for button: Button in action_buttons.values():
		if FocusMemory.eligible(button): button.grab_focus(); return

func _can_rectify() -> bool:
	return not state.get("movementLocked",false) and pending.is_empty() and Revision.available(state, history)

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
	if identity==12: _open_presentation(); return
	if identity==10: _inspect(); return
	if identity==11: _last_result(); return
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
		9: _open_controls()

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
	if presentation_dialog!=null and presentation_dialog.visible: return true
	if tactical_reader!=null and tactical_reader.visible: return true
	return new_dialog.visible or help_dialog.visible or credits_dialog.visible or details_dialog.visible or menu.get_popup().visible or (controls_dialog!=null and controls_dialog.visible)

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
	if combat_feedback.attack_effect.active: return
	var actor = Rules.active(state)
	if actor.team == "enemy":
		ai_clock += delta
		if ai_clock >= (0.1 if reduced_motion else 0.45):
			ai_clock = 0
			_commit(rules.choose_command(state))

func _player_turn() -> bool:
	return not state.is_empty() and state.outcome == "playing" and Rules.active(state).team == "ally"

func _refresh():
	hover_context.clear()
	var focused_action: String = ""
	for identity: String in action_buttons:
		if action_buttons[identity]==get_viewport().gui_get_focus_owner(): focused_action = identity
	_clear(timeline)
	_clear(actions)
	action_buttons.clear()
	board.state = state
	if board.has_method("invalidate_terrain"): board.invalidate_terrain()
	board.available = {}
	board.attackable = {}
	board.route = []
	board.affected = []
	board.forecast_hits = []
	board.facing_mode = selecting=="finish" and _player_turn() and pending.is_empty()
	if board.facing_mode and board.get("camera_mode")==true: board.toggle_camera()
	if board.facing_mode and facing_choice<0: facing_choice = int(Rules.active(state).facing)
	if not board.facing_mode: facing_choice = -1
	board.facing_preview = facing_choice
	board.reduced_motion = reduced_motion
	menu.get_popup().set_item_disabled(menu.get_popup().get_item_index(1), not FileAccess.file_exists(store.file_path))
	saved.text = "Guardado local" if save_warning.is_empty() else "¡Sin guardar!"
	saved.tooltip_text = save_warning
	saved.add_theme_color_override("font_color", MUTED if save_warning.is_empty() else GOLD)
	command_panel.visible = _player_turn()
	var menu_height: float = minf(size.y - 160,170 + 54 * (rules.profile(Rules.active(state)).actions_for(Rules.active(state)).size() if not state.is_empty() and state.outcome == "playing" else 3)) if action_page else (170 if selecting in ["attack", "finish"] or not pending.is_empty() else 240)
	if not command_panel.get_parent() is Container:
		command_panel.offset_top = -menu_height / 2
		command_panel.offset_bottom = menu_height / 2
	main_commands.visible = pending.is_empty() and selecting == "auto" and not action_page
	actions.visible = action_page and pending.is_empty()
	actions_scroll.visible = actions.visible
	actions_scroll.custom_minimum_size.y = 230 if actions.visible else 0
	if action_page and not command_panel.get_parent() is Container:
		command_panel.offset_top = -120
		command_panel.offset_bottom = 180
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
	for facing: int in direction_buttons:
		direction_buttons[facing].disabled = not _player_turn()
		direction_buttons[facing].set_pressed_no_signal(facing==facing_choice)
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
	actor_title.text = "EN TURNO  /  " + ("RIVAL" if actor.team=="enemy" else "TU EQUIPO")
	actor_tp.max_value = actor.maxTp
	actor_tp.value = actor.tp
	actor_info.text = "%s%s\n%d / %d PS\n%d / %d PT\n%s · %s" % [actor.name, " · IA" if actor.team == "enemy" else "", actor.hp, actor.maxHp, actor.tp, actor.maxTp, "Mov. usado" if state.moved else "Mov. %d" % actor.remaining, "Acc. usada" if state.acted else "Acc. lista"]
	if actor.has("abilityName"): actor_info.text += "\n"+actor.abilityName
	for index in rules.profile(actor).actions_for(actor).size():
		var definition = rules.profile(actor).actions_for(actor)[index].definition
		var button = _button("%d · %s\n%d PT · %d cas." % [index + 1, definition.name, definition.cost, definition.range], _select_action.bind(definition.id))
		if actor.get("recoveryPP",{}).has(definition.id): button.text += " · %d/5 usos" % actor.recoveryPP[definition.id]
		button.theme_type_variation = "CommandButton"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not _player_turn() or state.acted or actor.tp < definition.cost or not pending.is_empty()
		if actor.get("recoveryPP",{}).has(definition.id): button.disabled = button.disabled or actor.recoveryPP[definition.id]<=0
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
			if SpatialInput.enabled(self) and selecting=="attack":
				for point: Dictionary in rules.aim_points(state,selected_action):
					if rules.cast_plan(state,SpatialInput.aim(self,point),selected_action).ok: board.attackable[Movement.key(point)] = true
			else:
				for unit in Rules.living(state):
					if rules.attack_plan(state, int(unit.id), {}, selected_action).ok: board.attackable[Movement.key(unit)] = true
	target_info.text = "Pasa el cursor por una unidad\npara ver la previsión.\n\nAzul: puedes moverte.\nMarco coral: puedes atacar."
	hint.text = _default_hint()
	board.queue_redraw()
	_input_labels()
	if not focused_action.is_empty() and action_page:
		var replacement: Control = action_buttons.get(focused_action)
		if FocusMemory.eligible(replacement): replacement.grab_focus.call_deferred()

func interaction_context() -> String:
	# Existing selection fields remain the single source for presentation/input.
	if _modal_open(): return "modal"
	if not pending.is_empty(): return "confirmation"
	if selecting=="finish": return "facing"
	if action_page: return "ability_menu"
	if selecting=="attack": return "target_preview" if not board.affected.is_empty() or not _unit_at({"x":board.cursor.x,"y":board.cursor.y}).is_empty() else "ability_selected"
	if not board.forecast_hits.is_empty(): return "target_preview"
	if not board.route.is_empty(): return "movement_preview"
	return "board"

func _default_hint() -> String:
	if not save_warning.is_empty(): return save_warning
	if not _player_turn(): return "Turno rival…"
	if selecting == "finish": return "Flechas: orientar · Enter: terminar · Esc: volver.\n%s · %s" % ["Movimiento sin usar" if not state.moved else "Movimiento usado","Acción sin usar" if not state.acted else "Acción usada"]
	if selecting == "attack": return "%s: %s / %s cambia objetivo, Enter o clic acepta. Esc vuelve." % [rules.profile(Rules.active(state)).action(Rules.active(state), selected_action).definition.name,input_profile.label("previous_target"),input_profile.label("next_target")]
	if state.acted and state.moved: return "Turno listo. Elige una dirección para terminar."
	return "Clic en casilla: mover. Clic en rival: básico. Habilidades y fin de turno en el menú."

func _select_movement():
	if not _player_turn() or _modal_open(): return
	_cancel()

func _select_action(identity: String):
	if not _player_turn() or _modal_open() or state.acted or not pending.is_empty(): return
	var action = rules.profile(Rules.active(state)).action(Rules.active(state), identity)
	if action == null: return
	if Rules.active(state).tp < action.definition.cost: hint.text = "PT insuficientes para "+action.definition.name+"."; return
	action_page = false
	selected_action = identity
	if SpatialInput.enabled(self) and action.definition.get("special","")=="throw": spatial_throw = Rules.FACINGS.find(Rules.active(state).facing)
	selecting = "auto" if identity == "basic" else "attack"
	_refresh()
	board.grab_focus()
	if action.definition.target == "self":
		var actor: Dictionary = Rules.active(state)
		board.cursor = Vector2i(actor.x,actor.y)
		board.keyboard_control = true
		_hover_tile(actor)

func _cycle_target(step: int) -> void:
	if not _player_turn() or _modal_open() or state.acted or not pending.is_empty() or selecting=="finish": return
	if SpatialInput.rotate(self,step): return
	var valid: Array = Rules.living(state).filter(func(unit):return rules.attack_plan(state,int(unit.id),{},selected_action).ok)
	valid.sort_custom(func(a,b):return a.id<b.id)
	if valid.is_empty(): hint.text = "No hay objetivos válidos para esta acción."; return
	var index: int = -1
	for i: int in valid.size():
		if valid[i].x==board.cursor.x and valid[i].y==board.cursor.y: index = i; break
	index = (index+step+valid.size())%valid.size() if index>=0 else (0 if step>0 else valid.size()-1)
	var target: Dictionary = valid[index]
	board.cursor = Vector2i(target.x,target.y)
	board.keyboard_control = true
	if board.has_method("focus_point") and not board.play_area().grow(-45).has_point(board.center(target)): board.focus_point(target)
	_hover_tile(target)
	board.queue_redraw()

func _unit_at(point: Dictionary) -> Dictionary:
	for unit in Rules.living(state):
		if Movement.same(unit, point): return unit
	return {}

func _friendly_risk(plan: Dictionary) -> bool:
	return plan.get("hazardRisk",false) or plan.hits.any(func(hit):
		var unit: Dictionary = Rules.unit_by_id(state,int(hit.targetId))
		return unit.team=="ally" and (hit.damage>0 or hit.status!=null or hit.get("push")!=null or hit.get("volatile",{}).get("kind","") in ["confusion","seed"] or hit.get("changes",[]).any(func(c):return c.stages<0) or (hit.get("clearStages",false) and unit.stages.values().any(func(stage):return stage>0))))

func _action_risks(plan: Dictionary) -> Array[String]:
	var risks: Array[String] = []
	if _friendly_risk(plan): risks.append("Alcanza a aliados")
	var actor: Dictionary = Rules.active(state)
	var definition: Dictionary = rules.profile(actor).action(actor,selected_action).definition
	var cost: int = int(plan.get("recoil",0))
	var maximum: int = 0
	for hit: Dictionary in plan.hits: maximum += mini(Rules.unit_by_id(state,int(hit.targetId)).hp,maxi(hit.get("damageMax",hit.damage),hit.get("criticalMax",hit.damage)))
	if definition.get("selfKO",false): cost = actor.hp
	else:
		var recoil: int = 0 if actor.get("ability")=="rock-head" else int(floor(maximum*definition.get("recoil",0)/100.0))
		if actor.get("heldItem")=="life-orb" and maximum>0: recoil += maxi(1,int(actor.maxHp/10.0))
		cost = maxi(cost,recoil)
	if cost>=actor.hp: risks.append("El coste propio puede debilitar a "+actor.name)
	return risks

func _show_plan(unit: Dictionary, plan: Dictionary):
	target_portrait.visible = true
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

	target_info.set_meta("details",target_info.text)
	target_info.text = load("res://ui/tactical_info.gd").forecast(unit,plan)+( "\n¡Alcanza a aliados!" if plan.ok and _friendly_risk(plan) else "")+"\nFicha: "+input_profile.label("inspect")+" · detalle completo"

func _hover_tile(point: Dictionary) -> bool:
	if state.is_empty() or _modal_open() or not pending.is_empty(): return false
	var context: Array = [Vector2i(point.get("x",-1),point.get("y",-1)),selected_action,selecting,facing_choice]
	if context==hover_context: return false
	hover_context = context
	if not point.is_empty(): board.cursor = context[0]
	board.queue_redraw()
	board.route = []
	board.affected = []
	board.forecast_hits = []
	board.facing_preview = facing_choice if selecting=="finish" else -1
	hint.text = _default_hint()
	if point.is_empty(): return true
	var unit = _unit_at(point)
	if _player_turn() and selecting == "finish":
		if not Movement.same(Rules.active(state), point): _preview_facing(Movement.facing_from(Rules.active(state), point))
		return true
	if SpatialInput.enabled(self) and _player_turn() and selecting=="attack" and not state.acted:
		SpatialInput.preview(self,point)
		return true
	if not unit.is_empty():
		target_portrait.visible = true
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
	return true

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
	if SpatialInput.enabled(self) and selecting=="attack":
		SpatialInput.select(self,point)
		return
	var unit = _unit_at(point)
	if not unit.is_empty():
		if state.acted: return
		if SpatialInput.enabled(self): SpatialInput.select(self,point); return
		var plan = rules.attack_plan(state, int(unit.id), {}, selected_action)
		if not plan.ok:
			hint.text = plan.reason
			return
		var command = {"kind": "attack", "target": unit.id, "actionId": selected_action}
		var risks: Array[String] = _action_risks(plan)
		if not risks.is_empty() or input_profile.confirmation_mode=="safe":
			pending = command
			_refresh()
			_show_plan(unit, plan)
			hint.text = (" · ".join(risks)+".\n" if not risks.is_empty() else "")+"Confirma una vez para actuar; Esc cancela."
			buttons.confirm.text = "Confirmar acción"
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
	if board.get("camera_mode")==true: board.toggle_camera()
	_refresh()
	board.grab_focus()

func _preview_facing(facing: int):
	if _player_turn() and selecting=="finish" and pending.is_empty():
		facing_choice = facing
		board.facing_preview = facing
		for identity: int in direction_buttons: direction_buttons[identity].set_pressed_no_signal(identity==facing)

func _set_facing(facing: int):
	if not _player_turn() or _modal_open() or not pending.is_empty() or facing not in Rules.FACINGS: return
	_commit({"kind": "finish", "facing": facing})

func _cancel():
	if _modal_open(): return
	board.cancel_pointer()
	if board.get("camera_mode")==true: board.toggle_camera(); return
	if not pending.is_empty():
		pending = {}
		_refresh()
		_hover_tile({"x":board.cursor.x,"y":board.cursor.y})
		board.grab_focus()
		return
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
	var plan: Dictionary = _command_plan(state,command)
	var definition: Dictionary = _attack_definition(before,command)
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
	_remember_result(before,command,result.get("hits",[]))
	_present_combat(before,command,plan,result.get("hits",[]),definition,"victory" if state.outcome=="victory" else "")

func _command_plan(before: Dictionary, command: Dictionary) -> Dictionary:
	if command.kind!="attack": return {}
	if rules.has_method("cast_plan") and command.has("aim"): return rules.cast_plan(before,command.aim,command.get("actionId","basic"))
	return rules.attack_plan(before,int(command.target),{},command.get("actionId","basic"))

func _attack_definition(before: Dictionary, command: Dictionary) -> Dictionary:
	if command.kind!="attack": return {}
	var actor: Dictionary = Rules.active(before)
	var action: RefCounted = rules.profile(actor).action(actor,command.get("actionId","basic"))
	return action.definition.duplicate(true) if action!=null else {}

func _present_combat(before: Dictionary, command: Dictionary, plan: Dictionary, receipts: Array, definition: Dictionary, ending: String = "") -> void:
	if command.kind=="attack":
		combat_feedback.present(before,plan,receipts,definition)
		last_sound_requested = combat_feedback.last_sound
		# A final blow already transitions the campaign; preserve its outcome cue.
		if not board.visible:
			var sound_profile: Dictionary = preload("res://ui/attack_effect.gd").describe(definition)
			_play_attack_cue(sound_profile.cue if sound_profile.cue.begins_with("original/") else (combat_feedback.last_sound if combat_feedback.last_sound!="hit" else "impact"))
	else:
		combat_feedback.attack_effect.stop()
		_play("select" if ending.is_empty() else ending)
	if command.kind=="attack" and not ending.is_empty(): _play(ending)

func _play_attack_cue(identity: String) -> void:
	combat_sound.play_cue(identity,float(input_profile.preferences.volume),muted or qa_running)

func _open_presentation() -> void:
	if presentation_dialog==null:
		presentation_dialog = load("res://ui/preferences_dialog.gd").new()
		add_child(presentation_dialog)
		presentation_dialog.setup(self)
		_watch_dialog(presentation_dialog)
	_apply_preferences()
	presentation_dialog.popup_centered(Vector2i(700,570))

func _apply_preferences() -> void:
	font_update_queued = false
	if not is_inside_tree(): return
	if has_method("_layout_battle_hud") and actor_portrait!=null: call("_layout_battle_hud")
	load("res://ui/presentation_settings.gd").apply(self)
	if get("accessible_view")!=null: get("accessible_view").request_update(true)
	if menu!=null:
		menu.get_popup().set_item_checked(menu.get_popup().get_item_index(4),not muted)
		menu.get_popup().set_item_checked(menu.get_popup().get_item_index(5),not reduced_motion)

func _reset_readability() -> void:
	input_profile.set_preference("textScale",100)
	input_profile.set_preference("highContrast",false)
	for child: Node in get_children():
		if child is Window: child.hide()
	_apply_preferences()
	_refresh()
	_default_focus.call_deferred()

func _inspect() -> void:
	if not state.is_empty() and not _modal_open(): tactical_reader.open_unit()

func _last_result() -> void:
	if not state.is_empty() and not _modal_open(): tactical_reader.open_history()

func _remember_result(before: Dictionary, command: Dictionary, receipts: Array) -> void:
	recent_result = before.log.back() if not before.get("log",[]).is_empty() else ""
	if command.kind=="attack":
		var actor: Dictionary = Rules.active(before)
		recent_result = actor.name+" · "+command.get("actionId","basic")
		for receipt: Dictionary in receipts:
			var target: Dictionary = Rules.unit_by_id(before,int(receipt.targetId))
			recent_result += "\n%s: %s%s" % [target.name,"FALLO" if not receipt.hit else "%d PS reales" % receipt.damage," · CRÍTICO" if receipt.get("critical",false) else ""]
	else: recent_result = "\n".join(state.get("log",[]).slice(-6))

	if get("accessible_view")!=null and input_profile.preferences.accessibleMode:
		get("accessible_view").announce("Resultado: "+recent_result)

func _play(name: String):
	last_sound_requested = name
	if muted or qa_running or not AUDIO.has(name): return
	sound.stream = AUDIO[name]
	sound.play()

func _toggle_sound():
	input_profile.set_preference("muted",not muted)
	muted = input_profile.preferences.muted
	menu.get_popup().set_item_checked(menu.get_popup().get_item_index(4), not muted)
	if muted: sound.stop()
	if muted: combat_sound.stop()

func _toggle_motion():
	input_profile.set_preference("reducedMotion",not reduced_motion)
	reduced_motion = input_profile.preferences.reducedMotion
	board.reduced_motion = reduced_motion
	menu.get_popup().set_item_checked(menu.get_popup().get_item_index(5), not reduced_motion)

func _status_name(kind: String) -> String:
	return {"burn":"Quemadura","poison":"Veneno","paralysis":"Parálisis","sleep":"Sueño","freeze":"Congelación","confusion":"Confusión","seed":"Drenadoras"}.get(kind,kind)

func _type_names(types: Array) -> String:
	return " / ".join(types.map(func(type): return TYPE_NAMES.get(type, type)))

func _unhandled_key_input(event):
	if not event is InputEventKey or not event.pressed or event.echo: return
	if _modal_open(): return
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit: return
	if input_profile.matches(event,"cancel"): _cancel()
	elif input_profile.matches(event,"movement"): _select_movement()
	elif input_profile.matches(event,"abilities"): _open_actions()
	elif input_profile.matches(event,"rectify"): _rectify_movement()
	elif input_profile.matches(event,"finish"): _select_finish()
	elif input_profile.matches(event,"load"): _load_game()
	elif input_profile.matches(event,"menu"): menu.show_popup()
	elif input_profile.matches(event,"controls"): _open_controls()
	elif input_profile.matches(event,"inspect"): _inspect()
	elif input_profile.matches(event,"result"): _last_result()
	elif input_profile.matches(event,"panel"): _cycle_panel(event.shift_pressed)
	elif input_profile.matches(event,"previous_target") or input_profile.matches(event,"next_target"):
		if focused!=board: return
		_cycle_target(-1 if input_profile.matches(event,"previous_target") else 1)
	else:
		var found: bool = false
		for index: int in 5:
			if not input_profile.matches(event,"slot"+str(index+1)): continue
			if not _player_turn(): return
			var entries: Array = rules.profile(Rules.active(state)).actions_for(Rules.active(state))
			if index < entries.size(): _select_action(entries[index].definition.id)
			found = true
			break
		if not found: return
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if input_profile==null: return
	if event is InputEventKey and event.pressed and event.keycode==KEY_F12:
		_reset_readability(); get_viewport().set_input_as_handled(); return
	_guard_input(event,get_viewport())

func _guard_input(event: InputEvent, viewport: Viewport) -> void:
	if get("batch_busy")==true:
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: get("shop_batch").stop_requested = true
		viewport.set_input_as_handled()
		return
	if event.has_meta("tactics_guarded"): return
	event.set_meta("tactics_guarded",true)
	var focused: Control = viewport.gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit: return
	if event is InputEventMouseButton and event.pressed and event.double_click:
		viewport.set_input_as_handled()
		return
	if not input_profile.allow(event): viewport.set_input_as_handled()

func _watch_dialog(dialog: Window) -> void:
	var origin: Dictionary = {}
	dialog.about_to_popup.connect(func():
		board.cancel_pointer()
		var viewport: Viewport = dialog.get_parent() if dialog.get_parent() is Window else get_viewport()
		var focused: Control = viewport.gui_get_focus_owner()
		origin["focus"] = weakref(focused) if focused!=null else null)
	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			input_profile.held.clear()
			_restore_dialog_focus.call_deferred(origin))
	dialog.window_input.connect(func(event: InputEvent): _dialog_input(event,dialog))
	var listener: Node = load("res://ui/dialog_input.gd").new()
	listener.handler = func(event: InputEvent): _dialog_input(event,dialog)
	dialog.add_child(listener)

func _dialog_input(event: InputEvent, dialog: Window) -> void:
	if not dialog.visible: return
	if event is InputEventKey and event.pressed and event.keycode==KEY_F12:
		_reset_readability(); dialog.set_input_as_handled(); return
	_guard_input(event,dialog)
	if dialog.is_input_handled(): return
	if dialog is AcceptDialog and dialog!=controls_dialog and input_profile.matches(event,"cancel"):
		dialog.set_input_as_handled()
		dialog.canceled.emit()
		dialog.hide()

func _restore_dialog_focus(origin: Dictionary) -> void:
	if not is_inside_tree(): return
	var focused: Control = origin.focus.get_ref() if origin.get("focus")!=null else null
	if FocusMemory.eligible(focused): focused.grab_focus()
	elif not _modal_open(): _default_focus()

func _default_focus() -> void:
	if board.visible: board.grab_focus()

func _open_controls() -> void:
	if controls_dialog!=null: controls_dialog.popup_centered(Vector2i(700,640))

func _cycle_panel(_backwards: bool = false) -> void:
	if not board.visible: return
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused==board:
		if action_page: _focus_actions()
		elif directions.visible:
			for button: Button in direction_buttons.values():
				if FocusMemory.eligible(button): button.grab_focus(); return
		else:
			for button: Button in [buttons.confirm,buttons.actions,buttons.finish,buttons.cancel]:
				if FocusMemory.eligible(button): button.grab_focus(); return
	else: board.grab_focus()

func _input_labels() -> void:
	if not font_update_queued:
		font_update_queued = true
		_apply_preferences.call_deferred()
	if menu==null: return
	menu.text = input_profile.shortcut("Menú","menu")
	var popup: PopupMenu = menu.get_popup()
	popup.set_item_text(popup.get_item_index(1),input_profile.shortcut("Recuperar guardado","load"))
	popup.set_item_text(popup.get_item_index(9),input_profile.shortcut("Controles","controls"))
	for entry: Array in [[10,"Ficha","inspect"],[11,"Último resultado","result"],[13,"Aprender / salir","practice"],[14,"Glosario","glossary"]]:
		if popup.get_item_index(entry[0])>=0: popup.set_item_text(popup.get_item_index(entry[0]),input_profile.shortcut(entry[1],entry[2]))
	for entry: Array in [["actions","Habilidades","abilities"],["undo","Rectificar movimiento","rectify"],["finish","Orientar y terminar","finish"],["cancel","Volver","cancel"]]:
		buttons[entry[0]].text = input_profile.shortcut(entry[1],entry[2])
	var index: int = 1
	for button: Button in action_buttons.values():
		var separator: int = button.text.find(" · ")
		if separator>=0: button.text = input_profile.label("slot"+str(index))+button.text.substr(separator)
		index += 1
	if help_dialog!=null:
		help_dialog.dialog_text = "Un movimiento y una acción, en cualquier orden.\nClic en casilla: mover. Clic en rival: básico neutro.\nHabilidades: %s. Ranuras: %s / %s / %s / %s / %s.\nElegir habilidad solo prepara; Enter o clic la ejecuta.\n%s/%s recorre objetivos. Modos Rápido/Seguro en Controles.\nSiempre se avisa de aliados o coste propio letal.\n\nRectificar: %s, solo movimiento y antes de actuar.\nNo recupera PS, PT, ataques, estados o tiradas.\nOrientar y terminar: %s; flechas y Enter confirman.\nCámara: cruceta o modo %s; %s centra.\nAliados atravesables;\ndestinos ocupados no válidos.\n\nFlechas y Enter/Espacio siempre disponibles.\nTab / Mayús+Tab: controles. %s: cambiar panel.\nEscape o derecho: volver. %s: recuperar guardado.\n%s: reasignar controles. Guardado local por orden." % [input_profile.label("abilities"),input_profile.label("slot1"),input_profile.label("slot2"),input_profile.label("slot3"),input_profile.label("slot4"),input_profile.label("slot5"),input_profile.label("previous_target"),input_profile.label("next_target"),input_profile.label("rectify"),input_profile.label("finish"),input_profile.label("camera_mode"),input_profile.label("center"),input_profile.label("panel"),input_profile.label("load"),input_profile.label("controls")]

func _run_qa():
	await Qa.new().run(self, qa_dir)
