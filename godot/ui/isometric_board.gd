extends "res://ui/board.gd"

const Terrain = preload("res://core/terrain_movement.gd")
const TILE = Vector2(80,48)
const LIFT: float = 12
const BIOME_COLORS = {"cave":"8c8b81","ground":"b29b74","water":"b4ae83","ice":"a6c8c8","ship":"957b5b","rocket":"7f9195","ghost":"85768e","psychic":"a58dba","fire":"9d7562","dragon":"8d9daf","grass":"6c9661","legends-birds":"99a7a0","legends-psychic":"9182a8"}
var minimap_right: float = 276
var zoom: float = 1.2
var anchor: Vector2 = Vector2.ZERO
var dragging: bool = false
var tracked: int = -1
var encounter_key: String = ""
var manual_camera: bool = false
var strong_grid: bool = false
var show_heights: bool = false
var sprite_bounds: Dictionary = {}
var sprite_images: Dictionary = {}
var camera_mode: bool = false
var terrain_layer: Node2D
var minimap_layer: Node2D
var minimap_background: Node2D
var tile_nodes: Dictionary = {}
var terrain_context: Array = []
var tile_marks: Dictionary = {}
var terrain_rebuilds: int = 0
var tile_redraws: int = 0
signal camera_mode_changed

func _ready() -> void:
	super._ready()
	terrain_layer = Node2D.new()
	terrain_layer.show_behind_parent = true
	add_child(terrain_layer)
	terrain_layer.draw.connect(func():terrain_layer.draw_rect(Rect2(Vector2.ZERO,size),Color("0d242c")))
	minimap_layer = Node2D.new()
	add_child(minimap_layer)
	minimap_layer.draw.connect(_draw_minimap_overlay)
	minimap_background = Node2D.new()
	minimap_background.show_behind_parent = true
	minimap_layer.add_child(minimap_background)
	minimap_background.draw.connect(_draw_minimap_background)

func invalidate_terrain() -> void:
	terrain_context.clear()

func _update_terrain() -> void:
	# Godot retains each tile's drawing commands, including painter order and walls.
	# Animating sprites no longer rebuilds hundreds of unchanged tile polygons.
	var context: Array = [size,play_area(),anchor,zoom,strong_grid,show_heights,minimap_right,state.biome,state.board,state.heights]
	if context!=terrain_context:
		terrain_context = context
		terrain_rebuilds += 1
		terrain_layer.queue_redraw()
		minimap_background.queue_redraw()
		var area: Rect2 = play_area().grow(cell_size())
		for tile_node: Node2D in tile_nodes.values(): tile_node.hide()
		for sum: int in dimensions().x+dimensions().y-1:
			for x: int in dimensions().x:
				var y: int = sum-x
				if y<0 or y>=dimensions().y: continue
				var point: Dictionary = {"x":x,"y":y}
				var key: String = Movement.key(point)
				if not area.has_point(center(point)): continue
				if not tile_nodes.has(key):
					var tile_node: Node2D = Node2D.new()
					tile_node.draw.connect(_draw_tile.bind(point,tile_node))
					terrain_layer.add_child(tile_node)
					tile_nodes[key] = tile_node
				# Camera changes can expose tiles created later: keep painter order.
				terrain_layer.move_child(tile_nodes[key],terrain_layer.get_child_count()-1)
				tile_nodes[key].show()
				tile_nodes[key].queue_redraw()
	var marks: Dictionary = {}
	for key: String in available: marks[key] = 1
	for key: String in attackable: marks[key] = int(marks.get(key,0))|2
	for point: Dictionary in affected:
		var key: String = Movement.key(point)
		marks[key] = int(marks.get(key,0))|4
	var cursor_key: String = Movement.key({"x":cursor.x,"y":cursor.y})
	marks[cursor_key] = int(marks.get(cursor_key,0))|8
	for key: String in tile_marks:
		if not marks.has(key) and tile_nodes.has(key): tile_nodes[key].queue_redraw()
	for key: String in marks:
		if marks[key]!=tile_marks.get(key,0) and tile_nodes.has(key): tile_nodes[key].queue_redraw()
	tile_marks = marks

