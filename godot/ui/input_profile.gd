extends RefCounted

# Adapted from the installed Godot skill's input_remap/settings templates.
# Preferences belong to the player, never to a deterministic campaign journal.
const PREFIX: String = "tactics_"
const ACTIONS: Dictionary = {
	"accept":["Aceptar","Navegación",KEY_ENTER],"cancel":["Volver / cancelar","Navegación",KEY_ESCAPE],
	"left":["Izquierda","Navegación",KEY_LEFT],"right":["Derecha","Navegación",KEY_RIGHT],
	"up":["Arriba","Navegación",KEY_UP],"down":["Abajo","Navegación",KEY_DOWN],
	"panel":["Cambiar de panel","Navegación",KEY_F6],
	"abilities":["Habilidades","Combate",KEY_A],"rectify":["Rectificar movimiento","Combate",KEY_R],
	"finish":["Orientar y terminar","Combate",KEY_F],"movement":["Volver al movimiento","Combate",KEY_M],
	"slot1":["1 · Básico","Combate",KEY_1],"slot2":["2 · Movimiento","Combate",KEY_2],
	"slot3":["3 · Movimiento","Combate",KEY_3],"slot4":["4 · Movimiento","Combate",KEY_4],
	"slot5":["5 · Movimiento","Combate",KEY_5],
	"previous_target":["Objetivo anterior","Combate",KEY_Q],"next_target":["Objetivo siguiente","Combate",KEY_E],
	"center":["Centrar unidad","Cámara",KEY_C],"grid":["Cuadrícula","Cámara",KEY_G],
	"heights":["Alturas","Cámara",KEY_H],"zoom_in":["Acercar","Cámara",KEY_EQUAL],
	"zoom_out":["Alejar","Cámara",KEY_MINUS],
	"camera_mode":["Activar modo cámara","Cámara",KEY_P],
	"pan_left":["Cámara izquierda","Cámara",KEY_LEFT],"pan_right":["Cámara derecha","Cámara",KEY_RIGHT],
	"pan_up":["Cámara arriba","Cámara",KEY_UP],"pan_down":["Cámara abajo","Cámara",KEY_DOWN],
	"menu":["Menú","General",KEY_F1],"controls":["Controles","General",KEY_F2],
	"inspect":["Inspeccionar unidad","Combate",KEY_I],"result":["Último resultado","Combate",KEY_L],
	"load":["Recuperar guardado","General",KEY_F8]
}
const GUI: Dictionary = {"accept":"ui_accept","cancel":"ui_cancel","left":"ui_left","right":"ui_right","up":"ui_up","down":"ui_down"}
const SAFETY: Dictionary = {KEY_ENTER:"accept",KEY_KP_ENTER:"accept",KEY_SPACE:"accept",KEY_ESCAPE:"cancel",KEY_LEFT:"left",KEY_RIGHT:"right",KEY_UP:"up",KEY_DOWN:"down",KEY_TAB:"tab",KEY_BACKTAB:"tab"}
static var native_events: Dictionary = {}
var path: String
var bindings: Dictionary = {}
var navigation_repeat: bool = true
var confirmation_mode: String = "fast"
var warning: String = ""
var preserved: bool = false
var held: Dictionary = {}

