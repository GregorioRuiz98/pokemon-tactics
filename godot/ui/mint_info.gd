extends RefCounted

const SHORT: Dictionary = {"attack":"Ataque","defense":"Defensa","specialAttack":"At. especial","specialDefense":"Def. especial","speed":"Velocidad"}

static func caption(study: RefCounted, identity: String) -> String:
	var nature: Dictionary = study.traits.natures[identity]
	return "Menta "+nature.name+(" · ↑ "+SHORT[nature.up]+" / ↓ "+SHORT[nature.down] if nature.up!="" else " · neutra")

static func details(study: RefCounted, identity: String) -> String:
	var nature: Dictionary = study.traits.natures[identity]
	return "Sin modificadores de estadísticas." if nature.up=="" else "↑ %s +10 %%\n↓ %s −10 %%"%[study.STAT_NAMES[nature.up],study.STAT_NAMES[nature.down]]