func toggle_camera() -> void:
	camera_mode = not camera_mode
	cancel_pointer()
	camera_mode_changed.emit()

func cancel_pointer() -> void:
	super.cancel_pointer()
	dragging = false

func setup(records: Array) -> void:
	super.setup(records)
	for record: Dictionary in records:
		var identity: int = int(record.id)
		if sprite_bounds.has(identity): continue
		var meta: Dictionary = record.animations.Idle
		var pixels: Image = textures[identity].get_image()
		var bounds: Array = []
		var maximum: Vector2 = Vector2.ZERO
		for row: int in 8:
			for frame: int in int(meta.frames):
				var used: Rect2i = pixels.get_region(Rect2i(frame*int(meta.width),row*int(meta.height),int(meta.width),int(meta.height))).get_used_rect()
				bounds.append(used)
				maximum.x = maxf(maximum.x,used.size.x)
				maximum.y = maxf(maximum.y,used.size.y)
		sprite_bounds[identity] = {"frames":bounds,"maximum":maximum}
		sprite_images[identity] = pixels

func isometric() -> bool:
	return state.get("combatEdition",0)>=11

func play_area() -> Rect2:
	if not isometric(): return super.play_area()
	if state.get("combatEdition",0)>=13: return Rect2(Vector2(24,172),size-Vector2(reserved_right,426+extra_bottom))
	return Rect2(Vector2(24,156),size-Vector2(reserved_right,410+extra_bottom))

func cell_size() -> float:
	return TILE.x*zoom if isometric() else super.cell_size()

func projection(point: Dictionary) -> Vector2:
	return Vector2((point.x-point.y)*TILE.x*0.5,(point.x+point.y)*TILE.y*0.5-Terrain.height_at(state,point)*LIFT)

func center(point: Dictionary) -> Vector2:
	if not isometric(): return super.center(point)
	return play_area().get_center()+(projection(point)-anchor)*zoom

func focus_point(point: Dictionary) -> void:
	manual_camera = true
	anchor = projection(point)
	queue_redraw()

func focus_active() -> void:
	if not isometric() or Rules.active(state).is_empty(): return
	focus_point(Rules.active(state))
	manual_camera = false

func frame_combat() -> void:
	if not isometric(): return
	var units: Array = Rules.living(state)
	if units.is_empty(): return
	var extent: Rect2 = Rect2(projection(units[0]),Vector2.ZERO)
	for unit: Dictionary in units: extent = extent.expand(projection(unit))
	extent = extent.grow(88)
	zoom = clampf(minf(play_area().size.x/extent.size.x,play_area().size.y/extent.size.y),0.65,1.3)
	anchor = extent.get_center()-Vector2(0,18)
	manual_camera = false
	queue_redraw()

func fit_map() -> void:
	if not isometric(): return
	zoom = clampf(minf(play_area().size.x/(dimensions().x*TILE.x),play_area().size.y/(dimensions().y*TILE.y+64)),0.3,1.7)
	anchor = Vector2(0,(dimensions().x-1)*TILE.y*0.5-LIFT)
	manual_camera = true
	queue_redraw()

func change_zoom(factor: float) -> void:
	manual_camera = true
	zoom = clampf(zoom*factor,0.3,1.7)
	queue_redraw()

func pan(delta: Vector2) -> void:
	manual_camera = true
	anchor -= delta/zoom
	anchor.x = clampf(anchor.x,-dimensions().x*TILE.x*0.5,dimensions().x*TILE.x*0.5)
	anchor.y = clampf(anchor.y,-50,dimensions().y*TILE.y)
	queue_redraw()

func track_turn() -> void:
	if not isometric(): return
	var identity: String = state.seed+str(state.mapSize)
	if identity!=encounter_key:
		encounter_key = identity
		tracked = -1
		frame_combat()
	var actor: Dictionary = Rules.active(state)
	if not actor.is_empty() and actor.id!=tracked:
		tracked = int(actor.id)
		cursor = Vector2i(actor.x,actor.y)
		if not manual_camera and follow_camera:
			var screen: Vector2 = center(actor)
			var safe: Rect2 = play_area().grow(-72)
			var desired: Vector2 = screen.clamp(safe.position,safe.end)
			anchor += (screen-desired)/zoom

