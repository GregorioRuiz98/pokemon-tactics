extends RefCounted

static func needed(app: Control, member: Dictionary) -> int:
	return app.campaign.progression.member_next_xp(member) if app.run.get("edition",1)>=20 else app.campaign.progression.next_xp(member.level)

static func training(app: Control, parent: VBoxContainer, member: Dictionary, key: String = "train-xp") -> void:
	parent.add_child(app._label("Entrenamiento · "+app.rules.profiles[int(member.speciesId)].data.name,20,app.GOLD))
	var quote: Dictionary = app.campaign.training_quote(app.run,member)
	if not quote.ok:
		parent.add_child(app._label(quote.reason,17,app.MUTED))
		return
	parent.add_child(app._label("Nv. %d → %d · faltan %d EXP" % [member.level,member.level+1,quote.points],17))
	var button: Button = app._button("Completar nivel · %d ₽" % quote.price,review_training.bind(app,int(member.id)))
	button.disabled = app.run.money<quote.price
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "%d EXP por pokédolar. Se compra solo lo que falta para este nivel; respeta el límite del próximo gimnasio." % quote.rate
	if quote.has("discount"):
		button.text += " · recuperación −%d %%" % quote.discount
		button.tooltip_text = "Tarifa de recuperación: −%d %%. Completa los %d EXP pendientes por %d ₽. Descuento por estar al menos tres niveles por debajo de la media del equipo; conserva el límite del gimnasio." % [quote.discount,quote.points,quote.price]
	parent.add_child(button)
	app.travel_buttons[key] = button

static func review_training(app: Control, identity: int) -> void:
	var member: Dictionary = app.campaign.target(app.run,identity)
	var quote: Dictionary = app.campaign.training_quote(app.run,member)
	if not quote.ok: return
	app._review_dialog()
	var command: Dictionary = {"kind":"train-xp","member":identity,"price":quote.price,"points":quote.points,"at":app.run.revision}
	app.action_review.review("Completar nivel",app.rules.profiles[int(member.speciesId)].data.name+" · Nv. %d → %d\n%d EXP pendientes · %d ₽\nSaldo: %d → %d ₽\nRecupera únicamente el aumento de PS máximos." % [member.level,member.level+1,quote.points,quote.price,app.run.money,app.run.money-quote.price],func():app._event(command))

static func shop(app: Control, parent: VBoxContainer) -> void:
	var picker: OptionButton = OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for member: Dictionary in app.campaign.members(app.run):
		picker.add_item("%s · Nv. %d%s" % [app.rules.profiles[int(member.speciesId)].data.name,member.level," · PC" if member in app.run.reserve else ""],int(member.id))
		if member.id==app.selected_member: picker.select(picker.item_count-1)
	picker.item_selected.connect(func(index: int):app.selected_member = picker.get_item_id(index);app._refresh())
	parent.add_child(picker)
	app.travel_buttons.training_member = picker
	var member: Dictionary = app.campaign.target(app.run,app.selected_member)
	if not member.is_empty(): training(app,parent,member,"shop_train_xp")

static func evolutions(app: Control, parent: VBoxContainer, member: Dictionary) -> void:
	for choice: Array in app.campaign.progression.free_evolutions(member):
		var species_id: int = int(choice[0])
		var minimum: int = int(choice[1])
		var name_text: String = app.rules.profiles[species_id].data.name
		var button: Button = app._button("Evolucionar a %s · Nv. %d · gratis" % [name_text,minimum],review_evolution.bind(app,int(member.id),species_id))
		button.disabled = member.hp<=0 or member.level<minimum or app.run.phase not in ["map","shop","complete"]
		button.tooltip_text = "Decisión permanente. Conserva PS actuales, EXP y objeto. No requiere piedra ni intercambio."
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		parent.add_child(button)
		app.travel_buttons["evolution_"+str(species_id)] = button

static func review_evolution(app: Control, identity: int, species_id: int) -> void:
	app._review_dialog()
	var command: Dictionary = {"kind":"evolve-free","member":identity,"species":species_id,"at":app.run.revision}
	app.action_review.review("Elegir evolución",app._member_summary(identity)+"\n\nEvolucionará a "+app.rules.profiles[species_id].data.name+". Gratis; conserva sus PS actuales. Esta elección es permanente.",func():app._event(command))

static func capture(app: Control, parent: VBoxContainer) -> void:
	if app.campaign.capture_options(app.run).is_empty(): return
	var price: int = app.campaign.capture_price(app.run)
	var button: Button = app._button("Otro Pokémon de la zona · %d ₽" % price,review_capture.bind(app))
	button.disabled = app.run.money<price
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "Sustituye la oferta actual por otra especie local, al mismo nivel. Cada intento cuesta 60 ₽ más. Aceptar la captura cierra el sorteo."
	parent.add_child(button)
	app.travel_buttons.reroll_capture = button

static func review_capture(app: Control) -> void:
	app._review_dialog()
	var price: int = app.campaign.capture_price(app.run)
	var command: Dictionary = {"kind":"reroll-capture","at":app.run.revision}
	app.action_review.review("Repetir sorteo local","Sustituirá la oferta actual por otra especie de la zona.\nCoste: %d ₽ · saldo restante: %d ₽\nMismo nivel; el precio siguiente será %d ₽.\nEl resultado se guarda al confirmar." % [price,app.run.money-price,price+60],func():app._event(command))
