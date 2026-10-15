class_name LabBattle
extends RefCounted

const Movement = preload("res://core/movement.gd")
const Rng = preload("res://core/seeded_rng.gd")
const Pokemon = preload("res://core/pokemon.gd")
const FACINGS = [4, 2, 0, 6]
const VECTORS = {4: Vector2i.UP, 2: Vector2i.RIGHT, 0: Vector2i.DOWN, 6: Vector2i.LEFT}
var data: Dictionary
var profiles: Dictionary = {}

func _init():
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/laboratory.json"))
	var chart = {}
	for a in data.types.size():
		chart[data.types[a]] = {}
		for b in data.types.size(): chart[data.types[a]][data.types[b]] = data.typeChart[a][b]
	for record in data.species: profiles[int(record.id)] = Pokemon.new(record, chart)

func profile(unit: Dictionary):
	return profiles[int(unit.speciesId)]

static func living(state: Dictionary) -> Array:
	return state.units.filter(func(unit): return unit.hp > 0)

static func unit_by_id(state: Dictionary, identity: int) -> Dictionary:
	for unit in state.units:
		if unit.id == identity: return unit
	return {}

static func active(state: Dictionary) -> Dictionary:
	return unit_by_id(state, int(state.queue[0])) if state.outcome == "playing" and not state.queue.is_empty() else {}

static func speed(unit: Dictionary) -> float:
	return unit.speed * (0.5 if unit.status != null and unit.status.kind == "paralysis" else 1.0)

static func budget(unit: Dictionary) -> int:
	return maxi(1, int(floor(unit.budget / 2.0))) if unit.status != null and unit.status.kind == "paralysis" else int(unit.budget)

static func note(state: Dictionary, message: String) -> void:
	state.log.append(message)
	if state.log.size() > 40: state.log.pop_front()

func begin_activation(state: Dictionary) -> void:
	var actor = active(state)
	if actor.is_empty(): return
	actor.tp = mini(actor.maxTp, actor.tp + 1)
	actor.guarded = false
	actor.remaining = budget(actor)
	state.moved = false
	state.acted = false

func new_round(state: Dictionary) -> void:
	state.round += 1
	state.fields = state.fields.filter(func(field): return field.expires > state.round)
	var units = living(state)
	units.sort_custom(func(a, b): return a.id < b.id)
	state.initiative = []
	for unit in units:
		state.initiative.append({"id": unit.id, "score": speed(unit) * (1 + (Rng.next(state) * 2 - 1) * state.variance), "tie": Rng.next(state)})
	state.initiative.sort_custom(func(a, b):
		if a.score != b.score: return a.score > b.score
		if a.tie != b.tie: return a.tie < b.tie
		return a.id < b.id)
	state.queue = state.initiative.map(func(entry): return entry.id)
	state.completed = []
	for unit in units: unit.remaining = budget(unit)
	note(state, "Ronda %d: nueva cola de iniciativa." % state.round)
	begin_activation(state)

func create(seed: String = "godot-13", variance: float = 0.05, composition: String = "starters", mode: String = "current") -> Dictionary:
	if variance not in [0.05, 0.1] or composition not in ["starters", "mixed"] or mode not in ["classic", "current"]: return {}
	seed = seed.strip_edges().substr(0, 64)
	if seed.is_empty(): seed = "kanto-001"
	var allies = [1, 4, 7] if composition == "starters" else [25, 12, 74]
	var enemies = [25, 12, 74] if composition == "starters" else [1, 4, 7]
	var positions = [Vector2i(1, 6), Vector2i(3, 6), Vector2i(2, 7), Vector2i(5, 1), Vector2i(6, 2), Vector2i(5, 4)]
	var units = []
	for index in 6:
		var species_id = allies[index] if index < 3 else enemies[index - 3]
		var identity = (index + 1 if index < 3 else 1000 + index - 3) if mode == "current" else species_id
		units.append(profiles[species_id].create_unit(identity, "ally" if index < 3 else "enemy", {"x": positions[index].x, "y": positions[index].y}, mode))
	var state = {"seed": seed, "rng": Rng.hash_seed(seed), "variance": variance, "composition": composition, "round": 0, "board": data.board.duplicate(true), "fields": [], "units": units, "initiative": [], "queue": [], "completed": [], "moved": false, "acted": false, "outcome": "playing", "log": []}
	new_round(state)
	return state

