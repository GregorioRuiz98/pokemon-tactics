extends ConfirmationDialog

var app: Control
var operation: OptionButton
var item: OptionButton
var quantity: SpinBox
var summary: Label
var plan: Dictionary = {}
var stop_requested: bool = false
var accepted: int = 0
var persisted: int = 0

static func prepare(game: RefCounted, source: Dictionary, batch_mode: String, item_id: String, member: int, count: int) -> Dictionary:
	if count<1 or count>99 or source.phase!="shop": return {"ok":false,"reason":"Cantidad entre1 y99; solo disponible en tienda."}
	if not game.consumables.has(item_id): return {"ok":false,"reason":"Artículo no disponible."}
	var state: Dictionary = source.duplicate(true)
	var commands: Array = []
	var events: Array[String] = []
	var restored: int = 0
	for index: int in count:
		var command: Dictionary = {"kind":"buy","item":item_id,"at":state.revision}
		if batch_mode=="use":
			command = {"kind":"level-up" if item_id=="rare-candy" else ("revive" if item_id=="revive" else "heal"),"member":member,"at":state.revision}
			if command.kind=="heal": command.item = item_id
		var previous: Dictionary = game.target(state,member).duplicate(true)
		var step: Dictionary = game.transact(state,command)
		if not step.ok: return {"ok":false,"reason":"Unidad %d: %s" % [index+1,step.reason]}
		state = step.state
		commands.append(command)
		var next: Dictionary = game.target(state,member)
		if batch_mode=="use" and not previous.is_empty():
			restored += maxi(0,int(next.hp-previous.hp))
			if next.level!=previous.level: events.append("Nv. %d → %d · +%d PS actuales" % [previous.level,next.level,maxi(0,int(next.hp-previous.hp))])
			if next.speciesId!=previous.speciesId: events.append("Evoluciona: "+game.engine.profiles[int(next.speciesId)].data.name)
			for move: String in next.get("knownMoves",[]):
				if move not in previous.get("knownMoves",[]): events.append("Aprende "+game.progression.data.moves[move].name+" (preparación independiente)")
	return {"ok":true,"state":state,"commands":commands,"events":events,"restored":restored,"revision":source.revision,"member":member,"mode":batch_mode,"item":item_id,"quantity":count}

func setup(owner_app: Control) -> void:
	app = owner_app
	theme = app.theme
	title = "Tienda · compra o uso por cantidad"
	ok_button_text = "Confirmar operación"
	cancel_button_text = "Volver"
	dialog_close_on_escape = false
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size.x = 620
	add_child(column)
	operation = OptionButton.new()
	operation.add_item("Comprar · solo añade a la bolsa")
	operation.add_item("Usar · solo consume lo que ya tienes")
	column.add_child(operation)
	item = OptionButton.new()
	for key: String in ["rare-candy","potion","super-potion","hyper-potion","max-potion","revive"]:
		if app.campaign.consumables.has(key): item.add_item(app.campaign.consumables[key].name); item.set_item_metadata(item.item_count-1,key)
	column.add_child(item)
	quantity = SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = 99
	quantity.step = 1
	quantity.prefix = "Cantidad: "
	column.add_child(quantity)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620,300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	summary = app._label("",18)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(summary)
	operation.item_selected.connect(func(_index: int): preview())
	item.item_selected.connect(func(_index: int): preview())
	quantity.value_changed.connect(func(_value: float): preview())
	confirmed.connect(accept_plan)

func open(context: String = "buy") -> void:
	operation.select(1 if context=="use" else 0)
	operation.visible = not app._simple_hub()
	preview()
	popup_centered(Vector2i(700,480) if app._simple_hub() else Vector2i(700,570))
	app._apply_preferences()

