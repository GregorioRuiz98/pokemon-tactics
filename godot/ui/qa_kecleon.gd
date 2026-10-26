extends "res://ui/qa_context.gd"

const CurrentStore = preload("res://core/profile_campaign_store.gd")

func layout(app: Control) -> void:
	for frame: int in 6: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("shop-controls-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = CurrentStore.new(directory.path_join("shop-campaign-%d.json" % Time.get_ticks_usec()))
	app._show_oak(); app.journey_seed.text = "kecleon-ui"
	await click(app,app.travel_buttons.starter4)
	await click(app,app.travel_buttons.enter); await click(app,app.adventure.start_button)
	for step: int in 250:
		if app.run.phase!="battle": break
		app._event({"kind":"battle","order":app.rules.choose_command(app.state),"at":app.run.revision})
	check(app.run.phase=="capture","Natural encounter reaches capture")
	if app.run.phase!="capture": finish(app,directory); return
	await click(app,app.travel_buttons.capture); await key(app,KEY_ESCAPE); await layout(app)
	check(app.kecleon.using_scene(app) and app.shop_tab=="gear","Natural shop opens the Kecleon counter")
	check(app.kecleon.actor.is_visible_in_tree() and app.kecleon.cards.size()==3,"Merchant and three product cards appear")
	check(not app.campaign.progression.species.has(352),"Merchant is not added to the recruitable Kanto roster")
	var before: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	var draws: int = app.kecleon.actor.draw_count
	for frame: int in 70: await app.get_tree().process_frame
	check(app.kecleon.actor.draw_count>draws,"Merchant animates from original sheet")
	check(Store.equivalent(before,app.run) and app.transactions==journal,"Idle animation consumes no campaign state or RNG")
	await capture(app,directory,"kecleon-counter")
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		app.get_window().size = dimensions
		for scale_value: int in [100,125,150]:
			app.input_profile.set_preference("textScale",scale_value); app._apply_preferences(); await layout(app)
			for index: int in 3:
				var button: Button = app.travel_buttons["stock_"+str(index)]
				check(button.is_visible_in_tree() and button.get_global_rect().end.x<=app.size.x,"Product card fits at %d/%d/%d" % [dimensions.x,scale_value,index])
				var info: Button = app.travel_buttons["stock_detail_"+str(index)]
				info.grab_focus(); await layout(app)
				check(info.has_focus(),"Each product remains keyboard-inspectable")
			if scale_value==150: await capture(app,directory,"kecleon-%d-150" % dimensions.x)
	app.get_window().size = Vector2i(1280,900)
	app.input_profile.set_preference("textScale",100); app._apply_preferences(); await layout(app)
	await click(app,app.travel_buttons.stock_detail_0)
	check(app.action_review.visible and app.action_review.content.text.contains("Potencia:"),"MT detail shares power and precision information")
	await key(app,KEY_ESCAPE,app.action_review)
	check(Store.equivalent(before,app.run),"Inspecting and cancelling spends neither money nor RNG")
	var item: Dictionary = app.campaign.shop_data.items[app.run.stock[0].item]
	var old_count: int = int(app.run.bag.get(app.run.stock[0].item,0))
	await click(app,app.travel_buttons.stock_0)
	check(app.run.stock[0].sold and app.run.money==before.money-item.price,"One click buys exactly one product at displayed price")
	check(app.run.bag[item.id if item.has("id") else before.stock[0].item]==old_count+1,"Purchase appears in bag")
	check(app.travel_buttons.stock_0.disabled and app.travel_buttons.stock_0.text.contains("AGOTADO"),"Sold product is clearly unavailable")
	check(app.kecleon.greeting_label.text.contains("Gracias"),"Merchant reacts only after accepted purchase")
	for attempt: int in 2:
		var cost: int = app.campaign.reroll_price(app.run)
		before = app.run.duplicate(true)
		await click(app,app.travel_buttons.reroll)
		check(app.run.revision==before.revision+1 and app.run.money==before.money-cost,"Renew offers charges once")
		check(app.travel_buttons.reroll.text.contains(str(cost+25)),"Next renewal price increases visibly")
	check(app.run.stock.size()==3,"Renewal retains exactly three products")
	await click(app,app.travel_buttons.shop_supplies)
	check(app.travel_buttons.has("buy_potion") and app.travel_buttons.has("buy_revive"),"Medicine is a direct shop service")
	before = app.run.duplicate(true)
	await click(app,app.travel_buttons.buy_potion)
	check(app.run.bag.potion==before.bag.potion+1 and app.run.money==before.money-app.campaign.consumables.potion.price,"Medicine purchase uses existing economy")
	check(app.travel_buttons.buy_revive.disabled==(app.run.money<app.campaign.consumables.revive.price),"Insufficient money is shown correctly")
	await click(app,app.travel_buttons.shop_evolution)
	check(app.travel_buttons.has("shop_train_xp") and app.travel_buttons.has("training_member"),"Training and member selection remain accessible")
	if not app.travel_buttons.shop_train_xp.disabled:
		before = app.run.duplicate(true)
		await click(app,app.travel_buttons.shop_train_xp)
		check(app.action_review.visible,"Training retains exact-price confirmation")
		await key(app,KEY_ESCAPE,app.action_review)
		check(Store.equivalent(before,app.run),"Cancelled training changes nothing")
	await click(app,app.travel_buttons.shop_traits)
	check(app.travel_buttons.has("buy_mint") and app.travel_buttons.has("buy_ability-capsule"),"Mints and ability capsules remain available")
	await click(app,app.travel_buttons.shop_team)
	check(app.hub_mode=="team" and app.travel_buttons.has("roster_team"),"Team and bag open from counter")
	for index: int in 3:
		if app.kecleon.using_scene(app): break
		await key(app,KEY_F6)
	check(app.kecleon.using_scene(app),"Panel keyboard navigation returns to the shop")
	app._shop_page("gear"); await layout(app)
	app.input_profile.set_preference("reducedMotion",true); app.input_profile.set_preference("highContrast",true)
	app._apply_preferences(); await layout(app)
	var merchant: Control = app.kecleon.actor
	merchant.react(); await layout(app)
	check(merchant.frame==0 and merchant.reaction==0,"Reduced motion freezes merchant and reactions")
	draws = merchant.draw_count
	for frame: int in 20: await app.get_tree().process_frame
	check(merchant.draw_count==draws,"Static merchant has no repeated redraws")
	await capture(app,directory,"kecleon-contrast")
	before = app.run.duplicate(true)
	app._open_title(); await layout(app)
	for frame: int in 20: await app.get_tree().process_frame
	check(Store.equivalent(before,app.run),"Leaving the scene cancels presentation without game writes")
	await click(app,app.title_screen.controls["continue"])
	app._load_game(); await layout(app)
	check(Store.equivalent(before,app.run),"Shop purchases, rerolls and profile metadata replay exactly")
	finish(app,directory)

func finish(app: Control, directory: String) -> void:
	var result: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"campaignEdition":app.run.get("edition",0),"scope":"Natural Route1/shop, original merchant animation, three offers, purchase/rerolls, services, keyboard, scales100/125/150, contrast/reduced motion and reload. No balance changes."}
	FileAccess.open(directory.path_join("shop-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("QA shop "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
