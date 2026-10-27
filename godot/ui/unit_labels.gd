extends RefCounted

const Indicators = preload("res://ui/unit_indicators.gd")

static func layout(board: Control) -> Dictionary:
	var result: Dictionary = {}
	if board.state.is_empty() or not board.isometric(): return result
	var units: Array = board.state.units.filter(func(u):return u.hp>0 and board.play_area().grow(70).has_point(board.center(u)))
	var active_id: int = int(board.state.queue[0]) if not board.state.queue.is_empty() else -1
	units.sort_custom(func(a,b):return priority(board,a,active_id)>priority(board,b,active_id) if priority(board,a,active_id)!=priority(board,b,active_id) else a.id<b.id)
	var occupied: Array[Rect2] = []
	var font: Font = board.get_theme_default_font()
	for unit: Dictionary in units:
		var detailed: bool = priority(board,unit,active_id)>0
		var badges: Array = Indicators.entries(unit)
		var shown: Array = badges.slice(0,4 if detailed else 1)
		var name_text: String = ("%s · %d/%d"%[unit.name,unit.hp,unit.maxHp]) if unit.id==active_id else unit.name if detailed else ""
		if not detailed and unit.get("dormant",false): name_text = "VIGÍA"
		var width: float = maxf(76 if detailed else 42,font.get_string_size(name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+10)
		var height: float = (19 if name_text!="" else 0)+ceil(shown.size()/float(2 if detailed else 1))*16
		if height==0: continue
		var foot: Vector2 = board.center(unit)
		var top: Vector2 = Vector2(foot.x,board.sprite_visual(unit).used.position.y-5)
		var best: Rect2 = Rect2(top-Vector2(width/2,height),Vector2(width,height))
		var least_overlap: float = INF
		for shift: Vector2 in [Vector2.ZERO,Vector2(-width*.6,-14),Vector2(width*.6,-14),Vector2(0,-32),Vector2(-width*.8,-38),Vector2(width*.8,-38)]:
			var candidate: Rect2 = Rect2(top-Vector2(width/2,height)+shift,Vector2(width,height))
			candidate.position.x = clampf(candidate.position.x,board.play_area().position.x+2,board.play_area().end.x-width-2)
			candidate.position.y = clampf(candidate.position.y,board.play_area().position.y+2,board.play_area().end.y-height-2)
			var overlap: float = 0
			for other: Rect2 in occupied: overlap += candidate.intersection(other.grow(2)).get_area()
			if overlap<least_overlap: best = candidate; least_overlap = overlap
			if overlap==0: break
		occupied.append(best)
		result[int(unit.id)] = {"rect":best,"name":name_text,"badges":shown,"extra":badges.size()-shown.size(),"detailed":detailed,"top":top}
	return result

static func priority(board: Control, unit: Dictionary, active_id: int) -> int:
	return 2 if unit.id==active_id else 1 if int(unit.x)==board.cursor.x and int(unit.y)==board.cursor.y else 0

static func draw(board: Control, unit: Dictionary, labels: Dictionary) -> void:
	var c: Vector2 = board.center(unit)
	var color: Color = board._unit_color(unit)
	var width: float = clampf(board.cell_size()*.52,28,58)
	var hp: Rect2 = Rect2(c+Vector2(-width/2,board.cell_size()*.20),Vector2(width,5))
	board.draw_rect(hp.grow(1),Color("17312e"))
	board.draw_rect(Rect2(hp.position,Vector2(width*unit.hp/unit.maxHp,5)),color)
	for hit: Dictionary in board.forecast_hits:
		if hit.targetId!=unit.id or hit.damage<=0: continue
		var low: int = mini(unit.hp,int(hit.get("damageMin",hit.damage)))
		var high: int = mini(unit.hp,maxi(int(hit.get("damageMax",hit.damage)),int(hit.get("criticalMax",0))))
		board.draw_rect(Rect2(hp.position+Vector2(width*(unit.hp-high)/unit.maxHp,0),Vector2(width*(high-low)/unit.maxHp,5)),Color("bd8d4c"))
		board.draw_rect(Rect2(hp.position+Vector2(width*(unit.hp-low)/unit.maxHp,0),Vector2(width*low/unit.maxHp,5)),Color("f8c76d"))
	board._tag(c+Vector2(0,18),"A" if unit.team=="ally" else "E",Color.WHITE,11)
	if not labels.has(int(unit.id)): return
	var entry: Dictionary = labels[int(unit.id)]
	var box: Rect2 = entry.rect
	var font: Font = board.get_theme_default_font()
	if box.get_center().distance_to(entry.top)>25: board.draw_line(box.get_center(),entry.top,Color(color,.65),1,true)
	board.draw_rect(box,Color("152c2b"))
	var y: float = box.position.y
	if entry.name!="":
		board.draw_string(font,Vector2(box.position.x+5,y+13),entry.name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ffe69a") if not board.state.queue.is_empty() and unit.id==board.state.queue[0] else color)
		y += 19
	for index: int in entry.badges.size():
		var columns: int = 2 if entry.detailed else 1
		Indicators.draw_badge(board,Rect2(Vector2(box.position.x+(index%columns)*36,y+int(index/float(columns))*16),Vector2(34,14)),entry.badges[index],font,10,true)
	if entry.extra>0: board.draw_string(font,box.end-Vector2(19,3),"+%d"%entry.extra,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.WHITE)
