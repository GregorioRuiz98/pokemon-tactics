extends "res://core/collection_run.gd"

# Edition29 freezes a recruitment counter on arrival. Published editions keep
# their original journal semantics; only explicit upgrades adopt this rule.
func _init(chapter_number: int = 33) -> void:
	super(chapter_number)

func create(campaign_seed: String, starter: int) -> Dictionary:
	var run: Dictionary = super.create(campaign_seed,starter)
	if chapter>=33 and not run.is_empty():
		run.recruitmentOffers = []; run.recruitmentLocation = ""
	return run

func collection_offers(run: Dictionary) -> Array:
	if not run.has("recruitmentOffers"): return super.collection_offers(run)
	if run.get("phase","")!="shop": return []
	var location: String = locations[int(run.stage)].id
	if location!=run.get("recruitmentLocation","") or location in run.get("collectionAdopted",[]): return []
	return run.recruitmentOffers.duplicate(true)

func prepare_counter(run: Dictionary) -> void:
	run.recruitmentLocation = locations[int(run.stage)].id
	run.recruitmentOffers = super.collection_offers(run).duplicate(true)

func transact(input: Dictionary, command: Dictionary) -> Dictionary:
	if chapter<33: return super.transact(input,command)
	if command.get("at",-1)!=input.revision: return fail("La pantalla ha cambiado. Vuelve a elegir.")
	if command.get("kind")=="upgrade":
		if command.get("edition")!=29 or input.get("edition",1)<12 or input.edition>=29 or input.phase not in ["map","shop","complete","ending"]: return fail("Actualiza entre encuentros.")
		var transition: Dictionary = input.duplicate(true)
		if input.edition<28:
			var conversion: Dictionary = preload("res://core/collection_run.gd").new().transact(input,{"kind":"upgrade","edition":28,"at":input.revision})
			if not conversion.ok: return conversion
			transition = conversion.state
		transition.edition = 29; transition.chapter = 33; transition.revision = input.revision+1
		transition.recruitmentOffers = []; transition.recruitmentLocation = ""
		if transition.phase=="shop": prepare_counter(transition)
		return {"ok":true,"state":transition}
	if input.get("edition",0)!=29: return fail("Esta aventura conserva sus reglas anteriores. Actualiza entre encuentros.")
	var projection: Dictionary = input.duplicate()
	projection.edition = 28
	var result: Dictionary = super.transact(projection,command)
	if not result.ok: return result
	var settled: Dictionary = result.state
	settled.edition = 29; settled.chapter = 33
	if settled.phase=="shop" and input.phase!="shop": prepare_counter(settled)
	elif settled.phase!="shop": settled.recruitmentOffers = []; settled.recruitmentLocation = ""
	return result
