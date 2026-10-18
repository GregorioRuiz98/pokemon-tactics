extends "res://ui/board.gd"

const Terrain = preload("res://core/terrain_movement.gd")
var zoom: float = 0.9
var anchor: Vector2 = Vector2.ZERO
var dragging: bool = false
var tracked: int = -1
var encounter_key: String = ""

func isometric() -> bool:
	return state.get("combatEdition",0)>=11

func play_area() -> Rect2:
	if not isometric(): return super.play_area()
	return Rect2(Vector2(24,156),size-Vector2(332,410))

func cell_size() -> float:
	return 76*zoom if isometric() else super.cell_size()

func projection(point: Dictionary) -> Vector2:
	return Vector2((point.x-point.y)*38,(point.x+point.y)*19-Terrain.height_at(state,point)*14)

func center(point: Dictionary) -> Vector2:
	if not isometric(): return super.center(point)
	return play_area().get_center()+(projection(point)-anchor)*zoom

func focus_point(point: Dictionary) -> void:
	anchor = projection(point)
	queue_redraw()

func focus_active() -> void:
	if not isometric() or Rules.active(state).is_empty(): return
	focus_point(Rules.active(state))

func fit_map() -> void:
	if not isometric(): return
	zoom = clampf(minf(play_area().size.x/(dimensions().x*76.0),play_area().size.y/(dimensions().y*38.0+64)),0.3,1.7)
	anchor = Vector2(0,(dimensions().x-1)*19-14)
	queue_redraw()

func change_zoom(factor: float) -> void:
	zoom = clampf(zoom*factor,0.3,1.7)
	queue_redraw()

func pan(delta: Vector2) -> void:
	anchor -= delta/zoom
	anchor.x = clampf(anchor.x,-dimensions().x*38,dimensions().x*38)
	anchor.y = clampf(anchor.y,-50,dimensions().y*38)
	queue_redraw()

func track_turn() -> void:
	if not isometric(): return
	var identity: String = state.seed+str(state.mapSize)
	if identity!=encounter_key:
		encounter_key = identity
		zoom = 0.9
		tracked = -1
	var actor: Dictionary = Rules.active(state)
	if not actor.is_empty() and actor.id!=tracked:
		tracked = int(actor.id)
		cursor = Vector2i(actor.x,actor.y)
		focus_active()

func diamond(point: Dictionary) -> PackedVector2Array:
	var c: Vector2 = center(point)
	var half: float = cell_size()*0.5
	return PackedVector2Array([c+Vector2(0,-half*0.5),c+Vector2(half,0),c+Vector2(0,half*0.5),c+Vector2(-half,0)])

func pick(screen: Vector2) -> Dictionary:
	if not play_area().has_point(screen): return {}
	# Test elevated top faces in reverse painter order; never select a cliff wall.
	for sum: int in range(dimensions().x+dimensions().y-2,-1,-1):
		for x: int in range(dimensions().x-1,-1,-1):
			var y: int = sum-x
			if y<0 or y>=dimensions().y: continue
			var point: Dictionary = {"x":x,"y":y}
			if Geometry2D.is_point_in_polygon(screen,diamond(point)): return point
	return {}

func _gui_input(event: InputEvent) -> void:
	if not isometric():
		super._gui_input(event)
		return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			accept_event()
			return
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			change_zoom(1.12 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.12)
			accept_event()
			return
		if event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
			cancelled.emit()
			accept_event()
			return
	if event is InputEventMouseMotion and dragging:
		pan(event.relative)
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var point: Dictionary = pick(event.position)
		if not point.is_empty(): cursor = Vector2i(point.x,point.y)
		if event is InputEventMouseMotion: tile_hovered.emit(point)
		elif event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not point.is_empty():
			grab_focus()
			tile_selected.emit(point)
			accept_event()
	if event is InputEventKey and event.pressed and not event.echo:
		var vector: Vector2i = Vector2i.ZERO
		match event.keycode:
			KEY_LEFT: vector = Vector2i.LEFT
			KEY_RIGHT: vector = Vector2i.RIGHT
			KEY_UP: vector = Vector2i.UP
			KEY_DOWN: vector = Vector2i.DOWN
			KEY_HOME, KEY_C: focus_active()
			KEY_EQUAL, KEY_PLUS: change_zoom(1.12)
			KEY_MINUS: change_zoom(1/1.12)
			KEY_ENTER, KEY_KP_ENTER: tile_selected.emit({"x":cursor.x,"y":cursor.y})
			_: return
		if vector!=Vector2i.ZERO:
			cursor = (cursor+vector).clamp(Vector2i.ZERO,dimensions()-Vector2i.ONE)
			var point: Dictionary = {"x":cursor.x,"y":cursor.y}
			if not play_area().grow(-45).has_point(center(point)): focus_point(point)
			tile_hovered.emit(point)
		accept_event()
		queue_redraw()