func _init(file_path: String = "user://controls.json") -> void:
	path = file_path
	for action: String in ACTIONS: bindings[action] = default_binding(action)
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path,FileAccess.READ)
		var parser: JSON = JSON.new()
		var data: Variant = parser.data if file!=null and file.get_length()<=65536 and parser.parse(file.get_as_text())==OK else null
		if file!=null: file.close()
		if data is Dictionary and data.get("schema")==1 and data.get("bindings") is Dictionary:
			var proposed: Dictionary = bindings.duplicate(true)
			for action: String in ACTIONS:
				var value: Variant = data.bindings.get(action)
				if value is Dictionary and valid(action,value): proposed[action] = normalized(value)
				elif value!=null: warning = "Se han recuperado controles no válidos; el archivo original se conserva."
			# New shortcuts must not displace a player's existing assignment.
			for action: String in ACTIONS:
				if data.bindings.has(action): continue
				var clashes: bool = proposed.keys().any(func(other):return other!=action and proposed[other]==proposed[action])
				if not clashes: continue
				for index: int in 52:
					var free: Dictionary = normalized({"key":KEY_A+index%26,"alt":index>=26})
					if valid(action,free) and free not in proposed.values(): proposed[action] = free; break
			var occupied: Dictionary = {}
			for action: String in ACTIONS:
				var token: String = JSON.stringify(proposed[action])
				if occupied.has(token): warning = "Había teclas en conflicto; se han recuperado los controles predeterminados."; proposed = bindings.duplicate(true); break
				occupied[token] = action
			bindings = proposed
			navigation_repeat = data.get("navigationRepeat",true) if data.get("navigationRepeat",true) is bool else true
			confirmation_mode = "safe" if data.get("confirmationMode")=="safe" else "fast"
		else: warning = "El archivo de controles no es válido; se usan valores seguros y se conserva el original."
	install()

static func normalized(value: Dictionary) -> Dictionary:
	return {"key":int(value.get("key",0)),"shift":value.get("shift",false)==true,"alt":value.get("alt",false)==true,"ctrl":value.get("ctrl",false)==true}

static func default_binding(action: String) -> Dictionary:
	return normalized({"key":ACTIONS[action][2],"alt":action.begins_with("pan_")})

static func valid(action: String, value: Dictionary) -> bool:
	if not (value.get("key") is int or value.get("key") is float): return false
	var code: int = int(value.key)
	if float(code)!=float(value.key) or code<=0 or code>KEY_SPECIAL+512 or OS.get_keycode_string(code).is_empty(): return false
	for field: String in ["shift","alt","ctrl"]:
		if value.has(field) and not value[field] is bool: return false
	if code in [KEY_SHIFT,KEY_CTRL,KEY_ALT,KEY_META] or value.get("ctrl",false) or (value.get("alt",false) and code==KEY_F4): return false
	if code==KEY_HOME and action!="center" or code==KEY_PLUS and action!="zoom_in": return false
	if SAFETY.has(code) and SAFETY[code]!=action:
		if not (code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN] and action.begins_with("pan_") and value.get("alt",false) and not value.get("shift",false)): return false
	return true

func event_for(action: String) -> InputEventKey:
	var value: Dictionary = bindings[action]
	var event: InputEventKey = InputEventKey.new()
	event.keycode = int(value.key) as Key
	event.shift_pressed = value.shift
	event.alt_pressed = value.alt
	event.ctrl_pressed = value.ctrl
	return event

func install() -> void:
	for action: String in ACTIONS:
		var identity: String = PREFIX+action
		if not InputMap.has_action(identity): InputMap.add_action(identity)
		InputMap.action_erase_events(identity)
		InputMap.action_add_event(identity,event_for(action))
	for action: String in GUI:
		var identity: String = GUI[action]
		if not native_events.has(identity): native_events[identity] = InputMap.action_get_events(identity)
		InputMap.action_erase_events(identity)
		for event: InputEvent in native_events[identity]: InputMap.action_add_event(identity,event)
		InputMap.action_add_event(identity,event_for(action))
	# Safety keys remain usable even when the primary key is changed.
	for code: int in SAFETY:
		var action: String = SAFETY[code]
		if action not in GUI: continue
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code as Key
		InputMap.action_add_event(PREFIX+action,event)
	if bindings.center.key!=KEY_HOME:
		var home: InputEventKey = InputEventKey.new()
		home.keycode = KEY_HOME
		InputMap.action_add_event(PREFIX+"center",home)

