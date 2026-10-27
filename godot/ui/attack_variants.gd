extends RefCounted

const GROUPS: Dictionary = {
	"dash":["tackle","quick-attack","take-down","double-edge","headbutt","slam"],
	"jaws":["bite","crunch","hyper-fang","super-fang"],
	"punch":["mega-punch","fire-punch","ice-punch","thunder-punch","mach-punch","karate-chop","brick-break"],
	"needles":["poison-sting","pin-missile","twineedle","fury-attack","spike-cannon"],
	"jet":["water-gun","scald","waterfall"],
	"ripple":["water-pulse","dragon-pulse","dark-pulse"],
	"embers":["ember","heat-wave","flame-wheel"],
	"stones":["rock-throw","rock-slide","rock-blast","rock-tomb"],
	"stars":["swift","dazzling-gleam"],
	"powder":["sleep-powder","stun-spore","poison-powder","spore"],
	"feathers":["roost","wing-attack","gust","air-slash","drill-peck"],
	"egg":["soft-boiled","egg-bomb","barrage"]
}

static func decorate(profile: Dictionary, definition: Dictionary) -> void:
	for identity: String in GROUPS:
		if definition.get("id","") in GROUPS[identity]:
			profile.reviewStyle = identity
			profile.reviewPower = float(definition.get("power",0))
			return

static func draw(effect: Control) -> void:
	var start: Vector2 = effect.source_points()[0]
	var phase: float = .6 if effect.board.reduced_motion else clampf(effect.clock/effect.length,0,1)
	var progress: float = clampf(phase*2,0,1)
	var fade: float = 1-phase*.8
	var color: Color = Color(effect.profile.color,fade)
	var style_name: String = effect.profile.reviewStyle
	for target: Dictionary in effect.targets:
		var end: Vector2 = effect._point(target.unit)
		if target.kind in ["miss","immune"]:
			if effect.impacted:
				effect.draw_texture_rect(effect.Art.texture("fx_"+target.kind),Rect2(end-Vector2(20,28),Vector2(40,40)),false,Color(1,1,1,fade))
			continue
		var at: Vector2 = start.lerp(end,progress)-Vector2(0,18)
		var radius: float = 13+phase*10
		match style_name:
			"dash":
				for index: int in 3:
					var shift: Vector2 = Vector2(0,(index-1)*6)
					effect.draw_line(at+shift-(end-start).normalized()*22,at+shift,color,2,true)
			"jaws":
				at = end-Vector2(0,22)
				for index: int in 4:
					var x: float = (index-1.5)*9
					for direction: int in [-1,1]:
						var y: float = direction*(19-progress*12)
						effect.draw_colored_polygon(PackedVector2Array([at+Vector2(x-4,y),at+Vector2(x+4,y),at+Vector2(x,y-direction*8)]),color)
			"punch":
				effect.draw_circle(at,11,color)
				for index: int in 4: effect.draw_circle(at+Vector2((index-1.5)*6,-7),4,Color("fff1cb",fade))
				effect.draw_arc(end-Vector2(0,18),radius,0,TAU,20,color,3,true)
			"needles":
				for index: int in 3:
					var p: Vector2 = start.lerp(end,clampf(progress-index*.08,0,1))+Vector2((index-1)*5,-18)
					effect.draw_line(p-(end-start).normalized()*14,p,color,2,true)
			"jet":
				var direction: Vector2 = (end-start).normalized()
				var normal: Vector2 = Vector2(-direction.y,direction.x)*7
				effect.draw_colored_polygon(PackedVector2Array([start-Vector2(0,18),at+normal,at-normal]),Color(color,.6*fade))
				effect.draw_line(start-Vector2(0,18),at,Color("e5f7ff",fade),3,true)
			"ripple":
				for index: int in 3: effect.draw_circle(at,radius+index*7,Color(color,fade*(1-index*.2)),false,2,true)
			"embers":
				for index: int in 7:
					var p: Vector2 = start.lerp(end,clampf(progress-index*.025,0,1))+Vector2(sin(index*2+phase)*10,-18+cos(index)*8)
					effect.draw_circle(p,3+index%3,Color("ffb454" if index%2 else "ff7045",fade))
			"stones":
				for index: int in (1 if effect.profile.name=="Lanzarrocas" else 3):
					var p: Vector2 = at+Vector2((index-1)*14,-sin(progress*PI)*25)
					effect.draw_colored_polygon(PackedVector2Array([p+Vector2(-7,4),p+Vector2(-4,-8),p+Vector2(5,-6),p+Vector2(8,5)]),color)
			"stars":
				for index: int in 3:
					var p: Vector2 = at+Vector2((index-1)*16,sin(phase*TAU+index)*10)
					for ray_index: int in 5:
						var ray: Vector2 = Vector2.from_angle(ray_index*TAU/5-PI/2)*9
						effect.draw_line(p,p+ray,Color("ffdf82",fade),3,true)
			"powder":
				for index: int in 12:
					var p: Vector2 = end+Vector2(sin(index*2)*radius,cos(index*3)*radius-25+phase*8)
					effect.draw_circle(p,2+index%3,color)
			"feathers":
				for index: int in 5:
					var p: Vector2 = at+Vector2((index-2)*10,sin(phase*TAU+index)*12)
					effect.draw_line(p-Vector2(4,9),p+Vector2(4,-9),Color("e5eff0",fade),3,true)
			"egg":
				effect.draw_circle(at,11,Color("f5ebd8",fade))
				for index: int in 3: effect.draw_circle(at+Vector2((index-1)*5,(index%2)*7-4),3,Color("edba92",fade))
		if effect.impacted and target.kind not in ["buff","debuff","field"]:
			var motif: String = "heal" if target.kind=="heal" else "critical" if target.kind=="critical" else "hit"
			effect.draw_texture_rect(effect.Art.texture("fx_"+motif),Rect2(end-Vector2(18,36),Vector2(36,36)),false,Color(1,1,1,fade*.6))
