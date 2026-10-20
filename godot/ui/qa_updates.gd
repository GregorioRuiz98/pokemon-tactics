extends "res://ui/qa_context.gd"

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("updates-controls-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile
	app.controls_dialog.profile = app.input_profile
	await fixture(app,directory)
	var before: Dictionary = app.run.duplicate(true)
	await key(app,KEY_I)
	check(app.tactical_reader.visible and app.tactical_reader.body.text.contains("PS"),"Keyboard opens persistent inspection")
	for i: int in 100: app.tactical_reader.show_unit(1)
	check(Store.equivalent(before,app.run) and app.transactions.is_empty(),"One hundred inspections preserve full state, journal and RNG")
	await key(app,KEY_ESCAPE,app.tactical_reader)
	check(not app.tactical_reader.visible and focus_is(app,app.board),"Inspection restores board focus")
	app._menu_selected(10)
	check(app.tactical_reader.visible,"Visible menu provides same inspection")
	await key(app,KEY_ESCAPE,app.tactical_reader)
	await key(app,KEY_1)
	await key(app,KEY_E)
	var plan: Dictionary = app.rules.attack_plan(app.state,10000,{},"basic")
	check(app.target_info.text.contains("%d–%d" % [plan.damageMin,plan.damageMax]),"Compact forecast uses exact normal damage band")
	await key(app,KEY_ENTER)
	await key(app,KEY_L)
	check(app.tactical_reader.body.text.contains("PS reales"),"Persistent result exposes real receipt after attack")
	await key(app,KEY_ESCAPE,app.tactical_reader)
	await capture(app,directory,"tactical-info")
	await additional(app,directory)
	var output: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"scope":"Native synthetic events and explicitly synthetic interaction fixtures; isolated saves"}
	FileAccess.open(directory.path_join("updates-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(output,"\t"))
	print("UPDATES_QA "+JSON.stringify(output))
	app.get_tree().quit(0 if failures.is_empty() else 1)

func additional(app: Control, directory: String) -> void:
	var before: Dictionary = app.run.duplicate(true)
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900),Vector2i(1920,1080)]:
		app.get_window().size = dimensions
		await settle(app)
		for scale_value: int in [100,125,150]:
			check(app.input_profile.set_preference("textScale",scale_value),"Text scale persisted")
			app._apply_preferences()
			await settle(app)
			check(app.actor_info.get_theme_font_size("font_size")>=18,"HUD compensates physical shrink and enlarges text")
			check(app.board.play_area().size.x>0 and app.board.play_area().size.y>0,"Positive board with enlarged HUD")
			await capture(app,directory,"text-%d-%d" % [dimensions.x,scale_value])
	check(Store.equivalent(before,app.run),"Presentation settings and window changes preserve complete campaign and RNG")
	check(app.input_profile.set_preference("muted",true) and app.input_profile.set_preference("reducedMotion",true),"Silence and reduced motion save")
	var reloaded: RefCounted = Profile.new(app.input_profile.path)
	check(reloaded.preferences.muted and reloaded.preferences.reducedMotion and reloaded.preferences.textScale==150,"Fresh profile restores presentation settings")
	app.input_profile.install()
	app._open_presentation()
	await key(app,KEY_F12,app.presentation_dialog)
	check(not app.presentation_dialog.visible and app.input_profile.preferences.textScale==100,"F12 recovers readability from modal")
	app.get_window().size = Vector2i(1280,900)
	app._apply_preferences()
