extends Node2D
## ベッドの上に出す「ねむる」の吹き出し。タップすると睡眠の設定欄を開く。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const TEXT := "ねむる"
const FONT_SIZE := 20
const HALF := Vector2(46, 20)
## しっぽの先（ベッドの枕のあたりを指す）
const TAIL_TIP := Vector2(16, 34)
const LINE := Color("0d2738")

var _t := 0.0


func _process(delta: float) -> void:
	# 机の名札やパチモンの「…」と同じ周期で上下に揺らす
	_t += delta
	queue_redraw()


func hit(p: Vector2) -> bool:
	return Rect2(global_position - HALF - Vector2(12, 12), HALF * 2 + Vector2(24, 36)).has_point(p)


func _draw() -> void:
	var c := Vector2(0, sin(_t * 3.0) * 4.0)
	var oval := ItemArt.rounded_rect(c, HALF, 14)
	draw_colored_polygon(oval, Color.WHITE)
	ItemArt.outline(self, oval, LINE, 3.0)
	# しっぽは吹き出しの枠に重ねて描き、付け根の線を隠す
	var a := c + Vector2(-2, HALF.y - 3)
	var b := c + Vector2(16, HALF.y - 3)
	var tip := TAIL_TIP
	draw_colored_polygon(PackedVector2Array([a, b, tip]), Color.WHITE)
	draw_line(a + Vector2(0, 1.5), tip, LINE, 3.0, true)
	draw_line(b + Vector2(0, 1.5), tip, LINE, 3.0, true)
	var w := FONT.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(FONT, c + Vector2(-w / 2, FONT_SIZE * 0.36), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, LINE)
