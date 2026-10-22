extends RefCounted

const PAGE_SIZE: int = 6
const Art = preload("res://ui/visual_assets.gd")
var filters: RefCounted = preload("res://ui/roster_filters.gd").new()

func render(app: Control, parent: VBoxContainer) -> void:
	var run: Dictionary = app.run
	var tabs: HBoxContainer = HBoxContainer.new()
	parent.add_child(tabs)
	if app._simple_hub(): app.hub_parts.roster_tabs = tabs
	for tab: String in ["team","pc"]:
		var label: String = "Equipo · %d/6" % run.party.size() if tab=="team" else "PC · %d" % run.reserve.size()
		var button: Button = app._button(label,app._roster_page.bind(tab,0),0 if app._simple_hub() else 205)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if tab=="pc":
			button.icon = Art.icon("pc")
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width",20)
		button.theme_type_variation = "TabButton"
		button.toggle_mode = true
		button.button_pressed = app.roster_tab==tab
		tabs.add_child(button)
		app.travel_buttons["roster_"+tab] = button
	var original: Array = run.party if app.roster_tab=="team" else run.reserve
	if app.roster_tab=="pc": filters.render(app,parent)
	var collection: Array = filters.filtered(app,original) if app.roster_tab=="pc" else original
	if app.roster_tab=="pc": parent.add_child(app._label("%d / %d resultados · selección por ID" % [collection.size(),original.size()],17))
	var heading: Label = app._label("%d en pie" % run.party.filter(func(m):return m.hp>0).size() if app.roster_tab=="team" else "Reserva",18,app.GOLD)
	heading.tooltip_text = "Seis plazas, incluidos debilitados. PC sin límite y cambios gratuitos fuera del combate. Perder un combate termina la campaña aunque queden reservas vivas."
	parent.add_child(heading)
	if collection.is_empty():
		parent.add_child(app._label("PC vacío. Las capturas que superen las seis\nplazas se enviarán aquí automáticamente." if original.is_empty() else "Sin coincidencias; los compañeros del PC se conservan. Limpia los filtros para verlos.",17,app.MUTED))
		if original.is_empty(): app.selected_member = -1
		else: parent.add_child(app._button("Mostrar todos · conservar selección ID %d" % app.selected_member,func(): filters.clear(); app._refresh()))
		return
	if not original.any(func(m):return m.id==app.selected_member): app.selected_member = int(collection[0].id)
	var pages: int = maxi(1,int(ceil(collection.size()/float(PAGE_SIZE))))
	app.roster_offset = clampi(app.roster_offset,0,pages-1)
	var grid: GridContainer = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	grid.columns = 1 if app._simple_hub() or load("res://ui/presentation_settings.gd").font_factor(app)>1.2 else 2
	parent.add_child(grid)
	for index: int in range(app.roster_offset*PAGE_SIZE,mini(collection.size(),(app.roster_offset+1)*PAGE_SIZE)):
		var member_data: Dictionary = collection[index]
		var unit: Dictionary = app.rules.member_unit(member_data)
		var vitals: String = "%d / %d PS" % [unit.hp,unit.maxHp] if unit.hp>0 else "Debilitado"
		var button: Button = app._button("%s · Nv. %d\n%s" % [unit.name,member_data.level,vitals],app._select_member.bind(int(member_data.id)),0 if app._simple_hub() else 205)
		button.accessibility_description = "Origen: %s · ID %d" % [member_data.origin,member_data.id]
		button.icon = app.faces[int(member_data.speciesId)]
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",32)
		button.add_theme_font_size_override("font_size",16)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = app._type_names(unit.types)+" · "+member_data.origin+" · ID %d" % member_data.id
		button.toggle_mode = true
		button.button_pressed = member_data.id==app.selected_member
		var cell: VBoxContainer = VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation",3)
		grid.add_child(cell)
		cell.add_child(button)
		var hp: ProgressBar = ProgressBar.new()
		hp.max_value = unit.maxHp
		hp.value = unit.hp
		hp.show_percentage = false
		hp.custom_minimum_size.y = 5
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = Color("71c5a1") if unit.hp>unit.maxHp/2.0 else (Color("e9c76d") if unit.hp>unit.maxHp/4.0 else Color("ee997e"))
		hp.add_theme_stylebox_override("fill",fill)
		var background: StyleBoxFlat = StyleBoxFlat.new()
		background.bg_color = Color("0b222b")
		hp.add_theme_stylebox_override("background",background)
		cell.add_child(hp)
		app.travel_buttons["member_"+str(int(member_data.id))] = button
	if pages>1:
		var navigation: HBoxContainer = HBoxContainer.new()
		parent.add_child(navigation)
		var previous: Button = app._button("←",app._roster_page.bind("pc",app.roster_offset-1),50)
		previous.disabled = app.roster_offset==0
		navigation.add_child(previous)
		navigation.add_child(app._label("%d / %d" % [app.roster_offset+1,pages],18))
		var next: Button = app._button("→",app._roster_page.bind("pc",app.roster_offset+1),50)
		next.disabled = app.roster_offset==pages-1
		navigation.add_child(next)
		app.travel_buttons.pc_previous = previous
		app.travel_buttons.pc_next = next
	if not collection.any(func(m):return m.id==app.selected_member):
		parent.add_child(app._label("El seleccionado ID %d está fuera del filtro; elige una fila o limpia los filtros." % app.selected_member,17))
		return
	var selected: Dictionary = app.campaign.target(run,app.selected_member)
	var allowed: bool = run.phase in ["map","shop","complete"]
	if app._simple_hub():
		var management: VBoxContainer = VBoxContainer.new()
		management.add_theme_constant_override("separation",10)
		parent.add_child(management)
		app.hub_parts.roster_manage = management
		parent = management
	if app.roster_tab=="team":
		var deposit: Button = app._travel_button("deposit","Guardar en el PC",parent,{"kind":"deposit","member":selected.id})
		deposit.theme_type_variation = "ToolButton"
		deposit.disabled = not allowed or (selected.hp>0 and run.party.filter(func(m):return m.hp>0).size()==1)
		deposit.tooltip_text = "Gratis. Conserva PS, nivel, EXP, movimientos, rasgos y objeto equipado. Deja al menos un compañero en pie."
	else:
		var withdraw: Button = app._travel_button("withdraw","Añadir al equipo · %d/6 plazas" % run.party.size(),parent,{"kind":"withdraw","member":selected.id})
		withdraw.disabled = not allowed or run.party.size()>=6
		withdraw.tooltip_text = "No cura ni revive; ocupa una plaza aunque esté debilitado."
		var choices: OptionButton = OptionButton.new()
		for index: int in run.party.size():
			var member_data: Dictionary = run.party[index]
			choices.add_item("Por %s · Nv. %d%s" % [app.rules.profiles[int(member_data.speciesId)].data.name,member_data.level," · debilitado" if member_data.hp==0 else ""],int(member_data.id))
			if member_data.id==app.roster_swap: choices.select(index)
		parent.add_child(choices)
		app.roster_swap = choices.get_selected_id()
		choices.item_selected.connect(func(_index: int): app.roster_swap = choices.get_selected_id(); app._refresh())
		var outgoing: Dictionary = app.campaign.target(run,app.roster_swap)
		var swap: Button = app._button("Revisar intercambio…",app._review_swap.bind(app.roster_swap,int(selected.id),int(run.revision)))
		parent.add_child(swap)
		app.travel_buttons.swap = swap
		swap.disabled = not allowed or (selected.hp<=0 and outgoing.hp>0 and run.party.filter(func(m):return m.hp>0).size()==1)
		swap.tooltip_text = "Intercambio directo: conserva la posición del equipo y todos los datos de ambos Pokémon. Sin curación ni coste."
		app.travel_buttons.swap_choice = choices
		if withdraw.disabled: parent.add_child(app._label("Retirada bloqueada: equipo lleno o fase sin cambios." ,16))
		if swap.disabled: parent.add_child(app._label("Intercambio bloqueado: conserva al menos un activo en pie y cambia fuera de combate.",16))
