extends Control

const Rules = preload("res://core/battle.gd")
const Movement = preload("res://core/movement.gd")
const Store = preload("res://core/save_store.gd")
const Board = preload("res://ui/board.gd")
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
var selecting = "inspect"
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
var direction_buttons: Dictionary = {}
var board
var timeline: HBoxContainer
var roster: VBoxContainer
var actor_info: Label
var target_info: Label
var journal: Label
var heading: Label
var hint: Label
var saved: Label
var actions: HBoxContainer
var directions: HBoxContainer
var new_dialog: ConfirmationDialog
var help_dialog: AcceptDialog
var credits_dialog: AcceptDialog
var seed_input: LineEdit
var composition_input: OptionButton
var mode_input: OptionButton
var variance_input: OptionButton
var sound: AudioStreamPlayer

func _ready():
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-dir="): qa_dir = argument.trim_prefix("--qa-dir=")
	qa_running = not qa_dir.is_empty()
	if qa_running: DirAccess.make_dir_recursive_absolute(qa_dir)
	store = Store.new(qa_dir.path_join("ui-save.json") if qa_running else "user://laboratory-save.json")
	for record in rules.data.species: portraits[int(record.id)] = load("res://assets/pokemon/%d/thumbnail.png" % record.id)
	_make_theme()
	_build_interface()
	_build_dialogs()
	sound = AudioStreamPlayer.new()
	sound.volume_db = -15
	add_child(sound)
	_refresh()
	if qa_running:
		call_deferred("_run_qa")
	elif FileAccess.file_exists(store.file_path):
		_load_game()
	else:
		new_dialog.popup_centered()

func _make_theme():
	theme = Theme.new()
	theme.default_font = load("res://assets/fonts/PixelifySans.ttf")
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_disabled_color", "Button", Color("718273"))
	for type in ["Button", "OptionButton"]:
		for entry in ["normal", "hover", "pressed", "disabled", "focus"]:
			var style = StyleBoxFlat.new()
			style.bg_color = Color("273d30") if entry == "normal" else (Color("344b37") if entry == "hover" else Color("17291e"))
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
	button.custom_minimum_size.x = minimum
	button.pressed.connect(callback)
	return button

