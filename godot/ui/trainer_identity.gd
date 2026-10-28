extends RefCounted

const Catalog = preload("res://core/collection_catalog.gd")

static func portrait(app: Control, species_id: int) -> Texture2D:
	if not app.faces.has(species_id):
		app.faces[species_id] = load("res://"+str(Catalog.record(species_id).face))
	return app.faces[species_id]

static func accent(frame: String) -> Color:
	return {"amber":Color("efc879"),"leaf":Color("8bcc9d"),"champion":Color("d1acfa")}.get(frame,Color("efc879"))
