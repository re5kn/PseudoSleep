extends Node2D
## ベッドの上に出す「ねむる」の角丸四角形。これかベッドをタップすると睡眠の設定欄を開く。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const TEXT := "ねむる"
const FONT_SIZE := 20
const HALF := Vector2(46, 20)
const LINE := Color("0d2738")
## ベッド（背景に描いてある）のタップ範囲。この札の位置からの相対
const BED_RECT := Rect2(-70, 26, 172, 118)

var _t := 0.0


func _process(delta: float) -> void:
	# 机の名札やパチモンの「…」と同じ周期で上下に揺らす
	_t += delta
	queue_redraw()


func hit(p: Vector2) -> bool:
	var local := p - global_position
	return Rect2(-HALF - Vector2(12, 12), HALF * 2 + Vector2(24, 24)).has_point(local) or BED_RECT.has_point(local)


func _draw() -> void:
	var c := Vector2(0, sin(_t * 3.0) * 4.0)
	var box := ItemArt.rounded_rect(c, HALF, 10)
	draw_colored_polygon(box, Color.WHITE)
	ItemArt.outline(self, box, LINE, 3.0)
	var w := FONT.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(FONT, c + Vector2(-w / 2, FONT_SIZE * 0.36), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, LINE)
