extends Node2D
## パチモンの見た目（images/pseudon.png のおばけ）。所持数があれば頭上にアイコン、スキル発動時は「!」を出す。
## アイコンが出ていないとき（タップで設定パネルを開けるとき）は「…」の吹き出しを出す。

const ItemArt = preload("res://scripts/item_art.gd")
const HeadMark = preload("res://scripts/head_mark.gd")
const TEXTURE = preload("res://images/pseudon.png")

const BODY_RX := 62.0
const BODY_RY := 56.0
## 画像は高さ SPRITE_HEIGHT で、体の中心より少し上に置く
const SPRITE_HEIGHT := 190.0
const SPRITE_CENTER := Vector2(0, -8)
## 頭上の印（アイコン・「…」・「!」）は画像の上端（-103）よりしっぽ込みで上に出す
const ICON_POS := Vector2(0, -152)
const ICON_RADIUS := HeadMark.ICON_RADIUS
## 手のひらのあたり（画面から見て左がパチモンの右手）。きのみは右手、食材は左手から出す
const RIGHT_HAND := Vector2(-60, 2)
## 食材は手のひらから食材Aの幅（19px）ぶん右に出す
const LEFT_HAND := Vector2(77, 6)
## 蝶ネクタイ（おやすみリボン）をつける首もと（口の下）と、羽の半分の幅・高さ。BOWTIE_SCALE 倍に縮めて描く
const BOWTIE_POS := Vector2(-3, -38)
const BOWTIE_SCALE := 0.5
const BOWTIE_HALF := Vector2(25, 13)
## おやすみリボンの段階ごとの蝶ネクタイの色（[地の色, 縁の色]）。段階 4 は虹色に光るので使わない
const BOWTIE_COLORS := {
	1: [Color(0.97, 0.97, 0.95), Color(0.55, 0.55, 0.6)],
	2: [Color(0.25, 0.5, 0.95), Color(0.08, 0.2, 0.5)],
	3: [Color(0.98, 0.78, 0.2), Color(0.55, 0.38, 0.05)],
}
## 虹色の蝶ネクタイの色が1秒に一周の何割ぶん変わるかと、彩度
const RAINBOW_SPEED := 0.4
const RAINBOW_SAT := 0.45

