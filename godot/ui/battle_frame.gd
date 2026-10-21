extends Control

var field: Rect2
var dock_height: float = 204
var contrast: bool = false

func configure(area: Rect2, height: float, high_contrast: bool) -> void:
	if field==area and dock_height==height and contrast==high_contrast: return
	field = area
	dock_height = height
	contrast = high_contrast
	queue_redraw()

func _draw() -> void:
	var ink: Color = Color.BLACK if contrast else Color("102632")
	var edge: Color = Color.WHITE if contrast else Color("728982")
	var top: float = size.y-dock_height
	draw_rect(Rect2(0,top,size.x,dock_height),ink)
	draw_line(Vector2(18,top),Vector2(size.x-18,top),edge,1)
	draw_line(Vector2(18,top),Vector2(126,top),Color("f0c568") if not contrast else edge,3)
	if field.has_area(): draw_rect(field.grow(1),edge,false,1)
