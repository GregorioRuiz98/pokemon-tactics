extends SceneTree

const Rules = preload("res://core/battle.gd")
const Movement = preload("res://core/movement.gd")
const Rng = preload("res://core/seeded_rng.gd")
const Store = preload("res://core/save_store.gd")
var failures: Array[String] = []
var checks: int = 0

func equal(actual, expected, context: String) -> bool:
	checks += 1
	if (actual is float or actual is int) and (expected is float or expected is int):
		if abs(float(actual) - float(expected)) < 0.00000001: return true
	elif actual is Array and expected is Array:
		if actual.size() == expected.size():
			for index in actual.size():
				if not equal(actual[index], expected[index], context + "[%d]" % index): return false
			return true
	elif actual is Dictionary and expected is Dictionary:
		if actual.size() == expected.size():
			for field in expected:
				if not actual.has(field):
					failures.append(context + ": missing field " + str(field))
					return false
				if not equal(actual[field], expected[field], context + "." + str(field)): return false
			return true
	elif actual == expected: return true
	failures.append("%s: actual=%s; expected=%s" % [context, str(actual).left(240), str(expected).left(240)])
	return false

func normalized(state: Dictionary) -> Dictionary:
	var result = state.duplicate(true)
	result.erase("log")
	return result

func expect(condition: bool, context: String) -> void:
	checks += 1
	if not condition: failures.append(context)

func _initialize():
	call_deferred("run")

func run() -> void:
	var rules = Rules.new()
	var reference_bytes = FileAccess.get_file_as_bytes("res://tests/parity.json.gz").decompress_dynamic(16 * 1024 * 1024, FileAccess.COMPRESSION_GZIP)
	var fixture = JSON.parse_string(reference_bytes.get_string_from_utf8())
	var commands = 0
	for sample in fixture.rng:
		var state = {"rng": Rng.hash_seed(sample.seed)}
		equal(state.rng, sample.hash, "seed " + sample.seed)
		for value in sample.values: equal(Rng.next(state), value, "rng " + sample.seed)
		equal(state.rng, sample.final, "rng final")
	for game in fixture.games:
		var state = rules.create(game.seed, game.variance, game.composition, game.mode)
		var context = "%s/%s/%s/%s" % [game.seed, game.mode, game.composition, game.variance]
		if not equal(normalized(state), game.initial, context + " initial"): continue
		for step in game.steps:
			var before = state.duplicate(true)
			var command = rules.choose_command(state)
			if not equal(state, before, context + " AI mutated input"): break
			if not equal(command, step.command, context + " command %d" % commands): break
			var result = rules.apply_command(state, command)
			expect(result.ok, context + " legal reference command")
			if not result.ok: break
			if not equal(state, before, context + " apply mutated input"): break
			state = result.state
			commands += 1
			if not equal(normalized(state), step.expected, context + " state %d" % commands): break
	for sample in fixture.scenarios:
		var state = sample.state
		var before = state.duplicate(true)
		for plan in sample.plans: equal(rules.attack_plan(state, int(plan.target), {}, plan.action), plan.expected, sample.name + " plan " + plan.action)
		var movement = Movement.routes(state.board, Rules.living(state), Rules.active(state))
		var expected_routes = {}
		for route in sample.movement: expected_routes[route.key] = route.route
		equal(movement, expected_routes, sample.name + " routes")
		equal(state, before, sample.name + " preview mutated input")
		if sample.has("command"):
			var result = rules.apply_command(state, sample.command)
			if result.ok: result.state = normalized(result.state)
			equal(result, sample.result, sample.name + " application")
	var test_dir = ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): test_dir = argument.trim_prefix("--save-dir=")
	if test_dir.is_empty():
		failures.append("Pass an isolated --save-dir for persistence tests.")
	else:
		DirAccess.make_dir_recursive_absolute(test_dir)
		var file_path = test_dir.path_join("parity-save-%d.json" % Time.get_ticks_usec())
		var store = Store.new(file_path)
		var state = rules.create("save-continuity")
		var history = []
		for index in 8:
			var command = rules.choose_command(state)
			history.append(command)
			state = rules.apply_command(state, command).state
		expect(store.save(state, history, "current").ok, "native save writes")
		var loaded = store.load_game(rules)
		expect(loaded.ok, "native save reconstructs: " + loaded.get("reason", "ok"))
		if loaded.ok:
			equal(loaded.state, state, "save exact state")
			var command = rules.choose_command(state)
			equal(rules.apply_command(loaded.state, command), rules.apply_command(state, command), "resume exact next roll")
		var concurrent = Store.new(file_path)
		expect(store.save(state, history, "current").ok, "native save replace")
		var prior_bytes = FileAccess.get_file_as_string(file_path)
		var oversized = history.duplicate(true)
		while oversized.size() <= 4000: oversized.append({"kind": "finish"})
		expect(not store.save(state, oversized, "current").ok, "excessive journal rejected before writing")
		expect(FileAccess.get_file_as_string(file_path) == prior_bytes, "journal limit preserves prior save")
		var corrupt = FileAccess.open(file_path, FileAccess.WRITE)
		corrupt.store_string("{broken")
		corrupt.close()
		expect(not store.load_game(rules).ok, "invalid save rejected")
		expect(FileAccess.get_file_as_string(file_path) == "{broken", "invalid save preserved")
		expect(not concurrent.save(state, history, "current").ok, "concurrent modification rejected")
		var failed_store = Store.new(test_dir.path_join("missing.json/block/save.json"))
		var blocker = FileAccess.open(test_dir.path_join("missing.json"), FileAccess.WRITE)
		blocker.store_string("file, not directory")
		blocker.close()
		expect(not failed_store.save(state, history, "current").ok, "write failure reported")
	var summary = {"checks": checks, "referenceBattles": fixture.games.size(), "commands": commands, "scenarios": fixture.scenarios.size(), "failures": failures}
	if not test_dir.is_empty():
		var output = FileAccess.open(test_dir.path_join("parity-result.json"), FileAccess.WRITE)
		output.store_string(JSON.stringify(summary, "  "))
		output.close()
	print(JSON.stringify(summary))
	quit(0 if failures.is_empty() else 1)
