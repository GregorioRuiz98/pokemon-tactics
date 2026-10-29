extends AcceptDialog

# Local, reviewable reports. No network requests, telemetry or campaign commands.
const CONTACT: String = "pruebasdequegregorionocopia%40gmail.com"
var app: Control
var category: OptionButton
var subject: LineEdit
var description: TextEdit
var include_context: CheckBox
var preview: TextEdit
var status: Label
var controls: Dictionary = {}
var context: String = ""
var save_dialog: FileDialog

func setup(owner_app: Control) -> void:
	app = owner_app
	title = "Errores y sugerencias"
	theme = app.theme
	ok_button_text = "Volver al juego"
	dialog_close_on_escape = false
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620,400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",10)
	scroll.add_child(column)
	var intro: Label = app._label("Cuéntanos qué ocurrió o qué mejorarías. Puedes revisar el informe antes de compartirlo.",18)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(intro)
	category = OptionButton.new()
	category.add_item("Informar de un error")
	category.add_item("Proponer una mejora")
	column.add_child(category)
	column.add_child(app._label("Título",17))
	subject = LineEdit.new()
	subject.placeholder_text = "Ej.: no puedo elegir un movimiento"
	subject.max_length = 120
	column.add_child(subject)
	column.add_child(app._label("Descripción",17))
	description = TextEdit.new()
	description.placeholder_text = "Error: qué hiciste, qué esperabas y qué ocurrió.\nMejora: qué cambiarías y por qué."
	description.custom_minimum_size.y = 140
	description.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	column.add_child(description)
	include_context = CheckBox.new()
	include_context.text = "Incluir semilla y situación de la partida"
	include_context.button_pressed = true
	column.add_child(include_context)
	column.add_child(app._label("Informe que vas a compartir",17))
	preview = TextEdit.new()
	preview.editable = false
	preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	preview.custom_minimum_size.y = 170
	column.add_child(preview)
	var actions: HFlowContainer = HFlowContainer.new()
	column.add_child(actions)
	for entry: Array in [["copy","Copiar informe",copy_report],["save","Guardar .txt",choose_file],["email","Preparar correo",prepare_email]]:
		var button: Button = app._button(entry[1],entry[2])
		button.theme_type_variation = "ToolButton"
		button.custom_minimum_size.x = 210
		actions.add_child(button)
		controls[entry[0]] = button
	status = app._label("El correo se abre en tu aplicación. Tú decides cuándo enviarlo. Sin correo configurado, copia o guarda el informe.",16)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	subject.text_changed.connect(func(_value: String): refresh())
	description.text_changed.connect(refresh)
	category.item_selected.connect(func(_index: int): refresh())
	include_context.toggled.connect(func(_value: bool): refresh())
	save_dialog = FileDialog.new()
	save_dialog.title = "Guardar informe"
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.filters = PackedStringArray(["*.txt ; Informe de texto"])
	add_child(save_dialog)
	save_dialog.file_selected.connect(save_report)
	app._watch_dialog(save_dialog)
	visibility_changed.connect(func():
		if not visible: save_dialog.hide())
	refresh()

func open() -> void:
	var lines: Array[String] = []
	if not app.run.is_empty():
		var stage: int = int(app.run.get("stage",0))
		var locations: Array = app.campaign.locations
		var place: String = locations[stage].name if stage>=0 and stage<locations.size() else "Final de aventura"
		lines.append("Lugar: "+place)
		lines.append("Fase: "+str(app.run.get("phase","")))
		lines.append("Semilla: "+str(app.run.get("seed","")))
		lines.append("Edición de campaña: "+str(app.run.get("edition","")))
		if app.run.get("battle",{}) is Dictionary and not app.run.get("battle",{}).is_empty():
			lines.append("Ronda: "+str(app.run.battle.get("round",1)))
	else: lines.append("Situación: pantalla de inicio / sin aventura cargada")
	context = "\n".join(lines)
	refresh()
	popup_centered(Vector2i(700,600))
	app._apply_preferences()
	subject.grab_focus.call_deferred()

func report() -> String:
	var kind: String = "Error" if category.selected==0 else "Sugerencia"
	var heading: String = "%s · %s\nVersión: %s\nSistema: %s\nVentana: %d × %d\nTexto: %s%%" % [ProjectSettings.get_setting("application/config/name"),kind,ProjectSettings.get_setting("application/config/version"),OS.get_name(),app.get_window().size.x,app.get_window().size.y,app.input_profile.preferences.textScale]
	if include_context.button_pressed: heading += "\n"+context
	return heading+"\n\nTítulo: "+subject.text.strip_edges()+"\n\nDescripción:\n"+description.text.strip_edges()+"\n"

func refresh() -> void:
	preview.text = report()
	var incomplete: bool = subject.text.strip_edges().is_empty() or description.text.strip_edges().is_empty()
	for button: Button in controls.values(): button.disabled = incomplete

func copy_report() -> void:
	DisplayServer.clipboard_set(report())
	status.text = "Informe copiado. Puedes pegarlo en un correo o compartirlo como texto."

func choose_file() -> void:
	save_dialog.current_file = "tactical-chronicles-kanto-informe.txt"
	save_dialog.popup_centered(Vector2i(700,500))
	app._apply_preferences()

func save_report(path: String) -> void:
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		status.text = "No se pudo guardar. Elige otra carpeta o copia el informe."
		return
	file.store_string(report())
	file.close()
	status.text = "Informe guardado. Puedes adjuntarlo al correo."

func email_uri() -> String:
	var label: String = "[%s · %s] %s: %s" % [ProjectSettings.get_setting("application/config/name"),ProjectSettings.get_setting("application/config/version"),"Error" if category.selected==0 else "Sugerencia",subject.text.strip_edges().left(60)]
	var body: String = report()
	var recipient: String = CONTACT.uri_decode()
	var uri: String = "mailto:"+recipient+"?subject="+label.uri_encode()+"&body="+body.uri_encode()
	# Long mailto URLs are unreliable on Windows. Full text always goes to clipboard.
	if uri.length()>1800:
		body = "Pega aquí el informe completo: ya está copiado en el portapapeles del juego. También puedes adjuntar el .txt guardado."
		uri = "mailto:"+recipient+"?subject="+label.uri_encode()+"&body="+body.uri_encode()
	return uri

func prepare_email() -> void:
	DisplayServer.clipboard_set(report())
	var uri: String = email_uri()
	var result: Error = OS.shell_open(uri)
	if result!=OK:
		status.text = "No se pudo abrir el correo. El informe está copiado; puedes guardarlo como .txt."
	elif not uri.get_slice("&body=",1).uri_decode().begins_with(str(ProjectSettings.get_setting("application/config/name"))):
		status.text = "Informe largo copiado: pégalo en el borrador o adjunta el .txt. Revisa el correo y envíalo desde tu aplicación."
	else: status.text = "Informe copiado y borrador solicitado. Revisa y envía desde tu aplicación; si no se abre, guarda el .txt."
