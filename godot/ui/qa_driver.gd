extends RefCounted

# In-process UI regression driver, invoked only by --qa-dir. Uses the same
# controls and confirmation signals as the player; never patches battle state.
const Rules = preload("res://core/battle.gd")
const Store = preload("res://core/save_store.gd")
var failures: Array[String] = []
var assertions = 0
var captures: Array[String] = []

func check(value: bool, message: String):
	assertions += 1
	if not value: failures.append(message)

func capture(app, directory: String, name: String):
	await app.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image = app.get_viewport().get_texture().get_image()
	check(not image.is_empty(), "Rendered viewport: " + name)
	if not image.is_empty():
		var result = image.save_png(directory.path_join(name + ".png"))
		check(result == OK, "Screenshot written: " + name)
		captures.append(name + ".png")

func run(app, directory: String):
	print("QA data directory: " + OS.get_user_data_dir())
	app.new_dialog.popup_centered()
	await capture(app, directory, "01-new-game")
	var completions = []
	var captured = {}
	var player_orders = 0
	for mode in ["current", "classic"]:
		for composition in ["starters", "mixed"]:
			app.seed_input.text = "godot-13"
			app.mode_input.select(0 if mode == "current" else 1)
			app.composition_input.select(0 if composition == "starters" else 1)
			app.variance_input.select(0)
			app.new_dialog.confirmed.emit()
			app.new_dialog.hide()
			check(app.state.outcome == "playing", "New battle starts")
			check(app.save_warning.is_empty(), "Initial state saved")
			for step in 240:
				if app.state.outcome != "playing": break
				var command = app.rules.choose_command(app.state)
				var before = app.state.duplicate(true)
				var expected = app.rules.apply_command(app.state, command)
				if Rules.active(app.state).team == "enemy":
					app._commit(command)
				else:
					player_orders += 1
					if command.kind == "move":
						app.buttons.move.pressed.emit()
						check(app.board.available.values().all(func(route): return route.cost > 0 and route.cost <= Rules.active(app.state).remaining), "Highlighted movement stays inside budget")
						app.board.tile_selected.emit(command.destination)
					elif command.kind == "attack":
						app.action_buttons[command.get("actionId", "basic")].pressed.emit()
						app.board.tile_selected.emit(Rules.unit_by_id(app.state, int(command.target)))
					else:
						app.buttons.finish.pressed.emit()
						app.direction_buttons[int(command.facing)].pressed.emit()
					check(Store.equivalent(app.pending, command), "GUI selects expected command")
					check(Store.equivalent(app.state, before), "Preview leaves state and RNG untouched")
					if not captured.has(command.kind):
						await capture(app, directory, "02-preview-" + command.kind)
						if command.kind == "attack":
							DisplayServer.window_set_size(Vector2i(1024, 720))
							await app.get_tree().process_frame
							await app.get_tree().process_frame
							await capture(app, directory, "02-preview-attack-small")
							_bounds(app, app, app.get_global_rect().grow(2))
							DisplayServer.window_set_size(Vector2i(1280, 900))
							await app.get_tree().process_frame
							await app.get_tree().process_frame
						captured[command.kind] = true
						var pending = app.pending.duplicate(true)
						app.buttons.cancel.pressed.emit()
						check(app.pending.is_empty(), "Cancellation clears preview")
						check(Store.equivalent(app.state, before), "Cancellation consumes no resources")
						# Re-select through the same controls after cancelling.
						if command.kind == "move":
							app.buttons.move.pressed.emit()
							app.board.tile_selected.emit(command.destination)
						elif command.kind == "attack":
							app.action_buttons[command.actionId].pressed.emit()
							app.board.tile_selected.emit(Rules.unit_by_id(app.state, int(command.target)))
						else:
							app.buttons.finish.pressed.emit()
							app.direction_buttons[int(command.facing)].pressed.emit()
						check(Store.equivalent(app.pending, pending), "Preview re-selected")
					app.buttons.confirm.pressed.emit()
				check(Store.equivalent(app.state, expected.state), "GUI commits the shared rule result")
				check(app.save_warning.is_empty(), "Accepted command saved before presentation")
				if step == 10:
					var saved = app.state.duplicate(true)
					app.buttons.load.pressed.emit()
					check(Store.equivalent(app.state, saved), "Continue restores exact state")
					if not app.save_warning.is_empty():
						var envelope = JSON.parse_string(FileAccess.get_file_as_string(app.store.file_path))
						var payload = JSON.parse_string(envelope.payload)
						var replay = app.rules.create(payload.seed, payload.variance, payload.composition, payload.mode)
						for entry in payload.commands: replay = app.rules.apply_command(replay, entry).state
						print("Save diagnostic: " + _difference(replay, payload.state, "state"))
					check(app.save_warning.is_empty(), "Continue validates native journal (%s/%s): %s" % [mode, composition, app.save_warning])
				await app.get_tree().process_frame
			check(app.state.outcome != "playing", "UI campaign ends within command budget")
			completions.append({"mode": mode, "composition": composition, "outcome": app.state.outcome, "round": app.state.round, "commands": app.history.size()})
	await capture(app, directory, "03-result")
	var unchanged = app.state.duplicate(true)
	app.buttons.sound.pressed.emit()
	app.buttons.motion.pressed.emit()
	check(Store.equivalent(app.state, unchanged), "Audio/motion settings do not change RNG")
	app.new_dialog.confirmed.emit()
	var pointer_before = app.state.duplicate(true)
	# A genuine keyboard event reaches the focused board/Control input path.
	var event = InputEventKey.new()
	event.keycode = KEY_RIGHT
	event.pressed = true
	app.board.grab_focus()
	var old_cursor = app.board.cursor
	Input.parse_input_event(event)
	await app.get_tree().process_frame
	check(app.board.cursor.x == mini(7, old_cursor.x + 1), "Keyboard navigates board")
	check(Store.equivalent(app.state, pointer_before), "Keyboard inspection does not consume RNG")
	DisplayServer.window_set_size(Vector2i(1024, 720))
	await app.get_tree().process_frame
	await app.get_tree().process_frame
	await capture(app, directory, "04-1024x720")
	_bounds(app, app, app.get_global_rect().grow(2))
	DisplayServer.window_set_size(Vector2i(1440, 1000))
	await app.get_tree().process_frame
	await app.get_tree().process_frame
	await capture(app, directory, "05-1440x1000")
	_bounds(app, app, app.get_global_rect().grow(2))
	app.credits_dialog.popup_centered(Vector2i(720, 550))
	check(app.credits_dialog.visible, "Credits dialog opens")
	await capture(app, directory, "06-credits")
	app.credits_dialog.hide()
	var native_path = "user://qa-isolated-%d.json" % Time.get_ticks_usec()
	var native_store = Store.new(native_path)
	var native_saved = native_store.save(app.state, app.history, app.mode)
	check(native_saved.ok, "Default user directory accepts native saves")
	if native_saved.ok:
		var native_loaded = native_store.load_game(app.rules)
		check(native_loaded.ok and Store.equivalent(native_loaded.get("state", {}), app.state), "Default user directory resumes exact state")
		check(DirAccess.remove_absolute(ProjectSettings.globalize_path(native_path)) == OK, "Isolated native user test cleaned up")
	var output = {"engine": Engine.get_version_info().string, "assertions": assertions, "playerOrders": player_orders, "completed": completions, "screenshots": captures, "failures": failures}
	var file = FileAccess.open(directory.path_join("ui-result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "  "))
	file.close()
	print(JSON.stringify(output))
	app.get_tree().quit(0 if failures.is_empty() else 1)

func _bounds(node: Node, app, viewport: Rect2):
	if node is Window: return
	if node is Control and node.is_visible_in_tree() and node.get_window() == app.get_window():
		check(viewport.encloses(node.get_global_rect()), "Control fits window: " + str(node.get_path()))
	if node is ScrollContainer: return # Intentional clipped content can extend beyond its viewport.
	for child in node.get_children(): _bounds(child, app, viewport)

func _difference(a, b, context: String) -> String:
	if Store.equivalent(a, b): return ""
	if a is Dictionary and b is Dictionary:
		for field in a:
			if not b.has(field): return context + ".missing." + str(field)
			var result = _difference(a[field], b[field], context + "." + str(field))
			if not result.is_empty(): return result
	if a is Array and b is Array and a.size() == b.size():
		for index in a.size():
			var result = _difference(a[index], b[index], context + "[%d]" % index)
			if not result.is_empty(): return result
	return context + ": " + JSON.stringify(a, "", true, true) + " vs " + JSON.stringify(b, "", true, true)
