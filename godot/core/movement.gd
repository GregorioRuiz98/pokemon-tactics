class_name LabMovement
extends RefCounted

# A* ordering adapted from EasyStar 0.4.4 and heap.js 0.2.6, to preserve
# equal-cost path/facing decisions during the port. Licenses are in res://licenses.
static func key(point: Dictionary) -> String:
	return "%d,%d" % [point.x, point.y]

static func same(a: Dictionary, b: Dictionary) -> bool:
	return a.x == b.x and a.y == b.y

static func distance(a: Dictionary, b: Dictionary) -> int:
	return absi(int(a.x - b.x)) + absi(int(a.y - b.y))

static func facing_from(a: Dictionary, b: Dictionary) -> int:
	var dx = b.x - a.x
	var dy = b.y - a.y
	return (2 if dx > 0 else 6) if abs(dx) >= abs(dy) and dx != 0 else (4 if dy < 0 else 0)

static func tile_cost(board: Array, point: Dictionary, profile: String = "ground") -> float:
	var x = int(point.x)
	var y = int(point.y)
	if x != point.x or y != point.y or y < 0 or y >= board.size() or x < 0 or x >= board[y].size():
		return INF
	match int(board[y][x]):
		0: return 1.0
		1: return 1.0 if profile in ["grass", "fly"] else 2.0
		3: return 1.0 if profile in ["swim", "fly"] else INF
	return INF

static func _score(node: Dictionary) -> float:
	return node.cost + node.estimate

static func _down(heap: Array, start: int, pos: int) -> void:
	var item = heap[pos]
	while pos > start:
		var parent_pos = (pos - 1) >> 1
		if _score(item) >= _score(heap[parent_pos]): break
		heap[pos] = heap[parent_pos]
		pos = parent_pos
	heap[pos] = item

static func _up(heap: Array, pos: int) -> void:
	var start = pos
	var item = heap[pos]
	var child = 2 * pos + 1
	while child < heap.size():
		var right = child + 1
		if right < heap.size() and _score(heap[child]) >= _score(heap[right]): child = right
		heap[pos] = heap[child]
		pos = child
		child = 2 * pos + 1
	heap[pos] = item
	_down(heap, start, pos)

static func _path(board: Array, actor: Dictionary, destination: Dictionary, blocked: Dictionary) -> Array:
	var start = {"x": actor.x, "y": actor.y, "cost": 0.0, "estimate": distance(actor, destination), "parent": null, "listed": false}
	var nodes = {key(actor): start}
	var heap = [start]
	while not heap.is_empty():
		var last = heap.pop_back()
		var current = last
		if not heap.is_empty():
			current = heap[0]
			heap[0] = last
			_up(heap, 0)
		if same(current, destination):
			var result = []
			while current != null:
				result.push_front({"x": current.x, "y": current.y})
				current = current.parent
			return result
		current.listed = true
		for vector in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var point = {"x": current.x + vector.x, "y": current.y + vector.y}
			var cost = tile_cost(board, point, actor.get("profile", "ground"))
			if is_inf(cost) or blocked.has(key(point)): continue
			var identity = key(point)
			if not nodes.has(identity):
				nodes[identity] = {"x": point.x, "y": point.y, "cost": current.cost + cost, "estimate": distance(point, destination), "parent": current, "listed": false}
			var node = nodes[identity]
			if not node.listed:
				node.listed = true
				heap.append(node)
				_down(heap, 0, heap.size() - 1)
			elif current.cost + cost < node.cost:
				node.cost = current.cost + cost
				node.parent = current
				var pos = heap.find(node)
				if pos >= 0:
					_down(heap, 0, pos)
					_up(heap, pos)
	return []

static func routes(board: Array, units: Array, actor: Dictionary) -> Dictionary:
	var result = {}
	var occupied = {}
	var blocked = {}
	for unit in units:
		if unit.id == actor.id: continue
		occupied[key(unit)] = true
		if unit.team != actor.team: blocked[key(unit)] = true
	for y in board.size():
		for x in board[y].size():
			var point = {"x": x, "y": y}
			if is_inf(tile_cost(board, point, actor.profile)) or occupied.has(key(point)): continue
			var route = [{"x": x, "y": y}] if same(actor, point) else _path(board, actor, point, blocked)
			if route.is_empty(): continue
			var cost = 0.0
			for step in route.slice(1): cost += tile_cost(board, step, actor.profile)
			result[key(point)] = {"path": route, "cost": cost}
	return result
