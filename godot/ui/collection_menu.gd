extends RefCounted

static func shop(app: Control, parent: VBoxContainer) -> void:
	parent.add_child(app._label("RECLUTAMIENTO",20,app.GOLD))
	parent.add_child(app._label("Un compañero por visita. Las ofertas se conservan al cargar.",17,app.MUTED))
	var offers: Array = app.campaign.collection_offers(app.run)
	if offers.is_empty(): parent.add_child(app._label("Ya has reclutado aquí. ¡Buen viaje!",19)); return
	for offer: Dictionary in offers:
		var row: HBoxContainer = HBoxContainer.new(); parent.add_child(row)
		var image: TextureRect = app._portrait(Vector2(56,56)); image.texture = app.faces.get(int(offer.speciesId)); row.add_child(image)
		var button: Button = app._button("%s · Nv. %d · %d ₽"%[app.rules.profiles[int(offer.speciesId)].data.name,offer.level,offer.price],review.bind(app,offer))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.disabled = app.run.money<offer.price
		button.tooltip_text = app._type_names(app.rules.profiles[int(offer.speciesId)].data.types)+(" · Saldo insuficiente" if button.disabled else "")
		row.add_child(button); app.travel_buttons["adopt_"+str(offer.speciesId)] = button

static func review(app: Control, offer: Dictionary) -> void:
	app._review_dialog()
	var command: Dictionary = {"kind":"adopt","species":int(offer.speciesId),"at":app.run.revision}
	app.action_review.review("Reclutar a "+app.rules.profiles[int(offer.speciesId)].data.name,"Nv. %d · %d ₽\nSaldo: %d → %d ₽\n%s\nSu primera forma quedará disponible como inicial de nivel 5."%[offer.level,offer.price,app.run.money,app.run.money-offer.price,"Se enviará al PC." if app.run.party.size()>=6 else "Se unirá al equipo."],func():app._event(command))

static func legendary(app: Control, parent: VBoxContainer) -> void:
	parent.add_child(app._label("Elige un único compañero de este combate.",18,app.GOLD))
	for species: int in app.run.legendaryChoices:
		var button: Button = app._travel_button("legend_"+str(species),app.rules.profiles[species].data.name,parent,{"kind":"select-recruit","species":species})
		button.toggle_mode = true; button.button_pressed = app.run.reward.speciesId==species
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
