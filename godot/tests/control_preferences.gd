extends SceneTree

const Profile = preload("res://ui/input_profile.gd")
var failures: Array[String] = []
var assertions: int = 0

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value: failures.append(message)

func _initialize() -> void:
	var directory: String = ""
	var phase: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): directory = argument.trim_prefix("--save-dir=")
		if argument.begins_with("--phase="): phase = argument.trim_prefix("--phase=")
	if directory.is_empty() or phase not in ["write","read"]: quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	var path: String = directory.path_join("process-controls.json")
	var profile: RefCounted = Profile.new(path)
	if phase=="write":
		check(profile.rebind("abilities",{"key":KEY_Z}).ok,"Write custom binding")
		profile.navigation_repeat = false
		profile.confirmation_mode = "safe"
		check(profile.save(),"Write navigation preference")
	else:
		check(profile.bindings.abilities.key==KEY_Z,"New process reloads custom key")
		check(not profile.navigation_repeat,"New process reloads navigation preference")
		check(profile.confirmation_mode=="safe","New process reloads safe confirmation mode")
		check(profile.bindings.pan_right.alt and profile.bindings.pan_right.key==KEY_RIGHT,"Camera default is Alt arrow")
		check(profile.rebind("pan_left",{"key":KEY_LEFT,"alt":true}).ok,"Camera pan accepts reserved arrow with Alt only")
		check(not profile.rebind("pan_left",{"key":KEY_LEFT}).ok,"Camera cannot steal unmodified cursor arrow")
		var event: InputEventKey = InputEventKey.new()
		event.keycode = KEY_Z
		event.pressed = true
		check(profile.matches(event,"abilities"),"Reloaded binding drives InputMap")
		event.keycode = KEY_A
		check(not profile.matches(event,"abilities"),"Old key removed from InputMap")
		check(not profile.rebind("finish",{"key":KEY_ESCAPE}).ok,"Cancel safety is reserved")
		check(not profile.rebind("finish",{"key":KEY_TAB}).ok,"Focus navigation is reserved")
		check(not profile.rebind("finish",{"key":KEY_HOME}).ok,"Center alias cannot conflict")
		check(not profile.rebind("finish",{"key":KEY_Q,"ctrl":true}).ok,"System editing combinations are preserved")
		check(not profile.rebind("finish",{"key":KEY_F4,"alt":true}).ok,"System close combination is preserved")
		var failed: RefCounted = Profile.new(directory.path_join("as-directory"))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(failed.path))
		var before: Dictionary = failed.bindings.duplicate(true)
		check(not failed.rebind("abilities",{"key":KEY_Z}).ok,"Write failure rejects binding")
		check(failed.bindings==before,"Write failure preserves previous controls")
		var legacy_bindings: Dictionary = profile.bindings.duplicate(true)
		for action: String in ["previous_target","next_target","camera_mode","pan_left","pan_right","pan_up","pan_down"]: legacy_bindings.erase(action)
		legacy_bindings.abilities = Profile.normalized({"key":KEY_E})
		var legacy_path: String = directory.path_join("legacy-custom-controls.json")
		FileAccess.open(legacy_path,FileAccess.WRITE).store_string(JSON.stringify({"schema":1,"bindings":legacy_bindings}))
		var legacy: RefCounted = Profile.new(legacy_path)
		check(legacy.bindings.abilities.key==KEY_E,"Existing custom shortcut survives newly added target defaults")
		check(legacy.bindings.next_target.key!=KEY_E and legacy.warning.is_empty(),"Only the new conflicting shortcut receives a free key")
		check(legacy.save() and Profile.new(legacy_path).bindings==legacy.bindings,"Upgraded preferences reload without changing assignments")
		profile.install()
	var output: Dictionary = {"phase":phase,"assertions":assertions,"failures":failures}
	var file: FileAccess = FileAccess.open(directory.path_join("preferences-"+phase+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"\t"))
	file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
