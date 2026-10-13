extends Node2D
## パチモンの周りの妖精の見た目。光る玉に羽が付いたもの。
## 休んでいるあいだは地上で止まっていて、回復するときはパチモンの肩の高さを漂う。
## パチモンと同じく、頭上におてつだいアイコン・「…」・スキルの「!」を（少し小さく）出す。

const ItemArt = preload("res://scripts/item_art.gd")
const HeadMark = preload("res://scripts/head_mark.gd")

const BODY_R := 17.0
const ICON_POS := Vector2(0, -66)
const ICON_SCALE := 0.75
## 休んでいるときの体の中心から地面（影）までの高さ
const SHADOW_Y := 22.0
const HIT_RADIUS := 44.0
## 地上と空中を行き来する速さ（1秒あたり）
const AIR_SPEED := 2.0
## スキル不発のとき「＞＜」を出しておく時間と、落ち込んで（傾いて沈んで）から戻るまでの時間
const FIZZLE_SEC := 2.2
const DROOP_IN_SEC := 0.35
const DROOP_HOLD_SEC := 1.2
const DROOP_OUT_SEC := 0.6
## 落ち込んだときの傾き（右肩＝画面の左側が下がる向き）
const DROOP_TILT := -0.45

## 休んでいるときに止まっている地上の位置と、回復するときに漂う中心（親ノードの座標）
var rest_pos := Vector2.ZERO
var fly_pos := Vector2.ZERO
## スキル不発で落ち込んだときに沈む高さ（パチモンの手のあたり。親ノードの y）
var droop_y := 0.0
var color := Color("ffb3d9")
## 漂い方をずらすための位相
var phase := 0.0
## おてつだいをしているか（回復しない設定のときは薄く出す）
var active := false
var show_icon := false
var show_menu := false
var icon_full := false
var exclaim_count := 0
var exclaim_anim := 0.0
## 0＝地上で休んでいる、1＝漂っている（切り替えるとこのあいだを移る）
var air := 0.0
## スキル不発の「＞＜」を出している残り時間と、落ち込み具合（0〜1）
var fizzle_left := 0.0
var droop := 0.0
var _droop_tween: Tween
var _t := 0.0


func _process(delta: float) -> void:
	air = move_toward(air, 1.0 if active else 0.0, delta * AIR_SPEED)
	# 休んでいるあいだは時間を止め、羽ばたきもきらきらも動かさない
	if air > 0.0:
		_t += delta
	var drift := Vector2(sin(_t * 0.9 + phase) * 14.0, sin(_t * 1.7 + phase * 2.0) * 9.0)
	position = rest_pos.lerp(fly_pos, _ease(air)) + drift * air
	position.y += (droop_y - fly_pos.y) * _ease(droop) * air
	fizzle_left = maxf(0.0, fizzle_left - delta)
	queue_redraw()


