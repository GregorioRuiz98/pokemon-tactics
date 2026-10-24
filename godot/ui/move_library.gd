extends RefCounted

var selected_slot: int = -1
var owner_id: int = -1
var query: String = ""
var category: int = 0
var max_cost: int = 5
var type_index: int = 0
var caret: int = 0

func render(app: Control, parent: VBoxContainer, member: Dictionary) -> void:
	if owner_id!=member.id: owner_id = int(member.id); selected_slot = -1
	var slots: GridContainer = GridContainer.new()
	slots.columns = 2
	slots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots.add_theme_constant_override("h_separation",8)
	slots.add_theme_constant_override("v_separation",8)
	parent.add_child(slots)
	for index: int in 4:
		var label: String = "%d · %s" % [index+1,app.campaign.progression.data.moves[member.moves[index]].name if index<member.moves.size() else "Vacía"]
		var slot: Button = app._button(label,func(): selected_slot = index; app._refresh())
		# Wrapped buttons have no text-based minimum width: expand both grid columns.
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot.disabled = index>member.moves.size()
		slot.tooltip_text = "Rellena primero la primera ranura vacía; las ranuras preparadas son consecutivas."
		slot.toggle_mode = true
		slot.button_pressed = selected_slot==index
		slots.add_child(slot)
		app.travel_buttons["move_slot_"+str(index)] = slot
	if selected_slot>=0 and selected_slot<member.moves.size():
		parent.add_child(app._button("Vaciar la ranura seleccionada…",func():
			var moves: Array = member.moves.duplicate()
			moves.remove_at(selected_slot)
			app._review_loadout(int(member.id),moves,"Vaciar ranura; el básico neutro se conserva.")))
	var search: LineEdit = LineEdit.new()
	search.placeholder_text = "Buscar movimiento conocido"
	search.text = query
	search.caret_column = caret
	search.text_changed.connect(func(value: String): query = value; caret = search.caret_column; app._refresh.call_deferred())
	parent.add_child(search)
	app.travel_buttons.move_search = search
	var filters: GridContainer = GridContainer.new()
	filters.columns = 1 if load("res://ui/presentation_settings.gd").font_factor(app)>1.2 else 2
	parent.add_child(filters)
	var category_choice: OptionButton = OptionButton.new()
	for text: String in ["Cualquier función","Ataques físicos/especiales","Apoyos y control"]: category_choice.add_item(text)
	category_choice.select(category)
	category_choice.item_selected.connect(func(index: int): category = index; app._refresh())
	filters.add_child(category_choice)
	var types: OptionButton = OptionButton.new()
	for text: String in ["Todos los tipos"]+app.TYPE_NAMES.values(): types.add_item(text)
	types.select(type_index)
	types.item_selected.connect(func(index: int): type_index = index; app._refresh())
	filters.add_child(types)
	var cost: SpinBox = SpinBox.new()
	cost.min_value = 0
	cost.max_value = 5
	cost.value = max_cost
	cost.prefix = "PT máximos: "
	cost.value_changed.connect(func(value: float): max_cost = int(value); app._refresh())
	filters.add_child(cost)
	var count: int = 0
	for id: String in member.knownMoves:
		var definition: Dictionary = app.campaign.progression.data.moves[id]
		if not query.is_empty() and query.to_lower() not in definition.name.to_lower(): continue
		if category==1 and definition.category=="status" or category==2 and definition.category!="status": continue
		if type_index>0 and definition.type!=app.TYPE_NAMES.keys()[type_index-1]: continue
		if definition.cost>max_cost: continue
		count += 1
		var button: Button = app._button("%s · %s · %d PT · alcance %d%s" % [definition.name,app.TYPE_NAMES.get(definition.type,definition.type),definition.cost,definition.range," · preparado" if id in member.moves else ""],choose.bind(app,member,id))
		button.tooltip_text = definition.description
		parent.add_child(button)
		app.travel_buttons["move_"+id] = button
	parent.add_child(app._label("%d movimientos disponibles. Elegir una ranura y un movimiento muestra la comparación; no consume MT." % count,16))

func choose(app: Control, member: Dictionary, id: String) -> void:
	var definition: Dictionary = app.campaign.progression.data.moves[id]
	if selected_slot<0:
		app._review_text("Detalle de movimiento",definition.name+"\n"+definition.description+"\nElige primero una ranura para preparar.")
		return
	if app.run.phase not in ["map","shop","complete"] or member.hp<=0:
		app._review_text("Preparación no disponible","Solo fuera de combate y con un compañero en pie.")
		return
	if id in member.moves:
		app._review_text("Ya preparado",definition.name+" ya ocupa una ranura; no se puede duplicar.")
		return
	var moves: Array = member.moves.duplicate()
	if selected_slot<moves.size(): moves[selected_slot] = id
	else: moves.append(id)
	app._review_loadout(int(member.id),moves,definition.name+"\n"+definition.description)
