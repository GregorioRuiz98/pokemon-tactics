extends Control

const Art = preload("res://ui/visual_assets.gd")
var identity: String = "title_keyart"
var dimmed: bool = false
var title_space: bool = false
var artwork: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func configure(slot_id: String, dark: bool = false, title_layout: bool = false) -> void:
	identity = slot_id
	dimmed = dark
	title_space = title_layout
	artwork = Art.texture(identity)
	queue_redraw()

func _draw() -> void:
	if artwork==null or size.x<=0 or size.y<=0: return
	var source: Vector2 = artwork.get_size()
	var scale_factor: float = maxf(size.x/source.x,size.y/source.y)
	var crop: Vector2 = size/scale_factor
	draw_texture_rect_region(artwork,Rect2(Vector2.ZERO,size),Rect2((source-crop)/2,crop))
	if dimmed: draw_rect(Rect2(Vector2.ZERO,size),Color(0.04,0.1,0.14,0.88))
	if title_space:
		var shade: PackedVector2Array = PackedVector2Array([Vector2.ZERO,Vector2(size.x*0.7,0),Vector2(size.x*0.7,size.y),Vector2(0,size.y)])
		draw_polygon(shade,PackedColorArray([Color(0.04,0.1,0.14,0.97),Color(0.04,0.1,0.14,0),Color(0.04,0.1,0.14,0),Color(0.04,0.1,0.14,0.97)]))
	if not dimmed and not Art.final_ready(identity) and size.x>=300 and size.y>=70:
		var record: Dictionary = Art.entry(identity)
		var text: String = record.prompt+" · Arte provisional"
		var font: Font = get_theme_default_font()
		var width: float = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		var origin: Vector2 = Vector2(size.x-width-16,size.y-(100 if title_space else 12))
		draw_rect(Rect2(origin-Vector2(8,17),Vector2(width+16,24)),Color(0.04,0.1,0.14,0.9))
		draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("c5c9b7"))
