extends RefCounted

func run(app: Control, output_path: String) -> void:
	var frames: int = 120
	var started: int = Time.get_ticks_usec()
	for frame: int in frames: await app.get_tree().process_frame
	var duration: float = maxf(.001,(Time.get_ticks_usec()-started)/1000000.0)
	var window_size: Vector2i = DisplayServer.window_get_size()
	var report: Dictionary = {"version":ProjectSettings.get_setting("application/config/version"),"os":OS.get_name(),"cpu":OS.get_processor_name(),"engine":Engine.get_version_info().string,"window":{"width":window_size.x,"height":window_size.y},"renderer":ProjectSettings.get_setting("rendering/renderer/rendering_method"),"frames":frames,"seconds":duration,"observedFps":frames/duration,"titleVisible":app.title_visible,"editorHint":Engine.is_editor_hint(),"executable":OS.get_executable_path().get_file(),"scope":"Local startup/rendering check only; not a complete playtest or proof of another physical computer."}
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file: FileAccess = FileAccess.open(output_path,FileAccess.WRITE)
	if file==null: app.get_tree().quit(1); return
	file.store_string(JSON.stringify(report,"  ")); file.close()
	app.get_tree().quit(0 if report.titleVisible else 1)
