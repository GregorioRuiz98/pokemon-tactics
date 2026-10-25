extends "res://ui/qa_context.gd"

const SpatialRun = preload("res://core/spatial_run.gd")
const SpatialStore = preload("res://core/spatial_store.gd")
var cues: Array[String] = []

func fixture(app: Control, directory: String, move: String = "smokescreen", width: int = 16) -> void:
	await super.fixture(app,directory,move,width)
	var old: Dictionary = app.state.duplicate(true)
	app.campaign = SpatialRun.new()
	app.rules = app.campaign.engine
	app.run = app.campaign.create("spatial-ui",1)
	app.run.mapSize = width
	app.run.phase = "battle"
	app.state = app.rules.encounter(app.run,app.campaign.locations[0])
	app.state.board = old.board
	app.state.heights = old.heights
	app.state.units = []
	for unit: Dictionary in old.units:
		var member: Dictionary = app.campaign.progression.create_member(int(unit.id),int(unit.speciesId),"Fixture",30)
		var fresh: Dictionary = app.rules.member_unit(member,{"x":unit.x,"y":unit.y})
		fresh.team = unit.team; fresh.facing = unit.facing; fresh.ability = "none"
		fresh.hp = 500; fresh.maxHp = 500
		if unit.id==1: fresh.moves = [move]; fresh.tp = 5
		app.state.units.append(fresh)
	app.state.queue = old.queue
	app.state.moved = false; app.state.acted = false
	app.run.battle = app.state
	app.run.battleInitial = app.state.duplicate(true)
	app.store = SpatialStore.new(directory.path_join("spatial-fixture-%d.json" % fixture_serial))
	app._prepare_campaign_assets()
	app._refresh()
	app.board.focus_point(app.state.units[0])
	app.board.grab_focus()
	await settle(app)

func cue(identity: String) -> void:
	cues.append(identity)