## スキルが不発だったときの演出。「＞＜」を出し、右肩を落とすように傾きながらパチモンの手の高さまで沈んで、しばらくして戻る
func fizzle() -> void:
	fizzle_left = FIZZLE_SEC
	if _droop_tween != null:
		_droop_tween.kill()
	_droop_tween = create_tween()
	_droop_tween.tween_property(self, "droop", 1.0, DROOP_IN_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_droop_tween.tween_interval(DROOP_HOLD_SEC)
	_droop_tween.tween_property(self, "droop", 0.0, DROOP_OUT_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


static func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


func show_exclaims(n: int) -> void:
	exclaim_count = n
	exclaim_anim = 0.0
	if n > 0:
		var tw := create_tween()
		tw.tween_property(self, "exclaim_anim", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hit(p: Vector2) -> bool:
	var local := p - global_position
	var mark := (show_icon or show_menu) and local.distance_to(ICON_POS) <= HeadMark.ICON_RADIUS * ICON_SCALE + 12
	return local.length() <= HIT_RADIUS or mark


func _draw() -> void:
	var a := 1.0 if active else 0.55
	# 地上の影。浮くほど小さく薄くする
	var shadow_s := 1.0 - 0.5 * air
	draw_colored_polygon(ItemArt.ellipse(rest_pos - position + Vector2(0, SHADOW_Y), 22 * shadow_s, 6 * shadow_s), Color(0, 0, 0, 0.18 * shadow_s))
	# 体と羽は落ち込むと傾ける（頭上の印は傾けない）
	var body := Transform2D(DROOP_TILT * _ease(droop), Vector2.ZERO)
	# 羽（前後2枚ずつ）。羽ばたきで横幅が変わる（休んでいるときはたたんだまま）
	var flap := lerpf(0.55, 0.55 + 0.45 * absf(sin(_t * 11.0 + phase)), air)
	for side in [-1.0, 1.0]:
		_wing(body, Vector2(side * 16, -8), side * 0.55, 20.0 * flap, 12.0, a)
		_wing(body, Vector2(side * 14, 8), side * -0.4, 13.0 * flap, 8.0, a)
	draw_set_transform_matrix(body)
	# 光のにじみと体
	var glow := 0.8 + 0.2 * sin(_t * 3.0 + phase)
	draw_circle(Vector2.ZERO, BODY_R * 2.0 * glow, Color(color, 0.18 * a))
	draw_circle(Vector2.ZERO, BODY_R * 1.4, Color(color, 0.35 * a))
	draw_circle(Vector2.ZERO, BODY_R, Color(color.lerp(Color.WHITE, 0.55), a))
	draw_circle(Vector2(-5, -5), BODY_R * 0.35, Color(1, 1, 1, 0.9 * a))
	# 目
	for x in [-5.0, 5.0]:
		draw_circle(Vector2(x, 1), 2.2, Color(0.25, 0.2, 0.3, a))
	# きらきら
	for i in 3:
		var k := _t * 0.8 + phase + i * TAU / 3
		var p := Vector2(cos(k) * 34, sin(k * 1.3) * 22 + 8)
		var tw := 0.5 + 0.5 * sin(_t * 5.0 + i * 2.0)
		if tw < 0.15:
			continue
		_sparkle(p, 3.5 * tw, Color(1, 1, 0.85, 0.85 * a * tw))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if fizzle_left > 0.0:
		_draw_fizzle_mark()
	elif show_icon:
		HeadMark.draw_icon(self, ICON_POS, icon_full, ICON_SCALE)
	elif show_menu and exclaim_count == 0:
		HeadMark.draw_menu(self, ICON_POS, ICON_SCALE)
	if exclaim_count > 0:
		HeadMark.draw_exclaims(self, ICON_POS, exclaim_count, exclaim_anim, ICON_SCALE)


## スキル不発の印。角丸の四角に「＞＜」
func _draw_fizzle_mark() -> void:
	draw_set_transform(ICON_POS, 0.0, Vector2.ONE * ICON_SCALE)
	var box := ItemArt.rounded_rect(Vector2.ZERO, Vector2(HeadMark.ICON_RADIUS + 6, HeadMark.ICON_RADIUS - 4), 12)
	draw_colored_polygon(box, Color.WHITE)
	ItemArt.outline(self, box, Color("0d2738"), 3.0)
	var w := 80.0
	draw_string(HeadMark.FONT, Vector2(-w / 2, 10), "＞＜", HORIZONTAL_ALIGNMENT_CENTER, w, 28, Color("0d2738"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _wing(body: Transform2D, c: Vector2, angle: float, rx: float, ry: float, a: float) -> void:
	draw_set_transform_matrix(body * Transform2D(angle, c))
	var pts := ItemArt.ellipse(Vector2(signf(c.x) * rx * 0.6, 0), rx, ry, 20)
	draw_colored_polygon(pts, Color(0.85, 0.95, 1.0, 0.55 * a))
	ItemArt.outline(self, pts, Color(color.darkened(0.1), 0.7 * a), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _sparkle(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -r * 2), c + Vector2(r * 0.4, -r * 0.4), c + Vector2(r * 2, 0), c + Vector2(r * 0.4, r * 0.4),
		c + Vector2(0, r * 2), c + Vector2(-r * 0.4, r * 0.4), c + Vector2(-r * 2, 0), c + Vector2(-r * 0.4, -r * 0.4),
	]), col)
