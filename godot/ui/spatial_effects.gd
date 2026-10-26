extends RefCounted

const Interaction = preload("res://ui/spatial_interaction.gd")
const COLORS: Dictionary = {"smoke":"bdc6d3","poison":"ce9ae8","fire":"f5ad65","mud":"c6ac7d","web":"e9e7be","rocks":"d9c5ac","mist":"bce9ed","wall":"a5e5db","reflect":"f2b5d7","light-screen":"f7e7a4"}
static var audio_records: Dictionary = {}

static func audio(identity: String) -> Dictionary:
	if audio_records.is_empty():
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/original-moves/manifest.json"))
		for entry: Dictionary in manifest.files: audio_records[entry.id] = entry
	return audio_records.get(identity,{})

static func fields(canvas: Control) -> void:
	var font: Font = canvas.get_theme_default_font()
	for field: Dictionary in canvas.state.fields:
		if not COLORS.has(field.kind): continue
		var at: Vector2 = canvas.center(field)
		if not canvas.play_area().grow(50).has_point(at): continue
		var radius: float = canvas.cell_size()*.26
		var tint: Color = Color(COLORS[field.kind])
		canvas.draw_colored_polygon(canvas.diamond(field),Color(tint,.19))
		canvas._outline(canvas.diamond(field),Color(tint,.65),1)
		glyph(canvas,at,radius,tint,field.kind,0)
		var duration: String = "∞" if field.get("source",1)==0 and int(field.expires)>=999 else str(maxi(1,int(field.expires)-int(canvas.state.round)-1))
		canvas.draw_string_outline(font,at+Vector2(radius,-radius*.3),duration,HORIZONTAL_ALIGNMENT_LEFT,-1,11,3,Color("142d30"))
		canvas.draw_string(font,at+Vector2(radius,-radius*.3),duration,HORIZONTAL_ALIGNMENT_LEFT,-1,11,tint)

static func glyph(canvas: CanvasItem, at: Vector2, radius: float, color: Color, motif: String, phase: float) -> void:
	match motif:
		"smoke","poison","mist":
			for i: int in 3:
				var point: Vector2 = at+Vector2((i-1)*radius*.7,-absf(i-1)*radius*.25)
				canvas.draw_circle(point,radius*.65,Color(color,color.a*.52))
				canvas.draw_arc(point,radius*.65,PI,TAU,10,color,1.5)
			if motif=="poison": canvas.draw_line(at-Vector2(radius*.25,0),at+Vector2(radius*.25,0),Color("42234f"),3)
		"wall","reflect","light-screen":
			var polygon: PackedVector2Array = PackedVector2Array([at+Vector2(-radius,-radius*1.3),at+Vector2(radius,-radius*1.8),at+Vector2(radius,radius*.3),at+Vector2(-radius,radius*.8)])
			canvas.draw_colored_polygon(polygon,Color(color,color.a*.28))
			polygon.append(polygon[0]); canvas.draw_polyline(polygon,color,2)
			canvas.draw_line(at-Vector2(radius,0),at+Vector2(radius,-radius*.5),color,1)
			canvas.draw_line(at-Vector2(0,radius*1.5),at+Vector2(0,radius*.5),color,1)
		"rocks":
			for i: int in 3:
				var p: Vector2 = at+Vector2((i-1)*radius*.7,(i%2)*radius*.25)
				canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-radius*.8),p+Vector2(radius*.35,radius*.35),p+Vector2(-radius*.35,radius*.35)]),color)
		"web":
			for i: int in 4:
				var ray: Vector2 = Vector2.from_angle(i*PI/4)*radius
				canvas.draw_line(at-ray,at+ray,color,1)
			canvas.draw_circle(at,radius*.6,color,false,1)
		"mud":
			canvas.draw_arc(at,radius,0,TAU,18,color,3)
			canvas.draw_line(at-Vector2(radius*.7,0),at+Vector2(radius*.5,radius*.4),color,3)
		"fire":
			canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-radius*.7,radius*.4),at+Vector2(-radius*.3,-radius*.6),at,at+Vector2(radius*.2,-radius*1.5),at+Vector2(radius*.8,radius*.4)]),color)
		_:
			canvas.draw_arc(at,radius,phase,phase+TAU*.85,22,color,2)