static func attack_side(origin: Dictionary, target: Dictionary) -> String:
	var vector = VECTORS[int(target.facing)]
	var dx = origin.x - target.x
	var dy = origin.y - target.y
	var forward = dx * vector.x + dy * vector.y
	var lateral = dx * vector.y - dy * vector.x
	return ("front" if forward >= 0 else "rear") if abs(forward) >= abs(lateral) else "flank"

static func accuracy(base, side: String) -> int:
	return clampi(int(base) - (15 if side == "front" else (5 if side == "flank" else 0)), 5, 100)

static func blocks_sight(board: Array, point: Dictionary) -> bool:
	var x = int(point.x)
	var y = int(point.y)
	return y < 0 or y >= board.size() or x < 0 or x >= board[y].size() or int(board[y][x]) not in [0, 1, 3]

static func clear_shot(state: Dictionary, actor: Dictionary, target: Dictionary) -> bool:
	if Movement.distance(actor, target) <= 1: return true
	var dx = target.x - actor.x
	var dy = target.y - actor.y
	var points = [{"x": actor.x, "y": actor.y + sign(dy)}] if dx == 0 else ([{"x": actor.x + sign(dx), "y": actor.y}] if dy == 0 else [{"x": target.x, "y": actor.y}, {"x": actor.x, "y": target.y}])
	for point in points:
		if blocks_sight(state.board, point): return false
		for unit in living(state):
			if unit.id != actor.id and Movement.same(unit, point): return false
	return true

func attack_plan(state: Dictionary, target_id: int, origin: Dictionary = {}, action_id: String = "basic") -> Dictionary:
	var current = active(state)
	var target = unit_by_id(state, target_id)
	if current.is_empty(): return {"ok": false, "reason": "El combate ha terminado."}
	if state.acted: return {"ok": false, "reason": "Ya has usado la acción de esta activación."}
	var action = profile(current).action(current, action_id)
	if action == null: return {"ok": false, "reason": "Este Pokémon no conoce esa habilidad."}
	var definition = action.definition
	if current.tp < definition.cost: return {"ok": false, "reason": "Necesita %d PT; quedan %d." % [definition.cost, current.tp]}
	var actor = current.duplicate(true)
	actor.merge(origin, true)
	if target.is_empty() or target.hp <= 0: return {"ok": false, "reason": "El objetivo ya no está en combate."}
	if definition.target == "enemy" and target.team == actor.team: return {"ok": false, "reason": "Esta acción requiere un enemigo."}
	if definition.target == "friendly" and target.team != actor.team: return {"ok": false, "reason": "Esta acción requiere un aliado o a sí mismo."}
	if definition.target == "self" and target.id != actor.id: return {"ok": false, "reason": "Esta acción solo se aplica a sí mismo."}
	if Movement.distance(actor, target) > definition.range: return {"ok": false, "reason": "Fuera de alcance: %d casillas." % definition.range}
	if not clear_shot(state, actor, target): return {"ok": false, "reason": "El terreno u otra unidad bloquea el disparo."}
	var effect = action.preview(actor, target)
	if effect.category == "status" and actor.heldItem == "assault-vest": return {"ok": false, "reason": "Chaleco Asalto impide acciones de estado y apoyo."}
	if effect.category == "status" and effect.statusReason != null: return {"ok": false, "reason": effect.statusReason}
	if effect.guard and target.guarded: return {"ok": false, "reason": "El objetivo ya está protegido."}
	var tiles = [{"x": target.x, "y": target.y}]
	if definition.kind in ["area-damage", "area-status"]:
		for vector in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]: tiles.append({"x": target.x + vector.x, "y": target.y + vector.y})
	tiles = tiles.filter(func(point): return not blocks_sight(state.board, point))
	var area = tiles.size() > 1
	var units = living(state)
	units.sort_custom(func(a, b): return a.id < b.id)
	var hits = []
	for unit in units:
		if area and unit.id == actor.id: continue
		if not tiles.any(func(point): return Movement.same(point, unit)): continue
		var forecast = action.preview(actor, unit)
		var side = attack_side(actor, unit) if definition.target == "enemy" else null
		var push = null
		var push_reason = null
		if definition.kind == "push":
			var vector = VECTORS[Movement.facing_from(actor, unit)]
			var destination = {"x": unit.x + vector.x, "y": unit.y + vector.y}
			if forecast.damage == 0: push_reason = "Inmune: no hay empuje."
			elif forecast.damage >= unit.hp: push_reason = "Si acierta, cae antes del empuje."
			elif is_inf(Movement.tile_cost(state.board, destination, unit.profile)): push_reason = "El borde o terreno bloquea el empuje."
			elif units.any(func(occupant): return Movement.same(occupant, destination)): push_reason = "Una unidad bloquea el empuje."
			else: push = destination
		forecast.merge({"targetId": unit.id, "accuracy": accuracy(definition.accuracy, side) if side != null else definition.accuracy, "side": side, "push": push, "pushReason": push_reason}, true)
		hits.append(forecast)
	var primary = hits.filter(func(hit): return hit.targetId == target_id)[0]
	var plan = primary.duplicate(true)
	plan.merge({"ok": true, "actionId": action_id, "name": definition.name, "cost": definition.cost, "hits": hits, "tiles": tiles, "embers": tiles.filter(func(point): return int(state.board[int(point.y)][int(point.x)]) in [0, 1]) if definition.embers else []}, true)
	return plan

