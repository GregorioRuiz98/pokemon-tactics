extends Button

func _ready() -> void:
	# No processing or animation loop: the cursor redraws only on interaction.
	for event: Signal in [focus_entered,focus_exited,mouse_entered,mouse_exited,toggled,button_down,button_up]:
		event.connect(_selection_changed)

func _selection_changed(_pressed: bool = false) -> void:
	queue_redraw()

func _draw() -> void:
	# Fine bevels scale with the control and need no textures or per-frame work.
	var ink: Color = get_theme_color("font_disabled_color" if disabled else "font_color")
	var edge: Color = Color(ink,0.12 if disabled else 0.24)
	if size.x>24 and size.y>24:
		draw_line(Vector2(11,4),Vector2(size.x-7,4),edge,1.0)
		draw_line(Vector2(4,11),Vector2(4,size.y-7),edge,1.0)
		draw_line(Vector2(8,size.y-6),Vector2(size.x-12,size.y-6),Color(0.02,0.05,0.06,0.16),1.0)
	if theme_type_variation not in ["CommandButton","FieldCommandButton"] or disabled: return
	var middle: float = size.y/2.0
	var color: Color = get_theme_color("font_hover_color") if is_hovered() or button_pressed else get_theme_color("font_focus_color")
	if has_focus() or is_hovered() or button_pressed:
		draw_colored_polygon(PackedVector2Array([Vector2(11,middle-6),Vector2(20,middle),Vector2(11,middle+6)]),color)
	else:
		draw_polyline(PackedVector2Array([Vector2(15,middle-4),Vector2(19,middle),Vector2(15,middle+4),Vector2(11,middle),Vector2(15,middle-4)]),Color(color,0.4),1.0,true)
