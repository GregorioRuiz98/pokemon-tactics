extends RefCounted

const Info = preload("res://ui/move_info.gd")
const Art = preload("res://ui/visual_assets.gd")
var actor: Control
var greeting: String = "¡Bienvenido! Echa un vistazo."
var selected: int = 0
var detail: Label
var greeting_label: Label
var cards: Dictionary = {}
var previous_stock: Dictionary = {}

func arrive() -> void:
	greeting = "¡Bienvenido! Echa un vistazo."; selected = 0; previous_stock.clear()

func available(app: Control) -> bool:
	return app.run.get("edition",0)>=20 and app.run.get("phase","")=="shop" and "--compat-economy" not in OS.get_cmdline_user_args()

func using_scene(app: Control) -> bool:
	return available(app) and app.hub_mode!="team"

func render(app: Control, parent: VBoxContainer) -> void:
	cards.clear()
	if app.shop_tab=="evolution": app.shop_tab = "gear"
	var navigation: HBoxContainer = HBoxContainer.new(); parent.add_child(navigation)
	for entry: Array in [["gear","Ofertas"],["team","Equipo"]]:
		var callback: Callable = app._shop_page.bind(entry[0]) if entry[0]!="team" else app._set_hub_mode.bind("team")
		var button: Button = app._button(entry[1],callback)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.theme_type_variation = "TabButton"
		button.toggle_mode = true; button.button_pressed = app.shop_tab==entry[0]
		navigation.add_child(button); app.travel_buttons["shop_"+entry[0]] = button
		if entry[0]=="gear": app.travel_buttons.hub_overview = button
		if entry[0]=="team": app.travel_buttons.hub_team = button
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_meta("scroll_id","kecleon-counter"); scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var body: VBoxContainer = VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12); scroll.add_child(body)
	var counter: PanelContainer = app._panel(); body.add_child(counter)
	var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation",20); counter.add_child(row)
	actor = preload("res://ui/kecleon_actor.gd").new(); row.add_child(actor); actor.setup(app)
	var welcome: VBoxContainer = VBoxContainer.new(); welcome.size_flags_horizontal = Control.SIZE_EXPAND_FILL; welcome.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(welcome)
	welcome.add_child(app._label("KECLEON",27,app.GOLD))
	greeting_label = app._label(greeting,18); welcome.add_child(greeting_label)
	var shortcuts: HFlowContainer = HFlowContainer.new(); welcome.add_child(shortcuts)
	for entry: Array in [["supplies","Medicina"],["traits","Mentas y habilidades"]]:
		var button: Button = app._button(entry[1],app._shop_page.bind(entry[0]))
		button.theme_type_variation = "ToolButton"; shortcuts.add_child(button); app.travel_buttons["shop_"+entry[0]] = button
	if app.run.get("edition",0)>=28:
		var recruit: Button = app._button("Reclutamiento",app._shop_page.bind("recruitment")); recruit.theme_type_variation = "ToolButton"
		shortcuts.add_child(recruit); app.travel_buttons.shop_recruitment = recruit
	if not app.save_warning.is_empty(): body.add_child(app._label(app.save_warning,17,app.GOLD))
	if not app.message.is_empty(): body.add_child(app._label(app.message,17,app.GOLD))
	match app.shop_tab:
		"supplies": medicines(app,body)
		"recruitment": preload("res://ui/collection_menu.gd").shop(app,body)
		"traits":
			app._render_mint_shop(body)
			var item: Dictionary = app.campaign.consumables["ability-capsule"]
			var buy: Button = app._travel_button("buy_ability-capsule","Cápsula Habilidad · %d ₽ · tienes %d" % [item.price,app.run.bag.get("ability-capsule",0)],body,{"kind":"buy","item":"ability-capsule"})
			app._item_picture(buy,"ability-capsule"); buy.disabled = app.run.money<int(item.price)
		_: offers(app,body)
	var proceed: Button = app._travel_button("continue","Seguir viaje",parent,{"kind":"continue"})
	proceed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app._apply_preferences.call_deferred()

