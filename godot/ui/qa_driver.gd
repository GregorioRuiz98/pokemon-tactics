extends RefCounted

# Native controls and board-local input events; no battle state patching.
const Rules = preload("res://core/battle.gd")
const Store = preload("res://core/save_store.gd")
var failures: Array[String] = []
var assertions = 0
var captures: Array[String] = []
var risk_checked = false
var risk_setup: Dictionary = {}
var undo_checks: int = 0
var blocked_undo_checks: int = 0

func check(value: bool, message: String):
	assertions += 1
	if not value: failures.append(message)

func hover(app, point: Dictionary):
	var event = InputEventMouseMotion.new()
	event.position = app.board.center(point)
	app.board._gui_input(event)

func click(app, point: Dictionary, button: int = MOUSE_BUTTON_LEFT):
	var event = InputEventMouseButton.new()
	event.position = app.board.center(point)
	event.pressed = true
	event.button_index = button
	app.board._gui_input(event)
	if button==MOUSE_BUTTON_LEFT:
		var release: InputEventMouseButton = event.duplicate()
		release.pressed = false
		app.board._gui_input(release)

func choose_action(app: Control, identity: String) -> void:
	app.buttons.actions.pressed.emit()
	check(app.actions.is_visible_in_tree(), "Ability submenu opens inside scene")
	check(app.action_buttons[identity].is_visible_in_tree(), "Ability is reachable through visible menu")
	app.action_buttons[identity].pressed.emit()

