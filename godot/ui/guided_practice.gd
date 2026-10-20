extends RefCounted

class MemoryStore extends RefCounted:
	var file_path: String = "user://practice-in-memory.json"
	func save(_state: Dictionary, _commands: Array, _mode: String) -> Dictionary: return {"ok":true}
	func load_campaign(_rules: RefCounted) -> Dictionary: return {"ok":false,"reason":"La práctica solo existe en memoria. Sal para volver a tu aventura."}
	func preserve_before_new() -> Dictionary: return {"ok":false,"reason":"Sal de la práctica antes de comenzar una aventura."}

var active: bool = false
var step: int = 0
var saved: Dictionary = {}

func begin(app: Control) -> void:
	if active: leave(app); return
	saved = {"run":app.run,"campaign":app.campaign,"rules":app.rules,"store":app.store,"transactions":app.transactions,"selected":app.selected_member,"result":app.recent_result,"message":app.message,"warning":app.save_warning}
	app.campaign = load("res://core/journey_run.gd").new(22)
	app.rules = app.campaign.engine
	app.run = app.campaign.create("practice-only",1)
	app.run.phase = "battle"
	var members: Array = []
	for entry: Array in [[1,1],[2,7]]:
		var member: Dictionary = app.campaign.progression.create_member(entry[0],entry[1],"Práctica aislada",30)
		member.moves = ["growth","tackle","vine-whip"] if entry[0]==1 else ["tackle","withdraw","bubble"]
		members.append(member)
	app.run.party = members
	app.run.battle = app.rules.encounter(app.run,app.campaign.locations[0])
	var units: Array = []
	for i: int in members.size():
		var unit: Dictionary = app.rules.member_unit(members[i],{"x":5,"y":8+i})
		unit.tp = 5
		units.append(unit)
	for i: int in 2:
		var unit: Dictionary = app.rules.member_unit(app.campaign.progression.create_member(10000+i,134,"Práctica aislada",30),{"x":6,"y":8+i})
		unit.team = "enemy"
		unit.status = {"kind":"burn","remaining":3}
		units.append(unit)
	app.state = app.run.battle
	app.state.units = units
	app.state.queue = [1,2,10000,10001]
	app.state.completed = []
	for row: Array in app.state.board: row.fill(0)
	for row: Array in app.state.heights: row.fill(0)
	app.run.battleInitial = app.state.duplicate(true)
	app.run.battleCommands = []
	app.transactions = []
	app.history = []
	app.store = MemoryStore.new()
	app.title_visible = false
	app.pending = {}
	app.selecting = "auto"
	app.action_page = false
	app.selected_action = "basic"
	app.save_warning = ""
	app.combat_feedback.clear()
	step = 0
	active = true
	app.board.encounter_key = ""
	app._prepare_campaign_assets()
	app._refresh()
	app.board.grab_focus()
	app.input_profile.held.clear()

func leave(app: Control) -> void:
	if not active: return
	active = false
	app.run = saved.run
	app.campaign = saved.campaign
	app.rules = saved.rules
	app.store = saved.store
	app.transactions = saved.transactions
	app.state = app.run.get("battle",{})
	app.history = app.run.get("battleCommands",[])
	app.selected_member = saved.selected
	app.recent_result = saved.result
	app.message = saved.message
	app.save_warning = saved.warning
	app.pending = {}
	app.selecting = "auto"
	app.selected_action = "basic"
	app.action_page = false
	app.input_profile.held.clear()
	app.combat_feedback.clear()
	app._prepare_campaign_assets()
	app._open_title()

func instruction(app: Control) -> String:
	var profile: RefCounted = app.input_profile
	var stages: Array[String] = ["Explora otra casilla con flechas o puntero.","Mueve a una casilla libre con Enter o clic.","Rectifica SOLO ese movimiento: "+profile.label("rectify")+" o su botón.","Selecciona una habilidad desde "+profile.label("abilities")+" o el menú. Aún no actúes.","Cancela la selección: "+profile.label("cancel")+" o Volver.","Elige Crecimiento (apoyo propio); seleccionarlo no lo ejecuta.","Acepta Crecimiento con Enter o clic en el propio Pokémon.","Orienta y termina con "+profile.label("finish")+", flecha y Enter; también sirven los botones de dirección.","Con Squirtle, elige básico y un rival contiguo; acepta el ataque.","Comprueba Rectificar: después de actuar el motor lo bloquea.","Inspecciona un rival con "+profile.label("inspect")+" o Menú/Ficha; consulta su quemadura y activaciones.","Cierra la ficha, orienta y termina este turno.","Práctica completada. "+profile.label("practice")+" o Menú/Salir devuelve tu aventura intacta."]
	return "PRÁCTICA %d / 12 · %s" % [mini(step+1,12),stages[mini(step,12)]]

func allowed(app: Control, command: Dictionary) -> bool:
	if not active: return true
	if command.kind=="rectify": return step in [2,9]
	if command.kind!="battle": return false
	var order: Dictionary = command.order
	if step==1: return order.kind=="move"
	if step in [7,11]: return order.kind=="finish"
	if step==6: return order.kind=="attack" and order.get("actionId")=="growth"
	if step==8: return order.kind=="attack" and app.rules.unit_by_id(app.state,int(order.target)).get("team")=="enemy"
	return false

func observe(app: Control, kind: String, value: Dictionary = {}) -> void:
	if not active: return
	var next: bool = (step==0 and kind=="cursor") or (step==3 and kind=="select" and app.selecting=="attack") or (step==4 and kind=="cancel") or (step==5 and kind=="select" and app.selected_action=="growth") or (step==10 and kind=="inspect")
	if kind=="accepted":
		next = (step==1 and value.kind=="battle" and value.order.kind=="move") or (step==2 and value.kind=="rectify") or (step==6 and value.kind=="battle" and value.order.kind=="attack") or (step==7 and value.kind=="battle" and value.order.kind=="finish") or (step==8 and value.kind=="battle" and value.order.kind=="attack") or (step==11 and value.kind=="battle" and value.order.kind=="finish")
	if step==9 and kind=="blocked" and value.get("kind")=="rectify": next = true
	if next:
		step += 1
		app.hint.text = instruction(app)
		if step==9: app.buttons.undo.disabled = false; app.buttons.undo.text = "Explicar bloqueo · "+app.input_profile.label("rectify")
