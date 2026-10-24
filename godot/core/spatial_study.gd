extends "res://core/expedition_study.gd"

var spatial_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/spatial.json"))

func _init() -> void:
	super()
	for identity: String in data.moves:
		var definition: Dictionary = data.moves[identity]
		var original_description: String = definition.description
		definition.merge(spatial_data.moves[identity],true)
		definition.cost = maxi(int(definition.cost),int(definition.get("costFloor",0)))
		if definition.get("spatialArea",false) and definition.kind=="area-damage": definition.kind = "damage"
		definition.description = (original_description if definition.reviewPriority=="Mantener" else definition.spatialDescription)+"\nÁrea: "+definition.shapeName+" · "+str(definition.cost)+" PT."
		if definition.get("field","")!="": definition.description += " Zona temporal: dos rondas completas."
	data.version = 19
