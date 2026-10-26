extends ConfirmationDialog

var app: Control
var content: Label
var callback: Callable
var diagram: Control
var diagram_caption: Label

func setup(owner_app: Control) -> void:
	app = owner_app
	theme = app.theme
	ok_button_text = "Aceptar cambio"
	cancel_button_text = "Conservar"
	dialog_close_on_escape = false
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620,400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	content = app._label("",18)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(content)
	diagram = preload("res://ui/move_diagram.gd").new()
	column.add_child(diagram)
	diagram_caption = app._label("U: usuario · X: efecto",16)
	column.add_child(diagram_caption)
	confirmed.connect(func():
		hide()
		var action: Callable = callback
		callback = Callable()
		if action.is_valid(): action.call())

func review(label: String, text: String, action: Callable, definition: Dictionary = {}) -> void:
	title = label
	content.text = text
	callback = action
	diagram.visible = definition.has("shape")
	diagram_caption.visible = diagram.visible
	if diagram.visible: diagram.configure(definition)
	ok_button_text = "Confirmar" if action.is_valid() else "Volver"
	get_cancel_button().visible = action.is_valid()
	popup_centered(Vector2i(700,540))
	app._apply_preferences()
