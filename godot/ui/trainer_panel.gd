extends AcceptDialog

const Catalog = preload("res://core/collection_catalog.gd")
const Identity = preload("res://ui/trainer_identity.gd")
const GameSkin = preload("res://ui/game_skin.gd")

var app: Control
var session: RefCounted
var root: VBoxContainer
var body: VBoxContainer
var tabs: GridContainer
var card: PanelContainer
var avatar: TextureRect
var trainer_name: Label
var trainer_title: Label
var preview_notice: Label
var feedback_label: Label
var page: String = "card"
var controls: Dictionary = {}
var page_buttons: Dictionary = {}
var feedback: String = ""
var dex_browser: VBoxContainer
var fitting: bool = false

func setup(owner_app: Control, trainer: RefCounted) -> void:
	app = owner_app; session = trainer; theme = app.theme
	title = "Entrenador"; ok_button_text = "Volver"; dialog_close_on_escape = false
	root = VBoxContainer.new(); root.custom_minimum_size = Vector2(680,440)
	root.add_theme_constant_override("separation",10); add_child(root)
	card = app._panel(); root.add_child(card)
	var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation",18); card.add_child(row)
	avatar = app._portrait(Vector2(72,72)); row.add_child(avatar)
	var heading: VBoxContainer = VBoxContainer.new(); heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(heading)
	trainer_name = app._label("",26); trainer_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	trainer_name.clip_text = true; trainer_name.set_meta("single_line",true); heading.add_child(trainer_name)
	trainer_title = app._label("",17); heading.add_child(trainer_title)
	preview_notice = app._label("",15,app.MUTED); heading.add_child(preview_notice)
	tabs = GridContainer.new(); tabs.columns = 2; root.add_child(tabs)
	for entry: Array in [["card","Personalizar"],["achievements","Logros"],["dex","Pokédex"],["history","Historial"]]:
		var button: Button = app._button(entry[1],change_page.bind(entry[0]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.toggle_mode = true
		button.theme_type_variation = "TabButton"; button.set_meta("page_label",entry[1])
		tabs.add_child(button); page_buttons[entry[0]] = button
	var scroll: ScrollContainer = ScrollContainer.new(); scroll.custom_minimum_size.y = 180
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; root.add_child(scroll)
	body = VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12); scroll.add_child(body)
	size_changed.connect(queue_fit)
	app.get_window().size_changed.connect(func():
		if visible: queue_fit())

func queue_fit() -> void:
	if not fitting: fitting = true; call_deferred("fit_window")

func fit_window() -> void:
	var available: Vector2i = app.get_window().size
	size = Vector2i(mini(820,available.x-48),mini(660,available.y-64))
	position = Vector2i(Vector2(available-size)*0.5)
	fitting = false

func change_page(value: String) -> void:
	page = value; feedback = ""; render()

func render() -> void:
	app._clear(body); controls = page_buttons.duplicate()
	var model: RefCounted = session.model
	show_identity(model.data,false)
	for key: String in page_buttons:
		var selected: bool = key==page
		var button: Button = page_buttons[key]
		var label: String = button.get_meta("page_label")
		button.text = ("● " if selected else "")+label
		button.button_pressed = selected
		button.remove_theme_stylebox_override("pressed"); button.remove_theme_color_override("font_pressed_color")
		if selected:
			var active_style: StyleBoxFlat = GameSkin.panel(Identity.accent(model.data.frame))
			active_style.bg_color = Color("f7f2e6"); active_style.border_width_bottom = 3
			button.add_theme_stylebox_override("pressed",active_style)
			button.add_theme_color_override("font_pressed_color",Color("142d37"))
		button.accessibility_name = label+(" · seleccionada" if selected else "")
	if not session.warning.is_empty():
		body.add_child(app._label(session.warning,17,app.GOLD))
		var recover: Button = app._button("Recuperar copia" if not session.persistence.recovery.is_empty() else "Crear perfil conservando el archivo",request_recovery)
		body.add_child(recover); controls.recover = recover
	feedback_label = app._label(feedback,17,app.GOLD); feedback_label.visible = not feedback.is_empty(); body.add_child(feedback_label)
	match page:
		"card": render_card()
		"achievements": render_achievements()
		"dex":
			body.add_child(app._label("%d obtenidos · %d vistos / 151" % [model.data.dex.size(),model.data.seen.size()],18))
			dex_browser = preload("res://ui/collection_browser.gd").new(); body.add_child(dex_browser); dex_browser.setup(app)
		"history": render_history()
	app._apply_preferences()
	queue_fit()
	call_deferred("focus_tab")

func show_identity(data: Dictionary, unsaved: bool) -> void:
	var color: Color = Identity.accent(data.frame)
	var style: StyleBoxFlat = GameSkin.panel(color); style.border_color = color; style.border_width_left = 5
	if app.input_profile.preferences.get("highContrast",false): style.bg_color = Color.BLACK
	card.add_theme_stylebox_override("panel",style)
	avatar.texture = Identity.portrait(app,int(data.portrait))
	trainer_name.text = data.name if not str(data.name).strip_edges().is_empty() else "Tu entrenador"
	trainer_name.tooltip_text = trainer_name.text; trainer_name.accessibility_name = "Entrenador: "+trainer_name.text
	trainer_title.text = data.title
	preview_notice.text = "Sin guardar" if unsaved else "Perfil local"

func focus_tab() -> void:
	trainer_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	var target: Control = controls.get(page)
	if visible and is_instance_valid(target) and target.is_inside_tree(): target.grab_focus()

func section(parent: Control) -> VBoxContainer:
	var panel: PanelContainer = app._panel(); parent.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new(); content.add_theme_constant_override("separation",8); panel.add_child(content)
	return content

func render_card() -> void:
	var model: RefCounted = session.model
	var totals: Dictionary = model.summary()
	var metrics: GridContainer = GridContainer.new(); metrics.columns = 3; body.add_child(metrics)
	for entry: Array in [["Pokédex","%d / 151" % model.data.dex.size()],["Logros","%d / %d" % [model.data.unlocked.size(),model.ACHIEVEMENTS.size()]],["Medallas","%d / 8" % totals.bestMedals]]:
		var metric: VBoxContainer = section(metrics); metric.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		metric.add_child(app._label(entry[0],16,app.MUTED)); metric.add_child(app._label(entry[1],22))
	var form: VBoxContainer = section(body)
	var name_field: LineEdit = LineEdit.new(); name_field.text = model.data.name; name_field.max_length = 24
	name_field.accessibility_name = "Nombre del entrenador"; form.add_child(app._label("Nombre",17)); form.add_child(name_field); controls.name_field = name_field
	var choices_grid: GridContainer = GridContainer.new(); choices_grid.columns = 2; form.add_child(choices_grid)
	var portrait: OptionButton = OptionButton.new(); portrait.fit_to_longest_item = false
	var choices: Array = [1,4,7,25]
	for species_id: int in model.data.dex:
		if species_id not in choices: choices.append(species_id)
	for species_id: int in choices:
		portrait.add_item(Catalog.record(species_id).name,species_id)
		if species_id==int(model.data.portrait): portrait.select(portrait.item_count-1)
	add_choice(choices_grid,"Retrato",portrait); controls.portrait = portrait
	for entry: Array in [["title","Título",model.titles(),model.data.title],["frame","Marco",model.frames(),model.data.frame]]:
		var choice: OptionButton = OptionButton.new(); choice.fit_to_longest_item = false
		for value: String in entry[2]:
			choice.add_item({"amber":"Ámbar","leaf":"Hoja","champion":"Campeón"}.get(value,value)); choice.set_item_metadata(choice.item_count-1,value)
			if value==entry[3]: choice.select(choice.item_count-1)
		add_choice(choices_grid,entry[1],choice); controls[entry[0]+"_choice"] = choice
	var toggle: CheckButton = CheckButton.new(); toggle.text = "Avisos de logros"; toggle.button_pressed = model.data.get("notifications",true)
	form.add_child(toggle); controls.notifications = toggle
	var save: Button = app._button("Guardar cambios",save_card); form.add_child(save); controls.save = save
	name_field.text_changed.connect(func(_value: String): preview_card())
	for field: String in ["portrait","title_choice","frame_choice"]:
		controls[field].item_selected.connect(func(_index: int): preview_card())
	toggle.toggled.connect(func(_pressed: bool): preview_card())

func add_choice(parent: Control, label: String, choice: OptionButton) -> void:
	var column: VBoxContainer = VBoxContainer.new(); column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column); column.add_child(app._label(label,17)); column.add_child(choice)
	choice.accessibility_name = label

