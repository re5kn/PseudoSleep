extends Node2D
## ベッドと、その上に出す「ねむる」の角丸四角形。どちらかをタップすると睡眠の設定欄を開く。
## 机や収容箱と同じく背景とは別に描き、夕方・夜の色合いを重ねない。
## いいキャンプチケットが有効なときは天蓋付きのベッドになる（見た目だけ）。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const TEXT := "ねむる"
const FONT_SIZE := 20
const HALF := Vector2(46, 20)
const LINE := Color("0d2738")
## ベッドのタップ範囲（ベッドの中心からの相対）と、「ねむる」の札の位置
const BED_RECT := Rect2(-86, -64, 172, 118)
const TAG_POS := Vector2(-16, -90)
## 天蓋付きのときの札の位置（天蓋の上に出す）とタップ範囲
const CANOPY_TAG_POS := Vector2(26, -146)
const CANOPY_BED_RECT := Rect2(-90, -126, 232, 226)
## 天蓋の柱の高さ
const CANOPY_UP := Vector2(0, -84)

## いいキャンプチケットが有効なら天蓋付きで描く
var canopy := false
var _t := 0.0


func _process(delta: float) -> void:
	# 机の名札やパチモンの「…」と同じ周期で上下に揺らす
	_t += delta
	queue_redraw()


func tag_pos() -> Vector2:
	return CANOPY_TAG_POS if canopy else TAG_POS


func hit(p: Vector2) -> bool:
	var local := p - global_position
	var rect := CANOPY_BED_RECT if canopy else BED_RECT
	return Rect2(tag_pos() - HALF - Vector2(12, 12), HALF * 2 + Vector2(24, 24)).has_point(local) or rect.has_point(local)


func _draw() -> void:
	_draw_bed()
	var c := tag_pos() + Vector2(0, sin(_t * 3.0) * 4.0)
	var box := ItemArt.rounded_rect(c, HALF, 10)
	draw_colored_polygon(box, Color.WHITE)
	ItemArt.outline(self, box, LINE, 3.0)
	var w := FONT.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(FONT, c + Vector2(-w / 2, FONT_SIZE * 0.36), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, LINE)


func _draw_bed() -> void:
	var p := Vector2.ZERO
	# 左下が足元、右上が枕の斜め向き。L=長さ方向、W=幅方向、H=厚み
	var L := Vector2(110, -45)
	# 天蓋付きは横幅2倍のダブルベッド。奥の辺はそのままで手前に広げる
	var W := Vector2(52, 22) * (2.0 if canopy else 1.0)
	if canopy:
		p += Vector2(52, 22) / 2
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
	if canopy:
		# 奥側の2本の柱はマットレスより先に描く
		for q in [a, d]:
			_post(q, H)
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
	# まくら（ダブルベッドは2つ並べる）
	for pv in ([0.27, 0.73] if canopy else [0.5]):
		var pc: Vector2 = a + L * 0.84 + W * pv + Vector2(0, -3)
		var pillow := PackedVector2Array()
		for i in 20:
			var ang := TAU * i / 20.0
			pillow.append(pc + W.normalized() * cos(ang) * 22 + L.normalized() * sin(ang) * 8)
		draw_colored_polygon(pillow, Color("ffffff"))
		ItemArt.outline(self, pillow, Color("d8ccb4"), 1.5)
	# 掛け布団（足元側を覆い、手前と足元に垂れる）
	var k := 0.75
	if canopy:
		_draw_luxury_blanket(a, b, L, W, H, k)
	else:
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
	if canopy:
		_draw_canopy(a, b, c, d, H)


## 天蓋付きのときの高級な掛け布団。ワインレッドのキルティングに金のパイピングと房飾り
func _draw_luxury_blanket(a: Vector2, b: Vector2, L: Vector2, W: Vector2, H: Vector2, k: float) -> void:
	var drop := H * 1.4
	var gold := Color("e0b84c")
	var gold_dark := Color("a8812a")
	var top := PackedVector2Array([a, b, b + L * k, a + L * k])
	var side := PackedVector2Array([b, b + L * k, b + L * k + drop, b + drop])
	var foot := PackedVector2Array([a, b, b + drop, a + drop])
	draw_colored_polygon(side, Color("7f1d3a"))
	draw_colored_polygon(foot, Color("731834"))
	draw_colored_polygon(top, Color("9c2a4a"))
	# 上面のキルティング（ひし形の縫い目と金のボタン）。s は足元→枕方向、v は奥→手前
	var at := func(sv: Vector2) -> Vector2: return a + L * k * sv.x + W * sv.y
	var seam := Color("6e1530")
	var step := 0.25
	for i in range(1, 8):
		var c := i * step
		draw_line(at.call(Vector2(maxf(0, c - 1), minf(1, c))), at.call(Vector2(minf(1, c), maxf(0, c - 1))), seam, 1.2)
		var d := c - 1.0
		draw_line(at.call(Vector2(maxf(0, d), maxf(0, -d))), at.call(Vector2(minf(1, 1 + d), minf(1, 1 - d))), seam, 1.2)
	for si in range(1, 4):
		for vi in range(1, 4):
			if (si + vi) % 2 == 0:
				draw_circle(at.call(Vector2(si * step, vi * step)), 1.8, gold)
	# 折り返した白いサテンのシーツと、その手前の金の帯
	draw_colored_polygon(PackedVector2Array([a + L * (k - 0.1), b + L * (k - 0.1), b + L * k, a + L * k]), Color("fffaf0"))
	draw_colored_polygon(PackedVector2Array([a + L * (k - 0.14), b + L * (k - 0.14), b + L * (k - 0.1), a + L * (k - 0.1)]), gold)
	# 側面の金の縁取りライン
	for e in [[a, b], [b, b + L * k]]:
		draw_line(e[0] + drop * 0.72, e[1] + drop * 0.72, gold, 1.5)
	# 下端の房飾り
	for e in [[a, b, 6], [b, b + L * k, 10]]:
		var n: int = e[2]
		for i in n + 1:
			var q: Vector2 = (e[0] as Vector2).lerp(e[1], float(i) / n) + drop
			draw_line(q, q + Vector2(0, 5), gold, 2.0)
	# 金のパイピング
	ItemArt.outline(self, foot, gold_dark, 1.5)
	ItemArt.outline(self, side, gold_dark, 1.5)
	ItemArt.outline(self, top, gold, 2.0)


