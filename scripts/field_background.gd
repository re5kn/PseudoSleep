extends Node2D
## 無人島のフィールド背景。画像を使わず図形で描く。

const ItemArt = preload("res://scripts/item_art.gd")

const SIZE := Vector2(720, 1040)
const ISLAND := Vector2(360, 570)

var _waves: Array = []
var _sparkles: Array = []
var _tufts: Array = []
var _flowers: Array = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261010
	for i in 70:
		_waves.append([Vector2(rng.randf_range(0, SIZE.x), rng.randf_range(0, SIZE.y)), rng.randf_range(14, 40)])
	for i in 40:
		_sparkles.append([Vector2(rng.randf_range(0, SIZE.x), rng.randf_range(0, SIZE.y)), rng.randf_range(2, 4.5)])
	while _tufts.size() < 46:
		var p := Vector2(rng.randf_range(80, 640), rng.randf_range(340, 790))
		if _on_grass(p, 0.9):
			_tufts.append(p)
	var flower_colors := [Color("ffd84a"), Color("f59bd6"), Color("ffffff"), Color("c58cf0")]
	while _flowers.size() < 34:
		var p := Vector2(rng.randf_range(80, 640), rng.randf_range(340, 790))
		if _on_grass(p, 0.88) and absf(p.x - 360) > 90:
			_flowers.append([p, flower_colors[rng.randi_range(0, flower_colors.size() - 1)]])


func _on_grass(p: Vector2, k: float) -> bool:
	var d := p - (ISLAND + Vector2(0, -6))
	return Vector2(d.x / (308 * k), d.y / (226 * k)).length() <= 1.0


func _draw() -> void:
	_draw_sea()
	_draw_rock(Vector2(240, 140), 1.1)
	_draw_rock(Vector2(70, 905), 1.0)
	_draw_rock(Vector2(660, 880), 1.2)
	_draw_rock(Vector2(560, 985), 0.6)
	_draw_island()
	_draw_bush(Vector2(196, 395), 1.0)
	_draw_bush(Vector2(612, 700), 0.9)
	for t in _tufts:
		_draw_tuft(t)
	for f in _flowers:
		_draw_flower(f[0], f[1])


func _draw_sea() -> void:
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(SIZE.x, 0), SIZE, Vector2(0, SIZE.y)]),
		PackedColorArray([Color("7fe3f0"), Color("7fe3f0"), Color("45c9e0"), Color("45c9e0")])
	)
	for w in _waves:
		var p: Vector2 = w[0]
		draw_line(p, p + Vector2(w[1], 0), Color(1, 1, 1, 0.28), 2.0, true)
	for s in _sparkles:
		var p: Vector2 = s[0]
		var r: float = s[1]
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0, -r * 2), p + Vector2(r * 0.4, 0), p + Vector2(0, r * 2), p + Vector2(-r * 0.4, 0),
		]), Color(1, 1, 1, 0.85))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-r * 2, 0), p + Vector2(0, r * 0.4), p + Vector2(r * 2, 0), p + Vector2(0, -r * 0.4),
		]), Color(1, 1, 1, 0.85))


func _draw_island() -> void:
	var c := ISLAND
	draw_colored_polygon(ItemArt.ellipse(c + Vector2(0, 18), 372, 292, 64), Color(1, 1, 1, 0.35))
	draw_colored_polygon(ItemArt.ellipse(c + Vector2(0, 26), 348, 268, 64), Color("8fdfe0"))
	draw_colored_polygon(ItemArt.ellipse(c + Vector2(0, 10), 340, 262, 64), Color("fbf4dc"))
	draw_colored_polygon(ItemArt.ellipse(c + Vector2(0, -6), 312, 230, 64), Color("6cd83b"))
	draw_colored_polygon(ItemArt.ellipse(c + Vector2(-10, -24), 270, 190, 64), Color("7fe04a"))
	draw_colored_polygon(ItemArt.ellipse(c + Vector2(-30, -50), 180, 120, 48), Color(1, 1, 1, 0.08))


func _draw_rock(p: Vector2, s: float) -> void:
	draw_colored_polygon(ItemArt.ellipse(p + Vector2(0, 16) * s, 56 * s, 12 * s), Color(1, 1, 1, 0.4))
	var big := PackedVector2Array([
		p + Vector2(-48, 16) * s, p + Vector2(-34, -16) * s, p + Vector2(-8, -30) * s,
		p + Vector2(16, -18) * s, p + Vector2(24, 16) * s,
	])
	draw_colored_polygon(big, Color("b9d0e0"))
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-8, -30) * s, p + Vector2(16, -18) * s, p + Vector2(24, 16) * s, p + Vector2(-2, 16) * s,
	]), Color("9ab6cc"))
	var small := PackedVector2Array([
		p + Vector2(14, 16) * s, p + Vector2(26, -8) * s, p + Vector2(44, -12) * s, p + Vector2(56, 16) * s,
	])
	draw_colored_polygon(small, Color("a9c3d6"))


func _draw_bush(p: Vector2, s: float) -> void:
	draw_colored_polygon(ItemArt.ellipse(p + Vector2(0, 34) * s, 46 * s, 10 * s), Color(0, 0, 0, 0.12))
	draw_circle(p + Vector2(-20, 8) * s, 30 * s, Color("4cbf3a"))
	draw_circle(p + Vector2(22, 10) * s, 28 * s, Color("4cbf3a"))
	draw_circle(p + Vector2(0, -8) * s, 36 * s, Color("5fd046"))
	draw_circle(p + Vector2(-10, -18) * s, 16 * s, Color("7ee25c"))


func _draw_tuft(p: Vector2) -> void:
	var c := Color("43b532")
	draw_line(p, p + Vector2(-6, -12), c, 2.5, true)
	draw_line(p, p + Vector2(0, -15), c, 2.5, true)
	draw_line(p, p + Vector2(6, -12), c, 2.5, true)


func _draw_flower(p: Vector2, col: Color) -> void:
	for k in 5:
		var a := TAU * k / 5.0
		draw_circle(p + Vector2(cos(a), sin(a)) * 5.0, 4.0, col)
	draw_circle(p, 3.0, Color("f5a623"))
