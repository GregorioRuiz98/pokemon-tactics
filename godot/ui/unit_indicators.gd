extends Control

const STATS = {"attack":["ATQ","Ataque"],"defense":["DEF","Defensa"],"specialAttack":["AE","Ataque especial"],"specialDefense":["DE","Defensa especial"],"speed":["VEL","Velocidad"],"accuracy":["PRE","Precisión"],"evasion":["EVA","Evasión"]}
const CONDITIONS = {"poison":["ENV","Envenenado"],"burn":["QUE","Quemado"],"paralysis":["PAR","Paralizado"],"sleep":["DOR","Dormido"],"freeze":["CON","Congelado"],"confusion":["CFU","Confuso"],"seed":["DRE","Drenadoras"]}
var items: Array = []

static func entries(unit: Dictionary) -> Array:
	var result: Array = []
	if unit.is_empty(): return result
	var conditions: Dictionary = unit.get("volatile",{}).duplicate(true)
	if unit.get("status")!=null: conditions[unit.status.kind] = unit.status
	for key: String in CONDITIONS:
		if conditions.has(key): result.append({"key":key,"text":CONDITIONS[key][0],"stage":0,"hint":"%s · %d activaciones restantes" % [CONDITIONS[key][1],conditions[key].remaining]})
	for key: String in STATS:
		var stage: int = unit.get("stages",{}).get(key,0)
		if stage!=0: result.append({"key":key,"text":STATS[key][0],"stage":stage,"hint":"%s: %s%d etapas" % [STATS[key][1],"+" if stage>0 else "",stage]})
	return result

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_layout)

func show_unit(unit: Dictionary) -> void:
	items = entries(unit)
	_layout()

func _layout() -> void:
	var columns: int = maxi(1,int(size.x/72.0))
	custom_minimum_size.y = ceil(items.size()/float(columns))*25
	visible = not items.is_empty()
	queue_redraw()

func _get_tooltip(at: Vector2) -> String:
	var columns: int = maxi(1,int(size.x/72.0))
	var index: int = int(at.y/25)*columns+int(at.x/72)
	return items[index].hint if index>=0 and index<items.size() else ""

func _draw() -> void:
	var columns: int = maxi(1,int(size.x/72.0))
	for i: int in items.size(): draw_badge(self,Rect2(Vector2((i%columns)*72,(i/columns)*25),Vector2(68,22)),items[i],get_theme_default_font(),13,false)

static func draw_badge(canvas: CanvasItem, rect: Rect2, entry: Dictionary, font: Font, font_size: int, compact: bool) -> void:
	var tint: Color = Color("94e3ba") if entry.stage>0 else (Color("ffc193") if entry.stage<0 else Color("ebc7ff"))
	canvas.draw_rect(rect,Color("142d30"))
	canvas.draw_rect(rect,tint,false,1)
	var icon: Vector2 = rect.position+Vector2(6,rect.size.y/2)
	if entry.stage!=0:
		var direction: int = -1 if entry.stage>0 else 1
		canvas.draw_line(icon-Vector2(0,direction*4),icon+Vector2(0,direction*4),tint,1.5)
		canvas.draw_line(icon+Vector2(-3,direction),icon+Vector2(0,direction*4),tint,1.5)
		canvas.draw_line(icon+Vector2(3,direction),icon+Vector2(0,direction*4),tint,1.5)
	else:
		match entry.key:
			"paralysis": canvas.draw_polyline(PackedVector2Array([icon+Vector2(2,-5),icon+Vector2(-2,0),icon+Vector2(2,0),icon+Vector2(-2,5)]),tint,1.5)
			"burn": canvas.draw_colored_polygon(PackedVector2Array([icon+Vector2(0,-5),icon+Vector2(-3,2),icon+Vector2(0,5),icon+Vector2(3,2)]),tint)
			"poison":
				canvas.draw_circle(icon,3,tint)
				canvas.draw_line(icon+Vector2(-2,4),icon+Vector2(2,4),tint,1.5)
			"sleep": canvas.draw_polyline(PackedVector2Array([icon+Vector2(-3,-3),icon+Vector2(3,-3),icon+Vector2(-3,3),icon+Vector2(3,3)]),tint,1.5)
			_:
				canvas.draw_arc(icon,4,0,TAU,12,tint,1.5)
				canvas.draw_circle(icon,1,tint)
	var label: String = entry.text
	if not compact and entry.stage!=0: label += "%s%d" % ["+" if entry.stage>0 else "",entry.stage]
	canvas.draw_string(font,rect.position+Vector2(12,rect.size.y-5 if not compact else rect.size.y-3),label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("f1f3dc"))
