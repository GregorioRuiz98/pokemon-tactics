extends RefCounted

const PAGE_SIZE: int = 6

func render(app: Control, parent: VBoxContainer) -> void:
	var run: Dictionary = app.run
	var tabs: HBoxContainer = HBoxContainer.new()
	parent.add_child(tabs)
	for tab: String in ["team","pc"]:
		var label: String = "Equipo · %d/6" % run.party.size() if tab=="team" else "PC · %d" % run.reserve.size()
		var button: Button = app._button(label,app._roster_page.bind(tab,0),205)
		button.toggle_mode = true
		button.button_pressed = app.roster_tab==tab
		tabs.add_child(button)
		app.travel_buttons["roster_"+tab] = button
	var collection: Array = run.party if app.roster_tab=="team" else run.reserve
	var heading: Label = app._label("%d en pie · se despliega este equipo" % run.party.filter(func(m):return m.hp>0).size() if app.roster_tab=="team" else "Reserva · sin curación ni EXP de combate",18,app.GOLD)
	heading.tooltip_text = "Seis plazas, incluidos debilitados. PC sin límite y cambios gratuitos fuera del combate. Perder un combate termina la campaña aunque queden reservas vivas."
	parent.add_child(heading)
	if collection.is_empty():
		parent.add_child(app._label("PC vacío. Las capturas que superen las seis\nplazas se enviarán aquí automáticamente.",17,app.MUTED))
		app.selected_member = -1
		return
	if not collection.any(func(m):return m.id==app.selected_member): app.selected_member = int(collection[0].id)
	var pages: int = maxi(1,int(ceil(collection.size()/float(PAGE_SIZE))))
	app.roster_offset = clampi(app.roster_offset,0,pages-1)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	parent.add_child(grid)
	for index: int in range(app.roster_offset*PAGE_SIZE,mini(collection.size(),(app.roster_offset+1)*PAGE_SIZE)):
		var member_data: Dictionary = collection[index]
		var unit: Dictionary = app.rules.member_unit(member_data)
		var button: Button = app._button("%s · Nv. %d\n%d / %d PS%s" % [unit.name,member_data.level,unit.hp,unit.maxHp," · DEBILITADO" if unit.hp==0 else ""],app._select_member.bind(int(member_data.id)),205)
		button.toggle_mode = true
		button.button_pressed = member_data.id==app.selected_member
		grid.add_child(button)
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
	var selected: Dictionary = app.campaign.target(run,app.selected_member)
	var allowed: bool = run.phase in ["map","shop","complete"]
	if app.roster_tab=="team":
		var deposit: Button = app._travel_button("deposit","Guardar en el PC",parent,{"kind":"deposit","member":selected.id})
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
		var swap: Button = app._travel_button("swap","Intercambiar con el equipo",parent,{"kind":"swap","member":app.roster_swap,"reserve":selected.id})
		swap.disabled = not allowed or (selected.hp<=0 and outgoing.hp>0 and run.party.filter(func(m):return m.hp>0).size()==1)
		swap.tooltip_text = "Intercambio directo: conserva la posición del equipo y todos los datos de ambos Pokémon. Sin curación ni coste."
		app.travel_buttons.swap_choice = choices
