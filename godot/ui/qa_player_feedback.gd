extends "res://ui/qa_context.gd"

const Ledger = preload("res://core/relief_store.gd")

func layout(app: Control) -> void:
	for frame: int in 5: await app.get_tree().process_frame

func geometry(node: Node, lines: Array[String]) -> void:
	if node is Control: lines.append(str(node.get_path())+" "+str(node.get_rect())+" minimum="+str(node.get_combined_minimum_size()))
	for child: Node in node.get_children(): geometry(child,lines)

func run(app: Control, directory: String) -> void:
	app.get_window().gui_embed_subwindows = true
	app.store = Ledger.new(directory.path_join("feedback-natural-%d.json"%Time.get_ticks_usec()))
	await click(app,app.title_screen.controls.feedback)
	await layout(app)
	var form: AcceptDialog = app.player_feedback
	check(form.visible and app.title_visible,"Title feedback opens without a campaign")
	check(form.gui_get_focus_owner()==form.subject,"Title field receives keyboard focus")
	check(form.controls.copy.disabled and form.controls.save.disabled and form.controls.email.disabled,"Empty report cannot be shared")
	check(not form.report().contains("@"),"Report never includes recipient address")
	form.subject.text = "   "; form.description.text = "Texto"; form.refresh()
	check(form.controls.copy.disabled,"Whitespace title is invalid")
	form.subject.text = "Error al elegir"; form.refresh()
	await key(app,KEY_ESCAPE,form)
	check(not form.visible and app.title_visible,"Escape returns to title")
	check(app.get_viewport().gui_get_focus_owner()==app.title_screen.controls.feedback,"Title feedback focus is restored")
	await click(app,app.title_screen.controls.new)
	app.journey_seed.text = "feedback-regression"
	await click(app,app.travel_buttons.starter1)
	await click(app,app.travel_buttons.enter)
	await click(app,app.adventure.start_button)
	var original: Dictionary = app.run.duplicate(true)
	var journal: Array = app.transactions.duplicate(true)
	var save_before: String = FileAccess.get_file_as_string(app.store.file_path)
	for dimensions: Vector2i in [Vector2i(1280,900),Vector2i(1024,720)]:
		app.get_window().size = dimensions
		app.input_profile.set_preference("textScale",150 if dimensions.x==1024 else 100)
		app._apply_preferences()
		app.board.grab_focus()
		app._menu_selected(17); await layout(app)
		check(form.visible and app._modal_open(),"Game menu opens modal feedback")
		check(form.subject.text=="Error al elegir","Closing preserves the draft")
		check(form.size.x<=dimensions.x and form.size.y<=dimensions.y,"Feedback fits viewport")
		check(form.get_ok_button().get_global_rect().end.y<=form.size.y,"Return control stays visible")
		for button: Button in form.controls.values():
			check(button.size.x>=200 and button.size.y<160,"Report actions have legible button dimensions")
		await capture(app,directory,"feedback-form-%d"%dimensions.x)
		form.subject.grab_focus(); form.subject.text = ""
		await key(app,KEY_A,form); await key(app,KEY_R,form); await key(app,KEY_F,form)
		check(form.subject.text=="arf","Gameplay shortcuts type text in feedback")
		await key(app,KEY_TAB,form)
		check(form.gui_get_focus_owner()==form.description,"Tab reaches description")
		form.subject.text = "Precisión & sueño? #1 ñ"
		form.description.text = "1. Abrir Movimientos\n2. Elegir técnica\nEsperaba: volver. Ocurre: nada. + = & # ¿á?"
		form.refresh()
		check(form.preview.text==form.report(),"Preview equals shared report")
		check(form.report().contains("Semilla: feedback-regression"),"Campaign context includes seed")
		check(form.report().contains("Lugar:") and form.report().contains("Versión:"),"Campaign context and version are present")
		var uri: String = form.email_uri()
		check(uri.begins_with("mailto:") and uri.length()<=1800,"Mail URI has bounded length")
		check(uri.get_slice("?",0)=="mailto:"+form.CONTACT.uri_decode(),"Mail destination is correctly decoded outside the game UI")
		check(uri.get_slice("&body=",1).uri_decode()==form.report(),"Mail body roundtrips Unicode and reserved characters")
		check(uri.get_slice("?subject=",1).get_slice("&body=",0).uri_decode().ends_with(form.subject.text),"Subject encoding preserves special characters")
		await click(app,form.controls.copy)
		var copied: String = DisplayServer.clipboard_get().replace("\r\n","\n")
		FileAccess.open(directory.path_join("clipboard-%d.txt"%dimensions.x),FileAccess.WRITE).store_string(copied)
		check(copied==form.report(),"Copy button copies complete report")
		var boxes: Array[String] = []; geometry(form,boxes)
		FileAccess.open(directory.path_join("geometry-%d.txt"%dimensions.x),FileAccess.WRITE).store_string("\n".join(boxes))
		await capture(app,directory,"feedback-%d"%dimensions.x)
		await click(app,form.controls.save); await layout(app)
		check(form.save_dialog.visible and form.save_dialog.get_parent()==form,"Save dialog belongs to feedback window")
		await key(app,KEY_ESCAPE,form.save_dialog); await layout(app)
		check(not form.save_dialog.visible and form.visible,"Escape cancels only file picker")
		check(form.gui_get_focus_owner()==form.controls.save,"Save cancellation restores focus")
		var path: String = directory.path_join("player-report-%d.txt"%dimensions.x)
		form.save_dialog.file_selected.emit(path)
		check(FileAccess.get_file_as_string(path)==form.report(),"UTF-8 saved report equals preview")
		form.include_context.button_pressed = false; form.refresh()
		check(not form.report().contains("Semilla:") and not form.report().contains("Lugar:"),"Context can be excluded")
		form.category.select(1); form.refresh()
		check(form.report().contains("Sugerencia"),"Suggestions are distinguished from bugs")
		form.description.text = "Mejora & información: ".repeat(400); form.refresh()
		uri = form.email_uri()
		check(uri.length()<=1800 and uri.get_slice("&body=",1).uri_decode().contains("portapapeles"),"Long emails use clipboard fallback")
		form.subject.text = "😀".repeat(120)
		check(form.email_uri().length()<=1800,"Long Unicode subject still fits mail URI")
		form.copy_report()
		check(DisplayServer.clipboard_get().replace("\r\n","\n")==form.report(),"Long report remains complete on clipboard")
		form.save_report(directory.path_join("missing-folder/report.txt"))
		check(form.status.text.contains("No se pudo guardar"),"Save failure leaves a usable copy fallback")
		form.category.select(0)
		form.include_context.button_pressed = true
		form.subject.text = "Error al elegir"; form.description.text = "Descripción de prueba"; form.refresh()
		await key(app,KEY_ESCAPE,form); await layout(app)
		check(not form.visible and not app._modal_open(),"Escape returns to battle")
		check(app.get_viewport().gui_get_focus_owner()==app.board,"Battle focus restored")
		check(Ledger.equivalent(original,app.run) and app.transactions==journal,"Feedback preserves battle, RNG and journal")
		check(FileAccess.get_file_as_string(app.store.file_path)==save_before,"Feedback does not save campaign")
	var result: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"campaignEdition":app.run.edition,"stateHash":JSON.stringify(app.run,"",true,true).sha256_text(),"scope":"Automated same-PC source/EXE feedback UI: title and natural battle, keyboard/mouse/Escape/focus,1280/100% and1024/150%, Unicode URI and long fallback, clipboard and UTF-8 save. No email client launched, no email sent, no external hardware."}
	FileAccess.open(directory.path_join("player-feedback.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("QA player-feedback "+JSON.stringify({"assertions":assertions,"failures":failures})); app.get_tree().quit(0 if failures.is_empty() else 1)