func _draw() -> void:
	if not isometric():
		super._draw()
		return
	draw_rect(Rect2(Vector2.ZERO,size),Color("162e2b"))
	var cell: float = cell_size()
	var font: Font = get_theme_default_font()
	for sum: int in dimensions().x+dimensions().y-1:
		for x: int in dimensions().x:
			var y: int = sum-x
			if y<0 or y>=dimensions().y: continue
			var point: Dictionary = {"x":x,"y":y}
			var c: Vector2 = center(point)
			if not play_area().grow(cell).has_point(c): continue
			var polygon: PackedVector2Array = diamond(point)
			var tile: int = int(state.board[y][x])
			var h: int = Terrain.height_at(state,point)
			var color: Color = Color("7d9b64") if (x+y)%2==0 else Color("789460")
			if state.biome=="brock": color = Color("9e9782") if (x+y)%2==0 else Color("938c7b")
			if tile==1: color = Color("4c7753")
			if tile==2: color = Color("535e57")
			if tile==3: color = Color("508b9c")
			var drop: Vector2 = Vector2(0,(h+1)*14*zoom)
			draw_colored_polygon(PackedVector2Array([polygon[1],polygon[2],polygon[2]+drop,polygon[1]+drop]),color.darkened(0.45))
			draw_colored_polygon(PackedVector2Array([polygon[2],polygon[3],polygon[3]+drop,polygon[2]+drop]),color.darkened(0.3))
			draw_colored_polygon(polygon,color.lightened(h*0.035))
			draw_polyline(PackedVector2Array([polygon[0],polygon[1],polygon[2],polygon[3],polygon[0]]),Color(0.08,0.2,0.13,0.24),1)
			if tile==1:
				for i: int in 3: draw_line(c+Vector2((i-1)*9,4)*zoom,c+Vector2((i-1)*9+2,-5)*zoom,Color("a7ba76"),zoom)
			if tile==2:
				draw_colored_polygon(PackedVector2Array([c+Vector2(-16,4)*zoom,c+Vector2(-9,-15)*zoom,c+Vector2(11,-12)*zoom,c+Vector2(18,4)*zoom]),Color("8b9485"))
			var key: String = Movement.key(point)
			if available.has(key): draw_colored_polygon(polygon,Color(0.15,0.7,0.93,0.35))
			if attackable.has(key): draw_polyline(PackedVector2Array([polygon[0],polygon[1],polygon[2],polygon[3],polygon[0]]),Color("f8b397"),2)
			if affected.any(func(p):return Movement.same(p,point)): draw_colored_polygon(polygon,Color(1,0.5,0.1,0.5))
			if cursor==Vector2i(x,y): draw_polyline(PackedVector2Array([polygon[0],polygon[1],polygon[2],polygon[3],polygon[0]]),Color("f3d286"),3)
	for index: int in range(1,route.size()): draw_line(center(route[index-1]),center(route[index]),Color("f3d286"),3)
	for field: Dictionary in state.fields: draw_circle(center(field),cell*0.17,Color(0.95,0.3,0.1,0.45))
	var ordered: Array = state.units.duplicate()
	ordered.sort_custom(func(a,b):return a.x+a.y<b.x+b.y if a.x+a.y!=b.x+b.y else a.id<b.id)
	for unit: Dictionary in ordered:
		if unit.hp <= 0: continue
		var c = center(unit)
		if not play_area().grow(50).has_point(c): continue
		var active = not state.queue.is_empty() and unit.id == state.queue[0]
		var color = Color("6ad4b2") if unit.team == "ally" else Color("e5a182")
		draw_circle(c + Vector2(0, cell * 0.17), cell * 0.31, Color(0.03, 0.12, 0.08, 0.33))
		draw_arc(c + Vector2(0, cell * 0.11), cell * 0.33, 0, TAU, 32, color, 3 if active else 1)
		var meta = catalog[int(unit.speciesId)].animations.Idle
		var ticks = elapsed * 60
		var total = 0.0
		for duration in meta.durations: total += duration
		var phase = fmod(ticks, total)
		var frame = 0
		for duration in meta.durations:
			if phase < duration: break
			phase -= duration
			frame += 1
		var sprite_scale: float = minf(1.65, cell / 36.0)
		var texture = textures[int(unit.speciesId)]
		var point = c + Vector2(0, cell * 0.13)
		var destination = Rect2(point - Vector2(meta.anchorX, meta.anchorY) * sprite_scale, Vector2(meta.width, meta.height) * sprite_scale)
		draw_texture_rect_region(texture, destination, Rect2(frame * meta.width, ((int(unit.facing)+7)%8) * meta.height, meta.width, meta.height))
		if unit.get("dormant",false): draw_string(font,c+Vector2(-20,-cell*0.5),"VIGÍA",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("eccb7f"))
		var hp_rect = Rect2(c + Vector2(-cell * 0.3, cell * 0.34), Vector2(cell * 0.6, 5))
		draw_rect(hp_rect, Color("22372b"))
		draw_rect(Rect2(hp_rect.position, Vector2(hp_rect.size.x * unit.hp / unit.maxHp, 5)), color)
		for hit in forecast_hits:
			if hit.targetId != unit.id or hit.damage <= 0: continue
			var remaining = maxi(0, int(unit.hp - hit.damage))
			if hit.has("damageMin"):
				remaining = maxi(0,int(unit.hp-hit.damageMin))
				var possible: int = mini(unit.hp,maxi(hit.damageMax,hit.criticalMax if hit.criticalChance>0 else 0))
				draw_rect(Rect2(hp_rect.position+Vector2(hp_rect.size.x*(unit.hp-possible)/unit.maxHp,0),Vector2(hp_rect.size.x*(possible-hit.damageMin)/unit.maxHp,5)),Color(0.94,0.71,0.42,0.4))
			draw_rect(Rect2(hp_rect.position + Vector2(hp_rect.size.x * remaining / unit.maxHp, 0), Vector2(hp_rect.size.x * (unit.hp - remaining) / unit.maxHp, 5)), Color("f0b66a"))
			var prediction: String = "%d–%d" % [hit.damageMin,hit.damageMax] if hit.has("damageMin") else "−%d · %d%%" % [hit.damage,hit.accuracy]
			if hit.has("damageMin") and hit.damageMin==hit.damageMax: prediction = str(hit.damageMin)
			draw_string(font, c + Vector2(-cell * 0.3, cell * 0.65), prediction, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff0ca"))
		var logical: Vector2 = Vector2(Rules.VECTORS[int(unit.facing)])
		var facing_vector: Vector2 = Vector2(logical.x-logical.y,(logical.x+logical.y)*0.5).normalized()
		var arrow = c + facing_vector * cell * 0.37
		draw_line(arrow - facing_vector * 5, arrow + facing_vector * 2, Color("f8edce"), 2)
		if active:
			var top = c - Vector2(0, cell * 0.44)
			draw_colored_polygon(PackedVector2Array([top + Vector2(-5, -5), top + Vector2(5, -5), top + Vector2(0, 2)]), Color("f3d286"))
			if facing_preview >= 0:
				var logical_preview: Vector2 = Vector2(Rules.VECTORS[facing_preview])
				var vector: Vector2 = Vector2(logical_preview.x-logical_preview.y,(logical_preview.x+logical_preview.y)*0.5).normalized()
				draw_line(c, c + vector * cell * 0.65, Color("f3d286"), 4)
	for unit: Dictionary in ordered:
		if unit.hp<=0: continue
		var badges: Array = Indicators.entries(unit)
		var start: Vector2 = center(unit)+Vector2(-36,-cell*0.65)
		for i: int in badges.size():
			Indicators.draw_badge(self,Rect2(start+Vector2((i%2)*36,int(i/2.0)*15),Vector2(34,14)),badges[i],font,10,true)
	# Opaque margins keep clipped map geometry away from the HUD.
	var area: Rect2 = play_area()
	for rect: Rect2 in [Rect2(0,0,size.x,area.position.y),Rect2(0,area.end.y,size.x,size.y-area.end.y),Rect2(0,area.position.y,area.position.x,area.size.y),Rect2(area.end.x,area.position.y,size.x-area.end.x,area.size.y)]: draw_rect(rect,Color("162e2b"))
	draw_rect(area,Color("648b78"),false,1)
	draw_string(font,Vector2(30,area.end.y+21),"%d×%d · zoom %d %% · %s · altura %d" % [dimensions().x,dimensions().y,roundi(zoom*100),Rules.coordinate({"x":cursor.x,"y":cursor.y}),Terrain.height_at(state,{"x":cursor.x,"y":cursor.y})],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("eccb7f"))
	_draw_minimap()

func _draw_minimap() -> void:
	var origin: Vector2 = Vector2(size.x-276,126)
	var step: float = 72.0/dimensions().x
	draw_rect(Rect2(origin-Vector2.ONE*6,Vector2(84,84)),Color("0c2425"))
	for y: int in dimensions().y:
		for x: int in dimensions().x:
			var color: Color = Color("496e52") if state.board[y][x]!=2 else Color("253d36")
			draw_rect(Rect2(origin+Vector2(x,y)*step,Vector2.ONE*step),color)
	for unit: Dictionary in state.units:
		if unit.hp<=0: continue
		draw_circle(origin+(Vector2(unit.x,unit.y)+Vector2.ONE*0.5)*step,3,Color("6ad4b2") if unit.team=="ally" else (Color("eccb7f") if unit.get("dormant",false) else Color("e5a182")))
