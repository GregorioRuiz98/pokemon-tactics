extends RefCounted

static func font_factor(app: Control) -> float:
	var window: Window = app.get_window()
	var width: int = window.size.x if is_instance_valid(window) else 1280
	return app.input_profile.preferences.textScale/100.0*maxf(1,1280.0/maxi(1,width))

static func apply_fonts(app: Control, node: Node) -> void:
	if node is Control:
		var control: Control = node
		if not control.has_meta("base_font"):
			control.set_meta("base_font",control.get_theme_font_size("font_size") if control.has_theme_font_size_override("font_size") else 18)
			if control is Label: control.set_meta("base_color",control.get_theme_color("font_color"))
		var original: int = int(control.get_meta("base_font",18))
		var value: int = roundi(original*font_factor(app))
		if original>=40: value = mini(value,72)
		control.add_theme_font_size_override("font_size",value)
		if control is Label:
			control.add_theme_color_override("font_color",Color.WHITE if app.input_profile.preferences.highContrast else control.get_meta("base_color"))
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
	for child: Node in node.get_children(): apply_fonts(app,child)

static func apply(app: Control) -> void:
	app.muted = app.input_profile.preferences.muted
	app.reduced_motion = app.input_profile.preferences.reducedMotion
	app.board.reduced_motion = app.reduced_motion
	app.board.set("follow_camera",app.input_profile.preferences.followCamera)
	if app.sound!=null:
		app.sound.volume_db = linear_to_db(maxf(0.0001,app.input_profile.preferences.volume/100.0))
		if app.muted: app.sound.stop()
	if app.combat_feedback!=null: app.combat_feedback.duration = float(app.input_profile.preferences.resultSeconds)
	app.theme.default_font_size = roundi(18*font_factor(app))
	apply_fonts(app,app)
	for type: String in ["Button","OptionButton","MenuButton"]:
		for entry: String in ["normal","hover","pressed","disabled","focus"]:
			if not app.theme.has_stylebox(entry,type): continue
			var box: StyleBoxFlat = app.theme.get_stylebox(entry,type)
			if not box.has_meta("base_bg"): box.set_meta("base_bg",box.bg_color); box.set_meta("base_border",box.border_color)
			box.bg_color = Color.BLACK if app.input_profile.preferences.highContrast else box.get_meta("base_bg")
			box.border_color = Color.WHITE if app.input_profile.preferences.highContrast else box.get_meta("base_border")
