extends Control

signal tile_selected(point: Dictionary)
signal tile_hovered(point: Dictionary)
signal cancelled
const Rules = preload("res://core/battle.gd")
const Movement = preload("res://core/movement.gd")
var state: Dictionary = {}
var catalog: Dictionary = {}
var textures: Dictionary = {}
var available: Dictionary = {}
var route: Array = []
var affected: Array = []
var attackable: Dictionary = {}
var forecast_hits: Array = []
var facing_preview = -1
var cursor = Vector2i(1, 6)
var reduced_motion = false
var elapsed = 0.0
var redraw_clock = 0.0

func _ready():
	custom_minimum_size = Vector2(360, 360)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_exited.connect(func(): tile_hovered.emit({}))

func setup(records: Array):
	for record in records:
		catalog[int(record.id)] = record
		textures[int(record.id)] = load("res://" + record.animations.Idle.path)

func play_area() -> Rect2:
	# Space inside the game scene reserved for the floating HUD.
	return Rect2(Vector2(24, 124), size - Vector2(332, 378))

func dimensions() -> Vector2i:
	return Vector2i(state.board[0].size(), state.board.size()) if not state.is_empty() else Vector2i(8,8)

func cell_size() -> float:
	return floorf(minf(play_area().size.x / dimensions().x, play_area().size.y / dimensions().y))

func board_origin() -> Vector2:
	return play_area().position + (play_area().size - Vector2(dimensions()) * cell_size()) / 2

func center(point: Dictionary) -> Vector2:
	return board_origin() + Vector2(point.x + 0.5, point.y + 0.5) * cell_size()

func _process(delta):
	if not reduced_motion: elapsed += delta
	redraw_clock += delta
	if redraw_clock >= 1.0 / 20:
		redraw_clock = 0
		queue_redraw()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		cancelled.emit()
		accept_event()
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var local = (event.position - board_origin()) / cell_size()
		var point = Vector2i(floori(local.x), floori(local.y))
		if point.x >= 0 and point.x < dimensions().x and point.y >= 0 and point.y < dimensions().y:
			cursor = point
			if event is InputEventMouseMotion: tile_hovered.emit({"x": point.x, "y": point.y})
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				grab_focus()
				tile_selected.emit({"x": point.x, "y": point.y})
				accept_event()
		elif event is InputEventMouseMotion: tile_hovered.emit({})
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT: cursor.x = maxi(0, cursor.x - 1)
			KEY_RIGHT: cursor.x = mini(dimensions().x - 1, cursor.x + 1)
			KEY_UP: cursor.y = maxi(0, cursor.y - 1)
			KEY_DOWN: cursor.y = mini(dimensions().y - 1, cursor.y + 1)
			KEY_ENTER, KEY_KP_ENTER: tile_selected.emit({"x": cursor.x, "y": cursor.y})
			_: return
		if event.keycode not in [KEY_ENTER, KEY_KP_ENTER]: tile_hovered.emit({"x": cursor.x, "y": cursor.y})
		accept_event()
		queue_redraw()

