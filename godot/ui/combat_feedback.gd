extends Control

const Rules = preload("res://core/battle.gd")
var board: Control
var marks: Array = []
var age: float = 0.0
var last_sound: String = "select"
var last_kinds: Array = []
const MISS = preload("res://assets/progression/miss.png")
const IMMUNE = preload("res://assets/progression/immune.png")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func clear() -> void:
	marks = []
	last_kinds = []
	queue_redraw()

func present(before: Dictionary, plan: Dictionary, receipts: Array) -> void:
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
		elif forecast.get("heal",0) > 0:
			text = "+%d PS" % forecast.heal
			color = Color("a4e9b3")
		elif forecast.get("guard",false): text = "PROTEGIDO"
		elif receipt.damage == 0: text = "ATRIBUTO" if forecast.has("statChange") or not forecast.get("changes",[]).is_empty() else "ESTADO"
		marks.append({"point":{"x":unit.x,"y":unit.y},"kind":kind,"text":text,"color":color})
		last_kinds.append(kind)
	last_sound = "miss" if misses == receipts.size() and misses > 0 else ("immune" if immunities == receipts.size() and immunities > 0 else "hit")
	queue_redraw()

func _process(delta: float) -> void:
	if marks.is_empty(): return
	age += delta
	if age >= 0.95: marks = []
	queue_redraw()

func _draw() -> void:
	if board == null or not board.visible: return
	var font: Font = get_theme_default_font()
	for mark: Dictionary in marks:
		var point: Vector2 = board.center(mark.point)
		point.y -= board.cell_size()*0.55 + (0 if board.reduced_motion else age*16)
		if mark.kind == "recoil": point.y -= 30
		var alpha: float = 1 if board.reduced_motion else minf(1,(0.95-age)*3)
		var color: Color = mark.color
		color.a = alpha
		if mark.kind in ["miss","immune"]:
			draw_circle(board.center(mark.point),board.cell_size()*0.38,color,false,2)
			var icon: Texture2D = MISS if mark.kind == "miss" else IMMUNE
			draw_texture_rect(icon,Rect2(point-Vector2(34,26),Vector2(24,24)),false,color)
		var width: float = font.get_string_size(mark.text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
		var origin: Vector2 = point-Vector2(width/2,5)
		draw_string_outline(font,origin,mark.text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,5,Color(0.02,0.05,0.06,alpha))
		draw_string(font,origin,mark.text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
