extends "res://ui/laboratory.gd"

const Campaign = preload("res://core/kanto_run.gd")
const Advanced = preload("res://core/letsgo_run.gd")
const CampaignStore = preload("res://core/kanto_store.gd")
var campaign: RefCounted = Advanced.new()
var last_presentation: Dictionary = {}
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
	combat_feedback.clear()
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
	campaign = Advanced.new()
	rules = campaign.engine
	board.setup(rules.data.species)
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
	campaign = result.rules
	rules = campaign.engine
	board.setup(rules.data.species)
	combat_feedback.clear()
	run = result.state
	transactions = result.commands
	save_warning = ""
	message = "Campaña recuperada." if run.get("edition",1) == 5 else "Partida clásica %s: conserva sus reglas. Nueva campaña para las tablas de Let’s Go." % _classic_version()
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
		else: _refresh()
		return
	last_presentation = result.get("presentation",{})
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
	if command.kind=="level-up": _play("level-up")
	if run.phase == "battle": board.grab_focus()

func _commit(command: Dictionary) -> void:
	var before: Dictionary = state
	var revision: int = run.revision
	var plan: Dictionary = rules.attack_plan(state,int(command.target),{},command.get("actionId","basic")) if command.kind == "attack" else {}
	_event({"kind":"battle","order":command,"at":revision})
	if run.revision == revision: return
	if command.kind == "attack": combat_feedback.present(before,plan,last_presentation.get("hits",[]))
	var leveled: bool = run.get("lastProgress",[]).any(func(entry):return entry.level > entry.before)
	_play(("level-up" if leveled else "victory") if state.outcome == "victory" else (combat_feedback.last_sound if command.kind == "attack" else "select"))

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
		var location_name: String = ["Ruta 1","Ruta 2","Bosque Verde","Brock"][int(run.stage)] if run.get("edition",1) == 1 else campaign.locations[int(run.stage)].name
		heading.text = "%s · ronda %d%s" % [location_name,state.round," · clásica 0.14" if run.get("edition",1) == 1 else ""]
		heading.add_theme_font_size_override("font_size",15)
		var active: Dictionary = rules.active(state)
		if active.has("level"):
			actor_info.text = "Nv. %d · " % active.level + actor_info.text
			actor_info.tooltip_text = campaign.progression.roles(active)
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
	var classic: String = ""
	if not run.is_empty() and run.get("edition",1)<5: classic = "Clásica %s: Nueva campaña para encuentros y aprendizaje de Let’s Go." % _classic_version()
	var status: Label = _label(save_warning if not save_warning.is_empty() else (message if not message.is_empty() else (classic if not classic.is_empty() else "Guardado automático local · bajas definitivas")),17,MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	travel_content.add_child(status)
	if run.is_empty():
		travel_content.add_child(_label("Pueblo Paleta · Laboratorio de Oak",30,GOLD))
		travel_content.add_child(_label("Elige un inicial de nivel 5. Gana EXP, aprende y combina cuatro movimientos\nmás el básico neutro. Oak te entrega dos pociones y 120 ₽.",20))
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
	var story_scroll: ScrollContainer = ScrollContainer.new()
	story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(story_scroll)
	var narrative: VBoxContainer = VBoxContainer.new()
	narrative.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narrative.add_theme_constant_override("separation",18)
	story_scroll.add_child(narrative)
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
			text.text = "%s\nOrigen: %s\n\nLa captura ya está sorteada y guardada. Cargar no cambia el resultado. Se admiten duplicados en esta muestra." % [rules.profiles[int(run.reward.speciesId)].data.name + (" · Nv. %d" % run.reward.level if run.reward.has("level") else ""),run.reward.origin]
			_travel_button("capture","Dar la bienvenida al equipo",narrative,{"kind":"capture"})
		"shop":
			text.text = "Dinero: %d ₽\nPociones: %d · Superpociones: %d · Caramelos Raros: %d\n\nUn Caramelo evoluciona una etapa sin requisito de nivel. No cura. Entrenar añade +5; máximo dos compras por Pokémon.\n\nSelecciona un miembro a la derecha para usar objetos o entrenar." % [run.money,run.bag.potion,run.bag["super-potion"],run.bag["rare-candy"]]
			if run.get("edition",1) >= 2:
				text.text = "Dinero: %d ₽\nPociones: %d · Superpociones: %d · Caramelos Raros: %d\n\nLas estadísticas crecen al subir de nivel. La EXP se gana con victorias.\n\nEvolución: nivel requerido + un Caramelo Raro. No cura ni da niveles. Preparar movimientos es gratis." % [run.money,run.bag.potion,run.bag["super-potion"],run.bag["rare-candy"]]
			if run.get("edition",1) >= 3:
				text.text = "Dinero: %d ₽\nPociones: %d · Superpociones: %d · Caramelos: %d\nNivel mínimo + Caramelo para evolucionar; no cura.\nCompra MT/equipo y úsalo con un miembro a la derecha." % [run.money,run.bag.potion,run.bag["super-potion"],run.bag["rare-candy"]]
				if run.get("edition",1)>=4: text.text = "Dinero: %d ₽\nPociones: %d · Superpociones: %d · Caramelos: %d\nCaramelo: +1 nivel. Evolución automática al alcanzar el nivel.\nCompra y usa objetos con un miembro a la derecha." % [run.money,run.bag.potion,run.bag["super-potion"],run.bag["rare-candy"]]
				_render_stock(narrative)
			var consumables: Dictionary = campaign.consumables if run.get("edition",1)>=4 else Campaign.ITEMS
			for item: String in consumables:
				var button: Button = _travel_button("buy_"+item,"Comprar %s · %d ₽" % [consumables[item].name,consumables[item].price],narrative,{"kind":"buy","item":item})
				button.disabled = run.money < consumables[item].price
			if run.get("edition",1)>=5:
				var stone: Button = _travel_button("buy_leaf-stone","Comprar Piedra Hoja · 80 ₽",narrative,{"kind":"buy-stone"})
				stone.disabled = run.money<80
				stone.tooltip_text = "Evoluciona Gloom y Weepinbell. No cura ni sube niveles."
			_travel_button("continue","Seguir viaje" if run.stage < 3 else "Cerrar el tramo",narrative,{"kind":"continue"})
		"complete": text.text = "Has vencido a Geodude y Onix. Conservas tu equipo, dinero, objetos y bajas.\n\nLa muestra termina en Brock. Las siguientes rutas, Liga y legendarios pertenecen a otros sprints."
		"defeat": text.text = "Las bajas son definitivas. Esta campaña ha terminado y queda guardada para consultar el equipo.\n\nPuedes comenzar de nuevo con otro inicial o semilla."
	if run.get("edition",1) >= 2 and run.phase in ["capture","shop"]:
		var summary: Label = _label(_progress_summary(),17,GOLD)
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		narrative.add_child(summary)
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
		var button: Button = _button("%s\n%d / %d PS%s" % [unit.name + (" · Nv. %d" % member.level if member.has("level") else ""),unit.hp,unit.maxHp," · BAJA" if unit.hp == 0 else ""],_select_member.bind(int(member.id)),205)
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
	if run.get("edition",1) >= 3: _render_inventory(team,selected)
	if run.get("edition",1) >= 2 and run.phase != "shop":
		_render_moves(team,selected)
	if run.phase == "shop":
		for item: String in ["potion","super-potion"]:
			var button: Button = _travel_button("heal_"+item,"Usar %s · +%d PS" % [Campaign.ITEMS[item].name,Campaign.ITEMS[item].heal],team,{"kind":"heal","item":item,"member":selected_member})
			button.disabled = selected.hp <= 0 or selected.hp >= unit.maxHp or run.bag[item] <= 0
		if run.get("edition",1)>=4:
			var candy: Button = _travel_button("level-up","Usar Caramelo Raro · +1 nivel",team,{"kind":"level-up","member":selected_member})
			candy.disabled = selected.hp<=0 or selected.level>=campaign.progression.data.levelCap or run.bag["rare-candy"]<=0
			candy.tooltip_text = "Conserva EXP parcial y PS actuales. La evolución ocurre automáticamente al alcanzar su nivel."
			var automatic: Dictionary = campaign.progression.evolution(selected)
			var evolution_label: Label = _label("Evolución automática: %s · Nv. %d" % [rules.profiles[int(automatic.speciesId)].data.name,automatic.level] if not automatic.is_empty() else "Sin otra evolución de Kanto",17,MUTED)
			evolution_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			team.add_child(evolution_label)
			if run.get("edition",1)>=5 and campaign.progression.data.stoneEvolutions.has(str(int(selected.speciesId))):
				evolution_label.text = "Evolución con Piedra Hoja · bolsa: %d" % run.bag["leaf-stone"]
				var stone: Button = _travel_button("stone","Usar Piedra Hoja",team,{"kind":"stone","member":selected_member})
				stone.disabled = selected.hp<=0 or run.bag["leaf-stone"]<=0
			_render_moves(team,selected)
			return
		var evolve: Button = _travel_button("evolve","Evolucionar · 1 Caramelo Raro",team,{"kind":"evolve","member":selected_member})
		evolve.disabled = selected.hp <= 0 or not Campaign.EVOLUTIONS.has(int(selected.speciesId)) or run.bag["rare-candy"] <= 0
		if run.get("edition",1) >= 2:
			var requirement: Dictionary = campaign.progression.evolution(selected)
			evolve.text = "Sin otra evolución de Kanto" if requirement.is_empty() else "Evolucionar · Nv. %d + 1 Caramelo" % requirement.level
			evolve.disabled = selected.hp <= 0 or requirement.is_empty() or selected.level < requirement.level or run.bag["rare-candy"] <= 0
			_render_moves(team,selected)
			return
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

func _progress_summary() -> String:
	var lines: Array[String] = []
	for entry: Dictionary in run.get("lastProgress",[]):
		var text: String = "%s: +%d EXP" % [entry.name,entry.xp]
		if entry.level > entry.before: text += " · Nv. %d → %d" % [entry.before,entry.level]
		for evolution: Dictionary in entry.get("evolutions",[]): text += " · %s → %s" % [rules.profiles[int(evolution.from)].data.name,rules.profiles[int(evolution.to)].data.name]
		if not entry.learned.is_empty(): text += " · aprende " + ", ".join(entry.learned.map(func(id):return campaign.progression.data.moves[id].name))
		lines.append(text)
	return "\n".join(lines)

func _render_moves(parent: VBoxContainer, member: Dictionary) -> void:
	var study: RefCounted = campaign.progression
	parent.add_child(_label("Nv. %d · EXP %d / %d" % [member.level,member.xp,study.next_xp(member.level)],20,GOLD))
	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = study.next_xp(member.level)
	bar.value = member.xp
	bar.show_percentage = false
	bar.custom_minimum_size.y = 9
	parent.add_child(bar)
	var roles: Label = _label(study.roles(member),17,MUTED)
	roles.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roles.tooltip_text = "Número de movimientos preparados de cada rol; no concede estadísticas adicionales."
	parent.add_child(roles)
	parent.add_child(_label("Básico neutro fijo · 0 PT · sin STAB\nMOVIMIENTOS · %d / 4 · cambiar es gratis" % member.moves.size(),17,GOLD))
	for identity: String in member.knownMoves:
		var definition: Dictionary = study.data.moves[identity]
		var button: CheckButton = CheckButton.new()
		button.text = "%s · %s · %d PT" % [definition.name,TYPE_NAMES.get(definition.type,definition.type),definition.cost]
		button.button_pressed = identity in member.moves
		button.disabled = run.phase not in ["map","shop","complete"] or member.hp <= 0 or (member.moves.size() >= 4 and not button.button_pressed)
		button.tooltip_text = definition.description + " Quita uno para preparar otro si tienes cuatro."
		button.toggled.connect(_toggle_move.bind(int(member.id),identity,int(run.revision)))
		parent.add_child(button)
		travel_buttons["move_"+identity] = button
	var pending_moves: Array = []
	for entry: Dictionary in study.families[int(member.speciesId)].learnset:
		if run.get("edition",1)>=5 and (entry.level<=member.level or not entry.forms.any(func(id):return int(id)==int(member.speciesId))): continue
		if entry.id not in member.knownMoves:
			pending_moves.append("%s · Nv. %d%s" % [study.data.moves[entry.id].name,entry.level," · tras evolucionar" if not entry.forms.any(func(id):return int(id)==int(member.speciesId)) else ""])
	var pending_label: Label = _label("Próximos: " + "; ".join(pending_moves.slice(0,3)),16,MUTED)
	pending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(pending_label)

func _toggle_move(enabled: bool, member_id: int, identity: String, revision: int) -> void:
	var member: Dictionary = campaign.target(run,member_id)
	var moves: Array = member.moves.duplicate()
	if enabled: moves.append(identity)
	else: moves.erase(identity)
	_event({"kind":"loadout","member":member_id,"moves":moves,"at":revision})

func _default_hint() -> String:
	var classic: String = ""
	if not run.is_empty() and run.get("edition",1)<5: classic = "Clásica %s: menú → Nueva campaña para Let’s Go.\n" % _classic_version()
	return classic + super._default_hint()

func _classic_version() -> String:
	return {1:"0.14",2:"0.14.1",3:"0.14.2",4:"0.14.3"}.get(int(run.get("edition",1)),"0.14")

func _render_stock(parent: VBoxContainer) -> void:
	parent.add_child(_label("OFERTAS · MT Y EQUIPO",21,GOLD))
	var cost: int = campaign.reroll_price(run)
	var reroll: Button = _travel_button("reroll","Renovar 3 ofertas · %d ₽" % cost,parent,{"kind":"reroll"})
	reroll.disabled = run.money<cost
	reroll.tooltip_text = "Renovaciones: 25, 50, 75… ₽ por visita. Cada oferta tiene una copia; renovar repone tres. Las compras van a la bolsa."
	for i: int in run.stock.size():
		var offer: Dictionary = run.stock[i]
		var item: Dictionary = campaign.shop_data.items[offer.item]
		var card: PanelContainer = _panel()
		parent.add_child(card)
		var content: VBoxContainer = VBoxContainer.new()
		card.add_child(content)
		var buy: Button = _travel_button("stock_"+str(i),"%s · %s" % [item.name,"AGOTADO" if offer.sold else "%d ₽" % item.price],content,{"kind":"buy-stock","slot":i})
		buy.disabled = offer.sold or run.money<item.price
		var description: String = item.description
		if item.kind == "tm":
			var names: Array[String] = []
			for member: Dictionary in run.party:
				if member.hp>0 and campaign.compatible(member,offer.item) and item.move not in member.knownMoves: names.append(rules.profiles[int(member.speciesId)].data.name)
			var move: Dictionary = campaign.progression.data.moves[item.move]
			description = "%s · %d PT · alcance %d%s\nPuede aprender: %s" % [TYPE_NAMES.get(move.type,move.type),move.cost,move.range," · potencia %d" % move.power if move.power>0 else "",", ".join(names) if not names.is_empty() else "nadie del equipo actual"]
			buy.tooltip_text = move.description.replace("speed","Velocidad").replace("defense","Defensa").replace("attack","Ataque") + " " + item.description
		else: buy.tooltip_text = item.description
		var label: Label = _label(description,16,MUTED)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(label)

func _render_inventory(parent: VBoxContainer, member: Dictionary) -> void:
	var held: Variant = member.get("heldItem")
	parent.add_child(_label("Objeto: " + (campaign.shop_data.items[held].name if held != null else "ninguno") + " · 1 / Pokémon",18,GOLD))
	var allowed: bool = member.hp>0 and run.phase in ["map","shop","complete"]
	if held != null:
		var remove: Button = _travel_button("unequip","Guardar objeto en la bolsa",parent,{"kind":"equip","member":member.id,"item":""})
		remove.disabled = not allowed
	for identity: String in campaign.shop_data.items:
		if run.bag[identity]<=0: continue
		var item: Dictionary = campaign.shop_data.items[identity]
		var teach: bool = item.kind == "tm"
		var available: bool = allowed and (campaign.compatible(member,identity) and item.move not in member.knownMoves if teach else held != identity)
		var label: String = "%s %s · bolsa %d" % ["Aprender" if teach else "Equipar",item.name,run.bag[identity]]
		var button: Button = _travel_button("use_"+identity,label,parent,{"kind":"teach" if teach else "equip","member":member.id,"item":identity})
		button.disabled = not available
		button.tooltip_text = item.description + (" Ya aprendido o incompatible." if teach and not available else "")
