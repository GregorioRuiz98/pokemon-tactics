extends "res://ui/qa_quality_policy.gd"

func choose(game: RefCounted, state: Dictionary, final_path: String = "birds") -> Dictionary:
	if state.phase=="capture" and state.has("legendaryChoices"):
		var selected: int = 150 if 150 in state.legendaryChoices else 145
		if int(state.reward.speciesId)!=selected: return {"kind":"select-recruit","species":selected,"at":state.revision}
	return super.choose(game,state,final_path)
