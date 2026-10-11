extends Node2D
## きのみ収容箱・食材収容箱の見た目。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

enum Kind { BERRY, INGREDIENT }

var kind: int = Kind.BERRY
var label := ""
var _t := 0.0


func _process(delta: float) -> void:
	# 名札をパチモンの「…」と同じ周期で上下に揺らす
	_t += delta
	queue_redraw()


const TAG_POS := Vector2(0, -84)


func hit(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-80, -112), Vector2(160, 170)).has_point(p)


func _draw() -> void:
	draw_colored_polygon(ItemArt.ellipse(Vector2(0, 38), 62, 12), Color(0, 0, 0, 0.16))
	if kind == Kind.BERRY:
		_draw_crate()
	else:
		_draw_cooler()
	ItemArt.name_tag(self, TAG_POS + Vector2(0, sin(_t * 3.0) * 4.0), label, FONT)


func _draw_crate() -> void:
	var line := Color("9a7044")
	# 開いたふた
	var lid := PackedVector2Array([Vector2(-44, -22), Vector2(44, -22), Vector2(54, -58), Vector2(-34, -58)])
	draw_colored_polygon(lid, Color("e9d3a0"))
	ItemArt.outline(self, lid, line, 2.5)
	# 中のきのみ
	var fruits := [
		[Vector2(-28, -22), "berry"], [Vector2(-8, -26), "berry"], [Vector2(14, -22), "berry"],
		[Vector2(30, -26), "berry"], [Vector2(0, -16), "berry"],
	]
	for f in fruits:
		ItemArt.draw_item(self, f[1], f[0], 0.95)
	var body := PackedVector2Array([Vector2(-50, -18), Vector2(50, -18), Vector2(46, 38), Vector2(-46, 38)])
	draw_colored_polygon(body, Color("f6e7c1"))
	for y in [-2.0, 14.0]:
		draw_line(Vector2(-48, y), Vector2(48, y), Color("e2c98f"), 3.0)
	draw_rect(Rect2(-14, -6, 28, 12), Color("c9a063"))
	ItemArt.outline(self, body, line, 2.5)


func _draw_cooler() -> void:
	var line := Color("3f6f99")
	var body := PackedVector2Array([Vector2(-50, -14), Vector2(50, -14), Vector2(46, 38), Vector2(-46, 38)])
	draw_colored_polygon(body, Color("63aee8"))
	draw_rect(Rect2(-46, 10, 92, 6), Color("4f95cf"))
	ItemArt.outline(self, body, line, 2.5)
	var lid := PackedVector2Array([Vector2(-54, -32), Vector2(54, -32), Vector2(52, -12), Vector2(-52, -12)])
	draw_colored_polygon(lid, Color("f4f8fc"))
	ItemArt.outline(self, lid, line, 2.5)
	draw_arc(Vector2(0, -32), 22, PI, TAU, 16, Color("d1d9e2"), 6.0, true)
	draw_rect(Rect2(-12, -4, 24, 8), Color("f4f8fc"))
