extends Control
var playback_speed: float = 1.0

signal cue_requested(identity: String)
signal cancelled
const Rules = preload("res://core/battle.gd")
const Art = preload("res://ui/visual_assets.gd")
const SpatialEffects = preload("res://ui/spatial_effects.gd")
const COLORS: Dictionary = {"normal":"e8dcb5","fire":"ff9c48","water":"65c9fa","electric":"ffe46b","grass":"9de477","ice":"b4f2ff","fighting":"eea079","poison":"cd9eea","ground":"d4ac75","flying":"c8eaf3","psychic":"f0a3e8","bug":"c5db71","rock":"d3bb96","ghost":"b7a7f1","dragon":"9eaffe","dark":"bba9c9","steel":"d2e1e6","fairy":"ffd0eb"}
var board: Control
var origin: Dictionary = {}
var targets: Array = []
var profile: Dictionary = {}
var clock: float = 0
var impact_at: float = 0.24
var length: float = 0.64
var impacted: bool = false
var active: bool = false
var outcome_cue: String = "impact"
var tiles: Array = []
var aim: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_process(false)

static func describe(definition: Dictionary) -> Dictionary:
	var element: String = str(definition.get("type","normal"))
	if not COLORS.has(element): element = "normal"
	var identity: String = str(definition.get("id","basic"))
	var style: String = "projectile"
	var cue: String = element
	if definition.get("kind","") in ["heal","drain"] and definition.get("power",0)==0:
		style = "heal"; cue = "heal"
	elif definition.get("kind","")=="guard": style = "guard"; cue = "guard"
	elif definition.get("category","")=="status":
		style = "support"
		cue = "buff" if definition.get("target","") in ["self","friendly"] else "debuff"
	elif identity in ["slash","night-slash","fury-swipes","scratch","metal-claw","razor-leaf","x-scissor"]: style = "slash"
	elif definition.get("category","")=="physical" and int(definition.get("range",1))<=1: style = "strike"
	elif identity.contains("beam") or identity in ["flamethrower","hydro-pump","thunderbolt","psychic"]: style = "beam"
	elif definition.get("kind","")=="area-damage" or identity in ["earthquake","surf","explosion","self-destruct"]: style = "wave"
	var result: Dictionary = {"element":element,"color":Color(COLORS[element]),"style":style,"cue":cue,"name":str(definition.get("name","Ataque")),"spatial":definition.has("spatialDescription")}
	if definition.has("weather"):
		result.weather = definition.weather; result.style = "weather"; result.cue = element
	if result.spatial:
		result.signature = SpatialEffects.style(definition)
		result.variant = absi(identity.hash())%11
		var original: Dictionary = SpatialEffects.audio(identity)
		if not original.is_empty(): result.cue = "original/"+identity; result.audioDuration = float(original.duration)
	preload("res://ui/attack_variants.gd").decorate(result,definition)
	return result

func stop() -> void:
	active = false
	origin = {}
	targets = []
	tiles = []
	aim = {}
	set_process(false)
	queue_redraw()
	if board!=null: board.queue_redraw()
	cancelled.emit()

func start(before: Dictionary, plan: Dictionary, receipts: Array, definition: Dictionary) -> void:
	stop()
	origin = Rules.active(before).duplicate(true)
	if origin.is_empty() or board==null or not board.visible: return
	profile = describe(definition)
	tiles = plan.get("tiles",[]).duplicate(true)
	aim = plan.get("aim",origin).duplicate()
	if str(definition.get("shape","")).begins_with("L"):
		for point: Dictionary in tiles:
			if absi(int(point.x)-int(origin.x))+absi(int(point.y)-int(origin.y))>absi(int(aim.x)-int(origin.x))+absi(int(aim.y)-int(origin.y)): aim = point.duplicate()
	clock = 0
	impacted = false
	impact_at = 0.0 if board.reduced_motion else (0.14 if profile.style in ["heal","guard","support"] else 0.24)
	length = 0.32 if board.reduced_motion else 0.64
	if profile.get("spatial",false):
		impact_at = 0.0 if board.reduced_motion else (.55 if profile.signature=="hyper-beam" else .28)
		length = maxf(length,float(profile.get("audioDuration",0))+.08)
	var cues: Array = []
	for receipt: Dictionary in receipts:
		if receipt.get("recoil",false): continue
		var unit: Dictionary = Rules.unit_by_id(before,int(receipt.targetId))
		if unit.is_empty(): continue
		var forecast: Dictionary = {}
		for hit: Dictionary in plan.get("hits",[]):
			if hit.targetId==receipt.targetId: forecast = hit
		var kind: String = "impact"
		if not receipt.hit: kind = "miss"
		elif forecast.get("multiplier",1)==0: kind = "immune"
		elif receipt.get("heal",forecast.get("heal",0))>0: kind = "heal"
		elif forecast.get("guard",false): kind = "guard"
		elif receipt.get("critical",false): kind = "critical"
		elif receipt.damage==0: kind = "buff" if unit.team==origin.team else "debuff"
		cues.append(kind)
		targets.append({"unit":unit.duplicate(true),"kind":kind})
	if targets.is_empty() and profile.get("spatial",false): targets.append({"unit":{"x":aim.x,"y":aim.y,"id":-1},"kind":"field"})
	if targets.is_empty(): stop(); return
	for candidate: String in ["critical","impact","heal","guard","buff","debuff","immune","miss"]:
		if candidate in cues: outcome_cue = candidate; break
	active = true
	position = board.play_area().position
	size = board.play_area().size
	cue_requested.emit(profile.cue)
	set_process(true)
	advance(0)

