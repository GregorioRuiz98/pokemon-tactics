extends RefCounted

const Layouts: String = "res://data/kanto-landscapes.json"
static var layouts: Dictionary = {}

static func ensure_loaded() -> void:
	if layouts.is_empty(): layouts = JSON.parse_string(FileAccess.get_file_as_string(Layouts))

static func apply(state: Dictionary, location: Dictionary) -> void:
	ensure_loaded()
	var design: Dictionary = layouts[location.id]
	var map: Dictionary = design.maps[str(int(state.mapSize))]
	state.board = map.board.duplicate(true)
	state.heights = map.heights.duplicate(true)
	state.landscape = {"id":location.id,"title":design.title,"landmark":design.landmark,"material":design.material,"props":map.props.duplicate(true),"paths":map.paths.duplicate(true)}
	state.arena.title = design.title
	var offset: int = int((int(state.mapSize)-16)/2.0)
	for unit: Dictionary in state.units:
		var spawn: Array = design.get("enemySpawns",{}).get(str(int(unit.speciesId)),[])
		if unit.team=="enemy" and not spawn.is_empty(): unit.x = int(spawn[0])+offset; unit.y = int(spawn[1])+offset
	# The actual mission/portal rules and all unit/deployment positions are retained.
	# The authoring validator reserves these coordinates in both map sizes.
	state.arena.description = design.landmark+"\n"+state.arena.description
