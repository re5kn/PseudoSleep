extends Node2D
## ベッドと、その上に出す「ねむる」の角丸四角形。どちらかをタップすると睡眠の設定欄を開く。
## 机や収容箱と同じく背景とは別に描き、夕方・夜の色合いを重ねない。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const TEXT := "ねむる"
const FONT_SIZE := 20
const HALF := Vector2(46, 20)
const LINE := Color("0d2738")
## ベッドのタップ範囲（ベッドの中心からの相対）と、「ねむる」の札の位置
const BED_RECT := Rect2(-86, -64, 172, 118)
const TAG_POS := Vector2(-16, -90)

var _t := 0.0


func _process(delta: float) -> void:
	# 机の名札やパチモンの「…」と同じ周期で上下に揺らす
	_t += delta
	queue_redraw()


func hit(p: Vector2) -> bool:
	var local := p - global_position
	return Rect2(TAG_POS - HALF - Vector2(12, 12), HALF * 2 + Vector2(24, 24)).has_point(local) or BED_RECT.has_point(local)


func _draw() -> void:
	_draw_bed()
	var c := TAG_POS + Vector2(0, sin(_t * 3.0) * 4.0)
	var box := ItemArt.rounded_rect(c, HALF, 10)
	draw_colored_polygon(box, Color.WHITE)
	ItemArt.outline(self, box, LINE, 3.0)
	var w := FONT.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(FONT, c + Vector2(-w / 2, FONT_SIZE * 0.36), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, LINE)


func _draw_bed() -> void:
	var p := Vector2.ZERO
	# 左下が足元、右上が枕の斜め向き。L=長さ方向、W=幅方向、H=厚み
	var L := Vector2(110, -45)
	var W := Vector2(52, 22)
	var H := Vector2(0, 16)
	var a := p - L / 2 - W / 2
	var b := a + W
	var c := b + L
	var d := a + L
	var line := Color("a8794a")
	var shadow := PackedVector2Array([a + H * 2.6 + Vector2(-6, 0), b + H * 2.6 + Vector2(0, 6), c + H * 2.6 + Vector2(8, 4), d + H * 2.6 + Vector2(6, -4)])
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.12))
	# 足は影の位置（H * 2.6）まで届く。頭側の2本はヘッドボードの下から出る
	for q in [d, a, c, b]:
		draw_rect(Rect2(q + H + Vector2(-3, -2), Vector2(6, H.y * 1.6 + 2)), Color("b38a55"))
	# ヘッドボード（上が丸い板）
	var head := PackedVector2Array([c + H * 1.6, d + H * 1.6])
	for i in 13:
		var t := i / 12.0
		head.append(d.lerp(c, t) + Vector2(0, -22 - 16 * sin(t * PI)))
	var thick := L.normalized() * 5
	var head_back := PackedVector2Array()
	for v in head:
		head_back.append(v + thick)
	draw_colored_polygon(head_back, Color("c98f52"))
	draw_colored_polygon(head, Color("e8b878"))
	ItemArt.outline(self, head, line, 2.0)
	# マットレス（上面・手前の側面・足元の面）
	var top := PackedVector2Array([a, b, c, d])
	var side := PackedVector2Array([b, c, c + H, b + H])
	var foot := PackedVector2Array([a, b, b + H, a + H])
	draw_colored_polygon(side, Color("efe6d2"))
	draw_colored_polygon(foot, Color("e6dcc6"))
	draw_colored_polygon(top, Color("fffaf0"))
	# まくら
	var pc := a + L * 0.84 + W * 0.5 + Vector2(0, -3)
	var pillow := PackedVector2Array()
	for i in 20:
		var ang := TAU * i / 20.0
		pillow.append(pc + W.normalized() * cos(ang) * 22 + L.normalized() * sin(ang) * 8)
	draw_colored_polygon(pillow, Color("ffffff"))
	ItemArt.outline(self, pillow, Color("d8ccb4"), 1.5)
	# 掛け布団（足元側を覆い、手前と足元に垂れる）
	var k := 0.75
	var bl_top := PackedVector2Array([a, b, b + L * k, a + L * k])
	var bl_side := PackedVector2Array([b, b + L * k, b + L * k + H * 1.25, b + H * 1.25])
	var bl_foot := PackedVector2Array([a, b, b + H * 1.25, a + H * 1.25])
	draw_colored_polygon(bl_side, Color("ee93b5"))
	draw_colored_polygon(bl_foot, Color("e486aa"))
	draw_colored_polygon(bl_top, Color("f7a8c4"))
	draw_colored_polygon(PackedVector2Array([a + L * (k - 0.1), b + L * (k - 0.1), b + L * k, a + L * k]), Color("fcd3e1"))
	for uv in [Vector2(0.12, 0.3), Vector2(0.22, 0.75), Vector2(0.36, 0.4), Vector2(0.46, 0.8)]:
		draw_circle(a + L * uv.x + W * uv.y, 2.5, Color(1, 1, 1, 0.8))
	for uv in [Vector2(0.15, 0.55), Vector2(0.4, 0.5)]:
		draw_circle(b + L * uv.x + H * uv.y, 2.5, Color(1, 1, 1, 0.8))
	ItemArt.outline(self, PackedVector2Array([a, b, b + H * 1.25, a + H * 1.25]), Color("d97a9e"), 1.5)
	ItemArt.outline(self, PackedVector2Array([b, b + L * k, b + L * k + H * 1.25, b + H * 1.25]), Color("d97a9e"), 1.5)
	ItemArt.outline(self, PackedVector2Array([a, b, b + L * k, a + L * k]), Color("d97a9e"), 1.5)
	ItemArt.outline(self, PackedVector2Array([b + L * k, c, d, a + L * k]), Color("d8ccb4"), 1.5)
	ItemArt.outline(self, PackedVector2Array([b + L * k + H * 1.25, b + L * k, c, c + H]), Color("d8ccb4"), 1.5)