func diamond(point: Dictionary) -> PackedVector2Array:
	var c: Vector2 = center(point)
	var half: float = cell_size()*0.5
	return PackedVector2Array([c+Vector2(0,-half*TILE.y/TILE.x),c+Vector2(half,0),c+Vector2(0,half*TILE.y/TILE.x),c+Vector2(-half,0)])

func pick(screen: Vector2) -> Dictionary:
	if not play_area().has_point(screen): return {}
	# Feet identify the occupied square even when a tall neighbour overlaps it.
	for unit: Dictionary in state.units:
		if unit.hp>0 and center(unit).distance_to(screen)<cell_size()*0.13: return {"x":unit.x,"y":unit.y}
	if state.get("combatEdition",0)>=13:
		# A tall sprite must not make the centre of a reachable empty tile unclickable.
		for route_entry: Dictionary in available.values():
			var point: Dictionary = route_entry.path.back()
			if center(point).distance_to(screen)<cell_size()*0.1: return {"x":point.x,"y":point.y}
	var ordered: Array = state.units.duplicate()
	ordered.sort_custom(func(a,b):return a.x+a.y>b.x+b.y if a.x+a.y!=b.x+b.y else a.id>b.id)
	for unit: Dictionary in ordered:
		if unit.hp<=0 or not sprite_bounds.has(int(unit.speciesId)): continue
		var visual: Dictionary = sprite_visual(unit)
		if not visual.rect.has_point(screen): continue
		var pixel: Vector2i = Vector2i((screen-visual.rect.position)/visual.factor)+Vector2i(visual.source.position)
		if sprite_images[int(unit.speciesId)].get_pixel(pixel.x,pixel.y).a>0.1: return {"x":unit.x,"y":unit.y}
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
		if camera_mode and event.button_index==MOUSE_BUTTON_LEFT:
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
		if (event.button_mask&MOUSE_BUTTON_MASK_MIDDLE)!=0 or (camera_mode and (event.button_mask&MOUSE_BUTTON_MASK_LEFT)!=0):
			pan(event.relative)
			return
		dragging = false
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var point: Dictionary = pick(event.position)
		if event is InputEventMouseMotion:
			if pointer_down and pointer_start.distance_to(event.position)>=8: pointer_dragged = true
			if not keyboard_control and not camera_mode: tile_hovered.emit(point)
		else: _pointer_click(event,point)
	if event is InputEventKey and event.pressed:
		keyboard_control = true
		if not camera_mode and _orientation_key(event): accept_event(); queue_redraw(); return
		for entry: Array in [["pan_left",Vector2(48,0)],["pan_right",Vector2(-48,0)],["pan_up",Vector2(0,48)],["pan_down",Vector2(0,-48)]]:
			if _pressed(event,entry[0]): pan(entry[1]); accept_event(); return
		if _pressed(event,"camera_mode"): toggle_camera(); accept_event(); return
		var vector: Vector2i = Vector2i.ZERO
		if _pressed(event,"left"): vector = Vector2i.LEFT
		elif _pressed(event,"right"): vector = Vector2i.RIGHT
		elif _pressed(event,"up"): vector = Vector2i.UP
		elif _pressed(event,"down"): vector = Vector2i.DOWN
		elif _pressed(event,"center"): focus_active()
		elif _pressed(event,"grid"): strong_grid = not strong_grid
		elif _pressed(event,"heights"): show_heights = not show_heights
		elif _pressed(event,"zoom_in"): change_zoom(1.12)
		elif _pressed(event,"zoom_out"): change_zoom(1/1.12)
		elif _pressed(event,"accept"):
			if not camera_mode: tile_selected.emit({"x":cursor.x,"y":cursor.y})
		else: return
		if vector!=Vector2i.ZERO:
			if camera_mode: pan(-Vector2(vector)*48); accept_event(); return
			cursor = (cursor+vector).clamp(Vector2i.ZERO,dimensions()-Vector2i.ONE)
			var point: Dictionary = {"x":cursor.x,"y":cursor.y}
			if not play_area().grow(-45).has_point(center(point)): focus_point(point)
			tile_hovered.emit(point)
		accept_event()
		queue_redraw()

