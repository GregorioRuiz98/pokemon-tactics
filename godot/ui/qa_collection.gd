extends "res://ui/qa_context.gd"

const CollectionStore = preload("res://core/collection_store.gd")
const Collection = preload("res://core/collection_catalog.gd")

func layout(app: Control) -> void:
	for frame: int in 8: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("collection-controls.json"))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.trainer.persistence = app.trainer.Store.new(directory.path_join("profile-%d.json"%Time.get_ticks_usec()))
	app.trainer.persistence.load_profile(); app.trainer.model = app.trainer.Model.new(); app.trainer.signature = ""; app.trainer.persist()
	app.store = CollectionStore.new(directory.path_join("natural-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	check(app.travel_buttons.other_starters.disabled,"New profile has only Oak starters")
	app.journey_seed.text = "release-33-kanto"
	await click(app,app.travel_buttons.starter1)
	check(app.run.edition==28 and app.trainer.model.data.version==2,"Current campaign and profile versions")
	await click(app,app.travel_buttons.enter); await click(app,app.adventure.start_button)
	for step: int in 220:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural opening reaches capture")
	if app.run.phase!="capture": finish(app,directory); return
	var reward: int = int(app.run.reward.speciesId)
	check(reward not in app.trainer.model.data.dex,"Previewed reward is not obtained yet")
	await click(app,app.travel_buttons.capture)
	check(reward in app.trainer.model.data.dex,"Claiming capture updates profile")
	check(app.trainer.model.data.unlocked.has("first-recruit"),"Recruitment achievement awarded")
	await click(app,app.travel_buttons.shop_recruitment)
	var offers: Array = app.campaign.collection_offers(app.run)
	check(offers.size()==3,"Kecleon offers three recruits")
	await capture(app,directory,"recruitment-shop")
	var offer: Dictionary = offers.filter(func(candidate):return Collection.base_species(int(candidate.speciesId)) not in [1,4,7])[0]
	var money: int = int(app.run.money)
	await click(app,app.travel_buttons["adopt_"+str(offer.speciesId)])
	check(app.action_review.visible and app.run.money==money,"Recruitment confirmation does not charge early")
	await click(app,app.action_review.get_ok_button())
	check(app.run.money==money-offer.price and int(offer.speciesId) in app.trainer.model.data.dex,"Purchase charges and records ownership")
	check(app.campaign.collection_offers(app.run).is_empty(),"Second purchase unavailable")
	var natural: Dictionary = app.run.duplicate(true)
	DirAccess.remove_absolute(app.store.file_path+".verified")
	app.store = CollectionStore.new(app.store.file_path)
	app._load_game(); await layout(app)
	check(CollectionStore.equivalent(app.run,natural),"Recruitment journal reloads exactly")
	check(not app.store.last_load.cached,"Recruitment reload reconstructs real JSON journal")
	check(app.save_warning.is_empty() and app.trainer.warning.is_empty(),"Campaign and profile saved without warning")
	app.trainer.open(app); app.trainer.dialog.change_page("dex"); await layout(app)
	var browser: VBoxContainer = app.trainer.dialog.dex_browser
	check(browser.matches.size()==151 and browser.controls.size()==10,"Pokédex pages all151 species")
	browser.query.text = "Mewtwo"; browser.render(); await layout(app)
	check(browser.matches==[150],"Pokédex finds species by name")
	browser.query.text = ""; browser.filter.select(1); browser.render()
	check(browser.matches.size()==app.trainer.model.data.dex.size(),"Obtained filter matches persistent collection")
	await capture(app,directory,"pokedex-obtained")
	app.get_window().size = Vector2i(1024,768)
	app.input_profile.set_preference("textScale",150); app._apply_preferences(); await layout(app)
	await capture(app,directory,"pokedex-1024-150")
	check(app.trainer.dialog.size.x<=1024 and app.trainer.dialog.size.y<=768,"Pokédex fits small window at150percent")
	app.trainer.dialog.change_page("achievements"); await layout(app)
	check(app.trainer.model.ACHIEVEMENTS.size()==19,"All19 achievements visible")
	await capture(app,directory,"achievements-1024-150")
	await key(app,KEY_ESCAPE,app.trainer.dialog); await layout(app)
	check(not app.trainer.dialog.visible,"Escape closes trainer panel")
	app.get_window().size = Vector2i(1280,900); app.input_profile.set_preference("textScale",100); app._apply_preferences()
	app._show_oak(); await layout(app)
	app.journey_seed.text = "collection-unlocked"
	check(not app.travel_buttons.other_starters.disabled,"Recruited species enables additional starters")
	await click(app,app.travel_buttons.other_starters)
	check(app.starter_dialog.visible,"Starter picker opens")
	var base: int = Collection.base_species(int(offer.speciesId))
	app.starter_browser.query.text = app.rules.profiles[base].data.name; app.starter_browser.render(); await layout(app)
	check(app.starter_browser.controls.has(base),"Only first family form appears as starter")
	await capture(app,directory,"unlocked-starter")
	await click(app,app.starter_browser.controls[base]); await layout(app)
	check(app.run.starter==base and app.run.party.size()==1 and app.run.party[0].level==5,"Selected unlocked starter starts fresh at5")
	check(app.trainer.model.data.unlocked.has("new-starter"),"New starter achievement")
	var saved: Dictionary = app.run.duplicate(true)
	app._load_game(); await layout(app)
	check(CollectionStore.equivalent(app.run,saved),"New starter survives real saved replay")
	var reloaded: RefCounted = app.trainer.Store.new(app.trainer.persistence.file_path)
	var recovered_profile: RefCounted = app.trainer.Model.new(reloaded.load_profile().data)
	check(int(offer.speciesId) in recovered_profile.data.dex and base in recovered_profile.starters(),"Collection survives independent profile load")
	# Presentation-only fixture: boss mechanics are exercised through real victory transactions in core tests.
	app.run.phase = "capture"; app.run.legendaryChoices = [144,145,146]; app.run.collectionAfter = "shop"
	app.run.reward = app.campaign.collection_member(app.run,144,75,"Desafío de las aves")
	app._prepare_campaign_assets(); app._refresh(); await layout(app)
	check(app.travel_buttons.has("legend_144") and app.travel_buttons.has("legend_145") and app.travel_buttons.has("legend_146") and not app.travel_buttons.has("reroll_capture"),"Boss screen exposes three choices without paid reroll")
	await capture(app,directory,"legendary-selection")
	app.run = saved; app._load_game(); await layout(app)
	check(CollectionStore.equivalent(app.run,saved),"Boss presentation fixture never replaces save")
	finish(app,directory)

func finish(app: Control, directory: String) -> void:
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"campaignEdition":app.run.edition,"profileSchema":app.trainer.model.data.version,"scope":"Natural first battle, capture, Kecleon recruitment, profile, fresh unlocked starter and saved reload; explicit boss presentation fixture. No human/external hardware claim."}
	FileAccess.open(directory.path_join("collection-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("QA collection "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
