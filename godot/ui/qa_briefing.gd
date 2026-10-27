extends "res://ui/qa_context.gd"

const ReviewStore = preload("res://core/tactics_quality_store.gd")

func layout(app: Control) -> void:
	for frame: int in 8: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("briefing-controls.json"))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.store = ReviewStore.new(directory.path_join("briefing-natural-%d.json"%Time.get_ticks_usec()))
	await capture(app,directory,"title-buttons")
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "release-33-kanto"
	await click(app,app.travel_buttons.starter1)
	await layout(app)
	var before_entry: Dictionary = app.run.duplicate(true)
	var before_journal: Array = app.transactions.duplicate(true)
	var pending: Dictionary = app.encounter_preview.travel_state.duplicate(true)
	check(app.run.phase=="map" and app.run.battle.is_empty(),"Preview is visible before entering any battle")
	check(not app.encounter_preview.travel_cards.is_empty(),"Map screen automatically shows actual rivals")
	check(not app.encounter_preview.travel_context.text.is_empty() and not app.encounter_preview.travel_objective.text.is_empty(),"Context and objective are readable before entry")
	check(app.hub_parts.rivals.visible and not app.hub_parts.team_body.visible,"Map reserves a visible panel for opponents")
	await capture(app,directory,"before-combat-rivals")
	await click(app,app.encounter_preview.travel_cards[0]); await layout(app)
	check(app.encounter_preview.dialog.visible,"Map rival opens details with pointer")
	check(app.encounter_preview.selected==pending.units.filter(func(u):return u.team=="enemy")[0],"Map details use actual opponent stats and moves")
	await capture(app,directory,"before-combat-details")
	await key(app,KEY_ESCAPE,app.encounter_preview.dialog)
	check(app.encounter_preview.travel_cards[0].has_focus(),"Escape returns focus to map rival")
	await key(app,KEY_ENTER); await layout(app)
	check(app.encounter_preview.dialog.visible,"Map rival opens with keyboard")
	await key(app,KEY_ESCAPE,app.encounter_preview.dialog)
	app._refresh(); await layout(app)
	check(ReviewStore.equivalent(before_entry,app.run) and before_journal==app.transactions,"Preview and repeated refresh preserve campaign, RNG and journal")
	check(ReviewStore.equivalent(pending,app.encounter_preview.travel_state),"Redraw reuses deterministic encounter snapshot")
	await click(app,app.travel_buttons.enter); await layout(app)
	check(ReviewStore.equivalent(pending,app.run.battle),"Actual encounter matches the map preview exactly")
	var preview: RefCounted = app.encounter_preview
	var natural: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	check(preview.panel.visible and app.state.deployment,"Rival roster appears automatically before first battle")
	check(preview.cards.size()==app.state.units.filter(func(u):return u.team=="enemy").size(),"One card per actual enemy")
	check(app.adventure.start_button.is_visible_in_tree(),"Start remains directly accessible without dismissing a modal")
	await capture(app,directory,"route-preview")
	await click(app,preview.cards[0]); await layout(app)
	check(preview.dialog.visible and app._modal_open(),"Mouse opens modal enemy details")
	check(preview.selected==app.state.units.filter(func(u):return u.team=="enemy")[0],"Details use exact generated stats and prepared moves")
	await capture(app,directory,"enemy-details")
	await key(app,KEY_ESCAPE,preview.dialog)
	check(not preview.dialog.visible and preview.cards[0].has_focus(),"Escape returns keyboard focus to enemy card")
	await key(app,KEY_ENTER); await layout(app)
	check(preview.dialog.visible,"Keyboard activates the same card")
	await key(app,KEY_ESCAPE,preview.dialog)
	check(ReviewStore.equivalent(app.run,natural),"Inspecting rivals consumes neither RNG nor transactions")
	app._load_game(); await layout(app)
	check(ReviewStore.equivalent(app.run,natural) and preview.panel.visible,"Reload preserves real opponents and prebattle preview")
	app.board.grab_focus(); await key(app,KEY_B); await layout(app)
	check(not app.state.deployment and not preview.panel.visible,"Start shortcut removes preview and begins battle")
	check(app.actor_portrait.get_parent().get_parent().get_parent().visible and app.hint.get_parent().visible,"Normal combat HUD restored")
	var saved_after_start: Dictionary = app.run.duplicate(true)
	check(not Profile.ACTIONS.has("threats"),"Removed threats have no controls entry or shortcut")
	check(not app.hint.text.contains("Alcance potencial"),"Combat has no automatic threat readout")
	var white: Color = Color.WHITE
	for state_name: String in ["normal","pressed","disabled"]:
		check(app.theme.get_stylebox(state_name,"FieldCommandButton").bg_color==white,"Field box stays white: "+state_name)
	for state_name: String in ["hover","hover_pressed"]:
		check(app.theme.get_stylebox(state_name,"FieldCommandButton").bg_color==Color("fff0a6"),"Yellow background only on hover: "+state_name)
	check(not app.theme.get_stylebox("focus","FieldCommandButton").draw_center,"Keyboard focus uses an outline, never a yellow fill")
	check(app.command_panel.get_theme_stylebox("panel").bg_color==white,"Ability panel is white")
	for action: Button in app.action_buttons.values():
		check(action.get_theme_stylebox("normal").bg_color==white and action.get_theme_stylebox("pressed").bg_color==white,"Icon margin override preserves white normal and selected: "+action.text)
		check(action.get_theme_stylebox("hover").bg_color==Color("fff0a6"),"Icon margin override preserves yellow hover: "+action.text)
	await click(app,app.buttons.actions); await layout(app)
	await capture(app,directory,"white-command-menu")
	var hovered: Button = app.action_buttons.values()[0]
	await motion(app,hovered.get_global_rect().get_center()); await layout(app)
	check(hovered.is_hovered(),"Native pointer reaches an equipped move")
	await capture(app,directory,"yellow-hover-only")
	await motion(app,Vector2(10,10)); await layout(app)
	check(not hovered.is_hovered(),"Leaving move restores its white selected background")
	# Presentation fixtures for every real encounter definition, not a played campaign.
	var covered: Array[String] = []
	var precombat: Array[String] = []
	for index: int in app.campaign.locations.size():
		var location: Dictionary = app.campaign.locations[index]
		app.run = natural.duplicate(true); app.run.stage = index
		app.run.phase = "map"; app.run.battle = {}; app.state = {}
		var map_before: Dictionary = app.run.duplicate(true)
		app._prepare_campaign_assets(); app._refresh(); await layout(app)
		if location.get("kind","")=="story":
			check(preview.travel_cards.is_empty() and preview.travel_state.is_empty(),"Narrative visit never advertises a fake battle: "+location.id)
		else:
			var expected: Dictionary = app.rules.encounter(app.run.duplicate(true),location)
			var preview_enemies: Array = expected.units.filter(func(u):return u.team=="enemy")
			check(ReviewStore.equivalent(expected,preview.travel_state),"Exact pending encounter before entry: "+location.id)
			check(preview.travel_cards.size()==preview_enemies.size(),"Map has every opponent: "+location.id)
			check(preview.travel_cards[0].get_global_rect().position.y<app.size.y-120,"First rival visible above fold: "+location.id)
			check(not preview.travel_context.text.is_empty() and not preview.travel_objective.text.is_empty(),"Map has context and objective: "+location.id)
			for position: int in preview_enemies.size():
				var opponent: Dictionary = preview_enemies[position]
				check(preview.travel_cards[position].text.contains(opponent.name) and preview.travel_cards[position].text.contains("Nv. %d"%opponent.level),"Map identity and level: "+location.id+"/"+str(position))
				for move: String in opponent.get("moves",[]):
					check(preview.travel_cards[position].text.contains(app.rules.catalog.moves[move].name),"Equipped move visible before entry: "+location.id+"/"+move)
			if location.get("leader",false) or location.id in ["legendary-birds","legendary-origin"]: await capture(app,directory,"map-"+location.id)
		check(ReviewStore.equivalent(map_before,app.run),"Map inspection preserves state and RNG: "+location.id)
		precombat.append(location.id)
		app.run.phase = "battle"
		app.run.battle = app.rules.encounter(app.run,location)
		app.run.battle.deployment = true; app.state = app.run.battle
		var before: Dictionary = app.run.duplicate(true)
		preview.refresh(app); await settle(app)
		var enemies: Array = app.state.units.filter(func(u):return u.team=="enemy")
		check(preview.cards.size()==enemies.size() and not enemies.is_empty(),"Preview covers all enemies: "+location.id)
		for position: int in enemies.size():
			check(preview.cards[position].text.contains(enemies[position].name) and preview.cards[position].text.contains("Nv. %d"%enemies[position].level),"Correct identity/level: "+location.id+"/"+str(position))
		check(ReviewStore.equivalent(app.run,before),"Pure preview: "+location.id)
		covered.append(location.id)
		if location.id.contains("brock") or index>=app.campaign.locations.size()-2:
			app._prepare_campaign_assets(); app._refresh(); await layout(app)
			await capture(app,directory,"encounter-"+location.id)
	# Small-window stress includes horizontal keyboard scrolling and a long details sheet.
	app.get_window().size = Vector2i(1024,768)
	app.input_profile.set_preference("textScale",150); app.input_profile.set_preference("highContrast",true)
	app._apply_preferences(); app._refresh(); await layout(app)
	preview.cards.back().grab_focus(); await layout(app)
	check(preview.scroll.scroll_horizontal>0 if preview.row.size.x>preview.scroll.size.x else true,"Focus scrolls overflowing enemy roster into view")
	check(preview.panel.get_global_rect().end.y<=app.size.y+1,"Large-text roster stays inside viewport")
	check(not preview.panel.get_global_rect().intersects(app.adventure.start_button.get_global_rect()),"Large-text preview never covers Start button")
	await capture(app,directory,"preview-1024-150")
	await key(app,KEY_ENTER); await layout(app)
	check(preview.dialog.visible,"Enemy sheet works at150 percent with keyboard")
	await capture(app,directory,"details-1024-150")
	await key(app,KEY_ESCAPE,preview.dialog)
	app.run.phase = "map"; app.run.battle = {}; app.state = {}
	app._refresh(); await layout(app)
	check(not preview.travel_cards.is_empty(),"Rival roster still present on map at150 percent")
	preview.travel_cards.back().grab_focus(); await layout(app)
	var map_card: Button = preview.travel_cards.back()
	check(map_card.get_global_rect().size.x<=app.size.x,"Large-font map cards fit viewport width")
	await capture(app,directory,"map-1024-150")
	await key(app,KEY_ENTER); await layout(app)
	check(preview.dialog.visible,"Map enemy sheet works at150 percent")
	await key(app,KEY_ESCAPE,preview.dialog)
	app.get_window().size = Vector2i(1280,900)
	app.input_profile.set_preference("textScale",100); app.input_profile.set_preference("highContrast",false)
	app._apply_preferences()
	app.run = natural.duplicate(true); app.run.phase = "map"; app.run.battle = {}; app.state = {}; app.transactions = journal
	app._prepare_campaign_assets(); app._refresh(); await layout(app)
	await click(app,app.travel_buttons.hub_team); await layout(app)
	check(app.hub_parts.team_body.visible and not app.hub_parts.rivals.visible,"Team and rival panels remain separate during preparation")
	await click(app,app.travel_buttons.hub_overview); await layout(app)
	check(app.hub_parts.rivals.visible,"Returning to journey restores opponents without an extra modal")
	check(app.camera_bar.size.y<65,"Toolbar shrinks after restoring normal text size")
	await capture(app,directory,"preview-restored")
	app._load_game(); await layout(app)
	check(ReviewStore.equivalent(app.run,saved_after_start),"Synthetic encounter inspections never overwrite saved campaign")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"encounters":covered,"precombatEncounters":precombat,"scope":"Native pointer/keyboard, map preview before entry, natural save/reload, white command styles, removed threats, presentation fixtures for all encounters; no human or external hardware claim."}
	FileAccess.open(directory.path_join("briefing-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA briefing "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