func matches(event: InputEvent, action: String) -> bool:
	if action=="zoom_in" and event is InputEventKey and event.keycode==KEY_PLUS and event.pressed and not event.echo and not event.alt_pressed and not event.ctrl_pressed and not event.meta_pressed: return true
	if action=="panel" and event is InputEventKey and event.shift_pressed and not bindings.panel.shift:
		var unshifted: InputEventKey = event.duplicate()
		unshifted.shift_pressed = false
		return unshifted.is_action_pressed(PREFIX+action,false,true)
	return event.is_action_pressed(PREFIX+action,navigation_repeat and (action in ["left","right","up","down"] or action.begins_with("pan_")),true)

func label(action: String) -> String:
	return event_for(action).as_text_keycode()

func shortcut(text: String, action: String) -> String:
	return text+" · "+label(action)

func conflict(action: String, value: Dictionary) -> String:
	for other: String in ACTIONS:
		if other!=action and normalized(bindings[other])==normalized(value): return other
	return ""

func rebind(action: String, value: Dictionary, exchange: bool = false) -> Dictionary:
	if not ACTIONS.has(action) or not valid(action,value): return {"ok":false,"reason":"Tecla reservada o combinación no disponible. Enter, Espacio, Escape, Tab y flechas mantienen su función de seguridad."}
	var other: String = conflict(action,value)
	if not other.is_empty() and not exchange: return {"ok":false,"conflict":other,"reason":"Esta tecla ya pertenece a "+ACTIONS[other][0]+"."}
	if not other.is_empty() and not valid(other,bindings[action]): return {"ok":false,"reason":"Este intercambio quitaría una tecla de seguridad. Elige otra tecla."}
	var before: Dictionary = bindings.duplicate(true)
	if not other.is_empty(): bindings[other] = bindings[action].duplicate(true)
	bindings[action] = normalized(value)
	if not save():
		bindings = before
		return {"ok":false,"reason":warning}
	install()
	return {"ok":true}

func reset_category(category: String) -> bool:
	var before: Dictionary = bindings.duplicate(true)
	var selected: Array = ACTIONS.keys().filter(func(a):return ACTIONS[a][1]==category)
	# Restore conflicting assignments as well; never leave two active actions on one key.
	for action: String in selected:
		var value: Dictionary = default_binding(action)
		var other: String = conflict(action,value)
		if not other.is_empty() and other not in selected: selected.append(other)
	for action: String in selected: bindings[action] = default_binding(action)
	# A chain of swaps can reach further categories. Defaults are the safe fallback.
	var used: Array = []
	for action: String in ACTIONS:
		if bindings[action] in used:
			for entry: String in ACTIONS: bindings[entry] = default_binding(entry)
			break
		used.append(bindings[action])
	if not save(): bindings = before; return false
	install()
	return true

func save() -> bool:
	var absolute: String = ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())!=OK: warning = "No se puede guardar la configuración."; return false
	if not warning.is_empty() and not preserved and FileAccess.file_exists(path):
		if DirAccess.copy_absolute(absolute,absolute+".invalid-"+str(Time.get_ticks_usec()))!=OK: warning = "No se pudo conservar el archivo de controles anterior."; return false
		preserved = true
	var file: FileAccess = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: warning = "No se pueden guardar los controles; el cambio no se aplica."; return false
	file.store_string(JSON.stringify({"schema":1,"bindings":bindings,"navigationRepeat":navigation_repeat,"confirmationMode":confirmation_mode},"\t"))
	file.flush()
	var error: int = file.get_error()
	file.close()
	if error!=OK or DirAccess.rename_absolute(absolute+".tmp",absolute)!=OK: warning = "No se pueden guardar los controles; el cambio no se aplica."; return false
	warning = ""
	return true

func allow(event: InputEvent) -> bool:
	if not event is InputEventKey: return true
	var identity: int = event.keycode if event.keycode!=0 else event.physical_keycode
	if not event.pressed: held.erase(identity); return true
	var navigation: bool = false
	for action: String in ["left","right","up","down","pan_left","pan_right","pan_up","pan_down"]:
		if matches(event,action): navigation = true
	if event.echo or held.has(identity): return navigation_repeat and navigation
	held[identity] = true
	return true
