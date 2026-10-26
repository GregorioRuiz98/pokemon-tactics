extends "res://ui/artwork_slot.gd"

const Landscape = preload("res://core/kanto_landscape.gd")
const Props = preload("res://ui/kanto_props.gd")
var location: String = ""

func _ready() -> void:
	super._ready()
	Landscape.ensure_loaded()

func _draw() -> void:
	if location.is_empty() or not Landscape.layouts.has(location): super._draw(); return
	var design: Dictionary = Landscape.layouts[location]
	var map: Dictionary = design.maps["16"]
	var paint: Color = Color(preload("res://ui/kanto_board.gd").PALETTE.get(design.material,"8ca56c"))
	draw_rect(Rect2(Vector2.ZERO,size),paint.darkened(.7))
	var origin: Vector2 = Vector2(size.x*.55,14)
	var scale_factor: float = .21
	for sum_value: int in 31:
		for x: int in 16:
			var y: int = sum_value-x
			if y<0 or y>=16: continue
			var at: Vector2 = origin+Vector2((x-y)*40,(x+y)*24-int(map.heights[y][x])*12)*scale_factor
			var c: Color = paint.lightened(.08 if "%d,%d"%[x,y] in map.paths else 0.0)
			if int(map.board[y][x])==3: c = Color("649ead")
			draw_colored_polygon(PackedVector2Array([at+Vector2(0,-5),at+Vector2(8.4,0),at+Vector2(0,5),at+Vector2(-8.4,0)]),c)
			var key: String = "%d,%d"%[x,y]
			if map.props.has(key): draw_texture_rect_region(Props.texture(),Props.rect(at,map.props[key],scale_factor),Props.region(map.props[key]))
	# Decorative map preview is not focusable and does not consume game RNG.