func move(state: Dictionary, destination: Dictionary) -> Dictionary:
	var actor = active(state)
	if actor.is_empty(): return {"ok": false, "reason": "El combate ha terminado."}
	if state.moved: return {"ok": false, "reason": "Ya has usado el desplazamiento de esta activación."}
	if Movement.same(actor, destination): return {"ok": false, "reason": "Ya está en esa casilla."}
	if is_inf(Movement.tile_cost(state.board, destination, actor.profile)): return {"ok": false, "reason": "Ese terreno bloquea el paso."}
	if living(state).any(func(unit): return unit.id != actor.id and Movement.same(unit, destination)): return {"ok": false, "reason": "Casilla ocupada por otro Pokémon."}
	var routes = Movement.routes(state.board, living(state), actor)
	var route = routes.get(Movement.key(destination))
	if route == null: return {"ok": false, "reason": "No hay camino hasta esa casilla."}
	if route.cost > actor.remaining: return {"ok": false, "reason": "Necesita %d puntos; quedan %d." % [route.cost, actor.remaining]}
	var next = state.duplicate(true)
	var moved = unit_by_id(next, int(actor.id))
	moved.merge(destination, true)
	moved.remaining -= route.cost
	moved.facing = Movement.facing_from(route.path[-2], destination)
	next.moved = true
	note(next, "%s se mueve a %s (%d puntos)." % [actor.name, coordinate(destination), route.cost])
	return {"ok": true, "state": next, "route": route}

static func coordinate(point: Dictionary) -> String:
	return "%s%d" % [String.chr(65 + int(point.x)), point.y + 1]

static func resolve_casualties(state: Dictionary) -> void:
	state.queue = state.queue.filter(func(identity): return unit_by_id(state, int(identity)).hp > 0)
	var units = living(state)
	state.outcome = "defeat" if not units.any(func(unit): return unit.team == "ally") else ("victory" if not units.any(func(unit): return unit.team == "enemy") else "playing")
	if state.outcome != "playing":
		state.queue = []
		note(state, "Victoria: zona despejada." if state.outcome == "victory" else "Derrota: el equipo ha caído.")

func attack(state: Dictionary, target_id: int, action_id: String = "basic") -> Dictionary:
	var plan = attack_plan(state, target_id, {}, action_id)
	if not plan.ok: return plan
	var next = state.duplicate(true)
	var actor = active(next)
	var primary = unit_by_id(next, target_id)
	actor.tp -= plan.cost
	next.acted = true
	if actor.id != primary.id: actor.facing = Movement.facing_from(actor, primary)
	note(next, "%s usa %s (%d PT)." % [actor.name, plan.name, plan.cost])
	var hits = []
	for forecast in plan.hits:
		var target = unit_by_id(next, int(forecast.targetId))
		var hit = forecast.accuracy == 100 or Rng.next(next) * 100 < forecast.accuracy
		if not hit:
			hits.append({"targetId": target.id, "hit": false, "damage": 0})
			note(next, "%s: el ataque falla (%d %%)." % [target.name, forecast.accuracy])
			continue
		target.hp = maxi(0, target.hp - forecast.damage)
		actor.hp = mini(actor.maxHp, actor.hp + forecast.heal)
		if forecast.guard: target.guarded = true
		if forecast.status != null and target.hp > 0 and (forecast.status.chance == 100 or Rng.next(next) * 100 < forecast.status.chance):
			target.status = {"kind": forecast.status.kind, "remaining": forecast.status.duration}
		if forecast.push != null and target.hp > 0: target.merge(forecast.push, true)
		var receipt = {"targetId": target.id, "hit": true, "damage": forecast.damage}
		if forecast.push != null and target.hp > 0: receipt.push = forecast.push
		hits.append(receipt)
		note(next, "%s: %d PS%s%s" % [target.name, forecast.damage, ", recupera %d PS" % forecast.heal if forecast.heal else "", ", fuera de combate" if target.hp == 0 else ""])
	for point in plan.embers:
		next.fields = next.fields.filter(func(field): return not Movement.same(field, point))
		next.fields.append({"x": point.x, "y": point.y, "kind": "embers", "expires": state.round + 2})
	resolve_casualties(next)
	var hit = hits.filter(func(entry): return entry.targetId == target_id)[0]
	return {"ok": true, "state": next, "damage": hit.damage, "hit": hit.hit, "hits": hits}