func sprite_visual(unit: Dictionary) -> Dictionary:
	var meta: Dictionary = catalog[int(unit.speciesId)].animations.Idle
	var phase: float = fmod(elapsed*60,meta.durations.reduce(func(total,duration):return total+duration,0.0))
	var frame: int = 0
	for duration: float in meta.durations:
		if phase<duration: break
		phase -= duration
		frame += 1
	frame = mini(frame,int(meta.frames)-1)
	var row: int = (int(unit.facing)+7)%8
	var cached: Dictionary = sprite_bounds[int(unit.speciesId)]
	var used: Rect2i = cached.frames[row*int(meta.frames)+frame]
	var large: bool = cached.maximum.y>48
	var factor: float = minf(2.05*zoom,minf(cell_size()*(1.16 if large else 0.65)/maxf(1,cached.maximum.x),cell_size()*(1.40 if large else 0.85)/maxf(1,cached.maximum.y)))
	var foot: Vector2 = center(unit)+Vector2(0,3*zoom)
	var rect: Rect2 = Rect2(foot-Vector2(used.position.x+used.size.x*0.5,used.end.y-1)*factor,Vector2(meta.width,meta.height)*factor)
	return {"rect":rect,"used":Rect2(rect.position+Vector2(used.position)*factor,Vector2(used.size)*factor),"factor":factor,"source":Rect2(frame*meta.width,row*meta.height,meta.width,meta.height)}

func edge_depth(point: Dictionary, vector: Vector2i) -> int:
	var other: Dictionary = {"x":point.x+vector.x,"y":point.y+vector.y}
	if other.x>=dimensions().x or other.y>=dimensions().y: return Terrain.height_at(state,point)+1
	return maxi(0,Terrain.height_at(state,point)-Terrain.height_at(state,other))

func _outline(polygon: PackedVector2Array, color: Color, width: float = 1, canvas: CanvasItem = null) -> void:
	if canvas==null: canvas = self
	var closed: PackedVector2Array = polygon.duplicate()
	closed.append(polygon[0])
	canvas.draw_polyline(closed,color,width,true)

func _tile_color(point: Dictionary) -> Color:
	var tile: int = int(state.board[int(point.y)][int(point.x)])
	var h: int = Terrain.height_at(state,point)
	var color: Color = Color("769264")
	if BIOME_COLORS.has(state.biome): color = Color(BIOME_COLORS[state.biome])
	if state.biome=="legends-birds": color = [Color("a6c8c8"),Color("b2ab7f"),Color("ae8067")][clampi(int((float(point.x)-(state.board.size()-16)/2.0)*3/16.0),0,2)]
	if state.biome=="brock": color = Color("afa78c")
	elif state.biome=="forest": color = Color("628355")
	if tile==1: color = Color("507345")
	elif tile==2: color = Color("667160") if state.biome!="brock" else Color("7c8176")
	elif tile==3: color = Color("548a9a")
	return color.lightened(h*0.065+((int(point.x)+int(point.y))%2)*0.013)