func run(app: Control, directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("spatial-controls.json"))
	app.board.input_profile = app.input_profile
	app.controls_dialog.profile = app.input_profile
	app.input_profile.set_preference("reducedMotion",false)
	app._apply_preferences()
	var effect: Control = app.combat_feedback.attack_effect
	effect.cue_requested.connect(cue)
	check(app.combat_sound.original_streams.size()==40,"Forty original move clips loaded")
	check(app.combat_sound.original_streams["hyper-beam"].get_length()>2.4,"Hyper Beam uses full original WAV")
	check(app.combat_sound.original_streams.values().all(func(stream):return stream is AudioStreamWAV and stream.format==AudioStreamWAV.FORMAT_16_BITS),"Original recordings import as 16-bit PCM without lossy compression")
	await fixture(app,directory,"tackle")
	var movement_before: Dictionary = app.state.duplicate(true)
	app._select_tile({"x":5,"y":7})
	check(app.state.moved and app._can_rectify(),"Pure movement exposes Rectify")
	app._rectify_movement()
	check(Store.equivalent(movement_before,app.state),"UI Rectify restores only movement and preserves RNG")
	await fixture(app,directory,"smokescreen")
	await key(app,KEY_2)
	app.board.cursor = Vector2i(8,8)
	app._hover_tile({"x":8,"y":8})
	check(app.board.affected.size()==5 and app.target_info.text.contains("Humo"),"Empty-ground smoke forecast and label")
	var before: Dictionary = app.run.duplicate(true)
	await key(app,KEY_ENTER)
	check(app.state.acted and app.state.fields.size()==5,"Keyboard casts smoke onto empty ground")
	check(app.run.revision==before.revision+1 and app.save_warning.is_empty(),"Accepted ground order is saved")
	check(effect.active and effect.tiles.size()==5,"Zone placement has its own animation without victims")
	effect.set_process(false)
	effect.advance(.4)
	await capture(app,directory,"smoke")
	await fixture(app,directory,"barrier")
	await key(app,KEY_2)
	app.board.cursor = Vector2i(7,7); app._hover_tile({"x":7,"y":7})
	var first: Array = app.board.affected.duplicate(true)
	await key(app,KEY_E)
	check(not Store.equivalent(first,app.board.affected),"Q/E rotates wall without a new button")
	await key(app,KEY_ENTER)
	check(app.state.fields.size()==3,"Rotated barrier commits from keyboard")
	await capture(app,directory,"barrier")
	await fixture(app,directory,"hyper-beam")
	await key(app,KEY_2)
	app.board.cursor = Vector2i(7,8); app._hover_tile({"x":7,"y":8})
	check(app.board.affected.size()==4 and app.board.forecast_hits.size()==2,"Piercing beam previews complete line")
	cues.clear()
	await key(app,KEY_ENTER)
	check(app.state.acted and cues==["original/hyper-beam"],"Hyper Beam launches its original sound once")
	effect.set_process(false); effect.advance(.6)
	check(effect.impacted and cues.size()==1 and effect.length>2.48,"Iconic sound remains intact without generic impact overlaid")
	await capture(app,directory,"hyper-beam")
	check(effect.clip_contents and effect.size==app.board.play_area().size,"New VFX are clipped to battlefield")
	var original_requests: int = app.combat_sound.requests
	app.board.hide(); app.qa_running = false
	var last_command: Dictionary = {"kind":"attack","target":10000,"actionId":"hyper-beam"}
	var initial: Dictionary = app.run.battleInitial
	app._present_combat(initial,last_command,app.rules.attack_plan(initial,10000,{},"hyper-beam"),[{"targetId":10000,"hit":true,"damage":500}],app.rules.catalog.moves["hyper-beam"])
	check(app.combat_sound.requests==original_requests+1,"Original sound also plays when a final hit opens rewards")
	app.qa_running = true; app.board.show(); app.combat_sound.stop()
	app._open_title()
	check(not effect.active,"Navigation cancels outstanding attack feedback")
	await fixture(app,directory,"surf")
	await key(app,KEY_2)
	app.board.cursor = Vector2i(6,8); app._hover_tile({"x":6,"y":8})
	check(app.target_info.text.contains("aliados"),"Area forecast announces friendly fire")
	await key(app,KEY_ENTER)
	check(not app.pending.is_empty() and not app.state.acted,"Friendly fire requires confirmation")
	await key(app,KEY_ESCAPE)
	check(not app.state.acted and app.pending.is_empty(),"Escape cancels area without action cost")
	await fixture(app,directory,"supersonic")
	app.state.units[1].x = 7; app.state.units[1].y = 8
	app.state.units[3].x = 9
	app.run.battleInitial = app.state.duplicate(true)
	await key(app,KEY_2)
	app.board.cursor = Vector2i(6,8); app._hover_tile({"x":6,"y":8})
	await key(app,KEY_ENTER)
	check(not app.pending.is_empty() and not app.state.acted,"Confusion area also warns before affecting allies")
	await key(app,KEY_ESCAPE)
	await fixture(app,directory,"seismic-toss")
	await key(app,KEY_2)
	app.spatial_throw = 0
	app.board.cursor = Vector2i(6,8); app._hover_tile({"x":6,"y":8})
	await key(app,KEY_E)
	await key(app,KEY_E)
	await key(app,KEY_ENTER)
	check(app.state.acted and app.state.units[2].x==5 and app.state.units[2].y==10,"Q/E chooses throw landing and Enter commits")
	await capture(app,directory,"throw")
	await fixture(app,directory,"psychic")
	await key(app,KEY_2)
	app.input_profile.set_preference("reducedMotion",true)
	app._apply_preferences()
	app.board.cursor = Vector2i(8,8); app._hover_tile({"x":8,"y":8})
	await tile(app,{"x":8,"y":8})
	if not app.pending.is_empty(): app._confirm()
	check(app.state.acted and effect.impacted and effect.offset_for(app.state.units[0])==Vector2.ZERO,"Mouse area order works with reduced motion")
	await capture(app,directory,"reduced-motion")
	var requests: int = app.combat_sound.requests
	app.combat_sound.play_cue("original/hyper-beam",100,true)
	app.combat_sound.play_cue("original/hyper-beam",0,false)
	check(app.combat_sound.requests==requests,"Mute and zero volume cover original sounds")
	app.combat_sound.play_cue("original/hyper-beam",50,false)
	check(app.combat_sound.requests==requests+1,"Original WAV starts under test audio driver")
	app.combat_sound.stop()
	await natural_battle(app,directory)
	effect.cue_requested.disconnect(cue)
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"originalSounds":40,"syntheticFixtures":true,"naturalCampaignReplay":true,"audioDriver":"Dummy; listening pending"}
	FileAccess.open(directory.path_join("spatial-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SPATIAL_UI "+JSON.stringify(report))
	app.get_tree().quit(0 if failures.is_empty() else 1)

func natural_battle(app: Control, directory: String) -> void:
	app.combat_feedback.clear()
	app.store = app.CampaignStore.new(directory.path_join("natural-campaign.json"))
	app._show_oak()
	app.journey_seed.text = "spatial-natural"
	await click(app,app.travel_buttons.starter1)
	check(app.run.edition==app.campaign.chapter-4,"Oak creates the requested compatibility edition")
	await click(app,app.travel_buttons.enter)
	for i: int in 120:
		if app.run.phase!="battle": break
		var prior: int = app.run.revision
		var order: Dictionary = app.rules.choose_command(app.state)
		app._commit(order)
		check(app.run.revision==prior+1,"Natural battle order accepted %d" % i)
		if app.run.revision==prior: break
		app.combat_feedback.clear()
	check(app.run.phase!="battle","Natural opening combat terminates")
	var loaded: Dictionary = app.CampaignStore.new(app.store.file_path).load_campaign(app.campaign)
	check(loaded.ok and Store.equivalent(loaded.get("state",{}),app.run),"Cold replay of natural campaign preserves all spatial state")