static func style(definition: Dictionary) -> String:
	var identity: String = definition.get("id","")
	if identity=="tri-attack": return "triad"
	if identity in ["razor-leaf","magical-leaf","petal-dance"]: return "leaves"
	if identity in ["bubble","bubble-beam"]: return "bubbles"
	if identity=="fire-blast": return "starburst"
	if identity=="substitute": return "decoy"
	if identity in ["psychic","psybeam","confusion"]: return "psychic"
	if identity in ["mimic","mirror-move","conversion"]: return "echo"
	if identity in ["sing","growl","roar","screech","supersonic","bug-buzz"]: return "sound"
	if definition.get("kind","")=="drain" or identity=="helping-hand": return "link"
	if definition.get("field","")!="": return definition.field
	if identity in ["hyper-beam","solar-beam","ice-beam","aurora-beam","hydro-pump","flamethrower"]: return identity
	if identity in ["thunderbolt","thunder","thunder-shock","thunder-wave"]: return "lightning"
	if identity=="vine-whip": return "vine"
	if definition.get("special","")=="teleport": return "portal"
	if definition.get("special","")=="throw": return "throw"
	if identity in ["explosion","self-destruct","fire-blast"]: return "burst"
	if identity in ["earthquake","fissure","dig"]: return "fault"
	if definition.get("shape","") in ["W6","F0","K2","T4"]: return "fan"
	if definition.get("shape","").begins_with("L"): return "ray"
	if definition.get("spatialArea",false): return "pulse"
	return "signature"

