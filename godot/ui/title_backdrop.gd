extends Control

# Decorative, deterministic diorama. Draws original local sprite sheets unchanged.
var creatures: Dictionary = {}

func setup(records: Array) -> void:
	for record: Dictionary in records:
		if int(record.id) in [1,4,7,25]:
			var texture: Texture2D = load("res://"+record.animations.Idle.path)
			var frame: Rect2i = Rect2i(0,0,int(record.animations.Idle.width),int(record.animations.Idle.height))
			var used: Rect2i = texture.get_image().get_region(frame).get_used_rect()
			creatures[int(record.id)] = {"texture":texture,"region":Rect2(used)}
	resized.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func tile(x: int, y: int) -> Vector2:
	var scale_factor: float = minf(size.x/1280.0,size.y/900.0)
	return Vector2(size.x*0.73,size.y*0.42)+Vector2((x-y)*35,(x+y)*18)*scale_factor

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0d242c"))
	var s: float = minf(size.x/1280.0,size.y/900.0)
	var ridge: PackedVector2Array = PackedVector2Array([Vector2(size.x*0.40,size.y),Vector2(size.x*0.40,size.y*0.65),Vector2(size.x*0.53,size.y*0.38),Vector2(size.x*0.64,size.y*0.52),Vector2(size.x*0.79,size.y*0.23),Vector2(size.x,size.y*0.53),size])
	draw_colored_polygon(ridge,Color("13333c"))
	for y: int in 9:
		for x: int in 9:
			var p: Vector2 = tile(x,y)
			var top: PackedVector2Array = PackedVector2Array([p+Vector2(0,-18)*s,p+Vector2(35,0)*s,p+Vector2(0,18)*s,p+Vector2(-35,0)*s])
			if x==8 or y==8:
				draw_colored_polygon(PackedVector2Array([top[1],top[2],top[3],top[3]+Vector2(0,26)*s,top[2]+Vector2(0,26)*s,top[1]+Vector2(0,26)*s]),Color("33443b"))
			var path: bool = y in [4,5] or x==4
			var color: Color = Color("a69b71") if path else (Color("527458") if (x+y)%2==0 else Color("597b5c"))
			draw_colored_polygon(top,color)
			if not path and (x*3+y*5)%4==0:
				for k: int in 3: draw_line(p+Vector2(k*7-7,1)*s,p+Vector2(k*7-10,-6)*s,Color("80966b"),2*s)
	for p: Vector2i in [Vector2i(0,1),Vector2i(1,0),Vector2i(6,0),Vector2i(8,1),Vector2i(0,7),Vector2i(8,7)]:
		var foot: Vector2 = tile(p.x,p.y)
		draw_rect(Rect2(foot+Vector2(-4,-24)*s,Vector2(8,24)*s),Color("6a6448"))
		for level: int in 3:
			var c: Vector2 = foot+Vector2(0,-22-level*15)*s
			var half: float = (28-level*5)*s
			draw_colored_polygon(PackedVector2Array([c+Vector2(-half,0),c+Vector2(-half,-8*s),c+Vector2(0,-26*s),c+Vector2(half,-8*s),c+Vector2(half,0)]),Color("284e42").lightened(level*0.04))
	for entry: Array in [[1,3,5],[4,6,4],[7,5,7],[25,4,2]]:
		if not creatures.has(entry[0]): continue
		var record: Dictionary = creatures[entry[0]]
		var foot: Vector2 = tile(entry[1],entry[2])
		draw_rect(Rect2(foot+Vector2(-14,-2)*s,Vector2(28,6)*s),Color(0.04,0.14,0.16,0.35))
		var dimensions: Vector2 = record.region.size*2.2*s
		draw_texture_rect_region(record.texture,Rect2(foot-Vector2(dimensions.x/2,dimensions.y),dimensions),record.region)
	draw_line(Vector2(48,size.y-72),Vector2(size.x-48,size.y-72),Color("35505a"),1)
