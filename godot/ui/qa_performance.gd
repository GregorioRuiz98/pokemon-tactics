extends "res://ui/qa_context.gd"

var measurements: Dictionary = {}

func measure(label: String, iterations: int, operation: Callable) -> void:
	print("PERFORMANCE starting "+label)
	var samples: Array[float] = []
	for index: int in iterations:
		var started: int = Time.get_ticks_usec()
		operation.call()
		samples.append((Time.get_ticks_usec()-started)/1000.0)
	samples.sort()
	measurements[label] = {"iterations":iterations,"medianMs":samples[int(iterations*0.5)],"p95Ms":samples[mini(iterations-1,int(iterations*0.95))],"totalMs":samples.reduce(func(total,value):return total+value,0.0)}
	print("PERFORMANCE "+label+" "+JSON.stringify(measurements[label]))

func run(app: Control, directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("performance-controls-%d.json" % Time.get_ticks_usec()))
	app.board.input_profile = app.input_profile
	app.controls_dialog.profile = app.input_profile
	await fixture(app,directory,"tackle",24)
	var before: Dictionary = app.run.duplicate(true)
	measure("preferences",30,app._apply_preferences)
	measure("hover-same-cell",100,func():app._hover_tile({"x":6,"y":8}))
	measure("semantic-off",100,app.accessible_view.update)
	app.input_profile.set_preference("accessibleMode",true)
	measure("semantic-on",30,app.accessible_view.update)
	app.input_profile.set_preference("accessibleMode",false)
	measure("ai-plan",3,func():app.rules.choose_command(app.state))
	measure("refresh",30,app._refresh)
	check(Store.equivalent(before,app.run) and app.transactions.is_empty(),"Performance workload preserves full state, journal and RNG")
	if "--performance-baseline" in OS.get_cmdline_user_args() or "--performance-cpu-only" in OS.get_cmdline_user_args():
		write_result(app,directory)
		return
	await settle(app)
	var theme_changes: Array[int] = [0]
	var on_theme_change: Callable = func():theme_changes[0] += 1
	app.theme.changed.connect(on_theme_change)
	for index: int in 20: app._apply_preferences()
	app.theme.changed.disconnect(on_theme_change)
	check(theme_changes[0]==0,"Unchanged preferences never invalidate the shared theme")
	app._refresh()
	var evaluated: int = 0
	for index: int in 100:
		if app._hover_tile({"x":6,"y":8}): evaluated += 1
	check(evaluated==1,"One hundred pointer events on the same cell evaluate one forecast")
	check(app.board.cursor==Vector2i(6,8),"Pointer preview synchronizes the logical cursor")
	app._refresh()
	check(app._hover_tile({"x":6,"y":8}),"A state refresh invalidates the hover preview")
	check(app._hover_tile({"x":7,"y":8}),"Changing cell invalidates the hover preview")
	app.input_profile.set_preference("accessibleMode",true)
	app._apply_preferences()
	await settle(app)
	check(app.board.accessibility_name.contains("PT"),"Coalesced semantics describe the current hovered unit")
	var announcement_count: int = app.accessible_view.message_count
	for index: int in 100: app.accessible_view.request_update()
	await settle(app)
	check(app.accessible_view.message_count==announcement_count,"Stable cursor burst creates no repeated announcement")
	app.input_profile.set_preference("accessibleMode",false)
	app._apply_preferences()
	app.board.reduced_motion = true
	var animation_clock: float = app.board.elapsed
	app.board._process(1)
	check(app.board.elapsed==animation_clock,"Reduced motion performs no idle animation work")
	app.board.reduced_motion = false
	app.board.hide()
	app.board._process(1)
	check(app.board.elapsed==animation_clock,"Hidden board performs no idle animation work")
	app.board.show()
	app.board._process(0.1)
	check(app.board.elapsed>animation_clock,"Visible board resumes sprite animation")
	check(Store.equivalent(before,app.run) and app.transactions.is_empty(),"UI optimizations preserve complete state and RNG")
	await settle(app)
	var rebuilds: int = app.board.terrain_rebuilds
	var tiles_drawn: int = app.board.tile_redraws
	var frame_times: Array[float] = []
	var draw_samples: Array[float] = []
	app.board.set_meta("draw_samples",draw_samples)
	for index: int in 120:
		var started: int = Time.get_ticks_usec()
		await app.get_tree().process_frame
		frame_times.append((Time.get_ticks_usec()-started)/1000.0)
	frame_times.sort()
	draw_samples.sort()
	if not draw_samples.is_empty(): measurements.draw = {"count":draw_samples.size(),"medianMs":draw_samples[int(draw_samples.size()*0.5)],"p95Ms":draw_samples[mini(draw_samples.size()-1,int(draw_samples.size()*0.95))]}
	app.board.remove_meta("draw_samples")
	measurements.idleFrames = {"count":frame_times.size(),"medianMs":frame_times[60],"p95Ms":frame_times[114],"note":"24x24 synthetic fixture; wall-clock frame intervals include pacing and are not a hardware-independent FPS guarantee."}
	check(app.board.terrain_rebuilds==rebuilds and app.board.tile_redraws==tiles_drawn,"Sprite animation reuses terrain and minimap drawing commands")
	app._hover_tile({"x":8,"y":8})
	await settle(app)
	check(app.board.tile_redraws>tiles_drawn and app.board.terrain_rebuilds==rebuilds,"Cursor changes redraw tile marks without rebuilding terrain")
	app.board.change_zoom(1.12)
	await settle(app)
	check(app.board.terrain_rebuilds>rebuilds,"Camera zoom invalidates terrain geometry")
	app.board.change_zoom(1/1.12)
	var area: Rect2 = app.board.play_area()
	app.input_profile.set_preference("textScale",150)
	app._apply_preferences()
	await settle(app)
	check(app.board.play_area()!=area,"Text scale changes the reserved HUD area")
	app.input_profile.set_preference("textScale",100)
	app._apply_preferences()
	await settle(app)
	check(Store.equivalent(before,app.run) and app.transactions.is_empty(),"Camera, cached rendering and text scaling preserve state and RNG")
	await capture(app,directory,"performance-24")
	write_result(app,directory)

func write_result(app: Control, directory: String) -> void:
	var report: Dictionary = {"assertions":assertions,"failures":failures,"measurements":measurements,"engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),"screenshots":screenshots}
	var file: FileAccess = FileAccess.open(directory.path_join("performance-result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("QA performance "+JSON.stringify(report))
	app.get_tree().quit(0 if failures.is_empty() else 1)
