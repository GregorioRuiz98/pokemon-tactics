extends "res://ui/review_board.gd"

var relief_identity: String = ""
var faded_props: int = 0

func elevation_lift() -> float:
	return 20.0 if state.has("relief") else super.elevation_lift()

func cliff_color(_point: Dictionary, edge: int) -> Color:
	if not state.has("relief"): return super.cliff_color(_point,edge)
	return Color(state.relief.palette[1]).darkened(.16 if edge==1 else .02)

func _update_terrain() -> void:
	var identity: String = state.get("relief",{}).get("id","")
	if identity!=relief_identity:
		relief_identity = identity; invalidate_terrain(); prop_context.clear()
	super._update_terrain()

func _tile_color(point: Dictionary) -> Color:
	if not state.has("relief"): return super._tile_color(point)
	var color: Color = Color(state.relief.palette[0])
	var tile: int = int(state.board[int(point.y)][int(point.x)])
	var offset: int = int((int(state.mapSize)-16)/2.0)
	if state.relief.motif=="sectors": color = [Color("a4d3df"),Color("c5b46a"),Color("c08464")][clampi(int((float(point.x)-offset)*3/16),0,2)]
	if tile==3: return Color("568a9e") if state.relief.motif!="ice" else Color("6b9ead")
	if tile==2: return color.darkened(.15)
	if tile==1: color = color.darkened(.19)
	if Movement.key(point) in state.landscape.paths:
		color = color.lerp(Color("c3ad81"),.64) if state.landscape.material in ["meadow","forest"] else color.lightened(.15)
	return color.lightened(Terrain.height_at(state,point)*.045)

func _draw_tile(point: Dictionary, canvas: CanvasItem) -> void:
	super._draw_tile(point,canvas)
	if not state.has("relief"): return
	var c: Vector2 = center(point)
	var tile: int = int(state.board[int(point.y)][int(point.x)])
	var motif: String = state.relief.motif
	if tile==3:
		for i: int in 2: canvas.draw_line(c+Vector2(-13+i*8,-3+i*6)*zoom,c+Vector2(4+i*8,-3+i*6)*zoom,Color(.7,.9,.95,.35),maxf(1,zoom))
		return
	if tile==2: return
	var on_path: bool = Movement.key(point) in state.landscape.paths
	var ink: Color = Color(.95,.93,.79,.35)
	if motif in ["bridge","deck"] and on_path:
		for i: int in 4: canvas.draw_line(c+Vector2(-22+i*9,-10+i*5)*zoom,c+Vector2(-6+i*9,-19+i*5)*zoom,Color(.28,.22,.16,.45),maxf(1,zoom))
	elif motif in ["circuit","road"] and on_path:
		canvas.draw_line(c+Vector2(-21,-9)*zoom,c+Vector2(21,9)*zoom,Color(.8,.85,.5,.55),2*zoom)
		if int(point.x+point.y)%3==0: canvas.draw_circle(c,3*zoom,Color(.85,.94,.86,.7))
	elif motif in ["flowers","grove","fields"] and not on_path:
		for i: int in 3:
			var pos: Vector2 = c+Vector2(-12+i*12,(i%2)*6-3)*zoom
			canvas.draw_line(pos,pos-Vector2(0,5)*zoom,Color(.25,.4,.2,.55),zoom)
			if motif=="flowers": canvas.draw_circle(pos-Vector2(0,5)*zoom,2*zoom,Color(.95,.74,.68,.65))
	elif motif in ["fossil","rune","tombs","dojo","crown","gates","ruins","ice","magma","sectors"] and int(point.x+point.y)%3==0:
		var radius: float = 9*zoom
		if motif in ["rune","crown","sectors"]: canvas.draw_arc(c,radius,0,TAU,12,ink,zoom)
		elif motif in ["fossil","ice","magma"]:
			canvas.draw_polyline(PackedVector2Array([c+Vector2(-13,-3)*zoom,c+Vector2(-3,3)*zoom,c+Vector2(2,-4)*zoom,c+Vector2(12,1)*zoom]),Color(.98,.52,.24,.45) if motif=="magma" else ink,zoom)
		else: canvas.draw_line(c-Vector2(11,0)*zoom,c+Vector2(11,0)*zoom,ink,zoom)
	# Stair treads on the actual lower cell of a traversable rise.
	if on_path:
		for vector: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next: Dictionary = {"x":int(point.x)+vector.x,"y":int(point.y)+vector.y}
			if next.x<0 or next.y<0 or next.x>=dimensions().x or next.y>=dimensions().y: continue
			if int(state.board[int(next.y)][int(next.x)]) in [2,3] or Terrain.height_at(state,next)-Terrain.height_at(state,point)!=1: continue
			var direction: Vector2 = (center(next)-c).normalized()
			var normal: Vector2 = Vector2(-direction.y,direction.x)*9*zoom
			for step: int in 3:
				var middle: Vector2 = c+direction*(5+step*4)*zoom
				canvas.draw_line(middle-normal,middle+normal,Color(.95,.9,.7,.75),maxf(1,zoom))

func _draw_actors(ordered: Array, area: Rect2) -> void:
	if not state.has("relief"): super._draw_actors(ordered,area); return
	var context: Array = [state.landscape,anchor,zoom,size,play_area()]
	if context!=prop_context:
		prop_context = context.duplicate(true); prop_cache.clear()
		for key: String in state.landscape.props:
			var xy: PackedStringArray = key.split(",")
			var point: Dictionary = {"x":int(xy[0]),"y":int(xy[1]),"kind":state.landscape.props[key]}
			if area.grow(180).has_point(center(point)): prop_cache.append(point)
	var actors: Array = prop_cache.duplicate(); actors.append_array(ordered)
	actors.sort_custom(func(a,b):return a.x+a.y<b.x+b.y if a.x+a.y!=b.x+b.y else a.x<b.x if a.x!=b.x else a.has("kind") and not b.has("kind"))
	faded_props = 0; actor_sort_count += 1
	for actor: Dictionary in actors:
		if not actor.has("kind"):
			if area.grow(70).has_point(center(actor)): _draw_unit(actor)
			continue
		var scale_factor: float = 1.45 if Movement.same(actor,state.relief.landmarkCell) else 1.0
		var rect: Rect2 = Props.rect(center(actor),actor.kind,zoom*scale_factor)
		var faded: bool = rect.has_point(center({"x":cursor.x,"y":cursor.y}))
		for unit: Dictionary in ordered:
			if unit.x+unit.y<actor.x+actor.y and rect.intersects(sprite_visual(unit).used.grow(6)): faded = true
		if faded: faded_props += 1
		draw_texture_rect_region(Props.texture(),rect,Props.region(actor.kind),Color(1,1,1,.22 if faded else 1.0))
	var cell: Dictionary = {"x":cursor.x,"y":cursor.y}
	if int(state.board[cursor.y][cursor.x])==2: _outline(diamond(cell),Color("ffc783"),2)
