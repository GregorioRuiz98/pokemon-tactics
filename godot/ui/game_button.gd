extends Button

func _ready() -> void:
	# No processing or animation loop: the cursor redraws only on interaction.
	for event: Signal in [focus_entered,focus_exited,mouse_entered,mouse_exited,toggled]:
		event.connect(_selection_changed)

func _selection_changed(_pressed: bool = false) -> void:
	queue_redraw()

func _draw() -> void:
	if theme_type_variation not in ["CommandButton","FieldCommandButton"] or disabled: return
	if not has_focus() and not is_hovered() and not button_pressed: return
	var middle: float = size.y/2.0
	var color: Color = get_theme_color("font_hover_color") if is_hovered() or button_pressed else get_theme_color("font_focus_color")
	draw_colored_polygon(PackedVector2Array([Vector2(11,middle-6),Vector2(20,middle),Vector2(11,middle+6)]),color)
