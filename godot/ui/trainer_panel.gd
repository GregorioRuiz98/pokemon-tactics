extends AcceptDialog

var app: Control
var session: RefCounted
var body: VBoxContainer
var page: String = "card"
var controls: Dictionary = {}
var feedback: String = ""

func setup(owner_app: Control, trainer: RefCounted) -> void:
	app = owner_app; session = trainer; theme = app.theme
	title = "Perfil de entrenador"; ok_button_text = "Volver"; dialog_close_on_escape = false
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680,440); scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	body = VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12); scroll.add_child(body)

func change_page(value: String) -> void:
	page = value; feedback = ""; render()

func render() -> void:
	app._clear(body); controls.clear()
	var model: RefCounted = session.model
	var tabs: GridContainer = GridContainer.new(); tabs.columns = 2
	body.add_child(tabs)
	for entry: Array in [["card","Entrenador"],["achievements","Logros"],["dex","Pokédex"],["history","Aventuras"]]:
		var button: Button = app._button(entry[1],change_page.bind(entry[0]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.toggle_mode = true
		button.button_pressed = entry[0]==page; button.theme_type_variation = "TabButton"
		tabs.add_child(button); controls[entry[0]] = button
	var frame_color: Color = {"amber":app.GOLD,"leaf":Color("8bcc9d"),"champion":Color("d1acfa")}.get(model.data.frame,app.GOLD)
	var card: PanelContainer = app._panel()
	card.add_theme_stylebox_override("panel",preload("res://ui/game_skin.gd").panel(frame_color)); body.add_child(card)
	var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation",16); card.add_child(row)
	var image: TextureRect = app._portrait(Vector2(72,72)); image.texture = app.faces.get(int(model.data.portrait)); row.add_child(image)
	var heading: Label = app._label(model.data.name+"\n"+model.data.title,23,frame_color)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(heading)
	body.add_child(app._label("%d / 10 logros · %d / 151 Pokémon registrados" % [model.data.unlocked.size(),model.data.dex.size()],18))
	var totals: Dictionary = model.summary()
	body.add_child(app._label("Aventuras: %d · Victorias: %d · Récord de medallas: %d" % [totals.runs,totals.wins,totals.bestMedals],17,app.MUTED))
	if not session.warning.is_empty():
		body.add_child(app._label(session.warning,17,app.GOLD))
		var recover: Button = app._button("Recuperar copia" if not session.persistence.recovery.is_empty() else "Conservar archivo y crear perfil",request_recovery)
		body.add_child(recover); controls.recover = recover
	if not feedback.is_empty(): body.add_child(app._label(feedback,17,app.GOLD))
	match page:
		"card": render_card()
		"achievements":
			for key: String in model.ACHIEVEMENTS:
				var unlocked: bool = model.data.unlocked.has(key)
				body.add_child(app._label(("✓ " if unlocked else "○ ")+model.ACHIEVEMENTS[key][0],20,frame_color if unlocked else app.MUTED))
				body.add_child(app._label(model.ACHIEVEMENTS[key][1],17))
		"dex":
			if model.data.dex.is_empty(): body.add_child(app._label("Tu primer compañero iniciará esta colección.",18))
			for species_id: int in model.data.dex: body.add_child(app._label("#%03d · %s" % [species_id,app.rules.profiles[species_id].data.name],19))
		"history": render_history()
	app._apply_preferences()
	call_deferred("focus_tab")

func focus_tab() -> void:
	var target: Control = controls.get(page)
	if visible and is_instance_valid(target) and target.is_inside_tree(): target.grab_focus()

func render_card() -> void:
	var model: RefCounted = session.model
	var name_field: LineEdit = LineEdit.new(); name_field.text = model.data.name; name_field.max_length = 24
	name_field.accessibility_name = "Nombre del entrenador"; body.add_child(app._label("Nombre",17)); body.add_child(name_field); controls.name_field = name_field
	var portrait: OptionButton = OptionButton.new(); portrait.fit_to_longest_item = false
	var choices: Array = [1,4,7,25]
	for species_id: int in model.data.dex:
		if species_id not in choices: choices.append(species_id)
	for species_id: int in choices:
		portrait.add_item(app.rules.profiles[species_id].data.name,species_id)
		if species_id==int(model.data.portrait): portrait.select(portrait.item_count-1)
	body.add_child(app._label("Retrato",17)); body.add_child(portrait); controls.portrait = portrait
	for entry: Array in [["title","Título",model.titles(),model.data.title],["frame","Marco",model.frames(),model.data.frame]]:
		var choice: OptionButton = OptionButton.new(); choice.fit_to_longest_item = false
		for value: String in entry[2]:
			choice.add_item({"amber":"Ámbar","leaf":"Hoja","champion":"Campeón"}.get(value,value)); choice.set_item_metadata(choice.item_count-1,value)
			if value==entry[3]: choice.select(choice.item_count-1)
		body.add_child(app._label(entry[1],17)); body.add_child(choice); controls[entry[0]+"_choice"] = choice
	var toggle: CheckButton = CheckButton.new(); toggle.text = "Avisos de logros"; toggle.button_pressed = model.data.get("notifications",true)
	body.add_child(toggle); controls.notifications = toggle
	var save: Button = app._button("Guardar perfil",save_card); body.add_child(save); controls.save = save
	body.add_child(app._label("Las medallas desbloquean títulos y marcos. Son cambios de apariencia.",16,app.MUTED))

func save_card() -> void:
	var copy: RefCounted = session.Model.new(session.model.data)
	if not copy.customize(controls.name_field.text,controls.portrait.get_selected_id(),controls.title_choice.get_selected_metadata(),controls.frame_choice.get_selected_metadata()): feedback = "El nombre debe tener entre 1 y 24 caracteres."; render(); return
	copy.data.notifications = controls.notifications.button_pressed
	var previous: RefCounted = session.model
	session.model = copy
	if not session.persist(): session.model = previous; feedback = session.warning
	else: feedback = "Perfil guardado."; session.update_title(app)
	render()

func render_history() -> void:
	var entries: Array = session.model.data.runs.values()
	entries.sort_custom(func(a,b):return int(a.started)>int(b.started))
	if entries.is_empty(): body.add_child(app._label("Aún no has comenzado una aventura.",18))
	for entry: Dictionary in entries:
		body.add_child(app._label("%s · %s" % [app.rules.profiles[int(entry.starter)].data.name,{"active":"En curso","completed":"Completada","defeated":"Derrota","abandoned":"Abandonada"}[entry.status]],20,app.GOLD))
		body.add_child(app._label("Medallas: %d · Victorias: %d / %d combates · Bajas: %d\nSemilla: %s" % [entry.medals,entry.wins,entry.battles,entry.kos,entry.seed],17))
		if entry.get("partialHistory",false): body.add_child(app._label("Aventura anterior al perfil: algunos eventos no se registraron.",16,app.MUTED))

func request_recovery() -> void:
	hide()
	app._review_dialog()
	app.action_review.review("Recuperar perfil","Se conservará una copia del archivo dañado. Se restaurará la copia válida disponible o se creará un perfil nuevo. Tu aventura no se sustituye.",func():
		session.model = session.Model.new(session.persistence.recovery)
		if session.persist(true): session.signature = ""; session.sync(app)
		session.open(app))