func preview_card() -> void:
	var data: Dictionary = session.model.data.duplicate(true)
	data.name = controls.name_field.text; data.portrait = controls.portrait.get_selected_id()
	data.title = controls.title_choice.get_selected_metadata(); data.frame = controls.frame_choice.get_selected_metadata()
	data.notifications = controls.notifications.button_pressed
	show_identity(data,data!=session.model.data); feedback_label.hide()

func save_card() -> void:
	var copy: RefCounted = session.Model.new(session.model.data)
	if not copy.customize(controls.name_field.text,controls.portrait.get_selected_id(),controls.title_choice.get_selected_metadata(),controls.frame_choice.get_selected_metadata()):
		feedback = "Escribe un nombre de 1 a 24 caracteres."; feedback_label.text = feedback; feedback_label.show()
		controls.name_field.grab_focus(); return
	copy.data.notifications = controls.notifications.button_pressed
	var previous: RefCounted = session.model
	session.model = copy
	if not session.persist():
		session.model = previous; feedback_label.text = session.warning; feedback_label.show(); return
	feedback = "Cambios guardados."; session.update_title(app); render()

func render_achievements() -> void:
	var model: RefCounted = session.model
	body.add_child(app._label("%d / %d completados" % [model.data.unlocked.size(),model.ACHIEVEMENTS.size()],18))
	for completed: bool in [true,false]:
		for key: String in model.ACHIEVEMENTS:
			if model.data.unlocked.has(key)!=completed: continue
			var entry: VBoxContainer = section(body)
			entry.add_child(app._label(("✓ " if completed else "○ ")+model.ACHIEVEMENTS[key][0],20,Color("8bcc9d") if completed else Color.WHITE))
			entry.add_child(app._label(model.ACHIEVEMENTS[key][1],17,app.MUTED))

