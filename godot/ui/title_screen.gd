extends Control

# Container-driven title overlay, adapted from the Godot skill's title/pause UI.
# The campaign owns all state; this view never loads or writes a campaign.
var controls: Dictionary = {}
var notice: Label
var caption: Label
var app: Control

func setup(owner_app: Control) -> void:
	app = owner_app
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop: Control = load("res://ui/title_backdrop.gd").new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.setup(app.rules.data.species)
	var margin: MarginContainer = MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right"]: margin.add_theme_constant_override("margin_"+edge,56)
	margin.add_theme_constant_override("margin_top",28)
	margin.add_theme_constant_override("margin_bottom",18)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	column.add_child(app._label("KANTO  /  UNA AVENTURA TÁCTICA",16,app.GOLD))
	var center: HBoxContainer = HBoxContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(center)
	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size.x = 410
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation",12)
	center.add_child(left)
	left.add_child(app._label("POKÉMON",52,Color("f4e4bd")))
	var title: Label = app._label("TACTICS",72,app.GOLD)
	title.add_theme_constant_override("line_spacing",0)
	left.add_child(title)
	caption = app._label("Tu equipo. Tu estrategia.\nUn viaje desde Pueblo Paleta hasta la Liga.",19,Color("b9ccd0"))
	left.add_child(caption)
	var space: Control = Control.new()
	space.custom_minimum_size.y = 12
	left.add_child(space)
	for entry: Array in [["continue","Continuar aventura",app._resume_title],["new","Nueva partida",app._new_from_title]]:
		var button: Button = app._button(entry[1],entry[2])
		button.custom_minimum_size = Vector2(360,54)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		left.add_child(button)
		controls[entry[0]] = button
	var tools: HBoxContainer = HBoxContainer.new()
	tools.add_theme_constant_override("separation",8)
	left.add_child(tools)
	for entry: Array in [["help","Cómo jugar",func(): app.help_dialog.popup_centered(Vector2i(630,450))],["options","Opciones",app._title_options],["credits","Créditos",func(): app.credits_dialog.popup_centered(Vector2i(720,550))]]:
		var button: Button = app._button(entry[1],entry[2])
		button.add_theme_font_size_override("font_size",16)
		tools.add_child(button)
		controls[entry[0]] = button
	notice = app._label("",16,Color("ecad88"))
	notice.custom_minimum_size.x = 400
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(notice)
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation",16)
	column.add_child(footer)
	var version: Label = app._label("Proyecto de fans · %s · Guardado local" % ProjectSettings.get_setting("application/config/version"),14,Color("a4b9bd"))
	version.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(version)
	for entry: Array in [["lab","Laboratorio táctico",func(): app._menu_selected(7)],["quit","Salir",func(): app.get_tree().quit()]]:
		var button: Button = app._button(entry[1],entry[2])
		button.add_theme_font_size_override("font_size",16)
		footer.add_child(button)
		controls[entry[0]] = button

func refresh() -> void:
	var available: bool = not app.run.is_empty() or FileAccess.file_exists(app.store.file_path)
	for button: Button in controls.values(): button.disabled = app.title_loading
	controls["continue"].disabled = not available
	if app.title_loading: controls["continue"].disabled = true
	controls["continue"].text = "Continuar aventura" if available else "Sin partida guardada"
	controls["continue"].tooltip_text = "Recupera tu equipo y tu progreso." if available else "Elige Nueva partida para visitar a Oak."
	notice.text = app.save_warning
	caption.text = "Tu equipo. Tu estrategia.\nUn viaje desde Pueblo Paleta hasta la Liga."
	if not app.run.is_empty():
		caption.text = "%d medallas · %d compañeros en el equipo\nTu aventura está lista para continuar." % [app.run.get("medals",[]).size(),app.run.party.size()]
	if app.title_loading: return
	var focus: Button = controls["continue"] if available else controls["new"]
	var focused: Control = get_viewport().gui_get_focus_owner()
	if (focused==null or not is_ancestor_of(focused) or not focused.is_visible_in_tree() or (focused is BaseButton and focused.disabled)) and not app.campaign_confirm.visible and not app.help_dialog.visible and not app.credits_dialog.visible and (app.options_dialog==null or not app.options_dialog.visible): focus.grab_focus.call_deferred()
