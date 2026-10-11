extends RefCounted
## きのみ・食材のモデル図。どの CanvasItem の _draw からでも呼べる。

const OUTLINE := Color(0.25, 0.18, 0.12, 0.55)


static func ellipse(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
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
