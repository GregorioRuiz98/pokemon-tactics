extends SceneTree

const Journey = preload("res://core/journey_run.gd")
const Store = preload("res://core/journey_store.gd")
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _initialize() -> void:
	call_deferred("run_tests")

func write_payload(path: String, payload: Dictionary) -> void:
	var body: String = JSON.stringify(payload,"",true,true)
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checksum":body.sha256_text(),"payload":body}))

func run_tests() -> void:
	var directory: String = OS.get_user_data_dir()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
	var game: RefCounted = Journey.new(22)
	var board: Control = load("res://ui/isometric_board.gd").new()
	var palettes: Array = []
	for width: int in [16,24]:
		var tiles: Array = []
		for _y: int in width:
			var row: Array = []; row.resize(width); row.fill(0); tiles.append(row)
		board.state = {"board":tiles,"biome":"legends-birds"}
		var palette: Array = []
		for x: int in [4,8,12]: palette.append(board._tile_color({"x":x+int((width-16)/2.0),"y":4+int((width-16)/2.0)}))
		check(palette[0]!=palette[1] and palette[1]!=palette[2] and palette[0]!=palette[2],"Three distinct bird territories on%d" % width)
		palettes.append(palette)
	check(palettes[0]==palettes[1],"Bird territories stay aligned at both map sizes")
	board.free()
	var state: Dictionary = game.create("release-checks",1)
	var path: String = directory.path_join("release-guards-%d.json" % Time.get_ticks_usec())
	var first: RefCounted = Store.new(path)
	check(first.save(state,[],"journey").ok,"Current edition saves")
	var second: RefCounted = Store.new(path)
	check(second.load_campaign(game).ok,"Second instance loads current file")
	var order: Dictionary = {"kind":"enter","at":0}
	var entered: Dictionary = game.transact(state,order)
	check(entered.ok and first.save(entered.state,[order],"journey").ok,"First instance advances battle")
	var untouched: String = FileAccess.get_file_as_string(path)
	check(not second.save(state,[],"journey").ok,"Stale second instance cannot overwrite")
	check(FileAccess.get_file_as_string(path)==untouched,"Conflict preserves original bytes")
	check(FileAccess.file_exists(path+".bak"),"Previous save preserved as backup")
	var exact: Dictionary = first.load_campaign(game)
	check(exact.ok and Store.equivalent(exact.state,entered.state),"Battle replay exact after atomic replacement")
	var too_many: Array = []; too_many.resize(50001)
	check(not first.save(state,too_many,"journey").ok and FileAccess.get_file_as_string(path)==untouched,"Oversized journal rejected without overwrite")
	var huge: Dictionary = state.duplicate(true)
	huge.padding = "x".repeat(16*1024*1024)
	check(not first.save(huge,[],"journey").ok and FileAccess.get_file_as_string(path)==untouched,"Write respects the same16MB bound as load")
	var payload: Dictionary = first._payload(state,[],"journey")
	payload.state.party[0].hp -= 1
	var invalid_path: String = path+".invalid"
	write_payload(invalid_path,payload)
	var invalid: RefCounted = Store.new(invalid_path)
	var bytes: String = FileAccess.get_file_as_string(invalid_path)
	check(not invalid.load_campaign(game).ok,"A valid checksum cannot hide an altered snapshot")
	check(FileAccess.get_file_as_string(invalid_path)==bytes,"Rejected file remains intact")
	payload = first._payload(state,[],"journey")
	payload.version = 19
	write_payload(invalid_path,payload)
	bytes = FileAccess.get_file_as_string(invalid_path)
	check(not invalid.load_campaign(game).ok and FileAccess.get_file_as_string(invalid_path)==bytes,"Future edition rejected and preserved")
	check(not first._available_edition(19) and first._available_edition(18),"Installed version bounds known editions")
	payload = first._payload(state,[],"journey")
	payload.commands = ["invalid"]
	write_payload(invalid_path,payload)
	check(not invalid.load_campaign(game).ok,"Non-object journal order rejected")
	FileAccess.open(invalid_path,FileAccess.WRITE).store_string("{broken")
	bytes = FileAccess.get_file_as_string(invalid_path)
	check(not invalid.load_campaign(game).ok and FileAccess.get_file_as_string(invalid_path)==bytes,"Truncated save preserved")
	var previous_path: String = directory.get_base_dir().path_join("qa-sprint-21/journey-full.json")
	var old_store: RefCounted = Store.new(previous_path)
	var previous: Dictionary = old_store.load_campaign(game)
	check(previous.ok and previous.state.phase=="ending","Delivered ending21 loads")
	if previous.ok:
		var upgraded: Dictionary = game.transact(previous.state,{"kind":"upgrade","edition":18,"at":previous.state.revision})
		check(upgraded.ok and upgraded.state.phase=="ending" and upgraded.state.finalPath==previous.state.finalPath,"Update preserves completed ending")
		check(upgraded.ok and Store.equivalent(upgraded.state.party,previous.state.party) and upgraded.state.rng==previous.state.rng and upgraded.state.money==previous.state.money,"Finished update preserves party/RNG/money")
		if upgraded.ok: check(not game.transact(upgraded.state,{"kind":"destiny","path":"birds","at":upgraded.state.revision}).ok,"Update cannot reopen or change a finished adventure")
	var report: Dictionary = {"checks":checks,"failures":failures}
	FileAccess.open(directory.path_join("release-core-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
