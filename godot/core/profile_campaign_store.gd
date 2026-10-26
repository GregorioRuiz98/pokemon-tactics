extends "res://core/adventure_store.gd"

# Metadata lives outside the replayed domain state. Its outbox survives a crash
# between saving an accepted campaign order and updating the trainer profile.
const Trainer = preload("res://core/trainer_profile.gd")
var campaign_id: String = ""
var trainer_id: String = ""
var profile_events: Array = []
var tracker: Dictionary = {"known":false,"kos":0}

func new_binding(owner_id: String) -> void:
	campaign_id = Trainer.identity(); trainer_id = owner_id
	profile_events = []; tracker = {"known":false,"kos":0}

func _payload(state: Dictionary, commands: Array, mode: String) -> Dictionary:
	var payload: Dictionary = super._payload(state,commands,mode)
	if campaign_id.is_empty(): campaign_id = Trainer.identity()
	payload.trainer = {"campaignId":campaign_id,"profileId":trainer_id,"events":profile_events,"tracker":tracker}
	return payload

func load_campaign(rules: RefCounted) -> Dictionary:
	var result: Dictionary = super.load_campaign(rules)
	if not result.ok: return result
	var envelope: Dictionary = _decode_json(FileAccess.get_file_as_string(file_path))
	var payload: Dictionary = _decode_json(envelope.payload)
	var meta: Variant = payload.get("trainer",{})
	campaign_id = "legacy-"+envelope.checksum.substr(0,32); profile_events = []; tracker = {"known":false,"kos":0}
	if valid_meta(meta,int(result.state.revision)):
		campaign_id = meta.campaignId; trainer_id = meta.profileId
		profile_events = meta.events.duplicate(true); tracker = meta.tracker.duplicate(true)
	return result

static func valid_meta(meta: Variant, revision: int) -> bool:
	if not meta is Dictionary or not meta.get("campaignId") is String or meta.campaignId.is_empty() or meta.campaignId.length()>96: return false
	if not meta.get("profileId") is String or not meta.get("events") is Array or not meta.get("tracker") is Dictionary: return false
	if not meta.tracker.get("known") is bool or not (meta.tracker.get("kos") is int or meta.tracker.get("kos") is float) or meta.tracker.kos<0: return false
	var previous: int = -1
	for event: Variant in meta.events:
		if not event is Dictionary or not (event.get("revision") is int or event.get("revision") is float) or event.revision!=int(event.revision) or event.revision<=previous or event.revision>revision: return false
		previous = int(event.revision)
		if not event.get("flags") is Array or not event.get("species") is Array: return false
		for flag: Variant in event.flags:
			if not flag is String or not Trainer.ACHIEVEMENTS.has(flag): return false
		for species_id: Variant in event.species:
			if not (species_id is float or species_id is int) or species_id!=int(species_id) or species_id<1 or species_id>151: return false
		if event.has("outcome") and (event.outcome not in ["victory","defeat"] or not (event.get("kos") is int or event.get("kos") is float) or event.kos<0): return false
	return true

func record(rules: RefCounted, before: Dictionary, after: Dictionary, command: Dictionary, presentation: Dictionary, definition: Dictionary, location: Dictionary = {}) -> void:
	var event: Dictionary = {"revision":int(after.revision),"flags":[],"species":[]}
	if command.kind=="enter": tracker = {"known":true,"kos":0}
	if command.kind=="battle" and not before.get("battle",{}).is_empty():
		for unit: Dictionary in before.battle.units:
			var next: Dictionary = rules.unit_by_id(after.battle,int(unit.id))
			if unit.team=="ally" and unit.hp>0 and not next.is_empty() and next.hp<=0: tracker.kos += 1
		var actor: Dictionary = rules.active(before.battle)
		if actor.get("team")=="ally" and command.order.kind=="attack":
			for receipt: Dictionary in presentation.get("hits",[]):
				var target: Dictionary = rules.unit_by_id(before.battle,int(receipt.targetId))
				if target.get("team")=="enemy" and receipt.has("push") and after.battle.get("zoneEvents",[]).any(func(z):return z.targetId==target.id and z.name=="rocks"):
					if "trap-push" not in event.flags: event.flags.append("trap-push")
			if definition.get("dispel",false) and before.battle.get("round")==after.battle.get("round"):
				for field: Dictionary in before.battle.get("fields",[]):
					if field.kind=="smoke" and not after.battle.get("fields",[]).any(func(f):return f.kind=="smoke" and f.x==field.x and f.y==field.y):
						if "clear-smoke" not in event.flags: event.flags.append("clear-smoke")
		if before.phase=="battle" and after.phase in ["capture","ending","defeat"]:
			event.outcome = "defeat" if after.phase=="defeat" else "victory"; event.kos = tracker.kos
			if event.outcome=="victory":
				if location.get("leader",false) and tracker.known and tracker.kos==0: event.flags.append("clean-gym")
				var mission: Dictionary = after.battle.get("mission",{})
				if mission.get("kind")=="protect" and mission.get("health",0)==4: event.flags.append("fuji-perfect")
				if mission.get("kind")=="secure" and mission.get("points",[]).size()>0 and mission.get("captured",[]).size()==mission.points.size(): event.flags.append("rocket-terminals")
	if command.kind in ["capture","battle","train-xp","level-up","evolve-free","use-evolution","evolve"]:
		var original: Dictionary = {}
		for member: Dictionary in before.party+before.get("reserve",[]): original[int(member.id)] = int(member.speciesId)
		for member: Dictionary in after.party+after.get("reserve",[]):
			if original.get(int(member.id),0)!=int(member.speciesId): event.species.append(int(member.speciesId))
	if event.has("outcome") or not event.flags.is_empty() or not event.species.is_empty():
		if profile_events.is_empty() or int(profile_events[-1].revision)<int(event.revision): profile_events.append(event)
