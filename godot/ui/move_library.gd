extends RefCounted

const Info = preload("res://ui/move_info.gd")
const Tactics = preload("res://ui/tactical_loadouts.gd")

var selected_slot: int = -1
var owner_id: int = -1
var query: String = ""
var category: int = 0
var max_cost: int = 5
var type_index: int = 0
var caret: int = 0
var tactical_filter: int = 0

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
		if app.run.get("edition",0)>=23 and index<member.moves.size(): label += " · %d PP" % app.campaign.progression.data.moves[member.moves[index]].loadoutCost
		var slot: Button = app._button(label,func(): selected_slot = index; app._refresh())
		# Wrapped buttons have no text-based minimum width: expand both grid columns.
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot.disabled = index>member.moves.size()
		slot.tooltip_text = "Elige una ranura para cambiarla."
		slot.toggle_mode = true
		slot.button_pressed = selected_slot==index
		slots.add_child(slot)
		app.travel_buttons["move_slot_"+str(index)] = slot
	if app.run.get("edition",0)>=21:
		var team: Button = app._button("Herramientas del equipo",func():app._review_text("Movimientos del equipo",Tactics.team_summary(app)))
		team.theme_type_variation = "ToolButton"; parent.add_child(team); app.travel_buttons.team_tools = team
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
	cost.prefix = "PP: " if app.run.get("edition",0)>=23 else "PT: "
	cost.custom_minimum_size.x = 160
	cost.tooltip_text = "Coste máximo para filtrar movimientos. No consume PT."
	cost.accessibility_name = "Coste máximo al equipar, en PP" if app.run.get("edition",0)>=23 else "Coste máximo de movimiento, en PT"
	if app.run.get("edition",0)>=23: cost.tooltip_text = "Filtrar por PP necesarios al equipar."
	cost.value_changed.connect(func(value: float): max_cost = int(value); app._refresh())
	filters.add_child(cost)
	var tactics: OptionButton = OptionButton.new()
	for text: String in ["Todas las herramientas","Áreas","Zonas persistentes","Empujar, atraer o acercarse","Estados y atributos","Curar, proteger o disipar"]: tactics.add_item(text)
	tactics.select(tactical_filter)
	tactics.item_selected.connect(func(index: int): tactical_filter = index; app._refresh())
	tactics.accessibility_name = "Filtrar por función táctica"
	filters.add_child(tactics); app.travel_buttons.move_tactics = tactics
	var count: int = 0
	for id: String in member.knownMoves:
		var definition: Dictionary = app.campaign.progression.data.moves[id]
		if not query.is_empty() and query.to_lower() not in definition.name.to_lower(): continue
		if category==1 and definition.category=="status" or category==2 and definition.category!="status": continue
		if type_index>0 and definition.type!=app.TYPE_NAMES.keys()[type_index-1]: continue
		if int(definition.get("loadoutCost",definition.cost))>max_cost: continue
		if not Tactics.matches(definition,tactical_filter): continue
		count += 1
		var features: Array[String] = Tactics.tags(definition)
		var button: Button = app._button("%s%s\n%s%s" % [definition.name," · preparado" if id in member.moves else "",Info.summary(definition),"\n"+" · ".join(features) if not features.is_empty() else ""],choose.bind(app,member,id))
		button.tooltip_text = Info.details(definition)
		button.accessibility_description = button.tooltip_text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		parent.add_child(button)
		app.travel_buttons["move_"+id] = button
	parent.add_child(app._label("%d movimientos conocidos." % count,16))

func render_proposals(app: Control, parent: VBoxContainer, member: Dictionary) -> void:
	var suggestions: Array = [Tactics.propose(app.campaign.progression,member,0),Tactics.propose(app.campaign.progression,member,1)]
	var row: GridContainer = GridContainer.new(); row.columns = 2; parent.add_child(row)
	for index: int in 2:
		var proposal: Dictionary = suggestions[index]
		var names: String = ", ".join(proposal.moves.map(func(id):return app.campaign.progression.data.moves[id].name))
		var description: String = proposal.name+"\n"+" · ".join(proposal.features)+"\nPropuesta con tus movimientos aprendidos. Puedes modificarla después."
		var button: Button = app._button(proposal.name+"…",app._review_loadout.bind(int(member.id),proposal.moves,description))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = names+"\n"+description; button.accessibility_description = button.tooltip_text
		button.disabled = proposal.moves.is_empty() or member.hp<=0 or app.run.phase not in ["map","shop","complete"]
		row.add_child(button); app.travel_buttons["role_"+str(index)] = button
	var left: Array = suggestions[0].moves.duplicate(); var right: Array = suggestions[1].moves.duplicate()
	left.sort(); right.sort()
	if left==right:
		var note: Label = app._label("Los dos roles comparten movimientos por ahora. Aprende más técnicas o MT para diferenciarlos.",16,app.MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; parent.add_child(note)
	var team: Button = app._button("Herramientas del equipo",func():app._review_text("Plan de equipo",Tactics.team_summary(app)))
	team.theme_type_variation = "ToolButton"; parent.add_child(team); app.travel_buttons.team_tools = team

func choose(app: Control, member: Dictionary, id: String) -> void:
	var definition: Dictionary = app.campaign.progression.data.moves[id]
	if selected_slot<0:
		app._review_text(definition.name,Info.details(definition)+"\n\nElige primero una ranura para prepararlo.",definition)
		return
	if app.run.phase not in ["map","shop","complete"] or member.hp<=0:
		app._review_text("Preparación no disponible","Solo fuera de combate y con un compañero en pie.")
		return
	if id in member.moves:
		app._review_text("Ya preparado",definition.name+" ya está preparado.")
		return
	var moves: Array = member.moves.duplicate()
	if selected_slot<moves.size(): moves[selected_slot] = id
	else: moves.append(id)
	app._review_loadout(int(member.id),moves,definition.name+"\n"+Info.details(definition),definition)
