extends RefCounted

const Symbols = preload("res://ui/move_symbols.gd")
const Info = preload("res://ui/move_info.gd")
const Settings = preload("res://ui/presentation_settings.gd")
var panel: PanelContainer
var heading: Label
var row: HBoxContainer
var scroll: ScrollContainer
var dialog: AcceptDialog
var details: VBoxContainer
var detail_scroll: ScrollContainer
var cards: Array[Button] = []
var signature: String = ""
var selected: Dictionary = {}
var return_focus: Button

func setup(app: Control) -> void:
	panel = app._panel()
	app.battle_overlay.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 18; panel.offset_right = -18; panel.offset_bottom = -14
	var body: VBoxContainer = VBoxContainer.new()
	panel.add_child(body)
	heading = app._label("RIVALES",18)
	body.add_child(heading)
	scroll = ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	body.add_child(scroll)
	row = HBoxContainer.new(); scroll.add_child(row)
	panel.hide()
	dialog = AcceptDialog.new(); dialog.title = "Equipo rival"
	dialog.get_ok_button().text = "Volver"
	app.add_child(dialog)
	detail_scroll = ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialog.add_child(detail_scroll)
	details = VBoxContainer.new(); details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation",12)
	detail_scroll.add_child(details)
	app._watch_dialog(dialog)

func refresh(app: Control) -> void:
	if panel==null: return
	var active: bool = not app.title_visible and app.run.get("phase","")=="battle" and app.state.get("deployment",false)
	var was_visible: bool = panel.visible
	panel.visible = active
	if not active:
		if was_visible:
			app.actor_portrait.get_parent().get_parent().get_parent().show()
			app.hint.get_parent().show()
		if dialog.visible: dialog.hide()
		return
	app.actor_portrait.get_parent().get_parent().get_parent().hide()
	app.hint.get_parent().hide(); app.target_panel.hide()
	var enemies: Array = app.state.units.filter(func(unit: Dictionary): return unit.team=="enemy")
	var factor: float = Settings.font_factor(app)
	panel.offset_left = 18; panel.offset_right = -app.board.reserved_right-8 if factor>1.2 else -18; panel.offset_bottom = -14
	panel.offset_top = -280 if factor>1.2 else -196
	var next: String = JSON.stringify([enemies,factor,app.input_profile.preferences.highContrast])
	if next==signature: return
	signature = next
	app._clear(row); cards.clear()
	heading.text = "EQUIPO RIVAL · %d"%enemies.size()
	for unit: Dictionary in enemies:
		var types: PackedStringArray = []
		for kind: String in unit.types: types.append(Info.TYPES.get(kind,kind))
		var label: String = "%s · Nv. %d\n%s\n%s"%[unit.name,unit.level," / ".join(types),unit.get("abilityName","")]
		if unit.get("dormant",false): label += " · Refuerzo"
		var card: Button = app._button(label,func(): pass)
		card.theme_type_variation = "ToolButton"
		card.add_theme_font_size_override("font_size",17)
		card.custom_minimum_size = Vector2(280*factor,112*factor)
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.icon = app.faces.get(int(unit.speciesId))
		card.expand_icon = true
		card.add_theme_constant_override("icon_max_width",roundi(64*factor))
		card.tooltip_text = "Ver estadísticas y movimientos de "+unit.name
		card.pressed.connect(func(): inspect(app,unit,card))
		row.add_child(card); cards.append(card)
	Settings.apply_fonts(app,panel)

func inspect(app: Control, unit: Dictionary, source: Button) -> void:
	# Read the already generated encounter. Never rebuild enemies or draw RNG.
	selected = unit.duplicate(true); return_focus = source
	app._clear(details)
	dialog.title = "%s · Nv. %d"%[unit.name,unit.level]
	var top: HBoxContainer = HBoxContainer.new(); details.add_child(top)
	var portrait: TextureRect = app._portrait(Vector2(80,80))
	portrait.texture = app.faces.get(int(unit.speciesId)); top.add_child(portrait)
	var title: VBoxContainer = VBoxContainer.new(); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(title)
	title.add_child(app._label(dialog.title,24))
	Symbols.type_badges(title,unit.types)
	add_text(app,"PS %d / %d · Mov. %d"%[unit.hp,unit.maxHp,unit.remaining])
	add_text(app,"Ataque %d · Defensa %d · At. Esp. %d · Def. Esp. %d · Velocidad %d"%[unit.attack,unit.defense,unit.specialAttack,unit.specialDefense,unit.speed])
	add_text(app,str(unit.get("natureText","")))
	add_text(app,str(unit.get("abilityName",""))+" — "+str(unit.get("abilityDescription","")))
	if unit.get("dormant",false): add_text(app,"Refuerzo: entrará durante el combate.")
	add_text(app,"MOVIMIENTOS EQUIPADOS",20)
	var moves: Array = ["basic"]
	for identity: String in unit.get("moves",[]):
		if identity!="basic": moves.append(identity)
	for identity: String in moves:
		var definition: Dictionary = app.rules.progression.BASIC.duplicate(true) if identity=="basic" else app.rules.catalog.moves.get(identity,{})
		if definition.is_empty(): continue
		if identity=="basic" and app.state.get("combatEdition",0)>=20:
			definition.loadoutCost = 0
			definition.description = "Golpe neutro. Sin tipo, STAB, debilidades ni resistencias. Consume la acción."
		var box: PanelContainer = app._panel(); details.add_child(box)
		var content: VBoxContainer = VBoxContainer.new(); box.add_child(content)
		content.add_child(app._label(definition.name,19))
		var text: Label = app._label(Info.details(definition),16)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; content.add_child(text)
	Settings.apply_fonts(app,details)
	var available: Vector2 = app.get_viewport_rect().size
	detail_scroll.custom_minimum_size = Vector2(minf(760,available.x-100),minf(560,available.y-150))
	dialog.reset_size(); dialog.popup_centered()
	detail_scroll.scroll_vertical = 0
	dialog.get_ok_button().grab_focus()

func add_text(app: Control, text: String, font_size: int = 17) -> void:
	if text.is_empty(): return
	var label: Label = app._label(text,font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(label)
