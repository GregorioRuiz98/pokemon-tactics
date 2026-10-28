extends "res://ui/qa_context.gd"

const Identity = preload("res://ui/trainer_identity.gd")

func layout(app: Control) -> void:
	for frame: int in 8: await app.get_tree().process_frame

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("input-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile; app.controls_dialog.profile = app.input_profile
	app.trainer.persistence = app.trainer.Store.new(directory.path_join("trainer-%d.json" % Time.get_ticks_usec()))
	app.trainer.persistence.load_profile(); app.trainer.model = app.trainer.Model.new()
	# Cosmetic fixture only: no campaign wins, captures or medals are being claimed.
	app.trainer.model.data.dex = [1,151]; app.trainer.model.data.seen = [1,25,151]
	app.trainer.model.unlock("first-medal","cosmetic-fixture")
	app.trainer.model.unlock("champion","cosmetic-fixture")
	for status: String in ["active","completed","defeated","abandoned"]:
		app.trainer.model.data.runs[status] = {"seed":"cosmetic-fixture-"+status,"starter":4,"edition":29,"started":1793188800,"cursor":0,"status":status,"medals":8 if status=="completed" else 1,"battles":3,"wins":2,"kos":1,"locations":[],"partialHistory":false}
	check(app.trainer.model.customize("Ada",151,"Explorador de Kanto","leaf"),"Custom trainer fixture accepted")
	check(app.trainer.persist(),"Isolated profile saved")
	app.faces.erase(151); app.trainer.update_title(app)
	check(app.faces.has(151) and app.title_screen.controls.trainer.icon!=null,"Title loads an avatar absent from team cache")
	check(app.title_screen.controls.trainer.text.contains("Ada"),"Title identifies the saved trainer")
	var original: String = JSON.stringify(app.trainer.model.data,"",true,true)
	var disk: String = FileAccess.get_file_as_string(app.trainer.persistence.file_path)
	var campaign_before: String = JSON.stringify(app.run,"",true,true)
	await click(app,app.title_screen.controls.trainer); await layout(app)
	var panel: AcceptDialog = app.trainer.dialog
	check(panel.avatar.texture==Identity.portrait(app,151),"Saved portrait appears in trainer header")
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1280,900)]:
		app.get_window().size = dimensions
		for scale_value: int in [100,150]:
			app.input_profile.set_preference("textScale",scale_value)
			for contrast: bool in [false,true]:
				app.input_profile.set_preference("highContrast",contrast); app._apply_preferences(); await layout(app)
				for selected: String in ["card","achievements","dex","history"]:
					panel.controls[selected].grab_focus(); await settle(app); await key(app,KEY_ENTER,panel); await layout(app)
					check(panel.page==selected,"Keyboard selects %s/%d/%d/%s" % [selected,dimensions.x,scale_value,contrast])
					check(panel.card.visible and panel.trainer_name.text=="Ada" and panel.avatar.texture!=null,"Identity persists on "+selected)
					check(panel.controls[selected].button_pressed and panel.controls[selected].text.begins_with("● "),"Active page has a non-color marker")
					check(panel.size.x<=dimensions.x and panel.size.y<=dimensions.y,"Profile fits %d/%d/%s/%s" % [dimensions.x,scale_value,contrast,selected])
				if dimensions.x==1024 and scale_value==150:
					panel.change_page("card"); await capture(app,directory,"trainer-1024-150-"+str(contrast))
				elif dimensions.x==1280 and scale_value==100 and not contrast:
					panel.change_page("card"); await capture(app,directory,"trainer-card")
					panel.change_page("achievements"); await capture(app,directory,"trainer-achievements")
	check(JSON.stringify(app.trainer.model.data,"",true,true)==original and FileAccess.get_file_as_string(app.trainer.persistence.file_path)==disk,"Inspecting pages never writes or mutates profile")
	check(JSON.stringify(app.run,"",true,true)==campaign_before,"Profile inspection leaves campaign unchanged")
	panel.change_page("history"); await layout(app)
	var history: Dictionary = panel.controls.history_details[0]
	check(history.button.size.x>100 and history.button.size.y<100,"History details button remains readable at150percent")
	history.button.grab_focus(); await settle(app); await key(app,KEY_ENTER,panel); await layout(app)
	check(history.text.visible,"History details expand with keyboard")
	await capture(app,directory,"trainer-history")
	await key(app,KEY_ENTER,panel); await layout(app)
	check(not history.text.visible,"History details collapse with keyboard")
	app.input_profile.set_preference("textScale",100); app.input_profile.set_preference("highContrast",false)
	panel.change_page("card"); await layout(app)
	panel.controls.name_field.text = "M".repeat(24); panel.controls.name_field.text_changed.emit(panel.controls.name_field.text)
	app._apply_preferences(); await layout(app)
	check(panel.trainer_name.autowrap_mode==TextServer.AUTOWRAP_OFF and panel.size.y<=app.get_window().size.y,"Maximum name remains a single readable line after scaling")
	panel.controls.name_field.text = "Bruno"; panel.controls.name_field.text_changed.emit("Bruno")
	panel.controls.portrait.select(1); panel.controls.portrait.item_selected.emit(1)
	panel.controls.frame_choice.select(2); panel.controls.frame_choice.item_selected.emit(2)
	check(panel.trainer_name.text=="Bruno" and panel.preview_notice.text=="Sin guardar","Name previews without saving")
	check(panel.avatar.texture==Identity.portrait(app,4),"Portrait preview follows choice")
	check(panel.card.get_theme_stylebox("panel").border_color==Identity.accent("champion"),"Frame preview has its distinct accent")
	check(JSON.stringify(app.trainer.model.data,"",true,true)==original and FileAccess.get_file_as_string(app.trainer.persistence.file_path)==disk,"Preview is pure")
	await key(app,KEY_ESCAPE,panel); await layout(app)
	check(not panel.visible,"Escape closes the profile")
	app.trainer.open(app); panel.change_page("card"); await layout(app)
	check(panel.trainer_name.text=="Ada" and panel.controls.name_field.text=="Ada","Reopening discards unsaved cosmetic edits")
	panel.controls.name_field.text = "   "; panel.save_card(); await layout(app)
	check(panel.controls.name_field.text=="   " and panel.feedback_label.visible,"Invalid name stays editable with inline feedback")
	check(panel.gui_get_focus_owner()==panel.controls.name_field,"Invalid name receives keyboard focus")
	check(FileAccess.get_file_as_string(app.trainer.persistence.file_path)==disk,"Invalid name never reaches disk")
	panel.controls.name_field.text = "Bruno"; panel.controls.name_field.text_changed.emit("Bruno")
	panel.controls.portrait.select(1); panel.controls.portrait.item_selected.emit(1)
	panel.controls.frame_choice.select(2); panel.controls.frame_choice.item_selected.emit(2)
	await click(app,panel.controls.save); await layout(app)
	check(app.trainer.model.data.name=="Bruno" and app.trainer.model.data.portrait==4 and app.trainer.model.data.frame=="champion","Save commits cosmetic choices together")
	check(panel.preview_notice.text=="Perfil local" and app.title_screen.controls.trainer.text.contains("Bruno"),"Saved identity is reflected across screens")
	var loaded: Dictionary = app.trainer.Store.new(app.trainer.persistence.file_path).load_profile()
	check(loaded.ok and loaded.data.name=="Bruno" and loaded.data.frame=="champion","Independent profile reload preserves customization")
	check(JSON.stringify(app.run,"",true,true)==campaign_before,"Customization never alters campaign")
	var help: String = preload("res://ui/concise_copy.gd").tactical_rules(app.CURRENT_CHAPTER-4)
	check(help.contains("PP al equipar") and help.contains("Rectificar") and help.contains("Perder un combate"),"Shortened help retains game-specific restrictions")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.CURRENT_CHAPTER-4,"profileSchema":2,"scope":"Native keyboard/mouse; isolated cosmetic fixtures; profile persistence and preview purity; 1024x720/1280x900, 100/150%, both contrast modes. No natural campaign completion claimed."}
	FileAccess.open(directory.path_join("profile-polish.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("QA profile "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
