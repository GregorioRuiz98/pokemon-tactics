extends RefCounted

static func font_factor(app: Control) -> float:
	var window: Window = app.get_window()
	var width: int = window.size.x if is_instance_valid(window) else 1280
	return app.input_profile.preferences.textScale/100.0*maxf(1,1280.0/maxi(1,width))

static func apply_fonts(app: Control, node: Node, factor: float = -1) -> void:
	if factor<0: factor = font_factor(app)
	if node is Control:
		var control: Control = node
		if not control.has_meta("base_font"):
			control.set_meta("base_font",control.get_theme_font_size("font_size") if control.has_theme_font_size_override("font_size") else 18)
			if control is Label: control.set_meta("base_color",control.get_theme_color("font_color"))
		var original: int = int(control.get_meta("base_font",18))
		var value: int = roundi(original*factor)
		if original>=40: value = mini(value,72)
		# Theme overrides emit changes through the whole subtree even for equal values.
		if control.get_theme_font_size("font_size")!=value: control.add_theme_font_size_override("font_size",value)
		if control is Label:
			var color: Color = Color.WHITE if app.input_profile.preferences.highContrast else control.get_meta("base_color")
			if control.get_theme_color("font_color")!=color: control.add_theme_color_override("font_color",color)
			if not control.get_parent() is HBoxContainer:
				control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if control is Button:
			control.clip_text = false
			control.autowrap_mode = TextServer.AUTOWRAP_OFF if control.get_parent() is HBoxContainer and control.custom_minimum_size.x==0 else TextServer.AUTOWRAP_WORD_SMART
			if control is OptionButton:
				control.fit_to_longest_item = false
				control.custom_minimum_size.x = maxf(140,control.custom_minimum_size.x)
			control.custom_minimum_size.y = maxf(44,value*1.2+18)
	for child: Node in node.get_children(): apply_fonts(app,child,factor)

static func apply(app: Control) -> void:
	app.muted = app.input_profile.preferences.muted
	app.reduced_motion = app.input_profile.preferences.reducedMotion
	app.board.reduced_motion = app.reduced_motion
	app.board.set("follow_camera",app.input_profile.preferences.followCamera)
	if app.sound!=null:
		app.sound.volume_db = linear_to_db(maxf(0.0001,app.input_profile.preferences.volume/100.0))
		if app.muted: app.sound.stop()
	if app.combat_sound!=null: app.combat_sound.set_volume(float(app.input_profile.preferences.volume),app.muted or app.qa_running)
	if app.combat_feedback!=null: app.combat_feedback.duration = float(app.input_profile.preferences.resultSeconds)
	var factor: float = font_factor(app)
	var default_size: int = roundi(18*factor)
	if app.theme.default_font_size!=default_size: app.theme.default_font_size = default_size
	apply_fonts(app,app,factor)
	for type: String in preload("res://ui/game_skin.gd").TYPES:
		for entry: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			if not app.theme.has_stylebox(entry,type): continue
			var box: StyleBoxFlat = app.theme.get_stylebox(entry,type)
			if not box.has_meta("base_bg"): box.set_meta("base_bg",box.bg_color); box.set_meta("base_border",box.border_color)
			var background: Color = Color.BLACK if app.input_profile.preferences.highContrast else box.get_meta("base_bg")
			var border: Color = Color.WHITE if app.input_profile.preferences.highContrast else box.get_meta("base_border")
			if box.bg_color!=background: box.bg_color = background
			if box.border_color!=border: box.border_color = border
		for color_name: String in ["font_color","font_focus_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:
			var metadata: String = type+"_"+color_name
			if not app.theme.has_meta(metadata): app.theme.set_meta(metadata,app.theme.get_color(color_name,type))
			var color: Color = Color.WHITE if app.input_profile.preferences.highContrast else app.theme.get_meta(metadata)
			if app.theme.get_color(color_name,type)!=color: app.theme.set_color(color_name,type,color)
	preload("res://ui/move_symbols.gd").apply_contrast(app.input_profile.preferences.highContrast)
