extends "res://ui/adventure_board.gd"

const Props = preload("res://ui/kanto_props.gd")
const PALETTE: Dictionary = {"meadow":"8ca56c","forest":"6e925c","stone":"b1ab99","rock":"aa9c86","cave":"8d8a89","city":"a8b7b6","bridge":"8caeaa","wood":"ae9271","industrial":"9cabb0","haunted":"9c91aa","psychic":"b49cc0","road":"9da69d","sand":"d0bd8f","water":"a3b6a4","ice":"afc8d0","ruin":"a89c91","league":"b1b6c8","birds":"a3b5ad","origin":"a5a0bd"}
var prop_context: Array = []
var prop_cache: Array = []
var actor_sort_count: int = 0

func _draw_surround(canvas: CanvasItem) -> void:
	if not state.has("landscape"): super._draw_surround(canvas); return
	canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(PALETTE.get(state.landscape.material,"8ca56c")).darkened(.84))

func _draw() -> void:
	super._draw()
	if not state.has("landscape") or not isometric(): return
	var index: int = 0
	for pair: Array in state.get("arena",{}).get("portals",[]):
		var color: Color = Color("dac5ff") if index==0 else Color("9bf2e1")
		var hovered: bool = pair.any(func(p):return int(p.x)==cursor.x and int(p.y)==cursor.y)
		if hovered: draw_dashed_line(center(pair[0]),center(pair[1]),Color(color,.7),2,8)
		for point: Dictionary in pair:
			if play_area().grow(-15).has_point(center(point)): _tag(center(point)+Vector2(0,14),"A" if index==0 else "B",color,12)
		index += 1

func _draw_tile(point: Dictionary, canvas: CanvasItem) -> void:
	super._draw_tile(point,canvas)
	if preload("res://core/restorative_tiles.gd").contains(state,point):
		_outline(diamond(point),Color("a6f5ff"),3,canvas)
		var middle: Vector2 = center(point)
		canvas.draw_circle(middle,9*zoom,Color("164857"))
		canvas.draw_line(middle-Vector2(5,0)*zoom,middle+Vector2(5,0)*zoom,Color("c1fbff"),3*zoom)
		canvas.draw_line(middle-Vector2(0,5)*zoom,middle+Vector2(0,5)*zoom,Color("c1fbff"),3*zoom)
	if not state.has("landscape") or int(state.board[int(point.y)][int(point.x)])!=2: return
	# A visible footprint marks every solid tile, including gaps between border props.
	var polygon: PackedVector2Array = diamond(point)
	canvas.draw_colored_polygon(polygon,Color(.16,.22,.20,.25))
	_outline(polygon,Color("73887b"),maxf(1,zoom),canvas)
	if not state.landscape.props.has(Movement.key(point)):
		# Solid chamber walls must not look like traversable raised floor.
		var top: PackedVector2Array = polygon.duplicate()
		var rise: Vector2 = Vector2(0,22*zoom)
		for i: int in top.size(): top[i] -= rise
		for edge: int in [1,2]:
			canvas.draw_colored_polygon(PackedVector2Array([top[edge],top[(edge+1)%4],polygon[(edge+1)%4],polygon[edge]]),Color("58635c").darkened(.16 if edge==1 else .04))
		canvas.draw_colored_polygon(top,Color("7b8479"))
		_outline(top,Color("a2ad99"),maxf(1,zoom),canvas)
		var c: Vector2 = center(point)-rise
		canvas.draw_polyline(PackedVector2Array([c+Vector2(-11,-2)*zoom,c+Vector2(-3,3)*zoom,c+Vector2(4,-2)*zoom,c+Vector2(11,2)*zoom]),Color("536157"),maxf(1,zoom))

func _floor_identity() -> String:
	if not state.has("landscape"): return super._floor_identity()
	return "floor_"+{"stone":"rock","cave":"rock","city":"industrial","bridge":"wood","road":"industrial","sand":"meadow","ruin":"industrial","water":"meadow"}.get(state.landscape.material,state.landscape.material)

func _tile_color(point: Dictionary) -> Color:
	if not state.has("landscape"): return super._tile_color(point)
	var kind: int = int(state.board[int(point.y)][int(point.x)])
	var color: Color = Color(PALETTE.get(state.landscape.material,"8ca56c"))
	if state.landscape.material=="birds": color = [Color("b7d3da"),Color("bcb58b"),Color("c5987e")][clampi(int((float(point.x)-(state.board.size()-16)/2.0)*3/16.0),0,2)]
	if kind==1: color = color.darkened(.17)
	if kind==3: color = Color("649ead")
	if Movement.key(point) in state.landscape.paths: color = Color("b8a27d") if state.landscape.material in ["forest","meadow","sand","rock"] else color.lightened(.08)
	return color.lightened(Terrain.height_at(state,point)*.035)

func _draw_actors(ordered: Array, area: Rect2) -> void:
	if not state.has("landscape"): super._draw_actors(ordered,area); return
	var context: Array = [state.landscape,anchor,zoom,size,play_area()]
	if context!=prop_context:
		prop_context = context.duplicate(true); prop_cache.clear()
		for key: String in state.landscape.props:
			var xy: PackedStringArray = key.split(",")
			var point: Dictionary = {"x":int(xy[0]),"y":int(xy[1]),"kind":state.landscape.props[key]}
			if area.grow(140).has_point(center(point)): prop_cache.append(point)
	var actors: Array = prop_cache.duplicate()
	actors.append_array(ordered)
	actors.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a.x+a.y!=b.x+b.y: return a.x+a.y<b.x+b.y
		if a.x!=b.x: return a.x<b.x
		return a.has("kind") and not b.has("kind"))
	actor_sort_count += 1
	for actor: Dictionary in actors:
		if not actor.has("kind"):
			if area.grow(70).has_point(center(actor)): _draw_unit(actor)
			continue
		var rect: Rect2 = Props.rect(center(actor),actor.kind,zoom)
		var faded: bool = rect.has_point(center({"x":cursor.x,"y":cursor.y}))
		if not faded:
			for unit: Dictionary in ordered:
				if unit.x+unit.y>=actor.x+actor.y: continue
				if rect.intersects(sprite_visual(unit).used.grow(4)): faded = true; break
		draw_texture_rect_region(Props.texture(),rect,Props.region(actor.kind),Color(1,1,1,.28 if faded else 1.0))
	# Base outlines remain visible on occupied obstacle cells under a canopy.
	var cursor_cell: Dictionary = {"x":cursor.x,"y":cursor.y}
	if int(state.board[cursor.y][cursor.x])==2:
		_outline(diamond(cursor_cell),Color("ffc783"),2)
