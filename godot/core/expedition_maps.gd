extends RefCounted

const Original = preload("res://core/scale_maps.gd")

static func layout(biome: String, width: int) -> Dictionary:
	if biome in ["route-1","route-2","forest","brock"]: return Original.layout(biome,width)
	var map: Dictionary = Original.layout("route-1",width)
	var offset: int = int((width-16)/2.0)
	for y: int in width:
		for x: int in width:
			var lx: int = x-offset
			var ly: int = y-offset
			var tile: int = 0
			var height: int = 0
			if x==0 or y==0 or x==width-1 or y==width-1: tile = 2
			elif biome in ["cave","ground","ghost"]:
				if lx in [3,11] and ly in [3,4,9,12]: tile = 2
				if ly<=6: height = 1 if ly==6 else 2
			elif biome in ["water","ice"]:
				if lx in [2,3,11,12] or ly in [2,3]: tile = 3
				if lx>=10 and ly>=9: height = 1
			elif biome in ["ship","rocket","psychic"]:
				if ly in [4,12] and lx in [3,4,10,11]: tile = 2
				if ly<6: height = 1
			elif biome in ["fire","dragon"]:
				if lx in [3,11] and ly in [4,5,12]: tile = 2
				if ly<=5 or lx>=11: height = 1
			else:
				if lx in [3,4,10,11] and ly in range(3,13): tile = 1
				if lx>=11: height = 1
			map.board[y][x] = tile
			map.heights[y][x] = height
	map.enemies = []
	for point: Vector2i in [Vector2i(8,7),Vector2i(9,6),Vector2i(10,4),Vector2i(11,7),Vector2i(10,6),Vector2i(8,4)]: map.enemies.append({"x":point.x+offset,"y":point.y+offset})
	for point: Dictionary in map.allies+map.enemies:
		map.board[int(point.y)][int(point.x)] = 0
		# Keep deployment entrances reachable; heights rise further into each arena.
		map.heights[int(point.y)][int(point.x)] = mini(1,int(map.heights[int(point.y)][int(point.x)]))
	return map
