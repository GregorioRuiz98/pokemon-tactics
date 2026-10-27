extends "res://ui/qa_context.gd"

const ReviewStore = preload("res://core/review_store.gd")
const ReviewEffects = preload("res://ui/attack_effect.gd")
const ReviewVariants = preload("res://ui/attack_variants.gd")
const ReviewPoints = preload("res://core/power_points.gd")

func layout(app: Control) -> void:
	for frame: int in 8: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("review-controls.json"))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = ReviewStore.new(directory.path_join("review-natural-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "release-33-kanto"
	await click(app,app.travel_buttons.starter1)
	check(app.run.edition==26,"Current revision creates edition26")
	await click(app,app.travel_buttons.enter); await click(app,app.adventure.start_button)
	for step: int in 200:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural opening reaches its real reward")
	if app.run.phase=="capture": await click(app,app.travel_buttons.capture)
	check(app.run.phase=="shop","Natural reward reaches Kecleon")
	var natural: Dictionary = app.run.duplicate(true)
	var original_transactions: Array = app.transactions.duplicate(true)
	var original_store: RefCounted = app.store
	app._load_game(); await layout(app)
	check(ReviewStore.equivalent(app.run,natural),"Natural current journal reloads exactly")
	# Explicit menu-stress fixture; never saved as part of the natural campaign.
	app.run = natural.duplicate(true); app.run.party = []; app.run.reserve = []
	var team: Array = [1,4,7,25,34,113]
	var next_id: int = 100
	for dex: int in range(1,152):
		if dex in [144,145,146,150,151]: continue
		var member: Dictionary = app.campaign.progression.create_member(next_id,dex,"Menu stress fixture",75)
		app.campaign.progression.assign(member,app.run.seed); next_id += 1
		for item: Dictionary in app.campaign.shop_data.items.values():
			if item.kind=="tm" and item.get("species",[]).any(func(id):return int(id)==dex) and item.move not in member.knownMoves: member.knownMoves.append(item.move)
		member.moves = ReviewPoints.fit(member.knownMoves,member.level,app.rules.catalog.moves)
		if dex in team: app.run.party.append(member)
		else: app.run.reserve.append(member)
	app.selected_member = app.run.party.filter(func(m):return m.speciesId==34)[0].id
	app.state = {}; app._set_hub_mode("team"); app._set_member_view("moves"); await layout(app)
	check(app.run.party.size()==6 and app.run.reserve.size()==140,"Full team and140 legal nonlegendary reserve species")
	check(app.campaign.target(app.run,app.selected_member).knownMoves.size()>20,"Large legal learned/MT library")
	for index: int in 4: check(app.travel_buttons.has("move_slot_"+str(index)),"Prepared slot remains accessible: "+str(index))
	await capture(app,directory,"full-library-100")
	app.get_window().size = Vector2i(1024,768)
	app.input_profile.set_preference("textScale",150); app.input_profile.set_preference("highContrast",true); app._apply_preferences(); app._refresh(); await layout(app)
	await capture(app,directory,"full-library-1024-150")
	await click(app,app.travel_buttons.roster_pc)
	await click(app,app.travel_buttons.pc_next)
	check(app.roster_offset==1,"Large PC paginates by keyboard/mouse controls")
	await capture(app,directory,"full-pc-1024-150")
	app.roster_panel.filters.query = "Dragonite"; app.roster_offset = 0; app._refresh(); await layout(app)
	check(app.roster_panel.filters.filtered(app,app.run.reserve).size()==1,"Large PC search finds exactly one species")
	app.roster_panel.filters.clear()
	app.get_window().size = Vector2i(1280,900)
	app.input_profile.set_preference("textScale",100); app.input_profile.set_preference("highContrast",false); app._apply_preferences()
	app._refresh()
	app.run.phase = "battle"; app.run.battle = app.rules.encounter(app.run,app.campaign.locations[0]); app.run.battle.deployment = false
	var battle: Dictionary = app.run.battle
	var units: Array = []
	for index: int in 12:
		var unit: Dictionary = app.rules.member_unit(app.run.party[index%6],{"x":6+index%4,"y":5+int(index/4.0)})
		unit.id = index+1; unit.team = "ally" if index<6 else "enemy"
		unit.status = {"kind":"poison","remaining":3}; unit.stages = {"attack":1,"defense":-1,"speed":2}
		units.append(unit)
	battle.units = units; battle.queue = units.map(func(u):return u.id); battle.acted = false; battle.moved = false
	app.state = battle; app._prepare_campaign_assets(); app._refresh(); await layout(app)
	app.board.focus_point(units[0]); app.board.cursor = Vector2i(units[0].x,units[0].y); app.board.queue_redraw(); await layout(app)
	check(app.board.unit_labels.size()==12,"Crowded battle lays out every visible status label")
	check(app.board.unit_labels.values().filter(func(v):return v.detailed).size()<=2,"Only active/inspected units expand full details")
	await capture(app,directory,"crowded-battle-12")
	var before: Dictionary = app.run.duplicate(true)
	var effect: Control = app.combat_feedback.attack_effect
	var reviewed: int = 0
	for group: String in ReviewVariants.GROUPS:
		var identity: String = ReviewVariants.GROUPS[group][0]
		if not app.rules.catalog.moves.has(identity): continue
		var definition: Dictionary = app.rules.catalog.moves[identity]
		var described: Dictionary = ReviewEffects.describe(definition)
		check(described.get("reviewStyle","")==group,"Distinct motif for "+identity)
		var target: Dictionary = units[6]
		var plan: Dictionary = {"tiles":[target],"aim":target,"hits":[{"targetId":target.id,"multiplier":1,"heal":0}]}
		app.input_profile.set_preference("reducedMotion",true); app._apply_preferences()
		await layout(app)
		app.combat_feedback.present(battle,plan,[{"targetId":target.id,"hit":true,"damage":20}],definition)
		effect.set_process(false)
		effect.advance(.05); await layout(app)
		check(effect.active and effect.profile.get("reviewStyle","")==group,"Renderer accepts reduced-motion motif "+identity)
		if group in ["jaws","powder","stones"]: await capture(app,directory,"attack-"+group)
		effect.stop(); reviewed += 1
	check(ReviewEffects.describe(app.rules.catalog.moves["hyper-beam"]).cue=="original/hyper-beam","Hyper Beam original audio retained")
	check(ReviewStore.equivalent(app.run,before),"Labels and all animations consume no state or RNG")
	app.run = natural; app.state = {}; app.transactions = original_transactions; app.store = original_store
	app.selected_member = 1; app.roster_tab = "team"; app._refresh(); app._load_game(); await layout(app)
	check(ReviewStore.equivalent(app.run,natural),"Stress fixtures never replace natural save")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"motifs":reviewed,"scope":"Natural opening/save; separate synthetic140-member PC, large legal MT library and12-unit rendering fixtures. No human/external hardware claim."}
	FileAccess.open(directory.path_join("review-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA review "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