func preview() -> void:
	if app.run.phase!="shop": return
	var key: String = item.get_item_metadata(item.selected)
	var selected: Dictionary = app.campaign.target(app.run,app.selected_member)
	var unit: Dictionary = app.rules.member_unit(selected) if not selected.is_empty() else {}
	plan = prepare(app.campaign,app.run,"buy" if operation.selected==0 else "use",key,app.selected_member,int(quantity.value))
	summary.text = "Destinatario ID %d · %s\nNv. %d · PS %d / %d · cap %s\nEn bolsa: %d · por comprar: %d\nSaldo actual: %d ₽\n" % [app.selected_member,unit.get("name","Sin destinatario"),selected.get("level",0),unit.get("hp",0),unit.get("maxHp",0),str(app.campaign.level_cap(app.run)) if app.campaign.has_method("level_cap") else "sin límite por gimnasio",app.run.bag.get(key,0),int(quantity.value) if operation.selected==0 else 0,app.run.money]
	if app._simple_hub():
		title = "Comprar varias unidades" if operation.selected==0 else "Usar objetos · "+unit.get("name","")
		ok_button_text = "Comprar" if operation.selected==0 else "Usar"
		summary.text = "En bolsa: %d\n" % app.run.bag.get(key,0)
		if operation.selected==0: summary.text += "Saldo: %d ₽\n" % app.run.money
		else: summary.text += "%s · Nv. %d · Límite %d\n%d / %d PS\n" % [unit.get("name",""),selected.get("level",0),app.campaign.level_cap(app.run),unit.get("hp",0),unit.get("maxHp",0)]
	get_ok_button().disabled = not plan.ok
	get_ok_button().set_meta("semantic_manual",true)
	operation.set_meta("semantic_manual",true)
	item.set_meta("semantic_manual",true)
	operation.accessibility_name = "Operación: comprar o usar"
	item.accessibility_name = "Artículo: "+item.get_item_text(item.selected)
	quantity.accessibility_name = "Cantidad del artículo"
	summary.accessibility_name = summary.text
	if not plan.ok: summary.text += "\n"+plan.reason; summary.accessibility_name = summary.text; get_ok_button().accessibility_description = plan.reason; return
	if not app._simple_hub() or operation.selected==0: summary.text += "Coste total: %d ₽ · saldo final: %d ₽\n" % [app.run.money-plan.state.money,plan.state.money]
	if not app._simple_hub() or operation.selected==1: summary.text += "Restauración prevista: %d PS\n%s" % [plan.restored,"\n".join(plan.events)]
	if operation.selected==1 and key in ["potion","super-potion","hyper-potion"]:
		var wasted: int = maxi(0,int(app.campaign.consumables[key].heal*quantity.value)-plan.restored)
		if wasted>0 or not app._simple_hub(): summary.text += "\nCuración desperdiciada: %d PS" % wasted
	if not app._simple_hub(): summary.text += "\nCada orden se guarda por separado. Si falla, se detiene el lote; no se repite al reiniciar. Escape durante el lote detiene las órdenes pendientes."

	summary.accessibility_name = summary.text
	get_ok_button().accessibility_name = "Aceptar operación revisada"
	get_ok_button().accessibility_description = summary.text
	get_ok_button().accessibility_description += "\nDestinatario: %s · cap %s" % [unit.get("name","Sin destinatario"),str(app.campaign.level_cap(app.run)) if app.campaign.has_method("level_cap") else "sin límite por gimnasio"]
	if operation.selected==1: get_ok_button().accessibility_description += "\nSaldo: %d ₽" % app.run.money

func accept_plan() -> void:
	if app.batch_busy or not plan.get("ok",false): return
	if not app.save_warning.is_empty(): app.message = "Resuelve el aviso de guardado antes de procesar un lote."; app._refresh(); return
	if app.run.revision!=plan.revision or app.selected_member!=plan.member:
		app.message = "La selección o la revisión cambió. Revisa la operación."
		app._refresh()
		return
	var checked: Dictionary = prepare(app.campaign,app.run,plan.mode,plan.item,plan.member,plan.quantity)
	if not checked.ok: app.message = checked.reason; app._refresh(); return
	hide()
	stop_requested = false
	accepted = 0
	persisted = 0
	app.batch_busy = true
	for command: Dictionary in checked.commands:
		if stop_requested: break
		var revision: int = app.run.revision
		app._event(command,true)
		if app.run.revision==revision: break
		accepted += 1
		if not app.save_warning.is_empty(): break
		persisted += 1
		app.message = "Procesando %d / %d · %d guardadas" % [accepted,checked.commands.size(),persisted]
		app._refresh()
		await app.get_tree().process_frame
	app.batch_busy = false
	app.input_profile.held.clear()
	app.message = "%d órdenes aceptadas · %d guardadas · %d pendientes.%s" % [accepted,persisted,checked.commands.size()-accepted," Revisa el aviso de guardado antes de seguir." if accepted!=persisted else ""]
	if app._simple_hub() and accepted==persisted: app.message = "%d unidades %s.%s" % [accepted,"compradas" if checked.mode=="buy" else "usadas"," Operación detenida." if accepted<checked.commands.size() else ""]
	if accepted!=persisted: app.save_warning += " "+app.message
	app._refresh()
