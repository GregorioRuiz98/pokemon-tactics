extends "res://core/shop_run.gd"

const Growth = preload("res://core/growth.gd")
var consumables: Dictionary = ITEMS.duplicate(true)

func _init() -> void:
	super()
	progression = Growth.new()
	engine.progression = progression
	engine.catalog = progression.data
	for identity: int in engine.profiles: engine.profiles[identity].progression = progression
	consumables["rare-candy"].price = int(progression.config.candyPrice)

func create(seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(seed,starter)
	if not run.is_empty(): run.edition = 4
	return run

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("at",-1)!=input.revision: return fail("Esa opción pertenece a una pantalla anterior.")
	if not command.get("kind") is String: return fail("Orden de campaña no válida.")
	var kind: String = command.kind
	if kind=="buy" and not command.get("item") is String: return fail("Objeto no válido.")
	if kind=="evolve": return fail("La evolución es automática al alcanzar su nivel; el Caramelo ahora sube un nivel.")
	if kind=="level-up" or (kind=="buy" and command.get("item")=="rare-candy"):
		if input.phase!="shop": return fail("Compra y usa los Caramelos fuera del combate, en la tienda.")
		var run: Dictionary = input.duplicate(true)
		if kind=="buy":
			var cost: int = consumables["rare-candy"].price
			if run.money<cost: return fail("No tienes suficientes pokédolares para un Caramelo Raro.")
			run.money -= cost
			run.bag["rare-candy"] += 1
		else:
			var identity: Variant = command.get("member")
			if not (identity is int or identity is float) or identity!=int(identity): return fail("Miembro no válido.")
			var selected: Dictionary = target(run,int(identity))
			if selected.is_empty() or selected.hp<=0: return fail("Las bajas no pueden subir niveles.")
			if selected.level>=progression.data.levelCap: return fail("Ya ha alcanzado el nivel máximo.")
			if run.bag["rare-candy"]<=0: return fail("Falta un Caramelo Raro.")
			run.lastProgress = [progression.candy(selected)]
			run.bag["rare-candy"] -= 1
		run.revision += 1
		return {"ok":true,"state":run}
	return super.transact(input,command)
