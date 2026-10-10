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
	_draw_dock()
	_draw_bush(Vector2(196, 395), 1.0)
	_draw_bush(Vector2(612, 700), 0.9)
	for t in _tufts:
		_draw_tuft(t)
	for f in _flowers:
		_draw_flower(f[0], f[1])
	_draw_table(Vector2(455, 360))
	_draw_stump(Vector2(150, 760))
	_draw_stump(Vector2(185, 772))
	_draw_stump(Vector2(220, 780))
	_draw_stump(Vector2(668, 520))
	_draw_shell(Vector2(78, 690))
	_draw_shell(Vector2(470, 825))
	_draw_palm(Vector2(545, 410), 1.0)
	_draw_palm(Vector2(645, 445), 0.9)


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


func _draw_dock() -> void:
	var wood := Color("ead6a8")
	var dark := Color("c8a874")
	var deck := PackedVector2Array([Vector2(20, 360), Vector2(205, 322), Vector2(232, 358), Vector2(48, 398)])
	draw_colored_polygon(deck, wood)
	for i in range(1, 8):
		var t := i / 8.0
		draw_line(Vector2(20, 360).lerp(Vector2(205, 322), t), Vector2(48, 398).lerp(Vector2(232, 358), t), dark, 2.0)
	ItemArt.outline(self, deck, Color("a88350"), 2.0)
	for post in [Vector2(30, 362), Vector2(56, 400), Vector2(200, 325)]:
		draw_rect(Rect2(post + Vector2(-5, 0), Vector2(10, 42)), Color("c49a62"))
		draw_colored_polygon(ItemArt.ellipse(post, 5, 2.5, 12), Color("e2c18c"))


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


func _draw_table(p: Vector2) -> void:
	draw_colored_polygon(ItemArt.ellipse(p + Vector2(0, 40), 62, 10), Color(0, 0, 0, 0.12))
	for x in [-40.0, 34.0]:
		draw_line(p + Vector2(x, 6), p + Vector2(x - 8, 40), Color("b38a55"), 5.0)
		draw_line(p + Vector2(x, 6), p + Vector2(x + 8, 40), Color("b38a55"), 5.0)
	var top := PackedVector2Array([p + Vector2(-56, -6), p + Vector2(44, -14), p + Vector2(58, 8), p + Vector2(-46, 16)])
	draw_colored_polygon(top, Color("efd9a8"))
	ItemArt.outline(self, top, Color("b38a55"), 2.0)
	ItemArt.draw_item(self, "ing_a", p + Vector2(-12, -2), 0.7)
	ItemArt.draw_item(self, "berry", p + Vector2(12, -4), 0.7)


func _draw_stump(p: Vector2) -> void:
	draw_rect(Rect2(p + Vector2(-8, -18), Vector2(16, 22)), Color("c49a62"))
	draw_colored_polygon(ItemArt.ellipse(p + Vector2(0, -18), 8, 3.5, 14), Color("e8c890"))


func _draw_shell(p: Vector2) -> void:
	var shell := PackedVector2Array([p + Vector2(-9, 4), p + Vector2(-6, -6), p + Vector2(0, -9), p + Vector2(6, -6), p + Vector2(9, 4)])
	draw_colored_polygon(shell, Color("f6c9c0"))
	ItemArt.outline(self, shell, Color("d99a8c"), 1.5)


func _draw_palm(base: Vector2, s: float) -> void:
	var top := base + Vector2(-30, -230) * s
	draw_colored_polygon(ItemArt.ellipse(base + Vector2(-10, 4) * s, 60 * s, 12 * s), Color(0, 0, 0, 0.14))
	var trunk := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		var mid := base.lerp(top, t) + Vector2(sin(t * PI) * 22 * s, 0)
		trunk.append(mid)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in trunk.size():
		var w := lerpf(11.0, 6.0, i / 12.0) * s
		left.append(trunk[i] + Vector2(-w, 0))
		right.append(trunk[i] + Vector2(w, 0))
	right.reverse()
	draw_colored_polygon(left + right, Color("b97a43"))
	for i in range(1, 12, 2):
		draw_line(trunk[i] + Vector2(-8, 0) * s, trunk[i] + Vector2(8, 3) * s, Color("98602f"), 2.0)
	var angles := [-170.0, -135.0, -100.0, -60.0, -25.0, 10.0, 160.0, 35.0]
	for deg in angles:
		_draw_frond(top, deg_to_rad(deg), 95 * s)
	draw_circle(top + Vector2(-6, 8) * s, 7 * s, Color("8a5a2b"))
	draw_circle(top + Vector2(6, 9) * s, 7 * s, Color("7a4a26"))


func _draw_frond(origin: Vector2, angle: float, length: float) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	var normal := Vector2(-dir.y, dir.x)
	var droop := Vector2(0, length * 0.25)
	var tip := origin + dir * length + droop
	var mid := origin + dir * length * 0.55 + droop * 0.4
	var leaf := PackedVector2Array([
		origin, mid + normal * 16, tip, mid - normal * 12,
	])
	draw_colored_polygon(leaf, Color("7fdc3a"))
	draw_colored_polygon(PackedVector2Array([origin, mid - normal * 12, tip]), Color("5fc22f"))
	draw_line(origin, mid, Color("4aa82a"), 2.0, true)
	draw_line(mid, tip, Color("4aa82a"), 2.0, true)
