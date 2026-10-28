extends RefCounted

const Model = preload("res://core/collection_profile.gd")
const Store = preload("res://core/collection_profile_store.gd")
var model: RefCounted
var persistence: RefCounted
var dialog: AcceptDialog
var warning: String = ""
var signature: String = ""
var pending: Array[String] = []
var notice: PanelContainer
var notice_text: Label
var remaining: float = 0

func setup(app: Control, path: String) -> void:
	persistence = Store.new(path)
	var loaded: Dictionary = persistence.load_profile()
	model = Model.new(loaded.data)
	warning = loaded.warning
	if loaded.ok and (loaded.data.is_empty() or loaded.data.get("version")==1): persist()
	notice = app._panel(); notice.mouse_filter = Control.MOUSE_FILTER_IGNORE; notice.z_index = 100
	app.add_child(notice)
	var row: HBoxContainer = HBoxContainer.new(); row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_child(row)
	row.add_child(app._label("★",26,app.GOLD))
	notice_text = app._label("",18,app.GOLD)
	notice_text.autowrap_mode = TextServer.AUTOWRAP_OFF; notice_text.clip_text = true
	notice_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	notice_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(notice_text); notice.hide()

func persist(restoring: bool = false) -> bool:
	var result: Dictionary = persistence.save(model.data,restoring)
	warning = "" if result.ok else result.reason
	return result.ok

func supported(app: Control) -> bool:
	return model!=null and app.store.has_method("new_binding") and not app.practice.active

func begin_new(app: Control) -> void:
	if not supported(app): return
	var old: String = app.store.campaign_id
	if old.is_empty() and FileAccess.file_exists(app.store.file_path):
		var reader: RefCounted = load("res://core/closing_store.gd").new(app.store.file_path)
		var loaded: Dictionary = reader.load_campaign(app.campaign)
		if loaded.ok: old = reader.campaign_id
	model.abandon(old)
	app.store.new_binding(model.data.id); signature = ""

func prepare(app: Control, before: Dictionary, command: Dictionary, result: Dictionary) -> void:
	if not supported(app): return
	var definition: Dictionary = {}
	if command.kind=="battle" and command.order.kind=="attack": definition = result.get("presentation",{}).get("visualDefinition",app._attack_definition(before.battle,command.order))
	var location: Dictionary = app.campaign.locations[int(app.run.stage)] if app.campaign.get("locations")!=null else {}
	app.store.record(app.rules,before,app.run,command,result.get("presentation",{}),definition,location)

func sync(app: Control) -> void:
	if not supported(app) or app.run.is_empty(): return
	if app.store.campaign_id.is_empty(): app.store.new_binding(model.data.id)
	app.store.trainer_id = model.data.id
	var next: String = JSON.stringify([app.store.campaign_id,app.store.profile_events.size(),app.run.phase,app.run.get("cleared",[]),app.run.party.map(func(m):return int(m.speciesId)),app.run.get("reserve",[]).map(func(m):return int(m.speciesId))])
	if next==signature: return
	var unlocked: Array[String] = model.observe(app.store.campaign_id,app.run,app.store.profile_events)
	for key: String in unlocked:
		if key not in pending: pending.append(key)
	if persist(): signature = next
	if app.title_screen!=null: update_title(app)

func update_title(app: Control) -> void:
	if model==null or app.title_screen==null or not app.title_screen.controls.has("trainer"): return
	var button: Button = app.title_screen.controls.trainer
	button.text = "Entrenador · "+model.data.name
	button.icon = preload("res://ui/trainer_identity.gd").portrait(app,int(model.data.portrait))
	button.expand_icon = true; button.add_theme_constant_override("icon_max_width",40)
	button.tooltip_text = "%s · %d / 151 Pokémon · %d logros" % [model.data.title,model.data.dex.size(),model.data.unlocked.size()]
	if not warning.is_empty(): app.title_screen.notice.text = (app.save_warning+"\n" if not app.save_warning.is_empty() else "")+warning

func open(app: Control) -> void:
	if dialog==null:
		dialog = preload("res://ui/trainer_panel.gd").new()
		app.add_child(dialog); dialog.setup(app,self); app._watch_dialog(dialog)
	dialog.render()
	dialog.popup_centered(Vector2i(mini(820,app.get_window().size.x-48),mini(660,app.get_window().size.y-64))); app._apply_preferences()

func tick(app: Control, delta: float) -> void:
	if notice==null: return
	if remaining>0:
		remaining -= delta
		if remaining<=0 or app._modal_open(): notice.hide()
	if remaining>0 or pending.is_empty() or app._modal_open() or not warning.is_empty(): return
	var key: String = pending.pop_front()
	if not model.data.get("notifications",true): return
	var text: String = "Logro: "+Model.ACHIEVEMENTS[key][0]
	notice_text.text = text; notice_text.tooltip_text = text
	notice.custom_minimum_size = Vector2(minf(540,app.size.x-48),maxf(64,preload("res://ui/presentation_settings.gd").font_factor(app)*36+24))
	notice.size = notice.custom_minimum_size
	notice.position = Vector2((app.size.x-notice.size.x)*.5,72)
	notice.show(); remaining = 3
	app.accessible_view.announce(text)