func offers(app: Control, parent: VBoxContainer) -> void:
	var heading: HBoxContainer = HBoxContainer.new(); parent.add_child(heading)
	var title: Label = app._label("OFERTAS",19,app.GOLD); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; heading.add_child(title)
	var cost: int = app.campaign.reroll_price(app.run)
	var renew: Button = app._travel_button("reroll","Renovar · %d ₽" % cost,heading,{"kind":"reroll"})
	renew.theme_type_variation = "ToolButton"; renew.disabled = app.run.money<cost
	renew.tooltip_text = "Cambia las tres ofertas. La próxima renovación costará %d ₽." % (cost+25)
	var grid: GridContainer = GridContainer.new(); grid.columns = 3; grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12); parent.add_child(grid)
	for index: int in app.run.stock.size():
		var offer: Dictionary = app.run.stock[index]
		var item: Dictionary = app.campaign.shop_data.items[offer.item]
		var panel: PanelContainer = app._panel(); panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; grid.add_child(panel); cards[index] = panel
		var column: VBoxContainer = VBoxContainer.new(); column.alignment = BoxContainer.ALIGNMENT_CENTER; panel.add_child(column)
		var image: TextureRect = app._portrait(Vector2(64,64)); image.texture = Art.icon("tm" if item.kind=="tm" else "held"); column.add_child(image)
		var buy: Button = app._travel_button("stock_"+str(index),item.name+"\n"+("AGOTADO" if offer.sold else "%d ₽" % item.price),column,{"kind":"buy-stock","slot":index})
		buy.theme_type_variation = "CommandButton"; buy.alignment = HORIZONTAL_ALIGNMENT_LEFT
		buy.disabled = offer.sold or app.run.money<item.price
		buy.tooltip_text = Info.details(app.campaign.progression.data.moves[item.move]) if item.kind=="tm" else item.description
		if item.kind=="tm": preload("res://ui/move_symbols.gd").decorate(buy,app.campaign.progression.data.moves[item.move])
		buy.accessibility_description = buy.tooltip_text+(" Saldo insuficiente." if not offer.sold and app.run.money<item.price else "")
		var inspect: Button = app._button("Ficha",inspect_offer.bind(app,index))
		inspect.theme_type_variation = "ToolButton"; column.add_child(inspect); app.travel_buttons["stock_detail_"+str(index)] = inspect
		for button: Button in [buy,inspect]:
			button.mouse_entered.connect(select.bind(app,index)); button.focus_entered.connect(select.bind(app,index))
		var signature: String = str(app.run.stage)+"/"+str(offer)
		if previous_stock.get(index,"")!=signature and not app.reduced_motion:
			panel.modulate.a = 0
			panel.create_tween().tween_property(panel,"modulate:a",1.0,.18)
		previous_stock[index] = signature
	detail = app._label("",17); detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; parent.add_child(detail)
	select(app,clampi(selected,0,app.run.stock.size()-1))

func select(app: Control, index: int) -> void:
	if not using_scene(app) or app.shop_tab!="gear" or index>=app.run.stock.size(): return
	selected = index
	var item: Dictionary = app.campaign.shop_data.items[app.run.stock[index].item]
	if is_instance_valid(detail):
		if item.kind=="tm":
			var definition: Dictionary = app.campaign.progression.data.moves[item.move]
			var names: Array[String] = []
			for member: Dictionary in app.campaign.members(app.run):
				if member.hp>0 and app.campaign.compatible(member,app.run.stock[index].item) and item.move not in member.knownMoves: names.append(app.rules.profiles[int(member.speciesId)].data.name)
			detail.text = item.name+"\n"+Info.summary(definition)+"\nPuede aprender: "+(", ".join(names) if not names.is_empty() else "ningún Pokémon disponible")
		else: detail.text = item.name+"\n"+item.description
		if item.kind=="tm":
			var recommendations: Array[String] = []
			for member: Dictionary in app.run.party:
				if member.hp<=0 or not app.campaign.compatible(member,app.run.stock[index].item) or item.move in member.knownMoves: continue
				recommendations.append(app.campaign.progression.species[int(member.speciesId)].name+": "+preload("res://ui/tactical_loadouts.gd").improvement(app.campaign.progression,member,item.move))
			if not recommendations.is_empty(): detail.text += "\n"+"\n".join(recommendations)
	for slot: int in cards:
		if not is_instance_valid(cards[slot]): continue
		cards[slot].add_theme_stylebox_override("panel",preload("res://ui/game_skin.gd").panel(app.GOLD if slot==index else Color("547985")))
	if is_instance_valid(actor): actor.react()

func inspect_offer(app: Control, index: int) -> void:
	var item: Dictionary = app.campaign.shop_data.items[app.run.stock[index].item]
	if item.kind=="tm":
		var definition: Dictionary = app.campaign.progression.data.moves[item.move]
		app._review_text(item.name,Info.details(definition),definition)
	else: app._review_text(item.name,item.description)

func medicines(app: Control, parent: VBoxContainer) -> void:
	parent.add_child(app._label("MEDICINA",20,app.GOLD))
	var grid: GridContainer = GridContainer.new(); grid.columns = 2; parent.add_child(grid)
	for key: String in ["potion","super-potion","revive","hyper-potion","max-potion"]:
		var item: Dictionary = app.campaign.consumables[key]
		var buy: Button = app._travel_button("buy_"+key,"%s · %d ₽\nTienes: %d" % [item.name,item.price,app.run.bag.get(key,0)],grid,{"kind":"buy","item":key})
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL; app._item_picture(buy,key); buy.disabled = app.run.money<item.price
		buy.tooltip_text = "Revivir · 50 % de PS · solo en tienda." if key=="revive" else "Uso fuera de combate."
	var batch: Button = app._button("Comprar varias…",app._open_batch); parent.add_child(batch); app.travel_buttons.batch = batch

func present(app: Control, command: Dictionary) -> void:
	if not using_scene(app): return
	if command.kind in ["buy","buy-stock"]: greeting = "¡Gracias! Ya está en tu bolsa."
	elif command.kind=="reroll": greeting = "A ver qué te parecen estas ofertas."
	elif command.kind=="train-xp": greeting = "¡Tu compañero está más fuerte!"
	if is_instance_valid(greeting_label): greeting_label.text = greeting
	if is_instance_valid(actor): actor.react()