func _draw_tile(point: Dictionary, canvas: CanvasItem) -> void:
	tile_redraws += 1
	var polygon: PackedVector2Array = diamond(point)
	var c: Vector2 = center(point)
	var color: Color = _tile_color(point)
	var height: int = Terrain.height_at(state,point)
	for edge: int in [1,2]:
		var depth: int = edge_depth(point,Vector2i.RIGHT if edge==1 else Vector2i.DOWN)
		if depth==0: continue
		var a: Vector2 = polygon[edge]
		var b: Vector2 = polygon[(edge+1)%4]
		var drop: Vector2 = Vector2(0,depth*LIFT*zoom)
		canvas.draw_colored_polygon(PackedVector2Array([a,b,b+drop,a+drop]),Color("62654d").darkened(0.18 if edge==1 else 0.04))
		canvas.draw_line(a,b,Color("d3c79d"),maxf(1,zoom))
		# Light tread lines identify traversable single-height edges.
		if depth==1:
			for t: float in [0.45,0.85]: canvas.draw_line(a+drop*t,b+drop*t,Color(0.82,0.78,0.61,0.35),1)
		else:
			for t: float in [0.3,0.65]: canvas.draw_line(a.lerp(b,t),a.lerp(b,t)+drop,Color(0.1,0.17,0.12,0.22),1)
	canvas.draw_colored_polygon(polygon,color)
	_outline(polygon,Color(0.11,0.18,0.1,0.38 if strong_grid else 0.13),1,canvas)
	var tile: int = int(state.board[int(point.y)][int(point.x)])
	if tile==1:
		for i: int in 4:
			var offset: Vector2 = Vector2((i%2)*14-9,int(i/2.0)*9-3)*zoom
			canvas.draw_line(c+offset,c+offset+Vector2(-2,-6)*zoom,Color("a0b36a"),zoom)
			canvas.draw_line(c+offset,c+offset+Vector2(3,-4)*zoom,Color("a0b36a"),zoom)
	elif tile==2:
		var stone: PackedVector2Array = PackedVector2Array([c+Vector2(-18,3)*zoom,c+Vector2(-15,-8)*zoom,c+Vector2(-4,-13)*zoom,c+Vector2(14,-8)*zoom,c+Vector2(19,3)*zoom,c+Vector2(5,8)*zoom])
		canvas.draw_colored_polygon(stone,Color("8c9583") if state.biome!="brock" else Color("989d90"))
		canvas.draw_line(stone[1],stone[2],Color("bac1aa"),2*zoom)
		canvas.draw_line(c+Vector2(-2,-8)*zoom,c+Vector2(5,3)*zoom,Color("687361"),zoom)
	elif tile==0 and (int(point.x)*17+int(point.y)*13)%5==0:
		for i: int in 2: canvas.draw_line(c+Vector2(-9+i*14,3-i*7)*zoom,c+Vector2(-6+i*14,3-i*7)*zoom,color.darkened(0.12),zoom)
	var key: String = Movement.key(point)
	if available.has(key):
		canvas.draw_colored_polygon(polygon,Color(0.18,0.58,0.84,0.32))
		_outline(polygon,Color(0.61,0.86,0.95,0.48),1,canvas)
	if attackable.has(key): _outline(polygon,Color("f19a78"),2,canvas)
	if affected.any(func(p):return Movement.same(p,point)):
		canvas.draw_colored_polygon(polygon,Color(0.96,0.46,0.14,0.4))
		_outline(polygon,Color("ffc783"),2,canvas)
	if cursor==Vector2i(point.x,point.y): _outline(polygon,Color("fff1a8"),3,canvas)
	var height_marker: bool = (height==1 and (int(point.x)+int(point.y))%2==0) or (int(point.x)%3==0 and int(point.y)%3==0)
	if show_heights and zoom>=0.8 and tile!=2 and height>0 and height_marker:
		var occupied: bool = state.units.any(func(unit):return unit.hp>0 and Movement.same(unit,point))
		if not occupied: _tag(c+Vector2(0,-2),"H%d" % height,Color("f4e8c4"),11,canvas)

func _unit_order() -> Array:
	var ordered: Array = state.units.filter(func(unit):return unit.hp>0)
	ordered.sort_custom(func(a,b):return a.x+a.y<b.x+b.y if a.x+a.y!=b.x+b.y else a.id<b.id)
	return ordered

func _unit_color(unit: Dictionary) -> Color:
	return Color("64d4d1") if unit.team=="ally" else Color("ed8f74")

