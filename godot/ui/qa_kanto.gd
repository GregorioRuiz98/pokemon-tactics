extends "res://ui/qa_context.gd"

const CurrentRun = preload("res://core/kanto_journey.gd")
const CurrentStore = preload("res://core/kanto_campaign_store.gd")
var natural_hash: String = ""
var gallery: Array = []
var frame_times: Array = []

func layout(app: Control) -> void:
	for frame: int in 6: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("kanto-controls-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = CurrentStore.new(directory.path_join("kanto-natural-%d.json" % Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	check(app.journey_seed.text.begins_with("kanto-"),"Automatic seed on new adventure")
	app.journey_seed.text = "kecleon-ui"
	await click(app,app.travel_buttons.starter4)
	check(app.run.edition==22,"New game uses installed maps edition")
	check(preload("res://core/kanto_landscape.gd").layouts.has("route-1") and app.hub_parts.art_banner.get("location")=="route-1","Local map preview works before the first battle")
	app._set_hub_mode("team"); app._set_member_view("moves"); await layout(app)
	check(not app.travel_buttons.has("role_0") and not app.travel_buttons.has("role_1"),"No predefined role proposals")
	check(app.travel_buttons.has("move_slot_0") and app.travel_buttons.has("team_tools"),"Prepared slots and actual team tools retained")
	var before: Dictionary = app.run.duplicate(true)
	await click(app,app.travel_buttons.team_tools)
	check(app.action_review.visible and not app.action_review.callback.is_valid(),"Team tool inspection is read-only")
	await key(app,KEY_ESCAPE,app.action_review)
	check(CurrentStore.equivalent(before,app.run),"Inspecting moves does not consume state or RNG")
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		app.get_window().size = dimensions
		for scale_value: int in [100,125,150]:
			app.input_profile.set_preference("textScale",scale_value); app._apply_preferences(); await layout(app)
			for index: int in 4:
				var button: Button = app.travel_buttons["move_slot_"+str(index)]
				button.grab_focus(); await layout(app)
				check(button.has_focus() and button.is_visible_in_tree(),"Move slot keyboard/scaling %d/%d/%d" % [dimensions.x,scale_value,index])
				check(button.get_global_rect().end.x<=app.size.x,"Prepared move fits panel")
			if scale_value==150: await capture(app,directory,"moves-%d-150" % dimensions.x)
	app.get_window().size = Vector2i(1280,900); app.input_profile.set_preference("textScale",100); app._apply_preferences()
	app._set_hub_mode("overview"); await layout(app)
	await click(app,app.travel_buttons.enter)
	check(app.state.landscape.id=="route-1" and app.state.deployment,"Authored opening deployment")
	app.adventure.start_button.grab_focus(); await key(app,KEY_ENTER)
	check(not app.state.deployment,"Keyboard starts encounter")
	for step: int in 400:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural opening reaches capture on new map")
	if app.run.phase!="capture": finish(app,directory); return
	await click(app,app.travel_buttons.capture); await layout(app)
	check(app.kecleon.using_scene(app),"Integrated shop follows natural capture")
	await capture(app,directory,"natural-kecleon")
	before = app.run.duplicate(true)
	natural_hash = JSON.stringify(before,"",true,true).sha256_text()
	app._load_game(); await layout(app)
	check(CurrentStore.equivalent(before,app.run),"Natural map/capture/shop journal replays")
	app.adventure.toast_remaining = 0; app.adventure.toast.hide(); app.trainer.pending.clear(); app.trainer.remaining = 0; app.trainer.notice.hide()
	app.combat_feedback.clear()
	# Explicit gallery fixtures: rendering every authored location, not claimed victories.
	for size_value: int in [16,24]:
		for index: int in app.campaign.locations.size():
			app.run = app.campaign.create("landscape-gallery",1); app.run.mapSize = size_value; app.run.stage = index; app.run.phase = "battle"
			app.run.party = []
			for species_id: int in [3,6,9,26,65,68]: app.run.party.append(app.campaign.progression.create_member(app.run.party.size()+1,species_id,"Rendering fixture",40))
			app.run.battle = app.rules.encounter(app.run,app.campaign.locations[index])
			app.state = app.run.battle; app._prepare_campaign_assets(); app._refresh(); app.board.fit_map(); await layout(app)
			var identity: String = app.campaign.locations[index].id
			if identity=="legendary-birds":
				var bird: Dictionary = app.state.units.filter(func(u):return int(u.speciesId)==144)[0]
				check(app.board._tile_color(bird).is_equal_approx(Color("b7d3da").lightened(app.board.Terrain.height_at(app.state,bird)*.035)),"Articuno stays in ice sector at both sizes")
			check(not app.board.prop_cache.is_empty(),"Themed props rendered "+identity+str(size_value))
			check(app.state.landscape.id==identity,"Correct location presentation "+identity+str(size_value))
			var terrain_count: int = app.board.terrain_rebuilds
			for redraw: int in 3: app.board.queue_redraw(); await app.get_tree().process_frame
			check(app.board.terrain_rebuilds==terrain_count,"Idle redraw retains terrain cache "+identity)
			gallery.append({"id":identity,"mapSize":size_value,"props":app.board.prop_cache.size()})
			if size_value==16 and identity in ["forest","brock","mt-moon","ss-anne","sabrina","pokemon-mansion","blaine","legendary-birds","legendary-origin"]: await capture(app,directory,identity)
	await poses(app,directory)
	# Occlusion and cursor are presentation-only; never rewrite campaign geometry.
	before = app.run.duplicate(true)
	app.board.set_meta("draw_samples",[])
	for tick: int in 100: app.board.queue_redraw(); await app.get_tree().process_frame
	frame_times = app.board.get_meta("draw_samples").duplicate()
	check(CurrentStore.equivalent(before,app.run),"Rendering and canopy transparency preserve all domain state")
	app.input_profile.set_preference("textScale",150); app._apply_preferences(); await layout(app)
	await capture(app,directory,"final-map-150")
	finish(app,directory)

func poses(app: Control, directory: String) -> void:
	var effect: Control = app.combat_feedback.attack_effect
	app.board.focus_active(); await layout(app)
	var blastoise: Dictionary = app.state.units.filter(func(u):return int(u.speciesId)==9)[0]
	var enemy: Dictionary = app.state.units.filter(func(u):return u.team=="enemy")[0]
	var initial: Dictionary = app.run.duplicate(true)
	var visual: Dictionary = app.state.duplicate(true); visual.queue = [blastoise.id]
	var definition: Dictionary = app.campaign.progression.data.moves["hydro-pump"]
	var receipt: Dictionary = {"targetId":enemy.id,"damage":10,"hit":true}
	effect.start(visual,{"aim":{"x":enemy.x,"y":enemy.y},"hits":[],"tiles":[]},[receipt],definition)
	effect.set_process(false); effect.advance(.12)
	check(effect.source_points().size()==2 and effect.targets.size()==1,"Two Blastoise cannon origins, one target receipt")
	await capture(app,directory,"blastoise-cannons")
	check(CurrentStore.equivalent(initial,app.run),"Cannon animation cannot duplicate damage, spend resources or consume RNG")
	app.board.reduced_motion = true; effect.advance(0)
	check(effect.impacted,"Reduced motion resolves without a travel animation")
	effect.stop(); app.board.reduced_motion = false

func finish(app: Control, directory: String) -> void:
	frame_times.sort()
	var p95: float = float(frame_times[mini(frame_times.size()-1,int(frame_times.size()*.95))]) if not frame_times.is_empty() else 0.0
	var result: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"gallery":gallery,"mapCatalogHash":FileAccess.get_file_as_string("res://data/kanto-landscapes.json").sha256_text(),"drawP95Ms":p95,"naturalStateHash":natural_hash,"campaignEdition":app.run.get("edition",0),"scope":"Natural Charmander Route1/capture/shop/replay; keyboard and text scaling; synthetic rendering gallery116, not a completed campaign."}
	FileAccess.open(directory.path_join("kanto-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("QA kanto "+JSON.stringify({"assertions":assertions,"failures":failures,"drawP95Ms":p95})); app.get_tree().quit(0 if failures.is_empty() else 1)
