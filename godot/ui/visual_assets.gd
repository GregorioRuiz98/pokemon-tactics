extends RefCounted

# Presentation-only registry: never reads or advances campaign RNG.
static var catalog: Dictionary = {}
static var textures: Dictionary = {}
static var using_final: Dictionary = {}
static var rejected: Array[String] = []
static var loads: int = 0

static func manifest() -> Dictionary:
	if catalog.is_empty(): catalog = JSON.parse_string(FileAccess.get_file_as_string("res://art/manifest.json"))
	return catalog

static func slots() -> Array:
	return manifest().slots

static func entry(identity: String) -> Dictionary:
	for record: Dictionary in slots():
		if record.id==identity: return record
	return {}

static func texture(identity: String) -> Texture2D:
	if textures.has(identity): return textures[identity]
	var record: Dictionary = entry(identity)
	if record.is_empty(): return null
	var image: Texture2D
	using_final[identity] = false
	if ResourceLoader.exists(record.final):
		image = load(record.final) as Texture2D
		var valid: bool = image!=null and image.get_width()==record.width and image.get_height()==record.height
		if valid and record.alpha: valid = image.get_image().detect_alpha()!=Image.ALPHA_NONE
		if valid:
			using_final[identity] = true
		else:
			rejected.append(identity)
			image = null
	if image==null: image = load(record.placeholder) as Texture2D
	textures[identity] = image
	loads += 1
	return image

static func final_ready(identity: String) -> bool:
	texture(identity)
	return using_final.get(identity,false)

static func art_complete() -> bool:
	for record: Dictionary in slots():
		if record.required and not final_ready(record.id): return false
	return true

static func floor_id(biome: String) -> String:
	return "floor_"+manifest().biomes.get(biome,"meadow")

static func prop_id(biome: String) -> String:
	var family: String = manifest().biomes.get(biome,"meadow")
	if family in ["meadow","forest"]: return "prop_shrub"
	if family in ["wood","industrial"]: return "prop_crate"
	if family in ["psychic","origin","ice","haunted"]: return "prop_crystal"
	return "prop_rock"

static func icon(identity: String) -> Texture2D:
	return texture("icon_"+identity)

static func item_icon(identity: String) -> Texture2D:
	if identity=="rare-candy" or identity.ends_with("-stone") or identity=="link-cable": return icon("evolution")
	if identity.begins_with("mint-"): return icon("mint")
	if identity=="ability-capsule": return icon("capsule")
	return icon("medicine")