func render_history() -> void:
	var entries: Array = session.model.data.runs.values()
	entries.sort_custom(func(a,b):return int(a.started)>int(b.started))
	if entries.is_empty(): body.add_child(app._label("Tu próxima aventura empieza en Kanto.",18))
	for entry: Dictionary in entries:
		var content: VBoxContainer = section(body)
		var status: String = {"active":"En curso","completed":"Completada","defeated":"Derrota","abandoned":"Abandonada"}[entry.status]
		content.add_child(app._label("%s · %s" % [Catalog.record(int(entry.starter)).name,status],20,Identity.accent(session.model.data.frame)))
		var parts: PackedStringArray = Time.get_date_string_from_unix_time(int(entry.started)).split("-")
		var date: String = "%s/%s/%s" % [parts[2],parts[1],parts[0]]
		content.add_child(app._label("%s · %d %s · %d %s · %d %s" % [date,entry.medals,"medalla" if entry.medals==1 else "medallas",entry.wins,"victoria" if entry.wins==1 else "victorias",entry.kos,"baja" if entry.kos==1 else "bajas"],17))
		var detail: Label = app._label("Semilla: %s · %d combates" % [entry.seed,entry.battles],16,app.MUTED)
		detail.visible = false
		var details: Button = app._button("Ver detalles",func():pass); details.toggle_mode = true
		details.theme_type_variation = "ToolButton"; details.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		details.toggled.connect(func(expanded: bool): detail.visible = expanded; details.text = "Ocultar detalles" if expanded else "Ver detalles")
		var actions: HBoxContainer = HBoxContainer.new(); content.add_child(actions); actions.add_child(details)
		content.add_child(detail)
		if not controls.has("history_details"): controls.history_details = []
		controls.history_details.append({"button":details,"text":detail})
		if entry.get("partialHistory",false): content.add_child(app._label("Registro parcial de una versión anterior.",16,app.MUTED))

func request_recovery() -> void:
	hide()
	app._review_dialog()
	app.action_review.review("Recuperar perfil","Se conservará el archivo dañado y se restaurará su copia válida, si existe. En caso contrario, se creará un perfil nuevo. Tu aventura se mantiene.",func():
		session.model = session.Model.new(session.persistence.recovery)
		if session.persist(true): session.signature = ""; session.sync(app)
		session.open(app))
