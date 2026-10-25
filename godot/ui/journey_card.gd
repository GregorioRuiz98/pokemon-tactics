extends Control

const Art = preload("res://ui/visual_assets.gd")
var summary: Dictionary = {}
var portraits: Array[Texture2D] = []

func _draw() -> void:
	var font: Font = get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO,size),Color("102830"))
	draw_texture_rect(Art.texture("battle_surround"),Rect2(Vector2.ZERO,size),false,Color(1,1,1,.15))
	draw_string(font,Vector2(40,50),"POKÉMON / TACTICS",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("eccb7f"))
	draw_string(font,Vector2(40,88),summary.title,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("eee8ce"))
	var stats: Dictionary = summary.stats
	draw_string(font,Vector2(40,125),"%d medallas   ·   %d combates   ·   %d bajas   ·   %d rondas" % [summary.medals,stats.battles,stats.kos,stats.rounds],HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("a5cfbe"))
	for index: int in summary.team.size():
		var member: Dictionary = summary.team[index]
		var at: Vector2 = Vector2(40+(index%3)*300,158+int(index/3.0)*128)
		draw_style_box(preload("res://ui/game_skin.gd").panel(Color("71918b")),Rect2(at,Vector2(280,108)))
		draw_texture_rect(portraits[index],Rect2(at+Vector2(12,12),Vector2(72,72)),false)
		draw_string(font,at+Vector2(96,35),member.name,HORIZONTAL_ALIGNMENT_LEFT,174,19,Color("eee8ce"))
		draw_string(font,at+Vector2(96,62),"Nv. %d · %s" % [member.level,"KO" if member.hp<=0 else "En pie"],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("eccb7f"))
	draw_string(font,Vector2(40,442),"Semilla: "+summary.seed,HORIZONTAL_ALIGNMENT_LEFT,880,17,Color("eee8ce"))
	draw_string(font,Vector2(40,470),"Reto reproducible · edición 21 · inicial %d · mapa %d×%d" % [summary.starter,summary.width,summary.width],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("a5cfbe"))
	var code: String = summary.code
	for index: int in int(ceil(code.length()/96.0)):
		draw_string(font,Vector2(40,497+index*15),code.substr(index*96,96),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b4c3ac"))
	draw_string(font,Vector2(40,615),"Proyecto de fans · Windows offline · "+str(ProjectSettings.get_setting("application/config/version")),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("eccb7f"))