func advance(delta: float) -> void:
	if not active: return
	if not board.visible: stop(); return
	clock += delta
	if not impacted and (clock>=impact_at or board.reduced_motion):
		impacted = true
		if not profile.cue.begins_with("original/"): cue_requested.emit(outcome_cue)
	if clock>=length: stop(); return
	position = board.play_area().position
	size = board.play_area().size
	queue_redraw()
	board.queue_redraw()

func _process(delta: float) -> void:
	advance(delta*playback_speed)

func offset_for(unit: Dictionary) -> Vector2:
	if not active or board.reduced_motion: return Vector2.ZERO
	if unit.id==origin.id and clock<impact_at:
		if targets.is_empty(): return Vector2.ZERO
		var toward: Vector2 = (board.center(targets[0].unit)-board.center(origin)).normalized()
		var progress: float = clampf(clock/maxf(impact_at,0.01),0,1)
		return (board.center(origin)-board.center(unit))*(1-progress)+toward*sin(progress*PI)*(12 if profile.style in ["strike","slash"] else 3)
	if not impacted:
		for target: Dictionary in targets:
			if target.unit.id==unit.id: return board.center(target.unit)-board.center(unit)
	if impacted:
		var amount: float = clampf((clock-impact_at)/maxf(0.01,length-impact_at),0,1)
		for target: Dictionary in targets:
			if target.unit.id==unit.id and target.kind in ["impact","critical","miss"]:
				if profile.get("signature","")=="throw": return (board.center(target.unit)-board.center(unit))*(1-amount)-Vector2(0,sin(amount*PI)*38)
				return (board.center(target.unit)-board.center(unit))*(1-amount)+Vector2(sin(amount*PI)*(-8 if target.kind=="miss" else 5),0)
	return Vector2.ZERO

func _point(unit: Dictionary) -> Vector2:
	return board.center(unit)-position-Vector2(0,board.cell_size()*0.26)

func source_points() -> Array[Vector2]:
	if not board.has_method("isometric") or not board.isometric() or not board.sprite_bounds.has(int(origin.get("speciesId",0))): return [_point(origin)]
	var used: Rect2 = board.sprite_visual(origin).used
	var points: Array[Vector2] = []
	for anchor: Vector2 in preload("res://ui/pokemon_pose.gd").anchors(int(origin.speciesId),profile.element): points.append(used.position+used.size*anchor-position)
	return points

func _glyph(at: Vector2, radius: float, color: Color, element: String, phase: float) -> void:
	if element=="fire":
		var flicker: float = sin(phase)*radius*.25
		draw_colored_polygon(PackedVector2Array([at+Vector2(-radius,radius*.6),at+Vector2(-radius*.55,-radius*.2),at+Vector2(-radius*.3,radius*.1),at+Vector2(flicker,-radius*1.5),at+Vector2(radius*.6,-radius*.1),at+Vector2(radius,radius*.6)]),color)
		draw_colored_polygon(PackedVector2Array([at+Vector2(-radius*.45,radius*.6),at+Vector2(0,-radius*.4),at+Vector2(radius*.45,radius*.6)]),Color(1,.9,.55,color.a))
	elif element=="water":
		draw_circle(at,radius*.75,color)
		draw_colored_polygon(PackedVector2Array([at+Vector2(-radius*.6,0),at+Vector2(0,-radius*1.5),at+Vector2(radius*.6,0)]),color)
		draw_arc(at,radius*.5,PI*.5,PI,8,Color(.8,.95,1,color.a),2)
	elif element=="electric":
		draw_polyline(PackedVector2Array([at+Vector2(-radius,-radius),at+Vector2(radius*0.25,-2),at+Vector2(-radius*0.2,2),at+Vector2(radius,radius)]),color,3)
	elif element in ["grass","ice","rock","steel","bug"]:
		var points: PackedVector2Array = PackedVector2Array([at+Vector2(0,-radius),at+Vector2(radius*0.65,0),at+Vector2(0,radius),at+Vector2(-radius*0.65,0)])
		draw_colored_polygon(points,color)
		draw_line(at-Vector2(0,radius*.7),at+Vector2(0,radius*.7),Color(1,1,1,color.a*.6),1)
	elif element in ["psychic","ghost","fairy"]:
		draw_arc(at,radius,phase,phase+TAU*.85,18,color,2)
		draw_line(at-Vector2(radius*.5,0),at+Vector2(radius*.5,0),color,2)
		draw_line(at-Vector2(0,radius*.5),at+Vector2(0,radius*.5),color,2)
	elif element in ["flying","ground"]:
		draw_arc(at,radius,phase,phase+PI*1.5,18,color,2)
		draw_arc(at,radius*.6,-phase,-phase+PI,12,color,2)
	else:
		draw_circle(at,radius,color)
		draw_circle(at+Vector2(-radius*.2,-radius*.3),radius*.45,Color(1,1,.85,color.a*.65))

