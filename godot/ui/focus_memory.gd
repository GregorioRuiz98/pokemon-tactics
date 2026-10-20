extends RefCounted

static func eligible(control: Variant) -> bool:
	return is_instance_valid(control) and control is Control and control.is_inside_tree() and control.is_visible_in_tree() and control.focus_mode!=Control.FOCUS_NONE and not (control is BaseButton and control.disabled)

static func capture(root: Control, registry: Dictionary) -> Dictionary:
	var focused: Control = root.get_viewport().gui_get_focus_owner()
	var key: String = ""
	for identity: String in registry:
		if is_instance_valid(registry[identity]) and registry[identity]==focused: key = identity; break
	var scrolls: Dictionary = {}
	collect_scrolls(root,scrolls,false)
	return {"key":key,"keys":registry.keys(),"inside":focused!=null and root.is_ancestor_of(focused),"scrolls":scrolls}

static func collect_scrolls(node: Node, values: Dictionary, restoring: bool) -> void:
	if node is ScrollContainer and node.has_meta("scroll_id"):
		var identity: String = node.get_meta("scroll_id")
		if restoring:
			if values.has(identity): node.scroll_vertical = values[identity]
		else: values[identity] = node.scroll_vertical
	for child: Node in node.get_children(): collect_scrolls(child,values,restoring)

static func restore(root: Control, registry: Dictionary, memory: Dictionary, fallback: String) -> void:
	if not root.is_visible_in_tree(): return
	var key: String = memory.get("key","")
	var target: Control = registry.get(key)
	if not eligible(target):
		var previous: Array = memory.get("keys",[])
		var index: int = previous.find(key)
		if index>=0:
			for offset: int in previous.size():
				var candidate: Control = registry.get(previous[(index+offset)%previous.size()])
				if eligible(candidate): target = candidate; break
	if not eligible(target): target = registry.get(fallback)
	if not eligible(target):
		for control: Variant in registry.values():
			if eligible(control): target = control; break
	if eligible(target):
		target.grab_focus()
	collect_scrolls(root,memory.get("scrolls",{}),true)
	if eligible(target):
		var ancestor: Node = target.get_parent()
		while ancestor!=root and ancestor!=null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(target)
			ancestor = ancestor.get_parent()
