extends "res://ui/laboratory.gd"

const Campaign = preload("res://core/kanto_run.gd")
const CampaignStore = preload("res://core/kanto_store.gd")
var campaign: Campaign = Campaign.new()
var run: Dictionary = {}
var transactions: Array = []
var travel_root: MarginContainer
var travel_content: VBoxContainer
var travel_buttons: Dictionary = {}
var journey_seed: LineEdit
var selected_member: int = 1
var training_choice: OptionButton
var campaign_confirm: ConfirmationDialog
var message: String = ""
var campaign_qa_dir: String = ""

func _ready() -> void:
	rules = campaign.engine
	for record: Dictionary in rules.data.species: faces[int(record.id)] = load("res://" + record.face)
	super._ready()

func _boot() -> void:
	if not qa_dir.is_empty():
		get_tree().change_scene_to_file.call_deferred("res://scenes/laboratory.tscn")
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--campaign-qa-dir="): campaign_qa_dir = argument.trim_prefix("--campaign-qa-dir=")
	qa_running = not campaign_qa_dir.is_empty()
	if qa_running: DirAccess.make_dir_recursive_absolute(campaign_qa_dir)
	store = CampaignStore.new(campaign_qa_dir.path_join("campaign-save.json") if qa_running else "user://kanto-save.json")
	menu.get_popup().set_item_text(menu.get_popup().get_item_index(0),"Nueva campaña")
	menu.get_popup().set_item_text(menu.get_popup().get_item_index(7),"Laboratorio táctico")
	travel_root = MarginContainer.new()
	travel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: travel_root.add_theme_constant_override("margin_" + edge,24)
	add_child(travel_root)
	travel_content = VBoxContainer.new()
	travel_content.add_theme_constant_override("separation",14)
	travel_root.add_child(travel_content)
	campaign_confirm = ConfirmationDialog.new()
	campaign_confirm.title = "Volver al laboratorio de Oak"
	campaign_confirm.dialog_text = "Podrás elegir otro inicial. La campaña anterior se conservará\ncomo copia al comenzar la nueva."
	campaign_confirm.confirmed.connect(_show_oak)
	add_child(campaign_confirm)
	if qa_running: call_deferred("_run_campaign_qa")
	elif FileAccess.file_exists(store.file_path): _load_game()
	else: _show_oak()

func _show_oak() -> void:
	run = {}
	state = {}
	transactions = []
	_refresh()

func _choose_starter(identity: int) -> void:
	var preserved: Dictionary = store.preserve_before_new()
	if not preserved.ok:
		message = preserved.reason
		_refresh()
		return
	run = campaign.create(journey_seed.text,identity)
	transactions = []
	selected_member = 1
	message = ""
	_save()
	_refresh()

func _menu_selected(identity: int) -> void:
	match identity:
		0: campaign_confirm.popup_centered()
		7: get_tree().change_scene_to_file("res://scenes/laboratory.tscn")
		_: super._menu_selected(identity)

func _modal_open() -> bool:
	return super._modal_open() or (campaign_confirm != null and campaign_confirm.visible)

func _player_turn() -> bool:
	return not run.is_empty() and run.phase == "battle" and super._player_turn()

func _save() -> void:
	if run.is_empty(): return
	var result: Dictionary = store.save(run,transactions,"kanto-14")
	save_warning = "" if result.ok else result.reason

func _load_game() -> void:
	var result: Dictionary = store.load_campaign(campaign)
	if not result.ok:
		save_warning = result.reason
		_refresh()
		return
	run = result.state
	transactions = result.commands
	save_warning = ""
	message = "Campaña recuperada."
	pending = {}
	selecting = "auto"
	action_page = false
	selected_action = "basic"
	ai_clock = 0
	_refresh()

func _event(command: Dictionary) -> void:
	if _modal_open(): return
	var result: Dictionary = campaign.transact(run,command)
	if not result.ok:
		message = result.reason
		if _player_turn(): hint.text = message
		return
	run = result.state
	transactions.append(command.duplicate(true))
	pending = {}
	selected_action = "basic"
	action_page = false
	message = ""
	state = run.battle
	history = run.battleCommands
	selecting = "finish" if _player_turn() and state.moved and state.acted else "auto"
	_save()
	_refresh()
	if run.phase == "battle": board.grab_focus()

func _commit(command: Dictionary) -> void:
	_event({"kind":"battle","order":command,"at":run.revision})
	if not state.is_empty(): _play("victory" if state.outcome == "victory" else ("hit" if command.kind == "attack" else "select"))

func _rectify_movement() -> void:
	if not pending.is_empty() or not _player_turn(): return
	_event({"kind":"rectify","at":run.revision})