static func cast(effect: Control) -> void:
	var profile: Dictionary = effect.profile
	if not profile.get("spatial",false): return
	var style_name: String = profile.signature
	var from: Vector2 = effect.source_points()[0]
	var to: Vector2 = effect.board.center(effect.aim)-effect.position-Vector2(0,effect.board.cell_size()*.26)
	var color: Color = profile.color
	var progress: float = .75 if effect.board.reduced_motion else clampf(effect.clock/maxf(.01,effect.impact_at),0,1)
	var fade: float = 1.0 if not effect.impacted else clampf((effect.length-effect.clock)/maxf(.01,effect.length-effect.impact_at),0,1)
	var scale: float = clampf(effect.board.cell_size()/64.0,.65,1.3)
	var phase: float = 0 if effect.board.reduced_motion else effect.clock*5
	for i: int in effect.tiles.size():
		var point: Vector2 = effect.board.center(effect.tiles[i])-effect.position
		var alpha: float = fade*(.5 if effect.impacted else .22)
		if COLORS.has(style_name): glyph(effect,point,14*scale,Color(COLORS[style_name],alpha+.25),style_name,phase)
		elif style_name in ["pulse","burst","fan","fault"]:
			if style_name=="fault": effect.draw_polyline(PackedVector2Array([point+Vector2(-13,7)*scale,point+Vector2(-3,-3)*scale,point+Vector2(4,3)*scale,point+Vector2(13,-7)*scale]),Color(color,fade),2)
			else: effect.draw_arc(point,(10+progress*14)*scale,0,TAU,20,Color(color,alpha),2)
	if style_name in ["hyper-beam","solar-beam","ice-beam","aurora-beam","hydro-pump","flamethrower","ray"]:
		var tip: Vector2 = from.lerp(to,progress)
		var width: float = (12 if style_name=="hyper-beam" else 7)*scale*fade
		for source: Vector2 in effect.source_points():
			var end: Vector2 = source.lerp(to,progress)
			effect.draw_line(source,end,Color(color,.4*fade),width*2)
			effect.draw_line(source,end,Color(color,.95*fade),maxf(1,width))
			effect.draw_line(source,end,Color(1,.98,.88,fade),maxf(1,width*.3))
			effect.draw_circle(source,(6+sin(progress*PI)*8)*scale,Color(color,fade))
		if style_name in ["ice-beam","aurora-beam"]:
			for i: int in 5:
				var crystal: Vector2 = from.lerp(tip,(i+1)/6.0)
				effect.draw_line(crystal-Vector2(0,7)*scale,crystal+Vector2(0,7)*scale,Color(1,1,1,fade),2)
		if style_name=="hyper-beam":
			for i: int in 4: effect.draw_arc(from.lerp(tip,(i+1)/5.0),(8+progress*9)*scale,-PI*.4,PI*.4,12,Color("fff0ae",fade),2)
	elif style_name=="triad":
		var palette: Array[Color] = [Color("ffb074"),Color("b5edff"),Color("ffe476")]
		for i: int in 3:
			var vertex: Vector2 = to+Vector2.from_angle(i*TAU/3-PI*.5)*18*scale
			effect.draw_line(from,from.lerp(vertex,progress),Color(palette[i],fade),3*scale)
			effect.draw_circle(vertex,5*scale,Color(palette[i],fade))
	elif style_name=="lightning":
		var points: PackedVector2Array = PackedVector2Array([from])
		for i: int in range(1,9): points.append(from.lerp(to,i/8.0*progress)+Vector2(0,(1 if i%2 else -1)*7*scale))
		effect.draw_polyline(points,Color(color,fade),4*scale)
		effect.draw_polyline(points,Color(1,1,1,fade),1)
	elif style_name=="vine":
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in 13:
			var p: float = i/12.0*progress
			points.append(from.lerp(to,p)+Vector2(0,sin(p*TAU+phase)*8*scale*sin(p*PI)))
		effect.draw_polyline(points,Color("a2dc7b",fade),3*scale)
	elif style_name in ["leaves","bubbles","sound","psychic","echo","link"]:
		var travel: Vector2 = from.lerp(to,progress)
		if style_name=="link":
			for i: int in 6: effect.draw_circle(to.lerp(from,fposmod(progress+i/6.0,1)),3*scale,Color("b9efa1",fade))
		elif style_name=="leaves":
			for i: int in 5:
				var at: Vector2 = from.lerp(to,clampf(progress-i*.04,0,1))+Vector2((i-2)*8,sin(phase+i)*8)*scale
				effect.draw_colored_polygon(PackedVector2Array([at+Vector2(-8,1)*scale,at+Vector2(0,-5)*scale,at+Vector2(8,-1)*scale,at+Vector2(0,5)*scale]),Color(color,fade))
		elif style_name=="bubbles":
			for i: int in 6:
				var at: Vector2 = from.lerp(to,clampf(progress-i*.04,0,1))+Vector2(sin(i*2)*12,cos(i*3)*10)*scale
				effect.draw_circle(at,(4+i%3)*scale,Color(color,fade),false,2)
		else:
			for i: int in 3:
				var at: Vector2 = travel+Vector2((i-1)*6,-i*3)*scale
				effect.draw_arc(at,(10+progress*15+i*7)*scale,phase+i,phase+i+TAU*.8,25,Color(color,fade*(1-i*.2)),2)
	elif style_name in ["starburst","decoy"]:
		var center: Vector2 = to if style_name=="starburst" else from
		if style_name=="decoy":
			effect.draw_circle(center,25*scale,Color(color,fade),false,3)
			effect.draw_circle(center-Vector2(7,4)*scale,3*scale,Color("142d30",fade))
			effect.draw_circle(center+Vector2(7,-4)*scale,3*scale,Color("142d30",fade))
		else:
			for i: int in 5:
				var ray: Vector2 = Vector2.from_angle(-PI*.5+i*TAU/5)*(25+progress*20)*scale
				effect.draw_line(center,center+ray,Color("ffb05e",fade),7*scale)
				effect.draw_line(center,center+ray,Color("fff2a0",fade),2*scale)
	elif style_name=="portal":
		for point: Vector2 in [from,to]:
			effect.draw_arc(point,18*scale,phase,phase+TAU*.9,30,Color(color,fade),3)
			effect.draw_arc(point,11*scale,-phase,-phase+TAU*.8,24,Color(1,1,1,fade),1)
	elif style_name=="throw":
		for target: Dictionary in effect.targets:
			var destination: Dictionary = effect.Rules.unit_by_id(effect.board.state,int(target.unit.id))
			if destination.is_empty(): continue
			var start: Vector2 = effect._point(target.unit)
			var end: Vector2 = effect._point(destination)
			var points: PackedVector2Array = PackedVector2Array()
			for i: int in 17:
				var p: float = i/16.0
				points.append(start.lerp(end,p)-Vector2(0,sin(p*PI)*38*scale))
			effect.draw_polyline(points,Color(color,.7*fade),2)
	else:
		var facets: int = 3+int(profile.variant)%4
		for i: int in facets:
			var angle: float = i*TAU/facets+phase*.2
			var ray: Vector2 = Vector2.from_angle(angle)*(14+progress*10)*scale
			effect.draw_line(to+ray*.7,to+ray,Color(color,fade),2)
