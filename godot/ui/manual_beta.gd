extends SceneTree

# Explicitly synthetic, interactive acceptance fixture. Never a campaign save.
class MemoryStore extends RefCounted:
	var file_path: String = "user://beta-memory-only.json"
	func save(_state: Dictionary, _commands: Array, _mode: String) -> Dictionary: return {"ok":true}
	func load_campaign(_rules: RefCounted) -> Dictionary: return {"ok":false,"reason":"Fixture sintético en memoria: no existe guardado que recuperar. Para la tarea de continuar, usa una aventura nueva en otro perfil QA."}
	func preserve_before_new() -> Dictionary: return {"ok":false,"reason":"Cierra el fixture y abre una aventura normal en otro perfil QA."}

func _initialize() -> void:
	call_deferred("prepare")

func prepare() -> void:
	var app: Control = load("res://scenes/campaign.tscn").instantiate()
	root.add_child(app)
	current_scene = app
	app.store = MemoryStore.new()
	app.campaign = load("res://core/journey_run.gd").new(22)
	app.rules = app.campaign.engine
	app.run = app.campaign.create("beta-synthetic-only",1)
	app.run.phase = "shop"
	app.run.money = 2000
	app.run.party = []
	for record: Array in [[1,1,5],[2,7,8],[3,4,8],[4,25,14],[5,12,14],[6,15,14]]:
		var member: Dictionary = app.campaign.progression.create_member(record[0],record[1],"Fixture beta sintético",record[2])
		if record[0] in [2,3]: member.hp = maxi(1,int(member.hp/2.0))
		app.run.party.append(member)
	app.run.reserve = [app.campaign.progression.create_member(11,1,"Fixture beta · duplicado",8),app.campaign.progression.create_member(12,25,"Fixture beta · reserva",12)]
	app.run.nextId = 13
	app.run.bag["potion"] = 10
	app.transactions = []
	app.state = {}
	app.selected_member = 1
	app.title_visible = false
	app.message = "FIXTURE SINTÉTICO · solo en memoria, sin guardado. Tienda/PC/biblioteca para tareas6–8. Cerrar descarta todo."
	app._prepare_campaign_assets()
	app._refresh()
	var badge: Label = app._label("BETA SINTÉTICA · memoria · sin guardado de campaña · cerrar descarta los cambios",16,app.GOLD)
	app.add_child(badge)
	badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	badge.offset_left = 24
	badge.offset_right = -24
	badge.offset_top = -30
	badge.offset_bottom = -5
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("MANUAL_BETA_READY synthetic=true persistence=memory")
	if "--beta-smoke" in OS.get_cmdline_user_args():
		var Batch: GDScript = load("res://ui/shop_batch.gd")
		var bought: Dictionary = Batch.prepare(app.campaign,app.run,"buy","rare-candy",1,5)
		var used: Dictionary = Batch.prepare(app.campaign,bought.state,"use","rare-candy",1,5) if bought.ok else {"ok":false}
		var swap: Dictionary = app.campaign.transact(app.run,{"kind":"swap","member":1,"reserve":11,"at":app.run.revision})
		print(JSON.stringify({"fixture":true,"buyFive":bought.ok,"useFive":used.ok,"swapDuplicate":swap.ok,"filesWritten":FileAccess.file_exists(app.store.file_path)}))
		quit(0 if bought.ok and used.ok and swap.ok and not FileAccess.file_exists(app.store.file_path) else 1)
