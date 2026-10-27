extends AcceptDialog

var app: Control
var widgets: Dictionary = {}

func setup(owner_app: Control) -> void:
	app = owner_app
	theme = app.theme
	title = "Accesibilidad y presentación · F12 recupera lectura"
	ok_button_text = "Volver"
	dialog_close_on_escape = false
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620,430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",10)
	scroll.add_child(column)
	column.add_child(app._label("Texto independiente del zoom del tablero.\nF12: texto100% y contraste normal, incluso en diálogos.",17))
	var scale_choice: OptionButton = OptionButton.new()
	for value: int in [100,125,150]: scale_choice.add_item("Texto / HUD · %d %%" % value,value)
	scale_choice.select([100,125,150].find(int(app.input_profile.preferences.textScale)))
	scale_choice.item_selected.connect(func(_index: int): change("textScale",scale_choice.get_selected_id()))
	column.add_child(scale_choice)
	widgets.textScale = scale_choice
	var speed_choice: OptionButton = OptionButton.new()
	for value: int in [100,150,200]: speed_choice.add_item("Velocidad de combate · %s×"%str(value/100.0),value)
	speed_choice.select([100,150,200].find(int(app.input_profile.preferences.get("battleSpeed",100))))
	speed_choice.item_selected.connect(func(_index: int): change("battleSpeed",speed_choice.get_selected_id()))
	column.add_child(speed_choice); widgets.battleSpeed = speed_choice
	for entry: Array in [["highContrast","Alto contraste"],["muted","Silenciar sonidos"],["reducedMotion","Movimiento reducido"],["followCamera","Seguir la unidad activa con la cámara"],["tutorialHints","Ayudas de aventura"],["accessibleMode","Texto de casilla y avisos accesibles (prototipo)"]]:
		var field: String = entry[0]
		var toggle: CheckButton = CheckButton.new()
		toggle.text = entry[1]
		toggle.button_pressed = app.input_profile.preferences[field]
		toggle.toggled.connect(func(value: bool): change(field,value))
		column.add_child(toggle)
		widgets[field] = toggle
	for entry: Array in [["volume","Volumen general",0,100,5],["resultSeconds","Segundos de lectura de resultados",1,10,1]]:
		var row: HBoxContainer = HBoxContainer.new()
		column.add_child(row)
		var text: Label = app._label(entry[1],17)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(text)
		var value: SpinBox = SpinBox.new()
		value.min_value = entry[2]
		value.max_value = entry[3]
		value.step = entry[4]
		value.value = app.input_profile.preferences[entry[0]]
		value.value_changed.connect(func(number: float): change(entry[0],int(number)))
		row.add_child(value)
		widgets[entry[0]] = value
	column.add_child(app._button("Teclado y modo Rápido / Seguro…",func(): hide(); app._open_controls.call_deferred()))
	column.add_child(app._button("Restablecer presentación",reset))

func change(field: String, value: Variant) -> void:
	if app.input_profile.set_preference(field,value): app._apply_preferences()
	else: title = "No se ha podido guardar: "+app.input_profile.warning

func reset() -> void:
	var previous: Dictionary = app.input_profile.preferences.duplicate(true)
	app.input_profile.preferences = app.input_profile.DEFAULT_PREFERENCES.duplicate(true)
	if not app.input_profile.save(): app.input_profile.preferences = previous
	app._apply_preferences()
	hide()
