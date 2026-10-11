extends RefCounted
## きのみ・食材のモデル図。どの CanvasItem の _draw からでも呼べる。

const OUTLINE := Color(0.25, 0.18, 0.12, 0.55)


static func ellipse(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## 中心 c、半分の大きさ half、角の半径 r の角丸四角形
static func rounded_rect(c: Vector2, half: Vector2, r: float, n: int = 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]
	for k in 4:
		var q: Vector2 = c + (half - Vector2(r, r)) * corners[k]
		for i in n + 1:
			var a := PI / 2 * k + PI / 2 * i / n
			pts.append(q + Vector2(cos(a), sin(a)) * r)
	return pts


## メインスキルの「!」の後ろに出るギザギザ。真上から時計回りに [角度(度), 半径の倍率] を
## 山・谷の順に並べた固定の表で、左右非対称・不規則にしてある（毎フレーム同じ形）。
const BURST := [
	[8, 1.10], [24, 0.74], [40, 0.88], [54, 0.76], [74, 1.24], [97, 0.72],
	[111, 0.86], [125, 0.78], [149, 1.08], [170, 0.72], [187, 0.94], [202, 0.78],
	[222, 1.18], [245, 0.72], [261, 0.86], [276, 0.77], [299, 1.20], [320, 0.73],
	[335, 0.92], [349, 0.77],
]


## 中心 c、基準の半径 r のギザギザ。stretch で横に伸ばす（「!!」用）
static func burst(c: Vector2, r: float, stretch: float = 1.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in BURST:
		var a := deg_to_rad(p[0]) - PI / 2
		pts.append(c + Vector2(cos(a) * stretch, sin(a)) * r * p[1])
	return pts


static func outline(ci: CanvasItem, pts: PackedVector2Array, color: Color, width: float) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, color, width, true)


static func draw_item(ci: CanvasItem, id: String, c: Vector2, s: float = 1.0) -> void:
	match id:
		"berry":
			_berry(ci, c, s)
		"ing_a":
			_milk(ci, c, s)
		"ing_b":
			_chocolate(ci, c, s)
		"ing_c":
			_meat(ci, c, s)
		_:
			ci.draw_circle(c, 12.0 * s, Color.WHITE)


static func _berry(ci: CanvasItem, c: Vector2, s: float) -> void:
	var body := ellipse(c, 13.0 * s, 12.0 * s)
	ci.draw_colored_polygon(body, Color("f7d43c"))
	ci.draw_colored_polygon(ellipse(c + Vector2(2, 3) * s, 10.0 * s, 8.0 * s), Color("e8b923"))
	outline(ci, body, OUTLINE, 1.6 * s)
	ci.draw_circle(c + Vector2(-4.5, -4.5) * s, 3.6 * s, Color(1, 1, 1, 0.75))
	var leaf := PackedVector2Array([
		c + Vector2(0, -11) * s, c + Vector2(7, -19) * s, c + Vector2(13, -16) * s, c + Vector2(6, -10) * s,
	])
	ci.draw_colored_polygon(leaf, Color("5cc35a"))
	outline(ci, leaf, OUTLINE, 1.2 * s)


## 牛乳瓶: 細い首と紙のふた、胴に青いラベル
static func _milk(ci: CanvasItem, c: Vector2, s: float) -> void:
	var pts := PackedVector2Array()
	# 右側を上から下へ、左右対称にして閉じる
	var right := [
		Vector2(5.5, -12), Vector2(5.5, -8), Vector2(7.5, -4), Vector2(9.5, 0),
		Vector2(9.5, 11), Vector2(8.5, 13.5), Vector2(6, 14.5),
	]
	for v in right:
		pts.append(c + v * s)
	for i in range(right.size() - 1, -1, -1):
		var v: Vector2 = right[i]
		pts.append(c + Vector2(-v.x, v.y) * s)
	ci.draw_colored_polygon(pts, Color("fdfcf6"))
	ci.draw_rect(Rect2(c + Vector2(6, 1) * s, Vector2(3.5, 12) * s), Color("e6e9ec"))
	ci.draw_rect(Rect2(c + Vector2(-9.5, 3) * s, Vector2(19, 6.5) * s), Color("4f9be0"))
	ci.draw_rect(Rect2(c + Vector2(-9.5, 4.8) * s, Vector2(19, 1.2) * s), Color(1, 1, 1, 0.8))
	outline(ci, pts, OUTLINE, 1.6 * s)
	ci.draw_line(c + Vector2(-6, -1) * s, c + Vector2(-6, 1.5) * s, Color(1, 1, 1, 0.95), 2.2 * s, true)
	# 紙のふた
	var cap := ellipse(c + Vector2(0, -12.5) * s, 7.5 * s, 3.0 * s, 20)
	ci.draw_colored_polygon(cap, Color("4f9be0"))
	ci.draw_colored_polygon(ellipse(c + Vector2(0, -13) * s, 5.0 * s, 1.8 * s, 16), Color("fdfcf6"))
	outline(ci, cap, OUTLINE, 1.2 * s)


## 板チョコ: 上はブロック模様、下半分は赤い包み紙
static func _chocolate(ci: CanvasItem, c: Vector2, s: float) -> void:
	var w := 11.0
	var top := -14.0
	var bottom := 14.0
	var bar := PackedVector2Array([
		c + Vector2(-w, top) * s, c + Vector2(w, top) * s, c + Vector2(w, bottom) * s, c + Vector2(-w, bottom) * s,
	])
	ci.draw_colored_polygon(bar, Color("6e3d22"))
	for row in 2:
		for col in 2:
			var o := Vector2(-w + 2 + col * 10, top + 2 + row * 7.5)
			ci.draw_rect(Rect2(c + o * s, Vector2(8, 5.5) * s), Color("85502f"))
			ci.draw_rect(Rect2(c + o * s, Vector2(8, 1.4) * s), Color("a06a44"))
	# 包み紙（少しななめに破れた上辺）
	var wrap := PackedVector2Array([
		c + Vector2(-w - 1, 0) * s, c + Vector2(-4, 2) * s, c + Vector2(3, -0.5) * s, c + Vector2(w + 1, 1.5) * s,
		c + Vector2(w + 1, bottom + 1) * s, c + Vector2(-w - 1, bottom + 1) * s,
	])
	ci.draw_colored_polygon(wrap, Color("dc4436"))
	ci.draw_rect(Rect2(c + Vector2(-w - 1, 8) * s, Vector2(2 * w + 2, 2.2) * s), Color("f2c14e"))
	outline(ci, bar, OUTLINE, 1.6 * s)
	outline(ci, wrap, OUTLINE, 1.2 * s)


## 骨付きマンガ肉: ななめに骨が通った大きな肉のかたまり
static func _meat(ci: CanvasItem, c: Vector2, s: float) -> void:
	var ang := -0.6
	var bone := Color("fbf6ea")
	for side in [-1.0, 1.0]:
		var d: float = side
		var tip := c + Vector2(15.5 * d, 0).rotated(ang) * s
		ci.draw_line(c, tip, OUTLINE, 6.8 * s, true)
		for k in [-1.0, 1.0]:
			var kk: float = k
			ci.draw_circle(tip + Vector2(0.5 * d, 2.8 * kk).rotated(ang) * s, 3.5 * s, OUTLINE)
	for side in [-1.0, 1.0]:
		var d: float = side
		var tip := c + Vector2(15.5 * d, 0).rotated(ang) * s
		ci.draw_line(c, tip, bone, 4.6 * s, true)
		for k in [-1.0, 1.0]:
			var kk: float = k
			ci.draw_circle(tip + Vector2(0.5 * d, 2.8 * kk).rotated(ang) * s, 2.7 * s, bone)
	var body := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28
		body.append(c + Vector2(cos(a) * 10.5, sin(a) * 9.0).rotated(ang) * s)
	ci.draw_colored_polygon(body, Color("c4683e"))
	var shade := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20
		shade.append(c + (Vector2(cos(a) * 8.0, sin(a) * 5.5) + Vector2(1, 3)).rotated(ang) * s)
	ci.draw_colored_polygon(shade, Color("a9522f"))
	outline(ci, body, OUTLINE, 1.6 * s)
	ci.draw_circle(c + Vector2(-4, -3.5).rotated(ang) * s, 2.6 * s, Color(1, 1, 1, 0.55))


## タップできるものの上に出す名札。パチモンの「…」と同じ白い角丸四角に名前を書く
static func name_tag(ci: CanvasItem, c: Vector2, text: String, font: Font) -> void:
	var size := 16
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var oval := rounded_rect(c, Vector2(w / 2 + 12, 17), 10)
	ci.draw_colored_polygon(oval, Color.WHITE)
	outline(ci, oval, Color("0d2738"), 3.0)
	ci.draw_string(font, c + Vector2(-w / 2, size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("0d2738"))
