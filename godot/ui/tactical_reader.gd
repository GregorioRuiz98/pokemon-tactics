extends AcceptDialog

const Info = preload("res://ui/tactical_info.gd")
var app: Control
var body: Label
var choices: OptionButton

func setup(owner_app: Control) -> void:
	app = owner_app
	title = "Inspección táctica"
	ok_button_text = "Volver"
	dialog_close_on_escape = false
	theme = app.theme
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(620,400)
	add_child(column)
	choices = OptionButton.new()
	choices.item_selected.connect(func(_index: int): show_unit(choices.get_selected_id()))
	column.add_child(choices)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620,380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	body = app._label("",18)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.focus_mode = Control.FOCUS_ALL
	scroll.add_child(body)

func open_unit() -> void:
	choices.clear()
	choices.show()
	var target: Dictionary = app._unit_at({"x":app.board.cursor.x,"y":app.board.cursor.y})
	if target.is_empty(): target = app.rules.active(app.state)
	for unit: Dictionary in app.rules.living(app.state):
		choices.add_item("%s · %s · ID %d" % [unit.name,"aliado" if unit.team=="ally" else "rival",unit.id],int(unit.id))
		if unit.id==target.id: choices.select(choices.item_count-1)
	show_unit(int(target.id))
	popup_centered(Vector2i(700,570))

func show_unit(identity: int) -> void:
	var unit: Dictionary = app.rules.unit_by_id(app.state,identity)
	body.text = Info.unit_text(app,unit)
	if app._player_turn() and not app.state.acted:
		var plan: Dictionary = app.rules.attack_plan(app.state,identity,{},app.selected_action)
		app._show_plan(unit,plan)
		body.text += "\n\nPREVISIÓN\n"+(app.target_info.get_meta("details",app.target_info.text) if plan.ok else plan.reason)
	body.text += "\n\nPT: recurso de acciones, no dinero. Básico neutro: 0 PT, sin tipo ni STAB.\nLa orientación modifica la banda de daño y el crítico en ediciones actuales; no la precisión."

func open_history() -> void:
	choices.hide()
	body.text = "RESULTADOS REALES\n"+app.recent_result+"\n\nREGISTRO DEL COMBATE\n"+"\n".join(app.state.get("log",[]))
	popup_centered(Vector2i(700,570))
