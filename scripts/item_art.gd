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
			_apple(ci, c, s)
		"ing_b":
			_corn(ci, c, s)
		_:
			ci.draw_circle(c, 12.0 * s, Color.WHITE)


static func _berry(ci: CanvasItem, c: Vector2, s: float) -> void:
	var body := ellipse(c, 13.0 * s, 12.0 * s)
	ci.draw_colored_polygon(body, Color("4f7fe6"))
	ci.draw_colored_polygon(ellipse(c + Vector2(2, 3) * s, 10.0 * s, 8.0 * s), Color("3f68cc"))
	outline(ci, body, OUTLINE, 1.6 * s)
	ci.draw_circle(c + Vector2(-4.5, -4.5) * s, 3.6 * s, Color(1, 1, 1, 0.75))
	var leaf := PackedVector2Array([
		c + Vector2(0, -11) * s, c + Vector2(7, -19) * s, c + Vector2(13, -16) * s, c + Vector2(6, -10) * s,
	])
	ci.draw_colored_polygon(leaf, Color("5cc35a"))
	outline(ci, leaf, OUTLINE, 1.2 * s)


static func _apple(ci: CanvasItem, c: Vector2, s: float) -> void:
	var body := ellipse(c + Vector2(0, 1) * s, 13.0 * s, 12.0 * s)
	ci.draw_colored_polygon(body, Color("ec4c3c"))
	ci.draw_colored_polygon(ellipse(c + Vector2(3, 4) * s, 9.0 * s, 7.0 * s), Color("d23a2d"))
	outline(ci, body, OUTLINE, 1.6 * s)
	ci.draw_circle(c + Vector2(-5, -3) * s, 3.2 * s, Color(1, 1, 1, 0.7))
	ci.draw_line(c + Vector2(0, -9) * s, c + Vector2(2, -16) * s, Color("7a4a26"), 2.4 * s, true)
	var leaf := PackedVector2Array([
		c + Vector2(2, -13) * s, c + Vector2(10, -18) * s, c + Vector2(13, -13) * s, c + Vector2(6, -11) * s,
	])
	ci.draw_colored_polygon(leaf, Color("5cc35a"))


static func _corn(ci: CanvasItem, c: Vector2, s: float) -> void:
	var husk_l := PackedVector2Array([
		c + Vector2(-2, 14) * s, c + Vector2(-13, 4) * s, c + Vector2(-11, -8) * s, c + Vector2(-3, 6) * s,
	])
	var husk_r := PackedVector2Array([
		c + Vector2(2, 14) * s, c + Vector2(13, 4) * s, c + Vector2(11, -8) * s, c + Vector2(3, 6) * s,
	])
	var cob := ellipse(c + Vector2(0, -2) * s, 7.5 * s, 14.0 * s)
	ci.draw_colored_polygon(cob, Color("f7d23e"))
	outline(ci, cob, OUTLINE, 1.6 * s)
	for row in 4:
		var y := (-11.0 + row * 6.0) * s
		ci.draw_line(c + Vector2(-5 * s, y), c + Vector2(5 * s, y), Color("e0b326"), 1.2 * s)
	ci.draw_colored_polygon(husk_l, Color("6fcf4f"))
	ci.draw_colored_polygon(husk_r, Color("5cbf44"))
	outline(ci, husk_l, OUTLINE, 1.2 * s)
	outline(ci, husk_r, OUTLINE, 1.2 * s)
