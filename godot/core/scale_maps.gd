extends RefCounted

# Hand-authored tactical layouts on the existing terrain vocabulary, no new art.
# Padding differs; deployment/contact distances stay comparable at both sizes.
static func layout(biome: String, width: int) -> Dictionary:
	var board: Array = []
	var heights: Array = []
	var offset: int = int((width-16)/2.0)
	for y: int in width:
		var row: Array = []
		var levels: Array = []
		for x: int in width:
			var lx: int = x-offset
			var ly: int = y-offset
			var tile: int = 0
			var elevation: int = 0
			if x==0 or y==0 or x==width-1 or y==width-1: tile = 2
			if biome=="route-1":
				if lx in [2,3,10,11] and ly>2 and ly<13: tile = 1
				if lx>=9 and ly<=8: elevation = 1 if lx==9 else 2
			elif biome=="route-2":
				if lx in [2,3,11,12] and ly in range(3,13): tile = 1
				if lx==6 and ly in [3,4,5,12,13]: tile = 2
				if ly<6: elevation = 1 if ly==5 else 2
			elif biome=="forest":
				if (lx+ly)%4==0 and lx in range(2,14) and ly in range(2,14): tile = 1
				if lx in [3,11] and ly in [3,4,5,10,11,12]: tile = 2
				if lx>=9: elevation = 1 if lx==9 else 2
			else:
				if lx in [2,3,11,12] and ly in [3,4,10,11]: tile = 2
				if ly<=6: elevation = 1 if ly==6 else 2
			row.append(tile)
			levels.append(elevation)
		board.append(row)
		heights.append(levels)
	var allies: Array = []
	for point: Vector2i in [Vector2i(5,10),Vector2i(4,11),Vector2i(6,11),Vector2i(4,10),Vector2i(6,10),Vector2i(5,11)]:
		allies.append({"x":point.x+offset,"y":point.y+offset})
	var enemies: Array = []
	for point: Vector2i in [Vector2i(8,7),Vector2i(9,6),Vector2i(10,4)]:
		enemies.append({"x":point.x+offset,"y":point.y+offset})
	return {"board":board,"heights":heights,"allies":allies,"enemies":enemies}
