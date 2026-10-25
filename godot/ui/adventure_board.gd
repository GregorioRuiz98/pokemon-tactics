extends "res://ui/isometric_board.gd"

var threat_cells: Dictionary = {}
var deployment_drag: int = 0
signal deployment_dragged(identity: int, point: Dictionary)

func _draw_tile(point: Dictionary, canvas: CanvasItem) -> void:
	super._draw_tile(point,canvas)
	if state.get("deployment",false) and available.has(Movement.key(point)):
		canvas.draw_colored_polygon(diamond(point),Color(.2,.8,.38,.28))
		_outline(diamond(point),Color("8fe4a5"),2,canvas)

func _pointer_click(event: InputEventMouseButton, point: Dictionary) -> void:
	if state.get("deployment",false) and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			deployment_drag = 0
			for unit: Dictionary in state.units:
				if unit.team=="ally" and unit.hp>0 and Movement.same(unit,point): deployment_drag = int(unit.id)
		elif deployment_drag>0 and pointer_dragged and not point.is_empty():
			var identity: int = deployment_drag
			deployment_drag = 0
			cancel_pointer()
			deployment_dragged.emit(identity,point)
			accept_event()
			return
	super._pointer_click(event,point)

func _draw() -> void:
	var started: int = Time.get_ticks_usec() if has_meta("adventure_draw_samples") else 0
	super._draw()
	if state.get("combatEdition",0)<19: return
	var area: Rect2 = play_area()
	for key: String in threat_cells:
		var split: PackedStringArray = key.split(",")
		var point: Dictionary = {"x":int(split[0]),"y":int(split[1])}
		if not area.grow(-25).has_point(center(point)): continue
		_outline(diamond(point),Color("ee8677",.75),1.5)
	for pair: Array in state.get("arena",{}).get("portals",[]):
		for point: Dictionary in pair:
			if area.grow(-25).has_point(center(point)):
				draw_arc(center(point),cell_size()*.2,0,TAU,24,Color("bcadee"),3)
	var mission: Dictionary = state.get("mission",{})
	for point: Dictionary in mission.get("points",[]):
		if not area.grow(-25).has_point(center(point)): continue
		var done: bool = Movement.key(point) in mission.get("captured",[])
		_outline(diamond(point),Color("7bd7ae") if done else Color("ffda82"),3)
		_tag(center(point),"OK" if done else {"secure":"T","protect":"Fuji %d" % mission.get("health",0),"escape":"SALIDA"}.get(mission.get("kind"),""),Color("ffda82"),12)
	if started>0: get_meta("adventure_draw_samples").append((Time.get_ticks_usec()-started)/1000.0)