func _panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("17291f")
	style.border_color = Color("455541")
	style.set_border_width_all(1)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _clear(container: Node):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _build_interface():
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 18)
	add_child(margin)
	var main = VBoxContainer.new()
	main.add_theme_constant_override("separation", 10)
	margin.add_child(main)
	var header = HBoxContainer.new()
	main.add_child(header)
	var brand = _label("POKÉMON  /  TACTICS", 28, GOLD)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	header.add_child(_label("LABORATORIO 13", 16, MUTED))
	buttons["new"] = _button("Nuevo ensayo", func(): new_dialog.popup_centered())
	header.add_child(buttons.new)
	buttons["load"] = _button("Continuar · F8", _load_game)
	header.add_child(buttons.load)
	buttons["help"] = _button("?", func(): help_dialog.popup_centered(Vector2i(630, 450)))
	header.add_child(buttons.help)
	var subheader = HBoxContainer.new()
	main.add_child(subheader)
	heading = _label("Ensayo 3 contra 3 · preparación", 18)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subheader.add_child(heading)
	saved = _label("Guardado local", 15, MUTED)
	subheader.add_child(saved)
	timeline = HBoxContainer.new()
	timeline.add_theme_constant_override("separation", 8)
	main.add_child(timeline)
	var middle = HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 12)
	main.add_child(middle)
	var left = _panel()
	left.custom_minimum_size.x = 200
	middle.add_child(left)
	var left_content = VBoxContainer.new()
	left_content.add_theme_constant_override("separation", 12)
	left.add_child(left_content)
	left_content.add_child(_label("TU EQUIPO", 18, GOLD))
	roster = VBoxContainer.new()
	roster.add_theme_constant_override("separation", 10)
	left_content.add_child(roster)
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_content.add_child(spacer)
	var legend = _label("SUELO · coste 1\nMALEZA · coste 2*\nAGUA · acuáticos/voladores\nROCA · bloquea el paso\n\n* Planta y voladores: 1", 15, MUTED)
	left_content.add_child(legend)
	board = Board.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.setup(rules.data.species)
	board.tile_selected.connect(_select_tile)
	middle.add_child(board)
	var right = _panel()
	right.custom_minimum_size.x = 224
	middle.add_child(right)
	var right_content = VBoxContainer.new()
	right_content.add_theme_constant_override("separation", 10)
	right.add_child(right_content)
	right_content.add_child(_label("LECTURA TÁCTICA", 18, GOLD))
	var target_scroll = ScrollContainer.new()
	target_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	target_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	target_scroll.custom_minimum_size.y = 110
	target_scroll.focus_mode = Control.FOCUS_ALL
	right_content.add_child(target_scroll)
	target_info = _label("Selecciona una casilla\npara inspeccionar.", 17)
	target_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_info.custom_minimum_size.x = 190
	target_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_scroll.add_child(target_info)
	right_content.add_child(_label("ÚLTIMOS TURNOS", 15, MUTED))
	journal = _label("", 15, MUTED)
	journal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal.custom_minimum_size = Vector2(190, 105)
	right_content.add_child(journal)
	var orders = _panel()
	main.add_child(orders)
	var order_content = VBoxContainer.new()
	order_content.add_theme_constant_override("separation", 8)
	orders.add_child(order_content)
	actor_info = _label("Elige un ensayo para comenzar.", 20, GOLD)
	order_content.add_child(actor_info)
	var row = HBoxContainer.new()
	order_content.add_child(row)
	buttons["move"] = _button("Mover · M", _select_movement, 110)
	row.add_child(buttons.move)
	actions = HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(actions)
	buttons["finish"] = _button("Orientar / terminar · F", _select_finish, 185)
	row.add_child(buttons.finish)
	var last = HBoxContainer.new()
	order_content.add_child(last)
	hint = _label("Control manual contra IA · seis especies · recursos locales", 16, MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.custom_minimum_size.y = 38
	last.add_child(hint)
	directions = HBoxContainer.new()
	last.add_child(directions)
	for facing in Rules.FACINGS:
		var names = {4: "↑ N", 2: "→ E", 0: "↓ S", 6: "← O"}
		var button = _button(names[facing], _set_facing.bind(facing))
		directions.add_child(button)
		direction_buttons[facing] = button
	buttons["cancel"] = _button("Cancelar · Esc", _cancel)
	buttons["confirm"] = _button("Confirmar", _confirm, 110)
	last.add_child(buttons.cancel)
	last.add_child(buttons.confirm)
	var footer = HBoxContainer.new()
	main.add_child(footer)
	var caption = _label("Ensayo de combate · la campaña de Kanto llegará en las siguientes entregas", 14, MUTED)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(caption)
	buttons["sound"] = _button("Sonido: sí", _toggle_sound)
	buttons["motion"] = _button("Animación: sí", _toggle_motion)
	footer.add_child(buttons.sound)
	footer.add_child(buttons.motion)
	footer.add_child(_button("Créditos", func(): credits_dialog.popup_centered(Vector2i(720, 550))))

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
	help_dialog.dialog_text = "Cada Pokémon dispone de un desplazamiento y una acción,\nen cualquier orden. Después elige su orientación y termina.\n\nM: mover. 1/2/3: movimientos. F: orientar y terminar.\nFlechas y Enter: seleccionar una casilla. Escape: cancelar.\nConfirma siempre la previsión antes de ejecutar una orden.\nF8: continuar desde el guardado local.\n\nPuedes atravesar aliados, pero la casilla final debe estar libre.\nLos ataques de área también alcanzan a aliados.\nFrente, flancos y espalda modifican la precisión.\n\nLa partida se guarda tras cada orden aceptada.\nEste laboratorio tiene un guardado propio: no modifica la web."
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

func _start_from_dialog():
	var preserved = store.preserve_before_new()
	if not preserved.ok:
		save_warning = preserved.reason
		_refresh()
		return
	mode = "current" if mode_input.selected == 0 else "classic"
	state = rules.create(seed_input.text, 0.05 if variance_input.selected == 0 else 0.1, "starters" if composition_input.selected == 0 else "mixed", mode)
	history = []
	ai_clock = 0
	pending = {}
	selecting = "inspect"
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
	state = result.state
	history = result.commands
	mode = result.mode
	pending = {}
	selecting = "inspect"
	target_id = -1
	ai_clock = 0
	save_warning = ""
	_refresh()

func _process(delta):
	if qa_running or state.is_empty() or state.outcome != "playing" or new_dialog.visible or help_dialog.visible or credits_dialog.visible: return
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
	_clear(roster)
	_clear(actions)
	action_buttons.clear()
	board.state = state
	board.available = {}
	board.route = []
	board.affected = []
	board.reduced_motion = reduced_motion
	buttons.load.disabled = not FileAccess.file_exists(store.file_path)
	saved.text = "Guardado automático local" if save_warning.is_empty() else "Guardado pendiente"
	saved.add_theme_color_override("font_color", MUTED if save_warning.is_empty() else GOLD)
	buttons.cancel.visible = not pending.is_empty()
	buttons.confirm.visible = not pending.is_empty()
	directions.visible = selecting == "finish"
	buttons.move.disabled = not _player_turn() or state.get("moved", false)
	buttons.finish.disabled = not _player_turn()
	if state.is_empty():
		hint.text = save_warning if not save_warning.is_empty() else "Pulsa «Nuevo ensayo» para comenzar."
		return
	for identity in state.queue:
		var unit = Rules.unit_by_id(state, int(identity))
		var panel = _panel()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row = HBoxContainer.new()
		panel.add_child(row)
		var image = TextureRect.new()
		image.texture = portraits[int(unit.speciesId)]
		image.custom_minimum_size = Vector2(26, 26)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(image)
		var label = _label(unit.name, 15, GOLD if identity == state.queue[0] else (CREAM if unit.team == "ally" else Color("e5a182")))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		timeline.add_child(panel)
	for unit in state.units:
		if unit.team != "ally": continue
		var label = _label("%s\n%d / %d PS  ·  %d PT%s" % [unit.name, unit.hp, unit.maxHp, unit.tp, "\nFuera de combate" if unit.hp == 0 else ("\n" + _status_name(unit.status.kind) if unit.status != null else "")], 17, MUTED if unit.hp == 0 else CREAM)
		roster.add_child(label)
	journal.text = "\n".join(state.log.slice(maxi(0, state.log.size() - 3)))
	heading.text = "Ronda %d  ·  %s  ·  semilla %s" % [state.round, "Reglas actuales" if mode == "current" else "Ensayo clásico", state.seed]
	if target_id >= 0:
		var selected = Rules.unit_by_id(state, target_id)
		if not selected.is_empty(): target_info.text = "%s\n%s\n%d / %d PS\n%d PT · velocidad %d\n%s" % [selected.name, _type_names(selected.types), selected.hp, selected.maxHp, selected.tp, selected.speed, _status_name(selected.status.kind) if selected.status != null else ("Fuera de combate" if selected.hp == 0 else "Sin estado")]
	else: target_info.text = "Selecciona una casilla\npara inspeccionar."
	if state.outcome != "playing":
		actor_info.text = "VICTORIA · zona despejada" if state.outcome == "victory" else "DERROTA · el equipo ha caído"
		hint.text = "El resultado está guardado. Puedes comenzar otro ensayo con una composición diferente."
		if not save_warning.is_empty(): hint.text = save_warning
		board.queue_redraw()
		return
	var actor = Rules.active(state)
	actor_info.text = "%s  ·  %d / %d PS  ·  %d / %d PT  ·  movimiento %d%s" % [actor.name, actor.hp, actor.maxHp, actor.tp, actor.maxTp, actor.remaining, "  /  TURNO ENEMIGO" if actor.team == "enemy" else ""]
	for index in rules.profile(actor).actions_for(actor).size():
		var action = rules.profile(actor).actions_for(actor)[index]
		var definition = action.definition
		var button = _button("%d · %s\n%d PT · alcance %d" % [index + 1, definition.name, definition.cost, definition.range], _select_action.bind(definition.id))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not _player_turn() or state.acted or actor.tp < definition.cost
		button.tooltip_text = definition.description
		actions.add_child(button)
		action_buttons[definition.id] = button
	if selecting == "move":
		var routes = Movement.routes(state.board, Rules.living(state), actor)
		for identity in routes:
			if routes[identity].cost > 0 and routes[identity].cost <= actor.remaining: board.available[identity] = routes[identity]
	if not pending.is_empty():
		if pending.kind == "move": board.route = Movement.routes(state.board, Rules.living(state), actor)[Movement.key(pending.destination)].path
		elif pending.kind == "attack": board.affected = rules.attack_plan(state, pending.target, {}, pending.actionId).tiles
	hint.text = save_warning if not save_warning.is_empty() else ("El rival está decidiendo su turno…" if actor.team == "enemy" else "Mueve o elige un movimiento. Después orienta al Pokémon y termina su turno.")
	board.queue_redraw()

func _select_movement():
	if not _player_turn() or state.moved: return
	selecting = "move"
	pending = {}
	_refresh()
	hint.text = "Selecciona una casilla azul dentro del presupuesto de movimiento."
	board.grab_focus()

func _select_action(identity: String):
	if not _player_turn() or state.acted: return
	selected_action = identity
	selecting = "attack"
	pending = {}
	_refresh()
	hint.text = "Selecciona un objetivo para prever «%s»." % rules.profile(Rules.active(state)).action(Rules.active(state), identity).definition.name
	board.grab_focus()
	if rules.profile(Rules.active(state)).action(Rules.active(state), identity).definition.target == "self": _select_tile(Rules.active(state))

func _select_tile(point: Dictionary):
	if state.is_empty(): return
	var unit = {}
	for candidate in Rules.living(state):
		if Movement.same(candidate, point): unit = candidate
	if not unit.is_empty():
		target_id = int(unit.id)
		target_info.text = "%s\n%s\n%d / %d PS\n%d PT · velocidad %d\n%s" % [unit.name, _type_names(unit.types), unit.hp, unit.maxHp, unit.tp, unit.speed, _status_name(unit.status.kind) if unit.status != null else "Sin estado"]
	if not _player_turn(): return
	if selecting == "move":
		var result = rules.move(state, {"x": point.x, "y": point.y})
		if not result.ok:
			hint.text = result.reason
			return
		pending = {"kind": "move", "destination": {"x": point.x, "y": point.y}}
		_refresh()
		hint.text = "Mover a %s · coste %d. Confirma para desplazarte." % [Rules.coordinate(point), result.route.cost]
	elif selecting == "attack" and not unit.is_empty():
		var plan = rules.attack_plan(state, int(unit.id), {}, selected_action)
		if not plan.ok:
			hint.text = plan.reason
			return
		pending = {"kind": "attack", "target": unit.id, "actionId": selected_action}
		_refresh()
		var friendly = plan.hits.any(func(hit): return Rules.unit_by_id(state, int(hit.targetId)).team == "ally" and (hit.damage > 0 or hit.status != null))
		target_info.text += "\n\n%s\n%d PS · %d %%\nEficacia ×%s%s%s" % [plan.name, plan.damage, plan.accuracy, str(plan.multiplier), "\nRecupera %d PS" % plan.heal if plan.heal else "", "\n¡También afecta a aliados!" if friendly else ""]
		if plan.side != null: target_info.text += "\n" + {"front": "Frente", "flank": "Flanco", "rear": "Espalda"}[plan.side]
		if plan.guard: target_info.text += "\nProtege hasta su próximo turno."
		if plan.status != null: target_info.text += "\n%s: %d %% · %d turnos" % [_status_name(plan.status.kind), plan.status.chance, plan.status.duration]
		if plan.push != null: target_info.text += "\nEmpuja a " + Rules.coordinate(plan.push)
		elif plan.pushReason != null: target_info.text += "\n" + plan.pushReason
		for hit in plan.hits:
			if hit.targetId != unit.id: target_info.text += "\n%s: %d PS · %d %%" % [Rules.unit_by_id(state, int(hit.targetId)).name, hit.damage, hit.accuracy]
		hint.text = "%s · %d PT. Revisa la previsión y confirma." % [plan.name, plan.cost]
	_play("select")

func _select_finish():
	if not _player_turn(): return
	selecting = "finish"
	_set_facing(int(Rules.active(state).facing))

func _set_facing(facing: int):
	if not _player_turn(): return
	pending = {"kind": "finish", "facing": facing}
	_refresh()
	var names = {4: "norte", 2: "este", 0: "sur", 6: "oeste"}
	hint.text = "Terminar mirando al %s. Confirma o cancela." % names[facing]

func _cancel():
	pending = {}
	selecting = "inspect"
	_refresh()
	board.grab_focus()

func _confirm():
	if pending.is_empty() or not _player_turn(): return
	_commit(pending.duplicate(true))

func _commit(command: Dictionary):
	var result = rules.apply_command(state, command)
	if not result.ok:
		hint.text = result.reason
		return
	state = result.state
	history.append(command.duplicate(true))
	pending = {}
	selecting = "inspect"
	_save() # Persist accepted orders before presentation or sound.
	_refresh()
	_play("victory" if state.outcome == "victory" else ("hit" if command.kind == "attack" else "select"))

func _play(name: String):
	if muted or qa_running: return
	sound.stream = load("res://assets/audio/%s.wav" % name)
	sound.play()

func _toggle_sound():
	muted = not muted
	buttons.sound.text = "Sonido: no" if muted else "Sonido: sí"
	if muted: sound.stop()

func _toggle_motion():
	reduced_motion = not reduced_motion
	board.reduced_motion = reduced_motion
	buttons.motion.text = "Animación: no" if reduced_motion else "Animación: sí"

func _status_name(kind: String) -> String:
	return {"burn": "Quemadura", "poison": "Veneno", "paralysis": "Parálisis"}.get(kind, kind)

func _type_names(types: Array) -> String:
	return " / ".join(types.map(func(type): return TYPE_NAMES.get(type, type)))

func _unhandled_key_input(event):
	if not event is InputEventKey or not event.pressed or event.echo: return
	if new_dialog.visible or help_dialog.visible or credits_dialog.visible: return
	match event.keycode:
		KEY_ESCAPE: _cancel()
		KEY_M: _select_movement()
		KEY_F: _select_finish()
		KEY_F8: _load_game()
		KEY_F1: help_dialog.popup_centered(Vector2i(630, 450))
		KEY_1, KEY_2, KEY_3:
			if not _player_turn(): return
			var index = event.keycode - KEY_1
			var entries = rules.profile(Rules.active(state)).actions_for(Rules.active(state))
			if index < entries.size(): _select_action(entries[index].definition.id)
		_: return
	get_viewport().set_input_as_handled()

func _run_qa():
	await Qa.new().run(self, qa_dir)
