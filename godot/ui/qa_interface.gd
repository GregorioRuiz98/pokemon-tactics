extends RefCounted

const Store = preload("res://core/journey_store.gd")
const Policy = preload("res://ui/qa_journey_policy.gd")
const Art = preload("res://ui/visual_assets.gd")
var assertions: int = 0
var failures: Array[String] = []
var screenshots: Array[String] = []

func art_checks() -> void:
	var before: int = Art.loads
	var texture: Texture2D = Art.texture("title_keyart")
	for index: int in 100: check(Art.texture("title_keyart")==texture,"Artwork reuses cached texture")
	check(Art.loads<=before+1,"Drawing does not reload artwork")
	for record: Dictionary in Art.slots():
		var resource: Texture2D = Art.texture(record.id)
		check(resource!=null and resource.get_width()==record.width and resource.get_height()==record.height,"Native artwork contract: "+record.id)
	for biome: String in Art.manifest().biomes:
		check(Art.texture(Art.floor_id(biome))!=null and Art.texture(Art.prop_id(biome))!=null,"Biome has floor and obstacle art: "+biome)
	# Isolated registry fixtures; no files, campaign state or game RNG are changed.
	var trial: Dictionary = Art.entry("title_keyart").duplicate(true)
	trial.id = "qa_wrong_dimensions"
	trial.final = "res://art/placeholders/icon_medicine.svg"
	Art.manifest().slots.append(trial)
	check(Art.texture(trial.id).get_width()==1920 and not Art.final_ready(trial.id) and trial.id in Art.rejected,"Wrong final dimensions retain the placeholder")
	Art.manifest().slots.pop_back()
	Art.textures.erase(trial.id); Art.using_final.erase(trial.id); Art.rejected.erase(trial.id)
	trial.id = "qa_valid_final"
	trial.final = trial.placeholder
	Art.manifest().slots.append(trial)
	check(Art.texture(trial.id)!=null and Art.final_ready(trial.id),"Valid final path replaces the placeholder")
	Art.manifest().slots.pop_back()
	Art.textures.erase(trial.id); Art.using_final.erase(trial.id)
	trial = Art.entry("fx_hit").duplicate(true)
	trial.id = "qa_opaque_final"
	trial.final = "res://art/app_icon.png"
	Art.manifest().slots.append(trial)
	check(Art.texture(trial.id)!=null and not Art.final_ready(trial.id) and trial.id in Art.rejected,"Opaque final retains transparent-effect placeholder")
	Art.manifest().slots.pop_back()
	Art.textures.erase(trial.id); Art.using_final.erase(trial.id); Art.rejected.erase(trial.id)

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition: failures.append(label); print("UI_CHECK_FAILED: "+label)

func settle(app: Control) -> void:
	await app.get_tree().process_frame
	await app.get_tree().process_frame

func click(app: Control, button: Button) -> void:
	check(button.is_visible_in_tree() and not button.disabled,"Visible enabled control: "+button.text)
	await settle(app)
	if button.get_viewport()!=app.get_viewport():
		# Dialogs own a Window/viewport; use their native button signal there.
		if button.toggle_mode: button.button_pressed = not button.button_pressed
		else: button.pressed.emit()
		await settle(app)
		return
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	button.get_viewport().push_input(motion,true)
	for pressed: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		button.get_viewport().push_input(event,true)
	await settle(app)