func _tag(point: Vector2, text: String, color: Color, font_size: int = 13, canvas: CanvasItem = null) -> void:
	if canvas==null: canvas = self
	var font: Font = get_theme_default_font()
	var width: float = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var rect: Rect2 = Rect2(point-Vector2(width*0.5+5,font_size+1),Vector2(width+10,font_size+6))
	canvas.draw_rect(rect,Color("152c2b"))
	canvas.draw_string(font,point-Vector2(width*0.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw_unit(unit: Dictionary) -> void:
	var c: Vector2 = center(unit)
	var active: bool = not state.queue.is_empty() and unit.id==state.queue[0]
	var color: Color = _unit_color(unit)
	var polygon: PackedVector2Array = diamond(unit)
	for i: int in polygon.size(): polygon[i] = c+(polygon[i]-c)*0.67
	draw_colored_polygon(polygon,Color(color,0.28))
	_outline(polygon,Color("ffe69a") if active else color,3 if active else 2)
	var visual: Dictionary = sprite_visual(unit)
	draw_texture_rect_region(textures[int(unit.speciesId)],visual.rect,visual.source)
	var logical: Vector2 = Vector2(Rules.VECTORS[int(unit.facing)])
	if active and facing_preview>=0: logical = Vector2(Rules.VECTORS[facing_preview])
	var vector: Vector2 = Vector2(logical.x-logical.y,(logical.x+logical.y)*TILE.y/TILE.x).normalized()
	var tip: Vector2 = c+vector*cell_size()*0.35
	var normal: Vector2 = Vector2(-vector.y,vector.x)*4*zoom
	draw_colored_polygon(PackedVector2Array([tip+vector*5*zoom,tip-vector*4*zoom+normal,tip-vector*4*zoom-normal]),Color("ffe69a") if active else color)

func _draw_unit_info(unit: Dictionary) -> void:
	var c: Vector2 = center(unit)
	var color: Color = _unit_color(unit)
	var active: bool = not state.queue.is_empty() and unit.id==state.queue[0]
	var width: float = clampf(cell_size()*0.52,28,58)
	var hp: Rect2 = Rect2(c+Vector2(-width*0.5,cell_size()*0.20),Vector2(width,5))
	draw_rect(hp.grow(1),Color("17312e"))
	draw_rect(Rect2(hp.position,Vector2(width*unit.hp/unit.maxHp,5)),color)
	for hit: Dictionary in forecast_hits:
		if hit.targetId!=unit.id or hit.damage<=0: continue
		var low: int = int(hit.get("damageMin",hit.damage))
		var high: int = mini(unit.hp,maxi(int(hit.get("damageMax",hit.damage)),int(hit.get("criticalMax",0))))
		draw_rect(Rect2(hp.position+Vector2(width*(unit.hp-high)/unit.maxHp,0),Vector2(width*(high-low)/unit.maxHp,5)),Color("bd8d4c"))
		draw_rect(Rect2(hp.position+Vector2(width*(unit.hp-low)/unit.maxHp,0),Vector2(width*low/unit.maxHp,5)),Color("f8c76d"))
	var visual: Dictionary = sprite_visual(unit)
	var top: Vector2 = Vector2(c.x,visual.used.position.y-7)
	if active: _tag(top,"%s · %d/%d" % [unit.name,unit.hp,unit.maxHp],Color("ffe69a"),14)
	elif unit.get("dormant",false): _tag(top,"VIGÍA",Color("eccb7f"),12)
	var badges: Array = Indicators.entries(unit)
	_tag(c+Vector2(0,18),"A" if unit.team=="ally" else "E",Color("ffffff"),12)
	var extra: int = maxi(0,badges.size()-4)
	badges = badges.slice(0,4)
	if extra>0: _tag(c+Vector2(42,-25),"+%d · ficha" % extra,Color("ffffff"),12)
	var base: Vector2 = Vector2(c.x-36,visual.used.position.y-24-(22 if active else 0))
	for i: int in badges.size():
		Indicators.draw_badge(self,Rect2(base+Vector2((i%2)*36,-int(i/2.0)*15),Vector2(34,14)),badges[i],get_theme_default_font(),10,true)

func _draw() -> void:
	terrain_layer.visible = isometric()
	minimap_layer.visible = isometric()
	if not isometric():
		super._draw()
		return
	var started: int = Time.get_ticks_usec() if has_meta("draw_samples") else 0
	_update_terrain()
	var area: Rect2 = play_area()
	for index: int in range(1,route.size()):
		draw_line(center(route[index-1]),center(route[index]),Color("fff1a8"),3,true)
		draw_circle(center(route[index]),3,Color("fff1a8"))
	for field: Dictionary in state.fields: draw_circle(center(field),cell_size()*0.17,Color(0.95,0.3,0.1,0.45))
	var ordered: Array = _unit_order()
	for unit: Dictionary in ordered:
		if area.grow(70).has_point(center(unit)): _draw_unit(unit)
	for unit: Dictionary in ordered:
		if area.grow(70).has_point(center(unit)): _draw_unit_info(unit)
	for rect: Rect2 in [Rect2(0,0,size.x,area.position.y),Rect2(0,area.end.y,size.x,size.y-area.end.y),Rect2(0,area.position.y,area.position.x,area.size.y),Rect2(area.end.x,area.position.y,size.x-area.end.x,area.size.y)]: draw_rect(rect,Color("0d242c"))
	draw_rect(area,Color("567b68"),false,1)
	var font: Font = get_theme_default_font()
	draw_string(font,Vector2(30,area.end.y+23),"%s · altura %d · %d %%" % [Rules.coordinate({"x":cursor.x,"y":cursor.y}),Terrain.height_at(state,{"x":cursor.x,"y":cursor.y}),roundi(zoom*100)],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("eccb7f"))
	var legend: Vector2 = Vector2(area.end.x-268,area.end.y+18)
	for i: int in 3:
		var color: Color = [Color("64d4d1"),Color("ed8f74"),Color("ffe69a")][i]
		var point: Vector2 = legend+Vector2(i*94,0)
		draw_colored_polygon(PackedVector2Array([point+Vector2(0,-5),point+Vector2(7,0),point+Vector2(0,5),point+Vector2(-7,0)]),color)
		draw_string(font,point+Vector2(12,5),["Aliado","Rival","Turno"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("b3c7b1"))
	minimap_layer.queue_redraw()
	if started>0: get_meta("draw_samples").append((Time.get_ticks_usec()-started)/1000.0)

func _draw_minimap_background() -> void:
	var origin: Vector2 = Vector2(size.x-minimap_right,130)
	var factor: float = 108.0/(dimensions().x*TILE.x)
	var shift: Vector2 = origin+Vector2(58,8)
	var region: Rect2 = Rect2(origin,Vector2(116,82))
	minimap_background.draw_rect(region,Color("0d211f"))
	minimap_background.draw_string(get_theme_default_font(),origin+Vector2(0,-6),"VISTA GENERAL",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("a7ba9b"))
	for y: int in dimensions().y:
		for x: int in dimensions().x:
			var point: Dictionary = {"x":x,"y":y}
			var c: Vector2 = shift+projection(point)*factor
			var d: Vector2 = TILE*factor*0.5
			minimap_background.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-d.y),c+Vector2(d.x,0),c+Vector2(0,d.y),c+Vector2(-d.x,0)]),_tile_color(point).darkened(0.25))

func _draw_minimap_overlay() -> void:
	var origin: Vector2 = Vector2(size.x-minimap_right,130)
	var factor: float = 108.0/(dimensions().x*TILE.x)
	var shift: Vector2 = origin+Vector2(58,8)
	var region: Rect2 = Rect2(origin,Vector2(116,82))
	var area: Rect2 = play_area()
	var visible_rect: Rect2 = Rect2(shift+(anchor-area.size/(2*zoom))*factor,area.size/zoom*factor)
	var start: Vector2 = visible_rect.position.clamp(region.position,region.end)
	var end: Vector2 = visible_rect.end.clamp(region.position,region.end)
	minimap_layer.draw_rect(Rect2(start,end-start),Color(0.94,0.95,0.83,0.6),false,1)
	for unit: Dictionary in state.units:
		if unit.hp<=0: continue
		minimap_layer.draw_circle(shift+projection(unit)*factor,3,_unit_color(unit))
