extends VBoxContainer

const Collection = preload("res://core/collection_catalog.gd")
var app: Control
var starter_mode: bool = false
var choose: Callable
var query: LineEdit
var filter: OptionButton
var results: VBoxContainer
var page: int = 0
var controls: Dictionary = {}
var matches: Array[int] = []
const PAGE_SIZE: int = 8

func setup(owner_app: Control, selecting: bool = false, selected: Callable = Callable()) -> void:
	app = owner_app; starter_mode = selecting; choose = selected
	add_theme_constant_override("separation",10)
	query = LineEdit.new(); query.placeholder_text = "Buscar nombre o número"; query.accessibility_name = "Buscar Pokémon"
	add_child(query)
	query.text_changed.connect(func(_value: String):page = 0; render())
	if not starter_mode:
		filter = OptionButton.new()
		for label: String in ["Todos","Obtenidos","Vistos sin obtener","Sin ver"]: filter.add_item(label)
		filter.accessibility_name = "Filtrar Pokédex"; add_child(filter)
		filter.item_selected.connect(func(_index: int):page = 0; render())
	results = VBoxContainer.new(); results.add_theme_constant_override("separation",8); add_child(results)
	render()

func render() -> void:
	app._clear(results); controls.clear(); matches.clear()
	var model: RefCounted = app.trainer.model
	var source: Array = model.starters() if starter_mode else range(1,152)
	var needle: String = query.text.strip_edges().to_lower().trim_prefix("#")
	for species: int in source:
		var record: Dictionary = Collection.record(species)
		if not needle.is_empty() and needle not in record.name.to_lower() and needle!=str(species) and needle!="%03d"%species: continue
		var owned: bool = species in model.data.dex
		var seen: bool = species in model.data.seen
		if not starter_mode and ((filter.selected==1 and not owned) or (filter.selected==2 and (not seen or owned)) or (filter.selected==3 and seen)): continue
		matches.append(species)
	var pages: int = maxi(1,int(ceil(matches.size()/float(PAGE_SIZE))))
	page = clampi(page,0,pages-1)
	if matches.is_empty(): results.add_child(app._label("No hay Pokémon con este filtro.",18,app.MUTED))
	for species: int in matches.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE):
		var record: Dictionary = Collection.record(species)
		var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation",10); results.add_child(row)
		var image: TextureRect = app._portrait(Vector2(40,40))
		if not app.faces.has(species): app.faces[species] = load("res://"+record.face)
		image.texture = app.faces[species]; row.add_child(image)
		var owned: bool = species in model.data.dex
		var seen: bool = species in model.data.seen
		var status: String = "Nv. 5" if starter_mode else "Obtenido" if owned else "Visto" if seen else "Sin ver"
		var button: Button = app._button("#%03d  %s · %s"%[species,record.name,status],select_species.bind(species))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = "Elegir como inicial de nivel 5" if starter_mode else "Ver ficha y forma de obtención"
		row.add_child(button); controls[species] = button
	var nav: HBoxContainer = HBoxContainer.new(); results.add_child(nav)
	for offset: int in [-1,1]:
		var button: Button = app._button("Anterior" if offset<0 else "Siguiente",turn_page.bind(offset))
		button.disabled = page+offset<0 or page+offset>=pages; button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(button); controls["previous" if offset<0 else "next"] = button
		if offset<0: nav.add_child(app._label("%d / %d · %d especies"%[page+1,pages,matches.size()],16))
	app._queue_preferences()

func turn_page(offset: int) -> void:
	page += offset; render()
	controls["previous" if offset<0 else "next"].grab_focus.call_deferred()

func select_species(species: int) -> void:
	if starter_mode: choose.call(species); return
	var record: Dictionary = Collection.record(species)
	var base: int = Collection.base_species(species)
	var owned: bool = species in app.trainer.model.data.dex
	var seen: bool = species in app.trainer.model.data.seen
	var access: String = "Reclutamiento de Kecleon; también puede aparecer en encuentros locales."
	if species in Collection.LEGENDS: access = "Elige uno tras vencer a las tres aves." if species in [144,145,146] else "Elige uno tras vencer a Mew y Mewtwo."
	elif species!=base: access = "Evoluciona a %s o recluta esta forma en Kecleon desde Nv. %d."%[Collection.record(base).name,Collection.minimum_level(species)]
	var text: String = ("Obtenido" if owned else "Visto" if seen else "Sin ver")+"\n"+app._type_names(record.types)+"\n\n"+access
	text += "\n\nInicial: %s · Nv. 5\n%s"%[Collection.record(base).name,"Desbloqueado en este perfil." if base in app.trainer.model.starters() else "Se desbloquea al obtener una forma de esta línea."]
	app._review_text("#%03d · %s"%[species,record.name],text)
