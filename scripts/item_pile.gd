extends Node2D
## フィールドに置かれたきのみ・食材の山。タップで収容箱へ回収する。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

## 奥から手前の順に並べた積み方
const STACK := [
	Vector2(0, -26), Vector2(-9, -17), Vector2(9, -17), Vector2(-16, -6),
	Vector2(16, -6), Vector2(0, -6), Vector2(-9, 4), Vector2(9, 4),
]
const HIT_RADIUS := 46.0

var item_id := ""
## 表示中の個数（飛んでいる途中の分は着地してから足す）
var count := 0


func set_count(n: int) -> void:
	count = maxi(0, n)
	queue_redraw()


func bounce() -> void:
	scale = Vector2(1.25, 0.8)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func hit(p: Vector2) -> bool:
	return count > 0 and p.distance_to(global_position + Vector2(0, -6)) <= HIT_RADIUS


func _draw() -> void:
	if count <= 0:
		return
	draw_colored_polygon(ItemArt.ellipse(Vector2(0, 14), 30, 8), Color(0, 0, 0, 0.16))
	var n := mini(count, STACK.size())
	# 少ないときは手前から埋める
	for i in range(STACK.size() - n, STACK.size()):
		ItemArt.draw_item(self, item_id, STACK[i], 1.0)
	var text := "×%d" % count
	var pos := Vector2(-50, 44)
	draw_string_outline(FONT, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 100, 20, 6, Color.WHITE)
	draw_string(FONT, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 100, 20, Color("5a4632"))
