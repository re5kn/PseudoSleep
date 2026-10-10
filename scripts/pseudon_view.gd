extends Node2D
## パチモンの代わりの図形（もやをまとったおばけ）。所持数があれば頭上にアイコン、スキル発動時は「!」を出す。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const BODY_RX := 62.0
const BODY_RY := 56.0
const ICON_POS := Vector2(0, -112)
const ICON_RADIUS := 27.0

var show_icon := false
var icon_full := false
var exclaim_count := 0
var exclaim_anim := 0.0
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
	var icon := show_icon and local.distance_to(ICON_POS) <= ICON_RADIUS + 12
	return body or icon


func _draw() -> void:
	# ふわふわ浮いて、影は浮き上がるほど小さくなる
	var float_y := sin(_t * 1.8) * 6.0
	var shadow_s := 1.0 - float_y / 60.0
	draw_colored_polygon(ItemArt.ellipse(Vector2(0, BODY_RY + 8), BODY_RX * 0.8 * shadow_s, 12 * shadow_s), Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2(0, -float_y), 0.0, Vector2.ONE)
	_draw_body()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if show_icon:
		_draw_icon(sin(_t * 3.0) * 4.0)
	if exclaim_count > 0:
		_draw_exclaims()


func _draw_body() -> void:
	# まわりのもや（外側ほど薄く、輪郭がゆらゆら波打つ）
	for layer in 3:
		var reach := 20.0 - layer * 7.0
		var alpha := 0.18 + layer * 0.12
		draw_colored_polygon(_wisp(reach, layer * 1.7), Color(0.55, 0.32, 0.78, alpha))
	var body := ItemArt.ellipse(Vector2.ZERO, BODY_RX, BODY_RY, 48)
	draw_colored_polygon(body, Color("3b2156"))
	draw_colored_polygon(ItemArt.ellipse(Vector2(-14, -18), 36, 28, 32), Color("4c2d6c"))
	draw_circle(Vector2(-30, -30), 7, Color(1, 1, 1, 0.12))
	# 小さなおばけの手
	for side in [-1.0, 1.0]:
		var wave := sin(_t * 2.6 + side) * 5.0
		var hand := Vector2(side * (BODY_RX + 16), 6 + wave)
		draw_circle(hand, 13, Color("3b2156"))
		# 指は上から外側へ扇形に3本
		for k in 3:
			var a: float = -PI / 2 + side * (0.35 + k * 0.5)
			var tip := hand + Vector2(cos(a), sin(a)) * 17
			draw_line(hand, tip, Color("3b2156"), 9.0, true)
			draw_circle(tip, 4.5, Color("3b2156"))
	_draw_face()


## もやの輪郭。体のまわりに reach ぶん広がり、時間でうねる。
func _wisp(reach: float, phase: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 56
	for i in n:
		var a := TAU * i / n
		var wobble := sin(a * 7.0 + _t * 2.0 + phase) * 0.5 + sin(a * 4.0 - _t * 1.3 + phase) * 0.5
		var r := reach * (0.75 + 0.35 * wobble)
		pts.append(Vector2(cos(a) * (BODY_RX + r), sin(a) * (BODY_RY + r)))
	return pts


func _draw_face() -> void:
	var white := Color("fbf6ff")
	var dark := Color("1a0d29")
	for side in [-1.0, 1.0]:
		# 上辺が外側に向かって上がる、つり目の形
		var top_inner := Vector2(side * 6, -14)
		var top_outer := Vector2(side * 40, -30)
		var eye := PackedVector2Array([top_inner, top_outer])
		for i in range(1, 12):
			var t := i / 12.0
			var base := top_outer.lerp(top_inner, t)
			eye.append(base + Vector2(0, sin(PI * t) * 15))
		draw_colored_polygon(eye, white)
		var look := Vector2(sin(_t * 0.7) * 3.0, 0)
		draw_circle(Vector2(side * 24, -15) + look, 5, dark)
	# にやっと笑う大きな口
	var mouth := PackedVector2Array()
	for i in 17:
		var t := i / 16.0
		mouth.append(Vector2(lerp(-38.0, 38.0, t), 6 - sin(PI * t) * 4 + pow(t - 0.5, 2) * -20))
	for i in 17:
		var t := 1.0 - i / 16.0
		mouth.append(Vector2(lerp(-38.0, 38.0, t), 6 + sin(PI * t) * 30))
	draw_colored_polygon(mouth, Color("7a1d3b"))
	draw_colored_polygon(ItemArt.ellipse(Vector2(0, 26), 16, 7, 20), Color("e0577a"))
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 12, 4), Vector2(side * 22, 3), Vector2(side * 17, 14),
		]), white)
	ItemArt.outline(self, mouth, dark, 2.0)


func _draw_icon(bob: float) -> void:
	var c := ICON_POS + Vector2(0, bob)
	var border := Color("e2483d") if icon_full else Color("f0a43a")
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-9, ICON_RADIUS - 4), c + Vector2(9, ICON_RADIUS - 4), c + Vector2(0, ICON_RADIUS + 12),
	]), border)
	draw_circle(c, ICON_RADIUS + 3, border)
	draw_circle(c, ICON_RADIUS - 1, Color.WHITE)
	ItemArt.draw_item(self, "berry", c + Vector2(0, 2), 1.15)
	if icon_full:
		var pos := c + Vector2(-40, -ICON_RADIUS - 8)
		draw_string_outline(FONT, pos, "MAX", HORIZONTAL_ALIGNMENT_CENTER, 80, 18, 6, Color.WHITE)
		draw_string(FONT, pos, "MAX", HORIZONTAL_ALIGNMENT_CENTER, 80, 18, border)


func _draw_exclaims() -> void:
	# ストック2回分なら1つの吹き出しに「!!」を並べる
	var text := "!".repeat(exclaim_count)
	var stretch := 1.0 + 0.3 * (exclaim_count - 1)
	draw_set_transform(Vector2(0, ICON_POS.y), 0.0, Vector2.ONE * exclaim_anim)
	var burst := PackedVector2Array()
	for k in 16:
		var r := 30.0 if k % 2 == 0 else 21.0
		var a := TAU * k / 16.0 - PI / 2
		burst.append(Vector2(cos(a) * stretch, sin(a)) * r)
	draw_colored_polygon(burst, Color("ffd93b"))
	ItemArt.outline(self, burst, Color("e2483d"), 3.0)
	var w := 60.0 * exclaim_count
	var pos := Vector2(-w / 2, 13)
	draw_string_outline(FONT, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, 38, 6, Color.WHITE)
	draw_string(FONT, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, 38, Color("e2483d"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