func _draw() -> void:
	if active and profile.has("reviewStyle"):
		preload("res://ui/attack_variants.gd").draw(self)
		return
	if active and profile.has("weather"):
		preload("res://ui/climate_effect.gd").draw(self)
		return
	if not active or origin.is_empty(): return
	var from: Vector2 = source_points()[0]
	var color: Color = profile.color
	var unit_scale: float = clampf(board.cell_size()/64.0,0.65,1.3)
	var preparation: float = clampf(clock/maxf(0.01,impact_at),0,1)
	SpatialEffects.cast(self)
	for target: Dictionary in targets:
		if target.kind=="field": continue
		var to: Vector2 = _point(target.unit)
		if not impacted and not board.reduced_motion:
			if profile.get("spatial",false) and profile.signature!="signature": continue
			if profile.style in ["strike","slash"]:
				draw_arc(from,12*unit_scale,0,TAU*preparation,16,Color(color,.65),2)
			elif profile.style in ["heal","support","guard"]:
				draw_arc(to,22*preparation*unit_scale,0,TAU,24,Color(color,.6),2)
			else:
				var tip: Vector2 = from.lerp(to,preparation)
				if profile.style=="beam": draw_line(from,tip,Color(color,.6),5*unit_scale)
				for index: int in 3:
					var p: float = maxf(0,preparation-index*.09)
					_glyph(from.lerp(to,p),maxf(2,(8-index*2)*unit_scale),Color(color,1-index*.25),profile.element,clock*8)
		else:
			var progress: float = 0.25 if board.reduced_motion else clampf((clock-impact_at)/maxf(0.01,length-impact_at),0,1)
			var alpha: float = 1-progress
			if target.kind in ["miss","immune"]:
				var symbol: Texture2D = Art.texture("fx_"+target.kind)
				draw_texture_rect(symbol,Rect2(to-Vector2.ONE*22*unit_scale,Vector2.ONE*44*unit_scale),false,Color(1,1,1,alpha))
				continue
			var effect: String = "heal" if target.kind=="heal" else ("critical" if target.kind=="critical" else "hit")
			if target.kind in ["impact","critical","heal"]:
				var radius: float = (24+progress*12)*unit_scale*(1.25 if target.kind=="critical" else 1.0)
				draw_texture_rect(Art.texture("fx_"+effect),Rect2(to-Vector2.ONE*radius,Vector2.ONE*radius*2),false,Color(1,1,1,alpha))
			if target.kind=="heal":
				for index: int in 3:
					var p: Vector2 = to+Vector2((index-1)*14,-progress*28-10)*unit_scale
					draw_line(p-Vector2(4,0),p+Vector2(4,0),Color(.65,1,.7,alpha),3)
					draw_line(p-Vector2(0,4),p+Vector2(0,4),Color(.65,1,.7,alpha),3)
			elif target.kind in ["buff","debuff","guard"]:
				draw_arc(to,(18+progress*16)*unit_scale,0,TAU,24,Color(color,alpha),3)
				for index: int in 3:
					var p: Vector2 = to+Vector2((index-1)*15,(-1 if target.kind=="buff" else 1)*progress*20)*unit_scale
					var direction: float = -1 if target.kind=="buff" else 1
					draw_polyline(PackedVector2Array([p+Vector2(-4,-direction*4),p,p+Vector2(4,-direction*4)]),Color(color,alpha),2)
			elif profile.style=="slash":
				for index: int in 3:
					var p: Vector2 = to+Vector2(index*7-7,0)*unit_scale
					draw_line(p+Vector2(-15,19)*unit_scale,p+Vector2(15,-19)*unit_scale,Color(color,alpha),3)
			else:
				if profile.style=="wave": draw_arc(to,(12+progress*42)*unit_scale,0,TAU,32,Color(color,alpha),3)
				for index: int in 6:
					var angle: float = index*TAU/6
					var p: Vector2 = to+Vector2(cos(angle),sin(angle))*(12+progress*25)*unit_scale
					_glyph(p,(5-progress*3)*unit_scale,Color(color,alpha),profile.element,clock*7+angle)
