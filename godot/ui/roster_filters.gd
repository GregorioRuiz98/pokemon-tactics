extends RefCounted

var query: String = ""
var status: int = 0
var type_index: int = 0
var function_index: int = 0
var order: int = 0
var caret: int = 0

func filtered(app: Control, members: Array) -> Array:
	var types: Array = [""]+app.TYPE_NAMES.keys()
	var result: Array = members.filter(func(member):
		var unit: Dictionary = app.rules.member_unit(member)
		if not query.is_empty() and not (query.to_lower() in unit.name.to_lower() or query in str(int(member.id))): return false
		if status==1 and member.hp<=0 or status==2 and member.hp>0: return false
		if type_index>0 and types[type_index] not in unit.types: return false
		if function_index>0:
			var support: bool = function_index==2
			if not member.moves.any(func(id):return (app.campaign.progression.data.moves[id].category=="status")==support): return false
		return true)
	if order>0:
		result.sort_custom(func(a,b):
			var left: Variant = sort_key(app,a)
			var right: Variant = sort_key(app,b)
			return a.id<b.id if left==right else left<right)
	return result

func sort_key(app: Control, member: Dictionary) -> Variant:
	match order:
		1: return app.rules.profiles[int(member.speciesId)].data.name.to_lower()
		2: return -int(member.level)
		3: return -int(member.hp)
		4: return member.origin
	return member.id

func clear() -> void:
	query = ""
	status = 0
	type_index = 0
	function_index = 0
	order = 0

func render(app: Control, parent: VBoxContainer) -> void:
	var search: LineEdit = LineEdit.new()
	search.placeholder_text = "Buscar nombre o ID del PC"
	search.text = query
	search.caret_column = caret
	search.text_changed.connect(func(value: String): query = value; caret = search.caret_column; app.roster_offset = 0; app._refresh.call_deferred())
	parent.add_child(search)
	app.travel_buttons.pc_search = search
	var grid: GridContainer = GridContainer.new()
	grid.columns = 1 if load("res://ui/presentation_settings.gd").font_factor(app)>1.2 else 2
	parent.add_child(grid)
	var lists: Array = [["Todos los estados","En pie","Debilitado"],["Todos los tipos"]+app.TYPE_NAMES.values(),["Cualquier repertorio","Con ataques preparados","Con apoyos preparados"],["Orden original","Nombre","Nivel ↓","PS ↓","Origen"]]
	for index: int in lists.size():
		var choice: OptionButton = OptionButton.new()
		for label: String in lists[index]: choice.add_item(label)
		choice.select([status,type_index,function_index,order][index])
		choice.item_selected.connect(func(value: int):
			match index:
				0: status = value
				1: type_index = value
				2: function_index = value
				3: order = value
			app.roster_offset = 0; app._refresh())
		grid.add_child(choice)
		app.travel_buttons["pc_filter_"+str(index)] = choice
	parent.add_child(app._button("Limpiar filtros",func(): clear(); app._refresh()))
