extends Control

const Rules = preload("res://core/battle.gd")
var board: Control
var marks: Array = []
var age: float = 0.0
var duration: float = 3.0
var last_sound: String = "select"
var last_kinds: Array = []
const MISS = preload("res://assets/progression/miss.png")
const IMMUNE = preload("res://assets/progression/immune.png")
const Art = preload("res://ui/visual_assets.gd")
var attack_effect: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	attack_effect = preload("res://ui/attack_effect.gd").new()
	attack_effect.board = board
	add_child(attack_effect)
	board.attack_effect = attack_effect

func clear() -> void:
	if attack_effect!=null: attack_effect.stop()
	marks = []
	last_kinds = []
	queue_redraw()

func present(before: Dictionary, plan: Dictionary, receipts: Array, definition: Dictionary = {}) -> void:
	clear()
	age = 0
	var misses: int = 0
	var immunities: int = 0
	for receipt: Dictionary in receipts:
		var unit: Dictionary = Rules.unit_by_id(before,int(receipt.targetId))
		if unit.is_empty(): continue
		var kind: String = "hit"
		var text: String = "−%d PS" % receipt.damage
		var color: Color = Color("f3d286")
		var forecast: Dictionary = {}
		for entry: Dictionary in plan.get("hits",[]):
			if entry.targetId == receipt.targetId: forecast = entry
		if receipt.get("recoil",false):
			kind = "recoil"
			text = "%s −%d PS" % ["ORBE" if not receipt.get("moveRecoil",false) else "COSTE",receipt.damage]
			color = Color("dfb8ef")
		elif not receipt.hit:
			kind = "miss"
			text = "FALLO"
			color = Color("a4e7f3")
			misses += 1
		elif forecast.get("multiplier",1) == 0:
			kind = "immune"
			text = "INMUNE"
			color = Color("dfb8ef")
			immunities += 1
		elif receipt.get("heal",forecast.get("heal",0)) > 0:
			text = "+%d PS" % receipt.get("heal",forecast.heal)
			color = Color("a4e9b3")
		elif forecast.get("guard",false): text = "PROTEGIDO"
		elif definition.has("weather"): text = preload("res://core/climate_context.gd").WEATHER_NAMES[definition.weather].to_upper()
		elif receipt.damage == 0: text = "ATRIBUTO" if forecast.has("statChange") or not forecast.get("changes",[]).is_empty() else "ESTADO"
		if receipt.get("critical",false):
			kind = "critical"
			text = "CRÍTICO −%d" % receipt.damage
			color = Color("ffd26d")
		marks.append({"point":{"x":unit.x,"y":unit.y},"kind":kind,"text":text,"color":color})
		last_kinds.append(kind)
	last_sound = "miss" if misses == receipts.size() and misses > 0 else ("immune" if immunities == receipts.size() and immunities > 0 else "hit")
	if attack_effect!=null: attack_effect.start(before,plan,receipts,definition)
	queue_redraw()

func _process(delta: float) -> void:
	if marks.is_empty(): return
	if board==null or not board.visible:
		marks = []
		last_kinds = []
		# Let the final impact finish under the reward screen; an explicit exit still cancels it.
		if attack_effect!=null and attack_effect.active: attack_effect.stop()
		queue_redraw()
		return
	age += delta
	if age >= duration: marks = []
	queue_redraw()

func present_abilities(before: Dictionary, events: Array, reset: bool = false) -> void:
	if reset: clear()
	age = 0
	var count: Dictionary = {}
	for event: Dictionary in events:
		var unit: Dictionary = Rules.unit_by_id(before,int(event.targetId))
		if unit.is_empty(): continue
		var key: String = str(int(unit.id))+event.name
		if count.has(key): continue
		count[key] = true
		marks.append({"point":{"x":unit.x,"y":unit.y},"kind":"ability","text":event.name,"color":Color("a4e9b3"),"offset":40})
		last_kinds.append("ability")
	queue_redraw()

func _draw() -> void:
	if board == null or not board.visible: return
	var font: Font = get_theme_default_font()
	if attack_effect!=null and attack_effect.active:
		var title: String = attack_effect.profile.name
		var width: float = font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
		var label_at: Vector2 = board.play_area().position+Vector2((board.play_area().size.x-width)*.5,25)
		draw_string_outline(font,label_at,title,HORIZONTAL_ALIGNMENT_LEFT,-1,20,5,Color("0d242c"))
		draw_string(font,label_at,title,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff1c9"))
	for mark: Dictionary in marks:
		if attack_effect!=null and attack_effect.active and not attack_effect.impacted and mark.kind!="ability": continue
		var point: Vector2 = board.center(mark.point)
		point.y -= board.cell_size()*0.55 + (0 if board.reduced_motion else age*16)
		if mark.kind == "recoil": point.y -= 30
		point.y -= mark.get("offset",0)
		var alpha: float = 1 if board.reduced_motion else minf(1,(duration-age)*3)
		var color: Color = mark.color
		color.a = alpha
		if mark.kind in ["miss","immune"]:
			draw_circle(board.center(mark.point),board.cell_size()*0.38,color,false,2)
			var icon: Texture2D = Art.texture("fx_"+mark.kind)
			draw_texture_rect(icon,Rect2(point-Vector2(34,26),Vector2(24,24)),false,color)
		elif mark.kind=="critical" or mark.text.begins_with("+") or (mark.kind=="hit" and mark.text.begins_with("−")):
			var effect: String = "critical" if mark.kind=="critical" else ("heal" if mark.text.begins_with("+") else "hit")
			draw_texture_rect(Art.texture("fx_"+effect),Rect2(point-Vector2(20,38),Vector2(40,40)),false,Color(1,1,1,alpha))
		var width: float = font.get_string_size(mark.text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
		var origin: Vector2 = point-Vector2(width/2,5)
		draw_string_outline(font,origin,mark.text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,5,Color(0.02,0.05,0.06,alpha))
		draw_string(font,origin,mark.text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
