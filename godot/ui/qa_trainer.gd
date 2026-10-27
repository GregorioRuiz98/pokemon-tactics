extends "res://ui/qa_context.gd"

const MetaStore = preload("res://core/collection_store.gd")
const TrainerStore = preload("res://core/collection_profile_store.gd")
const Trainer = preload("res://core/collection_profile.gd")

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("trainer-controls-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.trainer.persistence = TrainerStore.new(directory.path_join("profile-%d.json" % Time.get_ticks_usec()))
	app.trainer.model = Trainer.new(); check(app.trainer.persist(),"Fresh isolated profile saved")
	app.store = MetaStore.new(directory.path_join("campaign-%d.json" % Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.trainer)
	check(app.trainer.dialog.visible and app._modal_open(),"Profile opens from title and pauses gameplay")
	app.trainer.dialog.controls.name_field.text = "Ada"
	await click(app,app.trainer.dialog.controls.save)
	check(app.trainer.model.data.name=="Ada" and app.title_screen.controls.trainer.text.contains("Ada"),"Name saved and reflected on title")
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		app.get_window().size = dimensions
		for scale_value: int in [100,125,150]:
			app.input_profile.set_preference("textScale",scale_value); app._apply_preferences(); await settle(app)
			for page: String in ["card","achievements","dex","history"]:
				app.trainer.dialog.controls[page].grab_focus(); await key(app,KEY_ENTER,app.trainer.dialog)
				check(app.trainer.dialog.page==page,"Keyboard profile page %s/%d/%d" % [page,dimensions.x,scale_value])
				check(app.trainer.dialog.size.x<=dimensions.x and app.trainer.dialog.size.y<=dimensions.y,"Profile dialog fits viewport")
			if scale_value==150: await capture(app,directory,"profile-%d-150" % dimensions.x)
	app.get_window().size = Vector2i(1280,900)
	app.input_profile.set_preference("textScale",100); app._apply_preferences()
	await key(app,KEY_ESCAPE,app.trainer.dialog)
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "trainer-ui"
	await click(app,app.travel_buttons.starter1)
	check(app.trainer.model.data.runs.size()==1 and app.trainer.model.data.dex==[1],"New campaign binds once and registers starter")
	var before: Dictionary = app.run.duplicate(true)
	var profile_revision: int = int(app.trainer.model.data.revision)
	app._refresh(); await settle(app)
	check(Store.equivalent(before,app.run) and app.trainer.model.data.revision==profile_revision,"UI refresh mutates neither campaign nor profile")
	await click(app,app.travel_buttons.enter)
	await click(app,app.adventure.start_button)
	for index: int in 220:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural Route1 victory")
	if app.run.phase=="capture": await click(app,app.travel_buttons.capture)
	check(app.run.phase=="shop" and app.trainer.model.data.dex.size()==2,"Natural capture updates persistent dex")
	var identity: String = app.store.campaign_id
	check(app.trainer.model.data.runs[identity].wins==1,"Natural victory recorded")
	before = app.run.duplicate(true)
	app._load_game(); await settle(app)
	check(Store.equivalent(before,app.run) and app.trainer.model.data.runs[identity].wins==1,"Reload and replay never double progress")
	app._show_oak(); app._open_title(); await settle(app)
	check(app.trainer.model.data.runs[identity].status=="active","Closing Oak or title does not abandon campaign")
	# Cosmetic preview is explicitly prepared profile data, not a natural medal.
	app.trainer.model.unlock("first-medal",identity); check(app.trainer.persist(),"Prepared cosmetic fixture saved")
	await click(app,app.title_screen.controls.trainer)
	app.trainer.dialog.change_page("card"); await settle(app)
	check(app.trainer.dialog.controls.frame_choice.item_count==2,"Unlocked cosmetic frame appears")
	app.trainer.dialog.change_page("achievements"); await capture(app,directory,"achievements")
	await key(app,KEY_ESCAPE,app.trainer.dialog)
	await click(app,app.title_screen.controls["continue"])
	app.trainer.pending.clear(); app.trainer.pending.append("first-medal"); app.trainer.remaining = 0
	app.trainer.tick(app,.016); await settle(app)
	check(app.trainer.notice.visible and app.trainer.notice.size.y<160,"Achievement notice stays compact and nonmodal")
	check(Store.equivalent(before,app.run),"Achievement notice changes no campaign state")
	await capture(app,directory,"achievement-notice")
	app.trainer.tick(app,4)
	app._open_title(); await settle(app)
	app._show_oak(); await settle(app); app.journey_seed.text = "trainer-ui"
	await click(app,app.travel_buttons.starter7)
	check(app.trainer.model.data.runs.size()==2 and app.trainer.model.data.runs[identity].status=="abandoned","Confirmed new adventure creates new identity and marks previous abandoned")
	check(app.trainer.model.data.unlocked.has("first-medal"),"New campaign retains achievements")
	var reloaded: Dictionary = TrainerStore.new(app.trainer.persistence.file_path).load_profile()
	check(reloaded.ok and reloaded.data.name=="Ada" and reloaded.data.runs.size()==2,"Cold profile load retains name, achievements and history")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"profileSchema":2,"runs":app.trainer.model.data.runs.size(),"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"scope":"Native mouse/keyboard, profile scales, real Route1/capture, reload and new adventure. Medal cosmetics use an explicit isolated fixture."}
	FileAccess.open(directory.path_join("trainer-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA trainer "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
