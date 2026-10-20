extends ConfirmationDialog

var app: Control
var content: Label
var callback: Callable

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
	content = app._label("",18)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	confirmed.connect(func():
		hide()
		var action: Callable = callback
		callback = Callable()
		if action.is_valid(): action.call())

func review(label: String, text: String, action: Callable) -> void:
	title = label
	content.text = text
	callback = action
	popup_centered(Vector2i(700,540))
	app._apply_preferences()
