extends "res://ui/qa_economy_policy.gd"

func choose(game: RefCounted, state: Dictionary, final_path: String = "birds") -> Dictionary:
	if state.phase=="battle" and state.battle.get("deployment",false): return {"kind":"start-battle","at":state.revision}
	return super.choose(game,state,final_path)