func capture(app, directory: String, name: String):
	await app.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image = app.get_viewport().get_texture().get_image()
	check(not image.is_empty(), "Rendered viewport: " + name)
	if not image.is_empty():
		check(image.save_png(directory.path_join(name + ".png")) == OK, "Screenshot written: " + name)
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
			app.new_dialog.hide()
			app.new_dialog.confirmed.emit()
			check(app.state.outcome == "playing" and app.save_warning.is_empty(), "New battle saved")
			for step in 240:
				if app.state.outcome != "playing": break
				var command = app.rules.choose_command(app.state)
				var before = app.state.duplicate(true)
				var expected = app.rules.apply_command(app.state, command)
				if Rules.active(app.state).team == "enemy":
					app._commit(command)
				else:
					await _check_risk(app, directory)
					player_orders += 1
					if command.kind == "move":
						check(app.board.available.values().all(func(route): return route.cost > 0 and route.cost <= Rules.active(app.state).remaining), "Reachable tiles inside budget")
						hover(app, command.destination)
						check(not app.board.route.is_empty(), "Hover previews path without move mode")
						check(Store.equivalent(app.state, before), "Hover leaves state and RNG untouched")
						if not captured.has("move"):
							await capture(app, directory, "02-hover-move")
							captured.move = true
						click(app, command.destination)
					elif command.kind == "attack":
						var definition = app.rules.profile(Rules.active(app.state)).action(Rules.active(app.state), command.actionId).definition
						if definition.target != "self":
							if command.actionId != "basic":
								if not captured.has("skills"):
									app.buttons.actions.pressed.emit()
									await capture(app, directory, "02-skills")
									_bounds(app, app, app.get_global_rect().grow(2))
									app._cancel()
									captured.skills = true
								choose_action(app, command.actionId)
							var target = Rules.unit_by_id(app.state, int(command.target))
							hover(app, target)
							check(not app.board.forecast_hits.is_empty(), "Hover previews attack on board")
							check(Store.equivalent(app.state, before), "Attack forecast consumes no RNG")
							if not captured.has("attack"):
								await capture(app, directory, "02-hover-attack")
								DisplayServer.window_set_size(Vector2i(1024, 720))
								await app.get_tree().process_frame
								await app.get_tree().process_frame
								await capture(app, directory, "02-hover-attack-small")
								_bounds(app, app, app.get_global_rect().grow(2))
								DisplayServer.window_set_size(Vector2i(1280, 900))
								await app.get_tree().process_frame
								await app.get_tree().process_frame
								captured.attack = true
							click(app, target)
						else:
							choose_action(app, command.actionId)
							check(Store.equivalent(app.state,before),"Own ability selection only previews")
							click(app,Rules.active(app.state))
						if not app.pending.is_empty():
							check(Store.equivalent(app.state, before), "Friendly fire awaits confirmation")
							app.buttons.confirm.pressed.emit()
					else:
						if not captured.has("finish"):
							if app.selecting != "finish": app.buttons.finish.pressed.emit()
							hover(app, {"x": 0, "y": 0})
							check(Store.equivalent(app.state, before), "Facing preview consumes no RNG")
							await capture(app, directory, "02-orientation")
							click(app, {"x": 0, "y": 0}, MOUSE_BUTTON_RIGHT)
							check(Store.equivalent(app.state, before) and app.selecting == "auto", "Right click cancels facing choice")
							captured.finish = true
						if app.selecting != "finish": app.buttons.finish.pressed.emit()
						check(app.directions.is_visible_in_tree(), "Facing controls are visible")
						app.direction_buttons[int(command.facing)].pressed.emit()
					if command.kind == "move" and not before.acted:
						check(app._can_rectify() and not app.buttons.undo.disabled, "Only unused action permits movement revision")
						if undo_checks == 0: await capture(app, directory, "02-can-rectify")
						app._menu_selected(1)
						check(app._can_rectify(), "Continue reconstructs movement revision eligibility")
						app.buttons.undo.pressed.emit()
						check(Store.equivalent(app.state, before), "Revision restores only the last movement state, with exact RNG/resources")
						check(app.save_warning.is_empty(), "Movement revision saved")
						app._menu_selected(1)
						check(Store.equivalent(app.state, before) and not app._can_rectify(), "Revised journal reloads and cannot undo further")
						if undo_checks == 0:
							await capture(app, directory, "02-rectified")
						undo_checks += 1
						click(app, command.destination)
					else:
						var locked = app.state.duplicate(true)
						app._rectify_movement()
						check(Store.equivalent(app.state, locked), "Attack/finish cannot be rewound")
						blocked_undo_checks += 1
					check(app.command_panel.visible == app._player_turn(), "Command menu follows allied activation")
					check(app.pending.is_empty(), "Direct order clears pending state")
				check(Store.equivalent(app.state, expected.state), "GUI commits exact shared rule result")
				check(app.save_warning.is_empty(), "Accepted command saved before presentation")
				if step == 10:
					var saved = app.state.duplicate(true)
					app._menu_selected(1)
					check(Store.equivalent(app.state, saved) and app.save_warning.is_empty(), "Menu Continue restores exact state")
				await app.get_tree().process_frame
			check(app.state.outcome != "playing", "Battle ends within budget")
			completions.append({"mode": mode, "composition": composition, "outcome": app.state.outcome, "round": app.state.round, "commands": app.history.size()})
	await capture(app, directory, "03-result")
	check(undo_checks > 0 and blocked_undo_checks > 0, "Movement-only undo covers allowed and locked cases")
	check(risk_checked, "Friendly-fire confirmation exercised with reachable state")
	# Rebuild the reachable risk position using its legal command journal, then
	# exercise acceptance separately so the four reference games stay comparable.
	if not risk_setup.is_empty():
		app.mode_input.select(0 if risk_setup.mode == "current" else 1)
		app.composition_input.select(0 if risk_setup.composition == "starters" else 1)
		app.new_dialog.confirmed.emit()
		for order in risk_setup.commands: app._commit(order)
		var before_risk = app.state.duplicate(true)
		var risk_result = app.rules.apply_command(app.state, risk_setup.order)
		choose_action(app, risk_setup.order.actionId)
		click(app, Rules.unit_by_id(app.state, int(risk_setup.order.target)))
		app.buttons.confirm.pressed.emit()
		check(Store.equivalent(app.state, risk_result.state), "Confirmed friendly fire executes shared result")
		check(app.history.size() == risk_setup.commands.size() + 1 and not Store.equivalent(app.state, before_risk), "Confirmation records exactly one order")
		app._menu_selected(1)
		check(Store.equivalent(app.state, risk_result.state) and app.save_warning.is_empty(), "Confirmed friendly fire reloads exactly")
	var unchanged = app.state.duplicate(true)
	app._menu_selected(4)
	app._menu_selected(5)
	check(Store.equivalent(app.state, unchanged), "Audio/motion settings leave RNG untouched")
	app._menu_selected(3)
	check(app.details_dialog.visible and not app.details_text.text.is_empty(), "Team and journal accessible in menu")
	app.details_dialog.hide()
	app.mode_input.select(1)
	app.composition_input.select(1)
	app.new_dialog.confirmed.emit()
	var pointer_before = app.state.duplicate(true)
	var event = InputEventKey.new()
	event.keycode = KEY_RIGHT
	event.pressed = true
	app.board.grab_focus()
	var old_cursor = app.board.cursor
	Input.parse_input_event(event)
	await app.get_tree().process_frame
	check(app.board.cursor.x == mini(7, old_cursor.x + 1), "Real keyboard input navigates board")
	check(Store.equivalent(app.state, pointer_before), "Keyboard hover preserves RNG")
	event.keycode = KEY_F1
	Input.parse_input_event(event)
	await app.get_tree().process_frame
	check(app.menu.get_popup().visible, "F1 opens native game menu")
	app.menu.get_popup().hide()
	app.help_dialog.popup_centered()
	var history_before = app.history.size()
	app._select_tile({"x": 1, "y": 5})
	app._set_facing(0)
	check(app.history.size() == history_before, "Modal blocks board orders")
	app.help_dialog.hide()
	# A genuine viewport mouse event exercises Godot's hit testing at native size.
	DisplayServer.window_set_size(Vector2i(1280, 900))
	await app.get_tree().process_frame
	await app.get_tree().process_frame
	var route = app.board.available.values()[0]
	var destination = route.path[-1]
	var move_result = app.rules.apply_command(app.state, {"kind": "move", "destination": destination})
	var mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = app.board.global_position + app.board.center(destination)
	Input.parse_input_event(mouse)
	await app.get_tree().process_frame
	mouse.pressed = false
	Input.parse_input_event(mouse)
	await app.get_tree().process_frame
	check(Store.equivalent(app.state, move_result.state), "Real viewport mouse click moves directly on release")
	var face_result = app.rules.apply_command(app.state, {"kind": "finish", "facing": 4})
	app.buttons.finish.pressed.emit()
	var actor = Rules.active(app.state)
	click(app, {"x": actor.x, "y": actor.y - 1})
	check(Store.equivalent(app.state, face_result.state), "Facing chosen on board ends turn directly")
	for dimensions in [Vector2i(1024, 720), Vector2i(1440, 1000)]:
		DisplayServer.window_set_size(dimensions)
		await app.get_tree().process_frame
		await app.get_tree().process_frame
		await capture(app, directory, "04-%dx%d" % [dimensions.x, dimensions.y])
		_bounds(app, app, app.get_global_rect().grow(2))
	app.credits_dialog.popup_centered(Vector2i(720, 550))
	await capture(app, directory, "05-credits")
	app.credits_dialog.hide()
	var native_path = "user://qa-isolated-%d.json" % Time.get_ticks_usec()
	var native_store = Store.new(native_path)
	var native_saved = native_store.save(app.state, app.history, app.mode)
	check(native_saved.ok, "Default user directory accepts native saves")
	if native_saved.ok:
		var loaded = native_store.load_game(app.rules)
		check(loaded.ok and Store.equivalent(loaded.get("state", {}), app.state), "Native save resumes exact state")
		check(DirAccess.remove_absolute(ProjectSettings.globalize_path(native_path)) == OK, "Isolated user test cleaned up")
	var output = {"engine": Engine.get_version_info().string, "assertions": assertions, "playerOrders": player_orders, "friendlyFireChecked": risk_checked, "movementRevisions": undo_checks, "lockedRevisionChecks": blocked_undo_checks, "completed": completions, "screenshots": captures, "failures": failures}
	var file = FileAccess.open(directory.path_join("ui-result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "  "))
	file.close()
	print(JSON.stringify(output))
	app.get_tree().quit(0 if failures.is_empty() else 1)

func _check_risk(app, directory: String):
	if risk_checked or app.state.acted: return
	for action in app.rules.profile(Rules.active(app.state)).actions_for(Rules.active(app.state)):
		for unit in Rules.living(app.state):
			var plan = app.rules.attack_plan(app.state, int(unit.id), {}, action.definition.id)
			if not plan.ok or not app._friendly_risk(plan): continue
			var before = app.state.duplicate(true)
			risk_setup = {"mode": app.mode, "composition": app.state.composition, "commands": app.history.duplicate(true), "order": {"kind": "attack", "actionId": action.definition.id, "target": unit.id}}
			choose_action(app, action.definition.id)
			click(app, unit)
			check(not app.pending.is_empty() and app.buttons.confirm.visible, "Risk exposes explicit confirmation")
			check(Store.equivalent(app.state, before), "Risk selection does not execute attack")
			click(app, {"x": 0, "y": 0})
			app.direction_buttons[0].pressed.emit()
			check(Store.equivalent(app.state, before), "Pending attack cannot be replaced by another order")
			await capture(app, directory, "02-friendly-fire")
			_bounds(app, app, app.get_global_rect().grow(2))
			click(app, unit, MOUSE_BUTTON_RIGHT)
			check(app.pending.is_empty() and Store.equivalent(app.state, before), "Right click cancels risk without resources")
			check(app.selected_action==action.definition.id,"Cancelling confirmation returns to prepared ability")
			click(app,unit,MOUSE_BUTTON_RIGHT)
			check(app.selected_action=="basic" and Store.equivalent(app.state,before),"Second cancel returns to neutral board without cost")
			risk_checked = true
			return

func _bounds(node: Node, app, viewport: Rect2):
	if node == app:
		var map_rect: Rect2 = Rect2(app.board.global_position + app.board.board_origin(), Vector2.ONE * app.board.cell_size() * 8)
		for panel: Control in [app.command_panel, app.actor_info.get_parent().get_parent().get_parent(), app.target_panel, app.hint.get_parent()]:
			if panel.is_visible_in_tree(): check(not map_rect.intersects(panel.get_global_rect()), "Floating HUD leaves playable cells uncovered")
	if node is Window: return
	if node is Control and node.is_visible_in_tree() and node.get_window() == app.get_window():
		check(viewport.encloses(node.get_global_rect()), "Control fits window: " + str(node.get_path()))
	if node is ScrollContainer: return
	for child in node.get_children(): _bounds(child, app, viewport)
