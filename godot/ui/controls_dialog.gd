extends AcceptDialog

# Capture-before-GUI and conflict handling adapted from Godot input_remap.gd.
var app: Control
var profile: RefCounted
var category: OptionButton
var rows: VBoxContainer
var status: Label
var repeat: CheckButton
var confirmation: CheckButton
var bindings: Dictionary = {}
var capturing: String = ""
var proposed: Dictionary = {}
var conflict_dialog: ConfirmationDialog
var reset_dialog: ConfirmationDialog
var column: VBoxContainer

func setup(owner_app: Control, input_profile: RefCounted) -> void:
	app = owner_app
	profile = input_profile
	title = "Controles · teclado y ratón"
	ok_button_text = "Volver"
	dialog_close_on_escape = false
	wrap_controls = false
	min_size = Vector2i(700,620)
	max_size = Vector2i(900,650)
	theme = app.theme
	column = VBoxContainer.new()
	column.custom_minimum_size = Vector2(660,540)
	column.custom_maximum_size = Vector2(860,558)
	column.add_theme_constant_override("separation",12)
	add_child(column)
	var instructions: Label = app._label("Elige una orden y pulsa su nueva tecla. Escape cancela la captura.\nEnter / Espacio, Escape, Tab y flechas siguen disponibles como seguridad.\nCámara: cruceta, Alt + flechas o modo P; rueda acerca; central arrastra.",16)
	column.add_child(instructions)
	category = OptionButton.new()
	for value: String in ["Combate","Navegación","Cámara","General"]: category.add_item(value)
	column.add_child(category)
	category.item_selected.connect(func(_index: int): rebuild())
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",6)
	scroll.add_child(rows)
	repeat = CheckButton.new()
	repeat.text = "Repetir navegación al mantener una tecla"
	repeat.button_pressed = profile.navigation_repeat
	repeat.toggled.connect(func(value: bool):
		var before: bool = profile.navigation_repeat
		profile.navigation_repeat = value
		if not profile.save(): profile.navigation_repeat = before; repeat.set_pressed_no_signal(before)
		status.text = profile.warning if not profile.warning.is_empty() else "Preferencia guardada. Las órdenes nunca se repiten al mantener una tecla.")
	column.add_child(repeat)
	confirmation = CheckButton.new()
	confirmation.text = "Modo Seguro · confirmar cada acción" if profile.confirmation_mode=="safe" else "Modo Rápido · ejecutar al aceptar objetivo"
	confirmation.button_pressed = profile.confirmation_mode=="safe"
	confirmation.tooltip_text = "En ambos modos se confirma el daño a aliados y el coste propio potencialmente letal. Elegir una habilidad solo la prepara."
	confirmation.toggled.connect(func(enabled: bool):
		var before: String = profile.confirmation_mode
		profile.confirmation_mode = "safe" if enabled else "fast"
		if not profile.save(): profile.confirmation_mode = before; confirmation.set_pressed_no_signal(before=="safe")
		confirmation.text = "Modo Seguro · confirmar cada acción" if profile.confirmation_mode=="safe" else "Modo Rápido · ejecutar al aceptar objetivo"
		status.text = profile.warning if not profile.warning.is_empty() else "Modo guardado. Seleccionar una habilidad nunca la ejecuta.")
	column.add_child(confirmation)
	var reset: Button = app._button("Restablecer categoría…",func(): reset_dialog.popup_centered())
	column.add_child(reset)
	status = app._label("",16)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 48
	column.add_child(status)
	conflict_dialog = ConfirmationDialog.new()
	conflict_dialog.title = "Tecla ocupada"
	conflict_dialog.ok_button_text = "Intercambiar teclas"
	conflict_dialog.cancel_button_text = "Conservar"
	add_child(conflict_dialog)
	conflict_dialog.confirmed.connect(_exchange)
	conflict_dialog.canceled.connect(func(): _restore_capture())
	reset_dialog = ConfirmationDialog.new()
	reset_dialog.title = "Restablecer controles"
	reset_dialog.dialog_text = "Se restablecerá esta categoría y las asignaciones que entren en conflicto.\nLos controles de seguridad permanecen disponibles."
	reset_dialog.confirmed.connect(func():
		profile.reset_category(category.get_item_text(category.selected))
		app._input_labels()
		rebuild()
		category.grab_focus.call_deferred())
	add_child(reset_dialog)
	app._watch_dialog(conflict_dialog)
	app._watch_dialog(reset_dialog)
	var listener: Node = load("res://ui/dialog_input.gd").new()
	listener.handler = capture_input
	add_child(listener)
	visibility_changed.connect(func():
		if visible: rebuild(); category.grab_focus.call_deferred()
		else: capturing = ""; proposed = {})
	size_changed.connect(_fit_column)

func _fit_column() -> void:
	if column==null: return
	column.position = Vector2(14,14)
	column.size = Vector2(size)-Vector2(28,82)

func rebuild() -> void:
	app._clear(rows)
	bindings.clear()
	capturing = ""
	for action: String in profile.ACTIONS:
		if profile.ACTIONS[action][1]!=category.get_item_text(category.selected): continue
		var row: HBoxContainer = HBoxContainer.new()
		rows.add_child(row)
		var name_label: Label = app._label(profile.ACTIONS[action][0],17)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var button: Button = app._button(profile.label(action),begin_capture.bind(action),190)
		row.add_child(button)
		bindings[action] = button
	status.text = profile.warning if not profile.warning.is_empty() else "Los cambios se guardan para la próxima sesión. Las órdenes de combate no cambian."
	size = Vector2i(700,640)
	_fit_column.call_deferred()

func begin_capture(action: String) -> void:
	capturing = action
	status.text = profile.ACTIONS[action][0]+": pulsa la nueva tecla; Escape cancela."
	bindings[action].text = "Esperando tecla…"

func _restore_capture() -> void:
	var action: String = capturing
	capturing = ""
	proposed = {}
	rebuild()
	if bindings.has(action): bindings[action].grab_focus.call_deferred()

func _exchange() -> void:
	var action: String = capturing
	var result: Dictionary = profile.rebind(action,proposed,true)
	_restore_capture()
	app._input_labels()
	status.text = "Teclas intercambiadas y guardadas." if result.ok else result.reason

func capture_input(event: InputEvent) -> void:
	if not visible or conflict_dialog.visible or reset_dialog.visible: return
	if not event is InputEventKey or not event.pressed: return
	if event.echo:
		set_input_as_handled()
		return
	if not capturing.is_empty():
		set_input_as_handled()
		if event.keycode==KEY_ESCAPE:
			_restore_capture()
			status.text = "Captura cancelada; no se ha cambiado ninguna tecla."
			return
		if event.meta_pressed: status.text = "Las combinaciones del sistema se conservan. Elige otra tecla."; return
		proposed = {"key":event.keycode if event.keycode!=0 else event.physical_keycode,"shift":event.shift_pressed,"alt":event.alt_pressed,"ctrl":event.ctrl_pressed}
		var action: String = capturing
		var result: Dictionary = profile.rebind(action,proposed)
		if result.has("conflict"):
			conflict_dialog.dialog_text = result.reason+"\n¿Intercambiar sus asignaciones?"
			conflict_dialog.popup_centered()
			return
		_restore_capture()
		app._input_labels()
		status.text = "Control guardado." if result.ok else result.reason
	elif profile.matches(event,"cancel"):
		set_input_as_handled()
		hide()