var show_icon := false
## 設定パネルを開ける印（「…」の吹き出し）を出すか
var show_menu := false
var icon_full := false
var exclaim_count := 0
var exclaim_anim := 0.0
## おやすみリボンの段階（Params.ribbon_tier）。1 以上なら首もとに蝶ネクタイをつける
var ribbon_tier := 0
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func show_exclaims(n: int) -> void:
	exclaim_count = n
	exclaim_anim = 0.0
	if n > 0:
		var tw := create_tween()
		tw.tween_property(self, "exclaim_anim", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hit(p: Vector2) -> bool:
	var local := p - global_position
	var body := Vector2(local.x / (BODY_RX + 12), local.y / (BODY_RY + 12)).length() <= 1.0
	var icon := (show_icon or show_menu) and local.distance_to(ICON_POS + Vector2(0, -_float_y())) <= ICON_RADIUS + 12
	return body or icon


## アイテムを出す手の位置（親ノードの座標。浮き上がりに合わせて動く）
func hand_position(id: String) -> Vector2:
	var hand := RIGHT_HAND if id == "berry" else LEFT_HAND
	return position + hand + Vector2(0, -_float_y())


## 体が浮き上がっている量（上向きが正）
func _float_y() -> float:
	return sin(_t * 1.8) * 6.0


func _draw() -> void:
	# ふわふわ浮いて、影は浮き上がるほど小さくなる。頭上のアイコンと「…」も体と一緒に動かし、間隔を一定に保つ
	var float_y := _float_y()
	var shadow_s := 1.0 - float_y / 60.0
	draw_colored_polygon(ItemArt.ellipse(Vector2(0, BODY_RY + 8), BODY_RX * 0.8 * shadow_s, 12 * shadow_s), Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2(0, -float_y), 0.0, Vector2.ONE)
	_draw_body()
	if ribbon_tier > 0:
		draw_set_transform(Vector2(0, -float_y) + BOWTIE_POS, 0.0, Vector2.ONE * BOWTIE_SCALE)
		_draw_bowtie()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if show_icon:
		_draw_icon(-float_y)
	elif show_menu and exclaim_count == 0:
		_draw_menu(-float_y)
	if exclaim_count > 0:
		_draw_exclaims()


func _draw_body() -> void:
	var size := Vector2(TEXTURE.get_width(), TEXTURE.get_height()) * (SPRITE_HEIGHT / TEXTURE.get_height())
	draw_texture_rect(TEXTURE, Rect2(SPRITE_CENTER - size / 2, size), false)


## 蝶ネクタイ（BOWTIE_POS を原点にした座標）。羽2枚と結び目を描き、段階 4 は虹色が流れるように変わる
func _draw_bowtie() -> void:
	var c := Vector2.ZERO
	var w := BOWTIE_HALF.x
	var h := BOWTIE_HALF.y
	var wings := []
	for side in [-1.0, 1.0]:
		wings.append(PackedVector2Array([
			c + Vector2(side * 4, -4), c + Vector2(side * w, -h), c + Vector2(side * (w - 3), 0),
			c + Vector2(side * w, h), c + Vector2(side * 4, 4),
		]))
	var knot := ItemArt.rounded_rect(c, Vector2(6, 7), 3)
	if ribbon_tier >= 4:
		_draw_rainbow_bowtie(wings, knot)
		return
	var fill: Color = BOWTIE_COLORS[ribbon_tier][0]
	var line: Color = BOWTIE_COLORS[ribbon_tier][1]
	for i in wings.size():
		draw_colored_polygon(wings[i], fill)
		# 羽のひだ（結び目から外へ広がる影）
		var side := -1.0 if i == 0 else 1.0
		draw_line(c + Vector2(side * 7, -2), c + Vector2(side * (w - 6), -h + 5), fill.darkened(0.25), 2.0)
		draw_line(c + Vector2(side * 7, 2), c + Vector2(side * (w - 6), h - 5), fill.darkened(0.25), 2.0)
		ItemArt.outline(self, wings[i], line, 2.0)
	draw_colored_polygon(knot, fill.darkened(0.12))
	ItemArt.outline(self, knot, line, 2.0)
	if ribbon_tier == 3:
		# 金色はときどききらっと光る
		var a := clampf(sin(_t * 2.6) * 2.0 - 1.0, 0.0, 1.0)
		_draw_sparkle(c + Vector2(-w + 8, -h + 5), 7.0 * a, Color(1, 1, 0.9, a))


func _draw_rainbow_bowtie(wings: Array, knot: PackedVector2Array) -> void:
	var hue := fmod(_t * RAINBOW_SPEED, 1.0)
	for i in wings.size():
		var pts: PackedVector2Array = wings[i]
		var cols := PackedColorArray()
		for j in pts.size():
			# 頂点ごとに色相をずらして、羽の上を虹色が流れるようにする
			cols.append(Color.from_hsv(fmod(hue + i * 0.5 + j * 0.12, 1.0), RAINBOW_SAT, 1.0))
		draw_polygon(pts, cols)
		ItemArt.outline(self, pts, Color(1, 1, 1, 0.9), 2.0)
	draw_colored_polygon(knot, Color.from_hsv(fmod(hue + 0.25, 1.0), RAINBOW_SAT * 0.8, 1.0))
	ItemArt.outline(self, knot, Color(1, 1, 1, 0.9), 2.0)


## 4つの角があるきらめき
func _draw_sparkle(p: Vector2, r: float, color: Color) -> void:
	if r <= 0.5:
		return
	var t := r * 0.28
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -r), p + Vector2(t, -t), p + Vector2(r, 0), p + Vector2(t, t),
		p + Vector2(0, r), p + Vector2(-t, t), p + Vector2(-r, 0), p + Vector2(-t, -t),
	]), color)


func _draw_icon(bob: float) -> void:
	HeadMark.draw_icon(self, ICON_POS + Vector2(0, bob), icon_full)


func _draw_menu(bob: float) -> void:
	HeadMark.draw_menu(self, ICON_POS + Vector2(0, bob))


func _draw_exclaims() -> void:
	HeadMark.draw_exclaims(self, Vector2(0, ICON_POS.y), exclaim_count, exclaim_anim)
