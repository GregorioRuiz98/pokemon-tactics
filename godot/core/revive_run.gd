extends "res://core/gym_run.gd"

func _init() -> void:
	super()
	consumables["revive"] = {"name":"Revivir","price":150,"heal":0}

func create(seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(seed,starter)
	if not run.is_empty():
		run.edition = 9
		run.bag.revive = 0
	return run

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	var purchase: bool = command.get("kind")=="buy" and command.get("item")=="revive"
	if not purchase and command.get("kind")!="revive": return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("Esa opción pertenece a una pantalla anterior.")
	if input.phase!="shop": return fail("Compra y usa Revivir fuera de combate, en la tienda.")
	var run: Dictionary = input.duplicate(true)
	if purchase:
		var price: int = consumables.revive.price
		if run.money<price: return fail("Revivir cuesta %d ₽." % price)
		run.money -= price
		run.bag.revive += 1
	else:
		var identity: Variant = command.get("member")
		if not (identity is int or identity is float) or identity!=int(identity): return fail("Miembro no válido.")
		var selected: Dictionary = target(run,int(identity))
		if selected.is_empty() or selected.hp!=0: return fail("Revivir solo se puede usar con un Pokémon debilitado.")
		if run.bag.revive<=0: return fail("No quedan Revivir en la bolsa.")
		var maximum: int = progression.stats(int(selected.speciesId),int(selected.level)).maxHp
		selected.hp = maxi(1,int(floor(maximum/2.0)))
		run.bag.revive -= 1
	run.revision += 1
	return {"ok":true,"state":run}
