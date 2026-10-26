extends RefCounted

const ORDER: Array[String] = ["oak","pine","bush","log","rock","pillar","fence","railing","desk","server","bin","statue","tomb","cottage","turbine","crystal"]
static var cached: Texture2D

static func texture() -> Texture2D:
	if cached==null: cached = load("res://assets/kanto/props.png")
	return cached

static func region(kind: String) -> Rect2:
	var index: int = maxi(0,ORDER.find(kind))
	var cell: Vector2 = texture().get_size()/4
	return Rect2(Vector2(index%4,int(index/4.0))*cell,cell)

static func rect(foot: Vector2, kind: String, factor: float) -> Rect2:
	var size: Vector2 = Vector2(76,76)*factor
	if kind in ["oak","pine"]: size = Vector2(100,108)*factor
	elif kind=="cottage": size = Vector2(112,108)*factor
	elif kind in ["bush","log","fence","railing"]: size = Vector2(76,64)*factor
	return Rect2(foot-Vector2(size.x*.5,size.y*.92),size)
