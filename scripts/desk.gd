extends Node2D
## ノートが載った机。タップするとおてつだいの記録を開く。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const WOOD := Color("d9a86a")
const WOOD_DARK := Color("b8844a")
const LINE := Color("8a5f32")

var label := "おてつだい記録"
var _t := 0.0


func _process(delta: float) -> void:
	# 名札をパチモンの「…」と同じ周期で上下に揺らす
	_t += delta
	queue_redraw()


const TAG_POS := Vector2(0, -72)


func hit(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-80, -96), Vector2(160, 150)).has_point(p)


func _draw() -> void:
	draw_colored_polygon(ItemArt.ellipse(Vector2(0, 38), 58, 11), Color(0, 0, 0, 0.16))
	# 脚（奥の2本は短く見せる）
	for x in [-34.0, 30.0]:
		draw_rect(Rect2(x, -12, 6, 34), WOOD_DARK)
	for x in [-46.0, 40.0]:
		draw_rect(Rect2(x, -6, 7, 44), WOOD)
		draw_rect(Rect2(x, -6, 7, 44), LINE, false, 2.0)
	# 天板（少し上から見た形）と前の厚み
	var top := PackedVector2Array([Vector2(-42, -22), Vector2(46, -22), Vector2(54, -4), Vector2(-52, -4)])
	draw_colored_polygon(top, Color("ecc488"))
	ItemArt.outline(self, top, LINE, 2.5)
	var edge := PackedVector2Array([Vector2(-52, -4), Vector2(54, -4), Vector2(54, 4), Vector2(-52, 4)])
	draw_colored_polygon(edge, WOOD)
	ItemArt.outline(self, edge, LINE, 2.5)
	_draw_notebook()
	ItemArt.name_tag(self, TAG_POS + Vector2(0, sin(_t * 3.0) * 4.0), label, FONT)


## 開いたノートと鉛筆
func _draw_notebook() -> void:
	var page_line := Color("9fb7d6")
	var ink := Color("6b7f99")
	var left := PackedVector2Array([Vector2(-30, -40), Vector2(-2, -36), Vector2(-2, -12), Vector2(-34, -15)])
	var right := PackedVector2Array([Vector2(-2, -36), Vector2(26, -40), Vector2(31, -15), Vector2(-2, -12)])
	# 表紙がページの下から少しのぞく
	var cover := PackedVector2Array([Vector2(-33, -42), Vector2(-2, -38), Vector2(29, -42), Vector2(34, -13), Vector2(-2, -10), Vector2(-37, -13)])
	draw_colored_polygon(cover, Color("e2483d"))
	for page in [left, right]:
		draw_colored_polygon(page, Color("fffdf6"))
		ItemArt.outline(self, page, ink, 1.6)
	for i in 3:
		var y := -32.0 + i * 6.0
		draw_line(Vector2(-27, y - 1 + i * 0.3), Vector2(-6, y + 2), page_line, 1.5, true)
		draw_line(Vector2(2, y + 2), Vector2(23 + i * 0.6, y - 1), page_line, 1.5, true)
	draw_line(Vector2(-2, -36), Vector2(-2, -12), ink, 1.6)
	# 鉛筆
	draw_line(Vector2(14, -14), Vector2(40, -30), Color("f6c445"), 5.0, true)
	draw_line(Vector2(38, -29), Vector2(43, -32), Color("f4a6a0"), 5.0, true)
	draw_line(Vector2(11, -12), Vector2(15, -15), Color("5a4632"), 3.0, true)
