extends RefCounted

const Threat = preload("res://core/threat_query.gd")
var revision: int = -1
var job: RefCounted
var cells: Dictionary = {}
var inspected: Dictionary = {}

func refresh(app: Control) -> void:
	if app.run.get("phase","")!="battle" or app.state.get("deployment",false): job = null; cells = {}; inspected = {}; revision = -1; return
	if revision==int(app.run.revision): return
	revision = int(app.run.revision); inspected = {}; cells = {}
	job = Threat.new(); job.start(app.rules,app.state)

func tick(app: Control) -> void:
	if job==null or app._modal_open(): return
	job.advance(1000)
	if not job.complete: return
	cells = job.cells; job = null
	app.hover_context.clear()
	app._hover_tile({"x":app.board.cursor.x,"y":app.board.cursor.y})

func describe(app: Control, point: Dictionary) -> String:
	if app.state.get("deployment",false) or not app._player_turn() or not app.board.available.has(app.rules.Movement.key(point)): return ""
	if job!=null: return "Cobertura rival: calculando…"
	var identities: Array = cells.get(app.rules.Movement.key(point),[])
	if identities.is_empty(): return "Fuera del alcance rival estimado."
	var names: PackedStringArray = []
	for identity: int in identities: names.append(app.rules.unit_by_id(app.state,identity).name)
	return "Alcance potencial: "+", ".join(names)+"."
