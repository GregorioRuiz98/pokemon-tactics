extends "res://ui/qa_context.gd"

const Effects = preload("res://ui/attack_effect.gd")
var cues: Array[String] = []

func record_cue(identity: String) -> void:
	cues.append(identity)

func run(app: Control, directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	app.get_window().gui_embed_subwindows = true
	app.input_profile = Profile.new(directory.path_join("attack-controls.json"))
	app.board.input_profile = app.input_profile
	app.input_profile.set_preference("reducedMotion",false)
	app._apply_preferences()
	var effect: Control = app.combat_feedback.attack_effect
	effect.cue_requested.connect(record_cue)
	for element: String in Effects.COLORS:
		var described: Dictionary = Effects.describe({"type":element,"category":"special","range":3})
		check(described.element==element and app.combat_sound.streams.has(described.cue),"Element has an effect and sound: "+element)
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/expedition.json"))
	for move: Dictionary in catalogue.moves.values():
		check(app.combat_sound.streams.has(Effects.describe(move).cue),"Move resolves audio: "+move.id)
	for identity: String in app.combat_sound.streams:
		var stream: AudioStream = app.combat_sound.streams[identity]
		check(stream!=null and stream.get_length()>0.04 and stream.get_length()<0.8,"Imported sound has bounded duration: "+identity)
	for move: String in ["tackle","flamethrower","water-gun","thunderbolt","razor-leaf","ice-beam","shadow-ball","swords-dance","recover"]:
		await fixture(app,directory,move)
		var actor: Dictionary = app.state.units[0]
		actor.hp = int(actor.maxHp/2.0)
		var command: Dictionary = {"kind":"attack","target":1 if move in ["swords-dance","recover"] else 10000,"actionId":move}
		var prior_run: Dictionary = app.run.duplicate(true)
		cues.clear()
		app._commit(command)
		expect_order(app,prior_run,command,"Attack remains the same saved transaction: "+move)
		check(effect.active and not effect.impacted,"Preparation before impact: "+move)
		check(cues.size()==1,"One launch sound: "+move)
		effect.set_process(false)
		var committed: Dictionary = app.run.duplicate(true)
		effect.advance(effect.impact_at*.5)
		if move in ["flamethrower","water-gun","thunderbolt"]: await capture(app,directory,move+"-launch")
		effect.advance(effect.impact_at*.5+.01)
		check(effect.impacted and cues.size()==2,"Exactly one impact cue: "+move)
		if move in ["flamethrower","razor-leaf","recover","swords-dance"]: await capture(app,directory,move+"-impact")
		effect.advance(.02)
		check(cues.size()==2,"No duplicate impact per frame: "+move)
		effect.advance(1)
		check(not effect.active and effect.offset_for(actor)==Vector2.ZERO,"Pose restored and processing stopped: "+move)
		check(Store.equivalent(committed,app.run),"Animation never changes HP, state or RNG: "+move)
	await fixture(app,directory,"flamethrower")
	var before: Dictionary = app.state.duplicate(true)
	var plan: Dictionary = app.rules.attack_plan(before,10000,{},"flamethrower")
	var definition: Dictionary = app._attack_definition(before,{"kind":"attack","actionId":"flamethrower"})
	for kind: String in ["miss","immune","critical"]:
		var preview: Dictionary = plan.duplicate(true)
		if kind=="immune": preview.hits[0].multiplier = 0
		var receipt: Dictionary = {"targetId":10000,"hit":kind!="miss","damage":12 if kind=="critical" else 0,"critical":kind=="critical"}
		cues.clear()
		app.combat_feedback.present(before,preview,[receipt],definition)
		effect.set_process(false)
		effect.advance(.3)
		check(effect.outcome_cue==kind and cues.back()==kind and kind in app.combat_feedback.last_kinds,"Distinct real-outcome presentation: "+kind)
		await capture(app,directory,kind)
	var sequence: Array = [{"targetId":10000,"hit":true,"damage":12}]
	var displaced: Dictionary = before.duplicate(true)
	displaced.units[0].x += 1
	displaced.units[2].x += 1
	app.board.state = displaced
	effect.start(before,plan,sequence,definition)
	effect.set_process(false)
	check(effect.offset_for(displaced.units[0]).length()>0,"Approach interpolates from previous visual position")
	check(effect.offset_for(displaced.units[2]).length()>0,"Pushed target starts at its previous visual position")
	effect.advance(1)
	check(effect.offset_for(displaced.units[2])==Vector2.ZERO,"Displacement ends at the committed destination")
	app.board.state = app.state
	cues.clear()
	effect.start(before,plan,[{"targetId":10000,"hit":false,"damage":0},{"targetId":10001,"hit":true,"damage":12,"critical":true}],definition)
	effect.set_process(false)
	effect.advance(.3)
	check(effect.targets.size()==2 and cues.size()==2 and effect.outcome_cue=="critical","Area attack has per-target results and a single prioritized impact sound")
	check(effect.clip_contents and effect.position==app.board.play_area().position and effect.size==app.board.play_area().size,"Effects stay clipped to the tactical area")
	app.combat_feedback.present(before,plan,sequence,definition)
	app.combat_feedback.clear()
	cues.clear()
	effect.advance(1)
	check(not effect.active and cues.is_empty(),"Cancellation has no delayed sound or offset")
	app.combat_feedback.present(before,plan,sequence,definition)
	app._open_title()
	check(not effect.active and app.combat_feedback.marks.is_empty(),"Returning to title clears attack visuals")
	await fixture(app,directory,"flamethrower")
	app.input_profile.set_preference("reducedMotion",true)
	app._apply_preferences()
	before = app.state.duplicate(true)
	cues.clear()
	app.combat_feedback.present(before,plan,sequence,definition)
	effect.set_process(false)
	check(effect.impacted and effect.offset_for(before.units[0])==Vector2.ZERO,"Reduced motion is static and resolves immediately")
	await capture(app,directory,"reduced-motion")
	effect.advance(1)
	var requests: int = app.combat_sound.requests
	app.combat_sound.play_cue("fire",100,true)
	app.combat_sound.play_cue("fire",0,false)
	check(app.combat_sound.requests==requests,"Mute and zero volume never start audio")
	app.combat_sound.play_cue("fire",50,false)
	var voice_index: int = posmod(app.combat_sound.next_voice-1,4)
	check(app.combat_sound.requests==requests+1 and app.combat_sound.voices[voice_index].playing,"Audio starts with the real stream under Dummy driver")
	app.combat_sound.set_volume(100,true)
	check(app.combat_sound.voices.all(func(voice):return not voice.playing),"Muting stops all voices immediately")
	for index: int in 12: app.combat_sound.play_cue("impact",10,false)
	check(app.combat_sound.voices.size()==4,"Rapid sounds use a bounded pool")
	app.combat_sound.stop()
	app.board.hide()
	app.combat_sound.play_cue("impact",50,false)
	app.combat_feedback.marks = [{"kind":"hit"}]
	app.combat_feedback._process(.01)
	check(app.combat_sound.voices.any(func(voice):return voice.playing),"Reward screen does not truncate the final impact sound")
	app.combat_feedback.clear()
	check(app.combat_sound.voices.all(func(voice):return not voice.playing),"Explicit navigation still cancels final impact audio")
	app.board.show()
	effect.cue_requested.disconnect(record_cue)
	await settle(app)
	check(Store.equivalent(before,app.state),"Presentation options and audio preserve combat")
	var report: Dictionary = {"assertions":assertions,"failures":failures,"screenshots":screenshots,"types":Effects.COLORS.size(),"sounds":app.combat_sound.streams.size(),"syntheticFixtures":true,"audioDriver":"Dummy; waveform inspection separate; listening pending"}
	FileAccess.open(directory.path_join("attack-effects-result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ATTACK_EFFECTS_QA "+JSON.stringify(report))
	app.get_tree().quit(0 if failures.is_empty() else 1)