static func field_damage(unit: Dictionary, fields: Array) -> int:
	if "fire" in unit.types or unit.profile == "fly" or unit.heldItem == "heavy-duty-boots": return 0
	return 4 if fields.any(func(field): return Movement.same(field, unit)) else 0

func finish(state: Dictionary, facing = null) -> Dictionary:
	if active(state).is_empty(): return {"ok": false, "reason": "El combate ha terminado."}
	if facing != null and (not (facing is int or facing is float) or int(facing) != facing or int(facing) not in FACINGS): return {"ok": false, "reason": "Elige una orientación cardinal válida."}
	if facing != null: facing = int(facing)
	var next = state.duplicate(true)
	var actor = active(next)
	actor.facing = facing if facing != null else actor.facing
	if actor.status != null:
		var status = actor.status
		var damage = 0 if status.kind == "paralysis" else maxi(1, int(floor(actor.maxHp / (8.0 if status.kind == "poison" else 16.0))))
		actor.hp = maxi(0, actor.hp - damage)
		note(next, "%s: %s, pierde %d PS." % [actor.name, status.kind, damage])
		actor.status = {"kind": status.kind, "remaining": status.remaining - 1} if status.remaining > 1 else null
	if actor.hp > 0: actor.hp = maxi(0, actor.hp - field_damage(actor, next.fields))
	if actor.hp > 0 and actor.heldItem == "leftovers": actor.hp += mini(actor.maxHp - actor.hp, maxi(1, int(floor(actor.maxHp / 16.0))))
	note(next, "%s termina su activación." % actor.name)
	next.completed.append(actor.id)
	next.queue = next.queue.slice(1)
	next.moved = false
	next.acted = false
	resolve_casualties(next)
	if next.outcome == "playing":
		if next.queue.is_empty(): new_round(next)
		else: begin_activation(next)
	return {"ok": true, "state": next}

func apply_command(state: Dictionary, command: Dictionary) -> Dictionary:
	match command.get("kind", ""):
		"move": return move(state, command.destination)
		"attack": return attack(state, int(command.target), command.get("actionId", "basic"))
		"finish": return finish(state, command.get("facing"))
	return {"ok": false, "reason": "Orden desconocida."}

func action_score(state: Dictionary, target: Dictionary, plan: Dictionary) -> float:
	if not plan.ok: return 0
	var actor = active(state)
	if plan.guard:
		return 9 if target.hp < target.maxHp * 0.7 and living(state).any(func(unit): return unit.team != target.team and Movement.distance(unit, target) <= 2) else 0
	var score = 0.0
	for hit in plan.hits:
		var affected = unit_by_id(state, int(hit.targetId))
		var benefit = hit.damage + (15 if hit.damage >= affected.hp else 0) + (8 * hit.status.chance / 100.0 if hit.status != null else 0) + (3 if hit.push != null else 0)
		score += benefit * hit.accuracy / 100.0 * (-2 if affected.team == actor.team else 1) + hit.heal * 0.5
	return score

func danger_at(state: Dictionary, actor: Dictionary, point: Dictionary) -> float:
	var placed = actor.duplicate(true)
	placed.merge(point, true)
	var exposure = 0.0
	for enemy in living(state):
		if enemy.team == actor.team: continue
		var basic = profile(enemy).action(enemy, "basic")
		if Movement.distance(enemy, placed) <= basic.definition.range + budget(enemy): exposure += basic.preview(enemy, placed).damage / (Movement.distance(enemy, placed) + 1.0)
	return field_damage(placed, state.fields) * 2 + exposure * 0.3

