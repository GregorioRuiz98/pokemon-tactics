extends Control

var mask: Dictionary = {}

func configure(definition: Dictionary) -> void:
	mask = preload("res://ui/move_info.gd").diagram(definition)
	custom_minimum_size = Vector2(140,140)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	accessibility_name = "Ejemplo de área: "+preload("res://ui/move_info.gd").area(definition)+". U: usuario; X: casillas afectadas. El tablero muestra el alcance real."
	queue_redraw()

func _draw() -> void:
	if mask.is_empty(): return
	var side: float = minf(24,minf(size.x,size.y)/7)
	for y: int in 7:
		for x: int in 7:
			var hit: bool = mask.tiles.any(func(p):return int(p.x)==x and int(p.y)==y)
			var actor: bool = int(mask.actor.x)==x and int(mask.actor.y)==y
			var rect: Rect2 = Rect2(Vector2(x,y)*side,Vector2.ONE*(side-2))
			draw_rect(rect,Color("ebc777") if actor else Color("87c7dc") if hit else Color("273d46"))
			if actor or hit: draw_string(get_theme_default_font(),rect.position+Vector2(4,side-6),"U" if actor else "X",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("10252c"))
