extends Node

# A child belongs to its Window's viewport; the Window node itself belongs to
# its parent's viewport. This also exercises native windows with push_input.
var handler: Callable

func _input(event: InputEvent) -> void:
	if handler.is_valid(): handler.call(event)