func _draw():
	if state.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO, size), Color("233c31"))
	var cell = cell_size()
	var origin = board_origin()
	var font = get_theme_default_font()
	draw_style_box(_border(), Rect2(origin - Vector2(3, 3), Vector2(dimensions()) * cell + Vector2.ONE * 6))
	for y in dimensions().y:
		for x in dimensions().x:
			var rect = Rect2(origin + Vector2(x, y) * cell, Vector2.ONE * cell)
			var tile = int(state.board[y][x])
			var color = Color("879d71") if (x + y) % 2 == 0 else Color("81966b")
			if tile == 1: color = Color("536f50")
			elif tile == 2: color = Color("4d5750")
			elif tile == 3: color = Color("568e9c") if (x + y) % 2 == 0 else Color("508794")
			draw_rect(rect, color)
			draw_rect(rect, Color(0.1, 0.2, 0.14, 0.13), false, 1)
			if tile == 1:
				for i in 4:
					var p = rect.position + Vector2(12 + (i % 2) * 21, 18 + (i / 2) * 23)
					draw_line(p, p + Vector2(-3, -7), Color("759365"), 2)
					draw_line(p, p + Vector2(4, -6), Color("759365"), 2)
			elif tile == 2:
				var c = rect.get_center()
				draw_colored_polygon(PackedVector2Array([c + Vector2(-cell * 0.35, cell * 0.2), c + Vector2(-cell * 0.22, -cell * 0.3), c + Vector2(cell * 0.19, -cell * 0.36), c + Vector2(cell * 0.36, cell * 0.22)]), Color("6d766b"))
				draw_line(c + Vector2(-cell * 0.2, -cell * 0.24), c + Vector2(cell * 0.13, -cell * 0.28), Color("959b85"), 3)
			elif tile == 3:
				for i in 2:
					var p = rect.position + Vector2(10, 20 + i * 20)
					draw_line(p, p + Vector2(cell - 20, 0), Color(0.8, 0.92, 0.95, 0.2), 2)
			var key = "%d,%d" % [x, y]
			if available.has(key): draw_rect(rect.grow(-2), Color(0.25, 0.68, 0.86, 0.25))
			if attackable.has(key): draw_rect(rect.grow(-5), Color("e5a182"), false, 2)
			if affected.any(func(point): return point.x == x and point.y == y): draw_rect(rect.grow(-2), Color(1, 0.58, 0.2, 0.4))
	for field in state.fields:
		var c = center(field)
		draw_circle(c, cell * 0.28, Color(0.95, 0.3, 0.1, 0.45))
	for index in range(1, route.size()): draw_line(center(route[index - 1]), center(route[index]), Color("f3d286"), 4)
	for unit in state.units:
		if unit.hp <= 0: continue
		var c = center(unit)
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
		var scale = minf(1.65, cell / 36.0)
		var texture = textures[int(unit.speciesId)]
		var point = c + Vector2(0, cell * 0.13)
		var destination = Rect2(point - Vector2(meta.anchorX, meta.anchorY) * scale, Vector2(meta.width, meta.height) * scale)
		draw_texture_rect_region(texture, destination, Rect2(frame * meta.width, unit.facing * meta.height, meta.width, meta.height))
		var hp_rect = Rect2(c + Vector2(-cell * 0.3, cell * 0.34), Vector2(cell * 0.6, 5))
		draw_rect(hp_rect, Color("22372b"))
		draw_rect(Rect2(hp_rect.position, Vector2(hp_rect.size.x * unit.hp / unit.maxHp, 5)), color)
		for hit in forecast_hits:
			if hit.targetId != unit.id or hit.damage <= 0: continue
			var remaining = maxi(0, int(unit.hp - hit.damage))
			draw_rect(Rect2(hp_rect.position + Vector2(hp_rect.size.x * remaining / unit.maxHp, 0), Vector2(hp_rect.size.x * (unit.hp - remaining) / unit.maxHp, 5)), Color("f0b66a"))
			draw_string(font, c + Vector2(-cell * 0.3, cell * 0.65), "−%d · %d%%" % [hit.damage, hit.accuracy], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff0ca"))
		var facing_vector = Vector2(Rules.VECTORS[int(unit.facing)])
		var arrow = c + facing_vector * cell * 0.37
		draw_line(arrow - facing_vector * 5, arrow + facing_vector * 2, Color("f8edce"), 2)
		if active:
			var top = c - Vector2(0, cell * 0.44)
			draw_colored_polygon(PackedVector2Array([top + Vector2(-5, -5), top + Vector2(5, -5), top + Vector2(0, 2)]), Color("f3d286"))
			if facing_preview >= 0:
				var vector = Vector2(Rules.VECTORS[facing_preview])
				draw_line(c, c + vector * cell * 0.65, Color("f3d286"), 4)
		if unit.status != null: draw_circle(c + Vector2(cell * 0.28, -cell * 0.25), 4, Color("e9c2f1"))
	var cursor_rect = Rect2(origin + Vector2(cursor) * cell + Vector2(2, 2), Vector2.ONE * (cell - 4))
	draw_rect(cursor_rect, Color("f3d286"), false, 2)
	for index in dimensions().x:
		draw_string(font, origin + Vector2(index * cell + cell * 0.45, -5), String.chr(65 + index), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d0d8bd"))
	for index in dimensions().y:
		draw_string(font, origin + Vector2(-13, index * cell + cell * 0.6), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d0d8bd"))

func _border() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("1b3026")
	return style
