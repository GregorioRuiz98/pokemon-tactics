extends RefCounted

const Store = preload("res://core/kanto_store.gd")
const Driver = preload("res://ui/qa_driver.gd")
var driver: RefCounted = Driver.new()
var healing: RefCounted = preload("res://ui/qa_campaign.gd").new()
var failures: Array[String] = []
var assertions: int = 0
var screenshots: Array[String] = []

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value: failures.append(message)

func capture(app: Control, directory: String, filename: String) -> void:
	await app.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = app.get_viewport().get_texture().get_image()
	check(not image.is_empty() and image.save_png(directory.path_join(filename+".png"))==OK,"Rendered "+filename)
	screenshots.append(filename+".png")

func run(app: Control, directory: String) -> void:
	var completed: Array = []
	for width: int in [16,24]:
		app._show_oak()
		app.journey_seed.text = "tactics-1"
		app.travel_buttons.starter1.pressed.emit()
		check(app.run.edition==11,"New campaign uses edition11")
		if width==24: app.travel_buttons.size_24.pressed.emit()
		check(app.run.mapSize==width,"Map size selected through UI")
		app.travel_buttons.enter.pressed.emit()
		check(app.state.board.size()==width and app.board.isometric(),"Real encounter uses selected isometric map")
		var before: Dictionary = app.run.duplicate(true)
		await capture(app,directory,"combat-%d" % width)
		for unit: Dictionary in app.state.units:
			check(app.board.play_area().grow(-20).has_point(app.board.center(unit)),"Default combat framing includes all units")
			check_sprite(app,unit)
		app.board.fit_map()
		await capture(app,directory,"map-%d" % width)
		var wheel: InputEventMouseButton = InputEventMouseButton.new()
		wheel.pressed = true
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.position = app.board.play_area().get_center()
		var zoom: float = app.board.zoom
		app.board._gui_input(wheel)
		check(app.board.zoom>zoom,"Wheel zoom works")
		app.camera_bar.get_child(1).pressed.emit()
		app.camera_bar.get_child(4).pressed.emit()
		app.camera_bar.get_child(2).pressed.emit()
		check(not app.board.manual_camera,"Combat framing restores edge-only automatic tracking")
		app.camera_bar.get_child(5).pressed.emit()
		check(app.board.strong_grid,"Grid guide can be enabled")
		app.camera_bar.get_child(5).pressed.emit()
		app.camera_bar.get_child(6).pressed.emit()
		check(app.board.show_heights,"Height guide can be enabled")
		await capture(app,directory,"height-guide-%d" % width)
		app.camera_bar.get_child(6).pressed.emit()
		check(Store.equivalent(app.run,before),"Camera buttons and wheel preserve journal and RNG")
		var rectified: bool = false
		for i: int in 1000:
			if app.run.phase in ["complete","defeat"]: break
			if app.run.phase=="capture":
				app.travel_buttons.capture.pressed.emit()
				continue
			if app.run.phase=="shop":
				healing.heal(app)
				app.travel_buttons["continue"].pressed.emit()
				continue
			if app.run.phase=="map":
				app.travel_buttons.enter.pressed.emit()
				check(app.combat_feedback.marks.is_empty(),"Old encounter feedback cleared on entry")
				await capture(app,directory,"natural-%d-%d" % [width,app.run.stage])
				continue
			var command: Dictionary = app.rules.choose_command(app.state)
			var expected: Dictionary = app.rules.apply_command(app.state,command)
			check(expected.ok,"AI emits legal order in UI")
			if app.rules.active(app.state).team=="enemy": app._commit(command)
			elif command.kind=="move":
				var origin: Dictionary = app.state.duplicate(true)
				app.board.focus_point(command.destination)
				driver.click(app,command.destination)
				if not origin.acted and not rectified:
					app.buttons.undo.pressed.emit()
					check(Store.equivalent(app.state,origin),"Isometric click then movement-only rectify")
					app.board.focus_point(command.destination)
					driver.click(app,command.destination)
					rectified = true
			elif command.kind=="attack":
				driver.choose_action(app,command.actionId)
				var target: Dictionary = app.rules.unit_by_id(app.state,int(command.target))
				app.board.focus_point(target)
				driver.hover(app,target)
				if not screenshots.has("attack-preview.png"): await capture(app,directory,"attack-preview")
				driver.click(app,target)
				if not app.pending.is_empty(): app.buttons.confirm.pressed.emit()
			else:
				app.buttons.finish.pressed.emit()
				app.direction_buttons[int(command.facing)].pressed.emit()
			check(Store.equivalent(app.state,expected.state),"UI result matches height-aware resolver")
		check(app.run.phase=="complete" and app.run.cleared.size()==4,"Four encounters complete through real controls")
		check(rectified,"Movement undo exercised")
		var snapshot: Dictionary = app.run.duplicate(true)
		app._load_game()
		check(Store.equivalent(app.run,snapshot),"Natural run reloads exactly")
		completed.append({"size":width,"phase":app.run.phase,"cleared":app.run.cleared.size(),"transactions":app.transactions.size()})
	# Explicit layout fixtures, separate from the saved natural journeys above.
	for width: int in [16,24]:
		for biome: int in [1,2,3]:
			app.campaign = load("res://core/scale_run.gd").new()
			app.rules = app.campaign.engine
			app.run = app.campaign.create("layout-15",1)
			app.run.stage = biome
			app.run.mapSize = width
			app.run.phase = "battle"
			app.run.battle = app.rules.encounter(app.run,app.campaign.locations[biome])
			app.state = app.run.battle
			app._refresh()
			app.board.fit_map()
			await capture(app,directory,"layout-%d-%d" % [width,biome])
	for dimensions: Vector2i in [Vector2i(1024,720),Vector2i(1440,1000),Vector2i(1280,900)]:
		DisplayServer.window_set_size(dimensions)
		await app.get_tree().process_frame
		await app.get_tree().process_frame
		app.board.fit_map()
		await capture(app,directory,"viewport-%d" % dimensions.x)
		check(app.board.play_area().size.x>0 and app.board.play_area().size.y>0,"Positive tactical viewport")
		check(app.camera_bar.get_global_rect().end.x<app.size.x,"Camera controls fit window")
		check(app.command_panel.get_global_rect().position.x>=app.board.play_area().end.x,"HUD does not cover selectable tiles")
		app.board.frame_combat()
		await capture(app,directory,"combat-viewport-%d" % dimensions.x)
	var report: Dictionary = {"assertions":assertions,"failures":failures,"completed":completed,"screenshots":screenshots,"layoutFixtures":true}
	FileAccess.open(directory.path_join("scale-ui-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report))
	app.get_tree().quit(0 if failures.is_empty() else 1)

func check_sprite(app: Control, unit: Dictionary) -> void:
	var visual: Dictionary = app.board.sprite_visual(unit)
	check(absf(visual.used.end.y-app.board.center(unit).y)<app.board.cell_size()*0.12,"Sprite feet stay on the occupied square")
	var pixels: Image = app.board.sprite_images[int(unit.speciesId)]
	var frame: Rect2i = Rect2i(visual.source)
	for y: int in frame.size.y:
		for x: int in frame.size.x:
			if pixels.get_pixel(frame.position.x+x,frame.position.y+y).a<=0.5: continue
			var point: Vector2 = visual.rect.position+Vector2(x+0.5,y+0.5)*visual.factor
			check(app.board.pick(point)=={"x":unit.x,"y":unit.y},"Clicking the visible sprite selects its own square")
			return
	check(false,"Sprite contains visible pixels")