func choose_facing(state: Dictionary, actor: Dictionary) -> int:
	var options = []
	for facing in FACINGS:
		var placed = actor.duplicate(true)
		placed.facing = facing
		var exposure = 0.0
		for enemy in living(state):
			if enemy.team == actor.team: continue
			var basic = profile(enemy).action(enemy, "basic")
			exposure += basic.preview(enemy, actor).damage * accuracy(basic.definition.accuracy, attack_side(enemy, placed)) / (Movement.distance(enemy, actor) + 1.0)
		options.append({"facing": facing, "exposure": exposure})
	options.sort_custom(func(a, b):
		if a.exposure != b.exposure: return a.exposure < b.exposure
		if (a.facing == actor.facing) != (b.facing == actor.facing): return a.facing == actor.facing
		return FACINGS.find(a.facing) < FACINGS.find(b.facing))
	return int(options[0].facing)

func affordable_destination(state: Dictionary, actor: Dictionary, route: Dictionary) -> Dictionary:
	var spent = 0.0
	var destination = {"x": actor.x, "y": actor.y}
	for step in route.path.slice(1):
		var cost = Movement.tile_cost(state.board, step, actor.profile)
		if spent + cost > actor.remaining: break
		spent += cost
		if not living(state).any(func(unit): return unit.id != actor.id and Movement.same(unit, step)): destination = step
	return destination

func choose_command(state: Dictionary) -> Dictionary:
	var actor = active(state)
	if actor.is_empty(): return {"kind": "finish"}
	var finish_command = {"kind": "finish", "facing": choose_facing(state, actor)}
	var targets = living(state)
	targets.sort_custom(func(a, b): return a.hp < b.hp if a.hp != b.hp else a.id < b.id)
	var actions = profile(actor).actions_for(actor)
	if not state.acted:
		var available = []
		for target in targets:
			for action in actions:
				var score = action_score(state, target, attack_plan(state, int(target.id), {}, action.definition.id))
				if score > 0: available.append({"target": target, "id": action.definition.id, "score": score})
		available.sort_custom(func(a, b):
			if a.score != b.score: return a.score > b.score
			if a.target.hp != b.target.hp: return a.target.hp < b.target.hp
			if a.target.id != b.target.id: return a.target.id < b.target.id
			return a.id < b.id)
		if not available.is_empty(): return {"kind": "attack", "target": available[0].target.id, "actionId": available[0].id}
	if state.moved: return finish_command
	var routes = Movement.routes(state.board, living(state), actor)
	if state.acted:
		var safer = []
		for route in routes.values():
			if route.cost > 0 and route.cost <= actor.remaining: safer.append({"route": route, "danger": danger_at(state, actor, route.path[-1])})
		safer.sort_custom(func(a, b):
			if a.danger != b.danger: return a.danger < b.danger
			if a.route.cost != b.route.cost: return a.route.cost < b.route.cost
			return Movement.key(a.route.path[-1]) < Movement.key(b.route.path[-1]))
		return {"kind": "move", "destination": safer[0].route.path[-1]} if not safer.is_empty() and safer[0].danger + 2 < danger_at(state, actor, actor) else finish_command
	var approaches = []
	for route in routes.values():
		if route.cost <= 0: continue
		var destination = affordable_destination(state, actor, route)
		if Movement.same(destination, actor): continue
		for target in targets:
			if target.team == actor.team: continue
			var value = -INF
			for action in actions:
				if action.definition.target == "enemy": value = maxf(value, action_score(state, target, attack_plan(state, int(target.id), route.path[-1], action.definition.id)))
			if value > 0: approaches.append({"route": route, "target": target, "destination": destination, "score": value / (1 + route.cost * 0.3) - danger_at(state, actor, destination)})
	approaches.sort_custom(func(a, b):
		if a.score != b.score: return a.score > b.score
		if a.route.cost != b.route.cost: return a.route.cost < b.route.cost
		if a.target.hp != b.target.hp: return a.target.hp < b.target.hp
		if a.target.id != b.target.id: return a.target.id < b.target.id
		return Movement.key(a.destination) < Movement.key(b.destination))
	return {"kind": "move", "destination": approaches[0].destination} if not approaches.is_empty() else finish_command