func capture(app: Control, directory: String, label: String) -> void:
	await settle(app)
	await RenderingServer.frame_post_draw
	check(app.get_viewport().get_texture().get_image().save_png(directory.path_join(label+".png"))==OK,"Rendered "+label)
	screenshots.append(label+".png")

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	art_checks()
	var path: String = directory.path_join("session-%d.json" % Time.get_ticks_usec())
	app.store = Store.new(path)
	app._open_title()
	await settle(app)
	check(app.title_visible and app.title_screen.visible,"Normal title is visible")
	check(app.title_screen.controls["continue"].disabled and not FileAccess.file_exists(path),"Empty title disables Continue and writes nothing")
	check(app.get_viewport().gui_get_focus_owner()==app.title_screen.controls["new"],"Keyboard starts on New game")
	await capture(app,directory,"title-1280")
	app.get_window().size = Vector2i(1024,720)
	await settle(app)
	check(app.title_screen.controls["quit"].get_global_rect().end.x<=app.size.x,"Title footer fits minimum width")
	check(app.title_screen.controls["new"].get_global_rect().end.y<app.size.y-60,"Title commands fit minimum height")
	await capture(app,directory,"title-1024")
	await click(app,app.title_screen.controls["new"])
	check(not app.title_visible and app.run.is_empty(),"New game opens Oak")
	app.journey_seed.text = "tactics-1"
	await click(app,app.travel_buttons.starter1)
	check(app.run.get("edition",0)==18 and FileAccess.file_exists(path),"Oak creates and saves unchanged rules18")
	check(not app.travel_buttons.has("travel_route-1"),"Current destination is not repeated as a disabled choice")
	await capture(app,directory,"hub-1024")
	var saved: Dictionary = app.run.duplicate(true)
	var bytes: String = FileAccess.get_file_as_string(path)
	await click(app,app.travel_buttons.home)
	check(app.title_visible and not app.title_screen.controls["continue"].disabled,"Home offers Continue after starting")
	await click(app,app.title_screen.controls["new"])
	check(app.campaign_confirm.visible,"Existing campaign asks before choosing a replacement")
	await click(app,app.campaign_confirm.get_cancel_button())
	check(FileAccess.get_file_as_string(path)==bytes and Store.equivalent(app.run,saved),"Cancelling New preserves file and in-memory campaign")
	await click(app,app.title_screen.controls["new"])
	await click(app,app.campaign_confirm.get_ok_button())
	check(app.run.is_empty(),"Confirmed New opens selection without overwriting save")
	await click(app,app.travel_buttons.home)
	check(Store.equivalent(app.run,saved) and FileAccess.get_file_as_string(path)==bytes,"Back from Oak restores previous campaign without reroll")
	await click(app,app.title_screen.controls["options"])
	await click(app,app.options_buttons["Sonidos"])
	check(app.muted,"Sound toggle applies from title")
	await click(app,app.options_buttons["Sonidos"])
	await click(app,app.options_buttons["Animaciones"])
	check(app.reduced_motion,"Reduced motion applies from title")
	await click(app,app.options_dialog.get_ok_button())
	await click(app,app.title_screen.controls["continue"])
	check(Store.equivalent(app.run,saved),"Warm Continue keeps exact state")
	await click(app,app.travel_buttons.enter)
	check(app.run.phase=="battle","Map enters actual battle")
	app._menu_selected(8)
	saved = app.run.duplicate(true)
	app.qa_running = false
	app._process(3)
	await settle(app)
	check(Store.equivalent(app.run,saved),"Title pauses rival processing and never advances battle")
	app.qa_running = true
	await click(app,app.title_screen.controls["continue"])
	var target: Dictionary = app.state.units.filter(func(u):return u.team=="enemy")[0]
	app._hover_tile(target)
	await settle(app)
	var actor_panel: Control = app.actor_portrait.get_parent().get_parent().get_parent()
	check(not actor_panel.get_global_rect().intersects(app.hint.get_parent().get_global_rect()),"Actor card and hint do not overlap at1024")
	check(not app.target_panel.get_global_rect().intersects(app.hint.get_parent().get_global_rect()),"Target card and hint do not overlap at1024")
	check(app.target_panel.get_global_rect().end.x<=app.size.x,"Target card stays in viewport")
	check(app.buttons.actions.theme_type_variation=="FieldCommandButton","Battle commands use paper-menu rows")
	check(not app.command_panel.get_global_rect().intersects(app.board.play_area()),"Command menu does not cover playable tiles")
	check(app.actor_tp.value==app.rules.active(app.state).tp,"Tactical resource meter matches active unit")
	app.buttons.actions.grab_focus()
	await capture(app,directory,"battle-1024")
	var selection_before: Dictionary = app.run.duplicate(true)
	app._open_actions()
	await capture(app,directory,"battle-abilities-1024")
	check(app.command_panel.get_global_rect().end.y<=app.size.y,"Ability menu fits viewport with readable rows")
	app._cancel()
	check(Store.equivalent(selection_before,app.run),"New menu and ability presentation preserve full campaign and RNG")
	var policy: RefCounted = Policy.new()
	for _step: int in 150:
		if app.run.phase=="shop" or app.run.phase=="defeat": break
		var command: Dictionary = policy.choose(app.campaign,app.run)
		if command.is_empty(): break
		app._event(command)
	check(app.run.phase=="shop","Natural first encounter reaches shop")
	if app.run.phase=="shop":
		var before: Dictionary = app.run.duplicate(true)
		check(app.hub_parts.shop.is_visible_in_tree() and not app.hub_parts.team.is_visible_in_tree(),"Buying has a dedicated view without use controls")
		check(app.hub_parts.art_banner.identity=="scene_shop" and app.travel_buttons.buy_potion.icon!=null,"Shop uses replaceable scenery and item icon slots")
		check(not app.travel_buttons["heal_potion"].is_visible_in_tree(),"Using a potion is not mixed into buying")
		await click(app,app.travel_buttons.shop_evolution)
		check(app.travel_buttons["buy_rare-candy"].is_visible_in_tree() and not app.travel_buttons.buy_potion.is_visible_in_tree(),"Evolution separates candies and stones from medicine")
		await click(app,app.travel_buttons.shop_gear)
		check(app.shop_sections.gear.is_visible_in_tree() and not app.shop_sections.supplies.is_visible_in_tree(),"Only selected shop category is visible")
		await click(app,app.travel_buttons.shop_traits)
		check(app.travel_buttons.buy_mint.is_visible_in_tree(),"Mints reachable in Traits")
		await click(app,app.travel_buttons.shop_supplies)
		check(Store.equivalent(app.run,before),"Shop navigation preserves full state and RNG")
		check(app.travel_buttons["continue"].get_global_rect().end.y<=app.size.y and app.travel_buttons["continue"].is_visible_in_tree(),"Continue remains visible outside the shop scroll")
		var expected: Dictionary = app.campaign.transact(app.run,{"kind":"buy","item":"potion","at":app.run.revision})
		await click(app,app.travel_buttons.buy_potion)
		check(expected.ok and Store.equivalent(app.run,expected.state),"Visible shop purchase matches unchanged domain")
		check(app.travel_buttons["member_1"].icon!=null,"Team cards reuse original portraits")
		check(app.travel_buttons["continue"].theme_type_variation=="PrimaryButton","Travel commitment has primary hierarchy")
		await capture(app,directory,"shop-1024")
		app.get_window().size = Vector2i(1280,900)
		await capture(app,directory,"shop-1280")
		await click(app,app.travel_buttons.hub_team)
		check(not app.hub_parts.shop.is_visible_in_tree() and app.hub_parts.details.is_visible_in_tree(),"Managing the team hides purchases")
		await click(app,app.travel_buttons.detail_items)
		check(app.travel_buttons.heal_potion.is_visible_in_tree() and not app.travel_buttons["heal_max-potion"].is_visible_in_tree(),"Bag displays owned medicine only")
		await capture(app,directory,"team-bag-1280")
		before = app.run.duplicate(true)
		await click(app,app.travel_buttons.use_batch)
		check(app.shop_batch.operation.selected==1 and not app.shop_batch.operation.is_visible_in_tree() and app.shop_batch.get_ok_button().text=="Usar","Use-many opens directly in use context")
		await capture(app,directory,"use-many")
		await click(app,app.shop_batch.get_cancel_button())
		check(Store.equivalent(before,app.run),"Cancelling use-many preserves HP, bag and RNG")
		var heal: Dictionary = app.campaign.transact(app.run,{"kind":"heal","member":app.selected_member,"item":"potion","at":app.run.revision})
		if heal.ok:
			await click(app,app.travel_buttons.heal_potion)
			check(Store.equivalent(app.run,heal.state),"Using the owned potion matches unchanged domain and stock")
		before = app.run.duplicate(true)
		for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
			app.get_window().size = dimensions
			for scale_value: int in [100,125,150]:
				app.input_profile.set_preference("textScale",scale_value)
				app._apply_preferences()
				await settle(app)
				for tab: String in ["profile","items","moves","traits"]:
					await click(app,app.travel_buttons["detail_"+tab])
					check(app.hub_parts[tab].is_visible_in_tree(),"Only requested Pokémon detail is presented: "+tab)
					check(app.travel_buttons["continue"].get_global_rect().end.y<=app.size.y,"Continue fits during management at %d/%d" % [dimensions.x,scale_value])
				check(app.hub_parts.details.get_global_rect().end.x<=app.size.x,"Details fit without horizontal overflow at %d/%d" % [dimensions.x,scale_value])
				check(app.travel_buttons.member_1.size.x>=280 and app.travel_buttons.member_1.size.y<140,"Roster cards remain readable and compact at %d/%d" % [dimensions.x,scale_value])
				check(app.travel_buttons.hub_team.get_global_rect().end.x<app.size.x,"Hub navigation fits at %d/%d" % [dimensions.x,scale_value])
				await capture(app,directory,"team-%d-%d" % [dimensions.x,scale_value])
		check(Store.equivalent(before,app.run),"Hub, bag and detail tabs preserve full campaign and all RNG")
		app.input_profile.set_preference("textScale",100)
		app._apply_preferences()
		await click(app,app.travel_buttons.hub_overview)
		await click(app,app.travel_buttons.shop_traits)
		var mint_buy: Dictionary = app.campaign.transact(app.run,{"kind":"buy","item":"mint-"+app.selected_mint,"at":app.run.revision})
		await click(app,app.travel_buttons.buy_mint)
		check(mint_buy.ok and Store.equivalent(app.run,mint_buy.state),"Buying a mint only adds it to the bag")
		await click(app,app.travel_buttons.hub_team)
		await click(app,app.travel_buttons.detail_traits)
		check(app.travel_buttons.use_mint_picker.is_visible_in_tree() and app.travel_buttons.use_mint_picker.item_count==1,"Owned mint picker contains only purchased mints")
		var mint_use: Dictionary = app.campaign.transact(app.run,{"kind":"mint","member":app.selected_member,"nature":app.selected_mint,"at":app.run.revision})
		await click(app,app.travel_buttons.use_mint)
		check(mint_use.ok and Store.equivalent(app.run,mint_use.state),"Using the purchased mint matches unchanged domain")
		saved = app.run.duplicate(true)
		app.run = {}; app.state = {}; app.transactions = []
		app.store = Store.new(path)
		app._open_title()
		await click(app,app.title_screen.controls["continue"])
		check(Store.equivalent(app.run,saved),"Cold Continue replays saved purchases and party exactly")
	var broken: String = path+".broken"
	FileAccess.open(broken,FileAccess.WRITE).store_string("{broken")
	app.run = {}; app.state = {}; app.transactions = []
	app.store = Store.new(broken)
	app._open_title()
	await click(app,app.title_screen.controls["continue"])
	check(app.title_visible and not app.title_screen.notice.text.is_empty(),"Failed Continue keeps title and explains the error")
	check(FileAccess.get_file_as_string(broken)=="{broken","Failed Continue preserves corrupt bytes")
	await capture(app,directory,"title-invalid-save")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"version":ProjectSettings.get_setting("application/config/version"),"screenshots":screenshots,"rulesEdition":18,"battlePaused":true,"savePreserved":true,"minimumViewport":"1024x720"}
	FileAccess.open(directory.path_join("interface-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	app.get_tree().quit(0 if failures.is_empty() else 1)
