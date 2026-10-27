extends "res://ui/climate_board.gd"

const Labels = preload("res://ui/unit_labels.gd")
var unit_labels: Dictionary = {}

func _draw() -> void:
	unit_labels = Labels.layout(self)
	super._draw()

func _draw_unit_info(unit: Dictionary) -> void:
	if not isometric(): super._draw_unit_info(unit); return
	Labels.draw(self,unit,unit_labels)
