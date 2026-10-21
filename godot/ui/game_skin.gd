extends RefCounted

# A shared native skin: ink frames, paper choices and the amber selection cursor.
# All controls remain real Godot buttons, including focus and accessibility.
const INK = Color("142a36")
const PAPER = Color("f1e9d2")
const AMBER = Color("f0c568")
const TYPES: Array[String] = ["Button","OptionButton","MenuButton","CommandButton","FieldCommandButton","PrimaryButton","ToolButton","TabButton"]

static func panel(accent: Color = AMBER) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("162e3b")
	box.border_color = Color("6f8586")
	box.set_border_width_all(1)
	box.border_width_top = 3
	box.border_color = accent.darkened(0.22)
	box.corner_radius_top_left = 3
	box.corner_radius_bottom_right = 12
	box.set_content_margin_all(14)
	box.shadow_color = Color(0.015,0.035,0.05,0.4)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0,3)
	return box

static func install(skin: Theme) -> void:
	for kind: String in TYPES:
		if kind not in ["Button","OptionButton","MenuButton"]: skin.set_type_variation(kind,"Button")
		var command: bool = kind in ["CommandButton","FieldCommandButton"]
		var field: bool = kind=="FieldCommandButton"
		var dark: bool = kind in ["ToolButton","TabButton","MenuButton"] or command
		var primary: bool = kind=="PrimaryButton"
		for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			var box: StyleBoxFlat = StyleBoxFlat.new()
			var active: bool = state in ["hover","pressed","hover_pressed"]
			box.bg_color = AMBER if active else (Color("a64335") if primary else (Color("1c3542") if dark else PAPER))
			box.border_color = Color("536c74") if dark else Color("b6b39e")
			box.border_width_bottom = 2 if not command else 1
			if command:
				box.bg_color = Color(0,0,0,0) if not active else AMBER
				box.border_color = Color("c6c1af") if field else Color("35505b")
			if state=="disabled":
				box.bg_color = Color("203440") if not command else Color(0,0,0,0)
				box.border_color = Color("304653")
			box.corner_radius_top_left = 2
			box.corner_radius_bottom_right = 8 if not command else 3
			box.content_margin_left = 30 if command else 14
			box.content_margin_right = 14
			box.content_margin_top = 10
			box.content_margin_bottom = 10
			if state=="focus":
				box.draw_center = command
				if command: box.bg_color = AMBER
				box.border_color = AMBER
				box.set_border_width_all(2)
				skin.set_stylebox(state,kind,box)
			else: skin.set_stylebox(state,kind,box)
		var normal: Color = INK if field else (PAPER if dark or primary else INK)
		skin.set_color("font_color",kind,normal)
		skin.set_color("font_focus_color",kind,INK if command else normal)
		for color_name: String in ["font_hover_color","font_pressed_color","font_hover_pressed_color"]: skin.set_color(color_name,kind,INK)
		skin.set_color("font_disabled_color",kind,Color("65717a") if field else Color("a0b1b7"))
		skin.set_constant("h_separation",kind,10)
	skin.set_stylebox("panel","PopupMenu",panel())
	skin.set_stylebox("panel","AcceptDialog",panel())
	for container: String in ["HBoxContainer","VBoxContainer","GridContainer"]: skin.set_constant("separation",container,8)
	for entry: String in ["normal","focus","read_only"]:
		var field: StyleBoxFlat = panel(Color("7ca9a9"))
		field.bg_color = Color("0e222e")
		field.set_content_margin_all(10)
		field.shadow_size = 0
		if entry=="focus": field.border_color = AMBER; field.set_border_width_all(2)
		skin.set_stylebox(entry,"LineEdit",field)
	skin.set_color("font_color","LineEdit",PAPER)
	skin.set_color("font_selected_color","LineEdit",INK)
	skin.set_color("selection_color","LineEdit",AMBER)
