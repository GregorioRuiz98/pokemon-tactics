extends RefCounted

static func draw(effect: Control) -> void:
	var points: Array = effect.source_points()
	if points.is_empty(): return
	var center: Vector2 = points[0]-Vector2(0,36)
	var phase: float = .5 if effect.board.reduced_motion else clampf(effect.clock/effect.length,0,1)
	var fade: float = 1.0-phase*.7
	var color: Color = Color(effect.profile.color,fade)
	match effect.profile.weather:
		"sun":
			effect.draw_circle(center,10+phase*3,color)
			for index: int in 8:
				var ray: Vector2 = Vector2.from_angle(index*TAU/8.0)
				effect.draw_line(center+ray*17,center+ray*(24+phase*5),color,2,true)
		"rain":
			for index: int in 7:
				var drop: Vector2 = center+Vector2((index-3)*10,((index*13)%29)-14+phase*22)
				effect.draw_line(drop,drop+Vector2(-4,10),color,2,true)
		"sand":
			for index: int in 3:
				effect.draw_arc(center,12+index*7,phase*TAU+index,phase*TAU+index+PI,18,color,2,true)