func _refresh() -> void:
	if travel_root == null:
		super._refresh()
		return
	var fighting: bool = not run.is_empty() and run.phase == "battle"
	board.visible = fighting
	battle_overlay.visible = fighting
	travel_root.visible = not fighting
	if fighting:
		state = run.battle
		history = run.battleCommands
		mode = "current"
		super._refresh()
		heading.text = "%s · ronda %d" % [campaign.locations[int(run.stage)].name,state.round]
		heading.add_theme_font_size_override("font_size",15)
	else: _render_travel()

func _travel_button(key: String, text: String, parent: Node, command: Dictionary) -> Button:
	command.at = run.revision
	var button: Button = _button(text,_event.bind(command))
	travel_buttons[key] = button
	parent.add_child(button)
	return button

func _render_travel() -> void:
	_clear(travel_content)
	travel_buttons.clear()
	var header: HBoxContainer = HBoxContainer.new()
	travel_content.add_child(header)
	var title: Label = _label("KANTO / DE PALETA A BROCK",28,GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var resume: Button = _button("Continuar · F8",_load_game)
	resume.disabled = not FileAccess.file_exists(store.file_path)
	header.add_child(resume)
	header.add_child(_button("Nueva campaña",func(): campaign_confirm.popup_centered()))
	header.add_child(_button("Laboratorio",func(): _menu_selected(7)))
	header.add_child(_button("Ayuda",func(): help_dialog.popup_centered(Vector2i(630,450))))
	var status: Label = _label(save_warning if not save_warning.is_empty() else (message if not message.is_empty() else "Guardado automático local · bajas definitivas"),17,MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	travel_content.add_child(status)
	if run.is_empty():
		travel_content.add_child(_label("Pueblo Paleta · Laboratorio de Oak",30,GOLD))
		travel_content.add_child(_label("Elige un único inicial. Recorrerás Ruta 1, Ruta 2 y Bosque Verde\nantes de desafiar a Brock. Oak te entrega dos pociones y 120 ₽.",20))
		journey_seed = LineEdit.new()
		journey_seed.text = "kanto-14"
		journey_seed.max_length = 64
		journey_seed.placeholder_text = "Semilla de la campaña"
		travel_content.add_child(journey_seed)
		var choices: HBoxContainer = HBoxContainer.new()
		choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
		travel_content.add_child(choices)
		for id: int in [1,4,7]:
			var panel: PanelContainer = _panel()
			panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			choices.add_child(panel)
			var content: VBoxContainer = VBoxContainer.new()
			content.alignment = BoxContainer.ALIGNMENT_CENTER
			content.add_theme_constant_override("separation",20)
			panel.add_child(content)
			var image: TextureRect = _portrait(Vector2(160,160))
			image.texture = faces[id]
			image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			content.add_child(image)
			var label: Label = _label(rules.profiles[id].data.name + "\n" + _type_names(rules.profiles[id].data.types),24,GOLD)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(label)
			var button: Button = _button("Elegir a " + rules.profiles[id].data.name,_choose_starter.bind(id))
			content.add_child(button)
			travel_buttons["starter" + str(id)] = button
		return
	var progress: HBoxContainer = HBoxContainer.new()
	travel_content.add_child(progress)
	for index: int in campaign.locations.size():
		var label: Label = _label(("✓ " if index < run.stage else ("▶ " if index == run.stage else "· ")) + ["Ruta 1","Ruta 2","Bosque Verde","Brock"][index],20,GOLD if index == run.stage else MUTED)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress.add_child(label)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",18)
	travel_content.add_child(body)
	var left: PanelContainer = _panel()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	var narrative: VBoxContainer = VBoxContainer.new()
	narrative.add_theme_constant_override("separation",18)
	left.add_child(narrative)
	var location: Dictionary = campaign.locations[mini(int(run.stage),campaign.locations.size()-1)]
	var heading_text: String = location.name
	if run.phase == "capture": heading_text = "¡Un nuevo compañero!"
	elif run.phase == "shop": heading_text = "Tienda · prepara tu equipo"
	elif run.phase == "complete": heading_text = "Medalla Roca conseguida"
	elif run.phase == "defeat": heading_text = "El equipo ha caído"
	var chapter: Label = _label(heading_text,28,GOLD)
	chapter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative.add_child(chapter)
	var text: Label = _label(location.story,20)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative.add_child(text)
	match run.phase:
		"map":
			_travel_button("enter","Entrar en " + location.name,narrative,{"kind":"enter"})
			text.text += "\n\nUn combate por ubicación. Al ganar: captura local, tienda y siguiente tramo. Los PS no se restauran entre encuentros."
		"capture":
			var image: TextureRect = _portrait(Vector2(160,160))
			image.texture = faces[int(run.reward.speciesId)]
			narrative.add_child(image)
			text.text = "%s\nOrigen: %s\n\nLa captura ya está sorteada y guardada. Cargar no cambia el resultado. Se admiten duplicados en esta muestra." % [rules.profiles[int(run.reward.speciesId)].data.name,run.reward.origin]
			_travel_button("capture","Dar la bienvenida al equipo",narrative,{"kind":"capture"})
		"shop":
			text.text = "Dinero: %d ₽\nPociones: %d · Superpociones: %d · Caramelos Raros: %d\n\nUn Caramelo evoluciona una etapa sin requisito de nivel. No cura. Entrenar añade +5; máximo dos compras por Pokémon.\n\nSelecciona un miembro a la derecha para usar objetos o entrenar." % [run.money,run.bag.potion,run.bag["super-potion"],run.bag["rare-candy"]]
			for item: String in Campaign.ITEMS:
				var button: Button = _travel_button("buy_"+item,"Comprar %s · %d ₽" % [Campaign.ITEMS[item].name,Campaign.ITEMS[item].price],narrative,{"kind":"buy","item":item})
				button.disabled = run.money < Campaign.ITEMS[item].price
			_travel_button("continue","Seguir viaje" if run.stage < 3 else "Cerrar el tramo",narrative,{"kind":"continue"})
		"complete": text.text = "Has vencido a Geodude y Onix. Conservas tu equipo, dinero, objetos y bajas.\n\nLa muestra termina en Brock. Las siguientes rutas, Liga y legendarios pertenecen a otros sprints."
		"defeat": text.text = "Las bajas son definitivas. Esta campaña ha terminado y queda guardada para consultar el equipo.\n\nPuedes comenzar de nuevo con otro inicial o semilla."
	var right: PanelContainer = _panel()
	right.custom_minimum_size.x = 470
	body.add_child(right)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var team: VBoxContainer = VBoxContainer.new()
	team.custom_minimum_size.x = 430
	team.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team.add_theme_constant_override("separation",14)
	scroll.add_child(team)
	team.add_child(_label("TU EQUIPO · %d / 6 vivos" % run.party.filter(func(m):return m.hp > 0).size(),22,GOLD))
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	team.add_child(grid)
	for member: Dictionary in run.party:
		var unit: Dictionary = rules.member_unit(member)
		var button: Button = _button("%s\n%d / %d PS%s" % [unit.name,unit.hp,unit.maxHp," · BAJA" if unit.hp == 0 else ""],_select_member.bind(int(member.id)),205)
		button.toggle_mode = true
		button.button_pressed = member.id == selected_member
		grid.add_child(button)
	var selected: Dictionary = campaign.target(run,selected_member)
	if selected.is_empty(): return
	var unit: Dictionary = rules.member_unit(selected)
	var image: TextureRect = _portrait(Vector2(96,96))
	image.texture = faces[int(selected.speciesId)]
	team.add_child(image)
	var info: Label = _label("%s · %s\nOrigen: %s\nAtaque %d / %d · Defensa %d / %d · Velocidad %d" % [unit.name,_type_names(unit.types),selected.origin,unit.attack,unit.specialAttack,unit.defense,unit.specialDefense,unit.speed],17)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	team.add_child(info)
	if run.phase == "shop":
		for item: String in ["potion","super-potion"]:
			var button: Button = _travel_button("heal_"+item,"Usar %s · +%d PS" % [Campaign.ITEMS[item].name,Campaign.ITEMS[item].heal],team,{"kind":"heal","item":item,"member":selected_member})
			button.disabled = selected.hp <= 0 or selected.hp >= unit.maxHp or run.bag[item] <= 0
		var evolve: Button = _travel_button("evolve","Evolucionar · 1 Caramelo Raro",team,{"kind":"evolve","member":selected_member})
		evolve.disabled = selected.hp <= 0 or not Campaign.EVOLUTIONS.has(int(selected.speciesId)) or run.bag["rare-candy"] <= 0
		training_choice = OptionButton.new()
		for stat: String in Campaign.STATS: training_choice.add_item(Campaign.STATS[stat])
		team.add_child(training_choice)
		var count: int = 0
		for amount: Variant in selected.training.values(): count += int(amount)
		var train: Button = _button("Entrenar +5 · 80 ₽ · %d / 2" % count,_train.bind(int(run.revision)))
		team.add_child(train)
		travel_buttons.train = train
		train.disabled = selected.hp <= 0 or count >= 2 or run.money < 80

func _select_member(identity: int) -> void:
	selected_member = identity
	_refresh()

func _train(revision: int) -> void:
	_event({"kind":"train","stat":Campaign.STATS.keys()[training_choice.selected],"member":selected_member,"at":revision})

func _run_campaign_qa() -> void:
	await load("res://ui/qa_campaign.gd").new().run(self,campaign_qa_dir)