## 天蓋の柱（足の下端から天蓋まで）
func _post(q: Vector2, h: Vector2) -> void:
	var r := Rect2(q + CANOPY_UP + Vector2(-3, 0), Vector2(6, h.y * 2.6 - CANOPY_UP.y))
	draw_rect(r, Color("e8b878"))
	draw_rect(r, Color("a8794a"), false, 1.5)
	draw_circle(q + CANOPY_UP + Vector2(0, -2), 4.5, Color("e8b878"))
	draw_arc(q + CANOPY_UP + Vector2(0, -2), 4.5, 0, TAU, 16, Color("a8794a"), 1.5)


## 手前の柱と、天蓋（屋根の布・ふち飾り・柱に結んだカーテン）
func _draw_canopy(a: Vector2, b: Vector2, c: Vector2, d: Vector2, h: Vector2) -> void:
	var u := CANOPY_UP
	var cloth := Color("fffaf0")
	var cloth_shade := Color("f3e3ea")
	var trim := Color("f7a8c4")
	var trim_line := Color("d97a9e")
	# 奥のカーテン（奥の柱に結んで手前の布より先に描く）
	_drape(a, (d - a), cloth_shade, trim_line)
	_post(b, h)
	_post(c, h)
	# 屋根の布（上面）
	var roof := PackedVector2Array([a + u, b + u, c + u, d + u])
	draw_colored_polygon(roof, cloth)
	ItemArt.outline(self, roof, Color("d8ccb4"), 1.5)
	# 手前に垂れるふち飾り（足元側と手前の側面）。下側は波形
	for e in [[a, b], [b, c]]:
		var p0: Vector2 = e[0] + u
		var p1: Vector2 = e[1] + u
		var frill := PackedVector2Array([p0, p1])
		var n := 4 if e[0] == a else 8
		for i in range(n * 6, -1, -1):
			var t := float(i) / (n * 6)
			var wave := absf(sin(t * n * PI))
			frill.append(p0.lerp(p1, t) + Vector2(0, 9 + 5 * wave))
		draw_colored_polygon(frill, trim)
		ItemArt.outline(self, frill, trim_line, 1.5)
		var mid0: Vector2 = p0 + Vector2(0, 4)
		var mid1: Vector2 = p1 + Vector2(0, 4)
		draw_line(mid0, mid1, Color(1, 1, 1, 0.8), 1.5)
	# 手前の柱に結んだカーテン
	_drape(b, (a - b), cloth_shade, trim_line)
	_drape(b, (c - b), cloth_shade, trim_line)
	_drape(c, (b - c), cloth_shade, trim_line)


## 柱 q から辺の向き toward に広がり、柱の中ほどでリボンで結んだカーテン
func _drape(q: Vector2, toward: Vector2, color: Color, line: Color) -> void:
	var u := CANOPY_UP
	var top := q + u + Vector2(0, 12)
	var tie := q + u * 0.5
	var poly := PackedVector2Array([top])
	# 上辺（ふち飾りの下）を少し広げ、結び目までしぼる
	for i in 9:
		var t := i / 8.0
		var w := 0.26 * (1.0 - t) * (1.0 - t) + 0.03
		poly.append(top.lerp(tie, t) + toward * w)
	# 結び目から下はふわっと広がって床近くまで
	var bottom := q + u * 0.06
	for i in range(1, 9):
		var t := i / 8.0
		var w := 0.03 + 0.11 * sin(t * PI * 0.5)
		poly.append(tie.lerp(bottom, t) + toward * w)
	poly.append(bottom)
	poly.append(tie)
	draw_colored_polygon(poly, color)
	ItemArt.outline(self, poly, Color("d8ccb4"), 1.2)
	# 結んだリボン
	draw_circle(tie + toward * 0.03, 3.5, Color("f7a8c4"))
	draw_arc(tie + toward * 0.03, 3.5, 0, TAU, 12, line, 1.2)
