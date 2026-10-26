extends Control

const PACK: String = "res://assets/merchant/manifest.json"
var app: Control
var sheet: Texture2D = preload("res://assets/merchant/Idle.png")
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PACK))
var frame: int = 0
var clock: float = 0
var reaction: float = 0
var draw_count: int = 0

func setup(owner_app: Control) -> void:
	app = owner_app
	custom_minimum_size = Vector2(176,144)
	clip_contents = true; mouse_filter = Control.MOUSE_FILTER_IGNORE
	accessibility_name = "Kecleon, comerciante"

func react() -> void:
	if app.reduced_motion: return
	reaction = .36; queue_redraw()

func _process(delta: float) -> void:
	if app==null or not is_visible_in_tree(): return
	if app.reduced_motion:
		if frame!=0 or reaction>0: frame = 0; reaction = 0; clock = 0; queue_redraw()
		return
	clock += delta
	var duration: float = maxf(.03,float(data.animation.d[frame])/60.0)
	if clock>=duration:
		clock = fmod(clock,duration); frame = (frame+1)%int(data.animation.n); queue_redraw()
	if reaction>0: reaction = maxf(0,reaction-delta); queue_redraw()

func _draw() -> void:
	draw_count += 1
	var box: Array = data.bounds
	var source: Rect2 = Rect2(frame*int(data.animation.w)+int(box[0]),int(box[1]),int(box[2])-int(box[0]),int(box[3])-int(box[1]))
	var height: float = minf(116,size.y-28)
	var width: float = height*source.size.x/source.size.y
	var lift: float = sin(reaction/.36*PI)*7 if reaction>0 else 0.0
	draw_circle(Vector2(size.x*.5,size.y-22),26,Color(0,0,0,.25))
	draw_texture_rect_region(sheet,Rect2(Vector2((size.x-width)*.5,size.y-height-22-lift),Vector2(width,height)),source)
	draw_rect(Rect2(8,size.y-28,size.x-16,28),Color("785032"))
	draw_rect(Rect2(4,size.y-31,size.x-8,7),Color("c29258"))
	draw_rect(Rect2(24,size.y-22,size.x-48,22),Color("436d4d"))
