extends Control

# Presentation only: sprites and styles are cached; inspection never touches rules/RNG.
const Info = preload("res://ui/move_info.gd")
const COLORS: Dictionary = {"normal":"9a9d91","fire":"f58a45","water":"62a5ef","electric":"edca43","grass":"85b953","ice":"7dcac4","fighting":"d56668","poison":"b17ac5","ground":"c7a366","flying":"a59bdf","psychic":"ed7a9f","bug":"a2b947","rock":"bcab78","ghost":"9680bb","dragon":"8885d6","dark":"948781","steel":"91afb5","fairy":"e8a4d4"}
static var textures: Dictionary = {}
static var styles: Dictionary = {}
var move_type: String = ""
var category: String = ""

static func texture(group: String, identity: String) -> Texture2D:
	var key: String = group+"/"+identity
	if not textures.has(key):
		var path: String = "res://assets/ui-symbols/"+key+".png"
		textures[key] = load(path) if ResourceLoader.exists(path) else null
	return textures[key]

static func type_color(identity: String) -> Color:
	return Color(COLORS.get(identity,"9aafba"))

static func type_name(definition: Dictionary) -> String:
	return "Sin tipo" if definition.get("id","")=="basic" else Info.TYPES.get(definition.get("type",""),"Sin tipo")

static func caption(definition: Dictionary) -> String:
	return type_name(definition)+" · "+Info.CATEGORIES.get(definition.get("category",""),"—")

static func decorate(button: Button, definition: Dictionary) -> void:
	var symbols: Control = load("res://ui/move_symbols.gd").new()
	symbols.name = "MoveSymbols"
	symbols.move_type = "" if definition.get("id","")=="basic" else definition.get("type","")
	symbols.category = definition.get("category","")
	symbols.mouse_filter = Control.MOUSE_FILTER_IGNORE
	symbols.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	symbols.offset_left = 26 if button.theme_type_variation=="CommandButton" else 12
	symbols.offset_right = symbols.offset_left+32
	button.add_child(symbols)
	button.set_meta("move_type",symbols.move_type)
	button.set_meta("move_category",symbols.category)
	button.custom_minimum_size.y = maxf(68,button.custom_minimum_size.y)
	for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var source: StyleBox = button.get_theme_stylebox(state)
		var key: String = str(source.get_instance_id())+"/"+str(symbols.offset_right)
		if not styles.has(key):
			var style: StyleBox = source.duplicate()
			style.content_margin_left = symbols.offset_right+12
			if style is StyleBoxFlat and not style.has_meta("base_bg"):
				style.set_meta("base_bg",style.bg_color); style.set_meta("base_border",style.border_color)
			styles[key] = style
		button.add_theme_stylebox_override(state,styles[key])

static func refresh_command_skin(button: Button) -> void:
	# The campaign changes the variation after the shared laboratory builds icons.
	# Rebase its margin overrides on the white field theme, once per new button.
	if button.has_meta("field_skin"): return
	button.set_meta("field_skin",true)
	var symbols: Control = button.get_node_or_null("MoveSymbols")
	if symbols==null: return
	symbols.offset_left = 26; symbols.offset_right = 58
	for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		button.remove_theme_stylebox_override(state)
		var source: StyleBox = button.get_theme_stylebox(state)
		var key: String = "field/"+str(source.get_instance_id())
		if not styles.has(key):
			var style: StyleBoxFlat = source.duplicate()
			style.content_margin_left = 70
			style.set_meta("base_bg",style.get_meta("base_bg",style.bg_color))
			style.set_meta("base_border",style.get_meta("base_border",style.border_color))
			styles[key] = style
		button.add_theme_stylebox_override(state,styles[key])

static func apply_contrast(enabled: bool) -> void:
	for style: StyleBox in styles.values():
		if not style is StyleBoxFlat: continue
		var background: Color = Color.BLACK if enabled else style.get_meta("base_bg")
		var border: Color = Color.WHITE if enabled else style.get_meta("base_border")
		if style.bg_color!=background: style.bg_color = background
		if style.border_color!=border: style.border_color = border

static func badge(group: String, identity: String, label_text: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("192f3b")
	style.border_color = type_color(identity) if group=="types" else Color("9aafba")
	style.set_border_width_all(1); style.set_corner_radius_all(7)
	style.content_margin_left = 8; style.content_margin_right = 10
	style.content_margin_top = 5; style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel",style)
	var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation",7); panel.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.texture = texture(group,identity)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(26,26)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(icon)
	var text: Label = Label.new(); text.text = label_text
	text.add_theme_font_size_override("font_size",16); text.add_theme_color_override("font_color",Color("fff6df"))
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(text)
	return panel

static func type_badges(parent: Node, types: Array) -> void:
	var row: HFlowContainer = HFlowContainer.new(); parent.add_child(row)
	for identity: String in types:
		row.add_child(badge("types",identity,Info.TYPES.get(identity,identity)))

func _draw() -> void:
	var midpoint: float = size.y/2.0
	var type_icon: Texture2D = texture("types",move_type) if not move_type.is_empty() else null
	if type_icon!=null:
		draw_texture_rect(type_icon,Rect2(0,midpoint-25,32,32),false)
	else:
		draw_circle(Vector2(16,midpoint-9),14,Color("344b58"))
		draw_line(Vector2(10,midpoint-9),Vector2(22,midpoint-9),Color("e4e9e7"),2,true)
	var category_icon: Texture2D = texture("categories",category) if not category.is_empty() else null
	if category_icon!=null:
		var height: float = 28.0*category_icon.get_height()/category_icon.get_width()
		draw_rect(Rect2(0,midpoint+9,32,height+4),Color("f1e9d2"))
		draw_texture_rect(category_icon,Rect2(2,midpoint+11,28,height),false)
	if get_parent() is BaseButton and get_parent().disabled: modulate.a = .55
