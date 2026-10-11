extends Node2D
## パチモンの代わりの図形。所持数があれば頭上にアイコン、スキル発動時は「!」を出す。
## アイコンが出ていないとき（タップで設定パネルを開けるとき）は「…」の吹き出しを出す。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const BODY_RX := 62.0
const BODY_RY := 56.0
const ICON_POS := Vector2(0, -112)
const ICON_RADIUS := 27.0

var show_icon := false
## 設定パネルを開ける印（「…」の吹き出し）を出すか
var show_menu := false
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
	var icon := (show_icon or show_menu) and local.distance_to(ICON_POS) <= ICON_RADIUS + 12
	return body or icon


func _draw() -> void:
	var breathe := sin(_t * 2.2) * 0.02
	draw_colored_polygon(ItemArt.ellipse(Vector2(0, BODY_RY - 4), BODY_RX * 0.95, 15), Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2(0, BODY_RY * -breathe), 0.0, Vector2(1.0 - breathe, 1.0 + breathe))
	_draw_body()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if show_icon:
		_draw_icon(sin(_t * 3.0) * 4.0)
	elif show_menu and exclaim_count == 0:
		_draw_menu(sin(_t * 3.0) * 4.0)
	if exclaim_count > 0:
		_draw_exclaims()


func _draw_body() -> void:
	var line := Color("8a5a2b")
	for side in [-1.0, 1.0]:
		var ear := PackedVector2Array([
			Vector2(side * 22, -46), Vector2(side * 50, -78), Vector2(side * 52, -30),
		])
		draw_colored_polygon(ear, Color("f6b75a"))
		ItemArt.outline(self, ear, line, 3.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 32, -46), Vector2(side * 47, -66), Vector2(side * 47, -40),
		]), Color("fde3a7"))
	var body := ItemArt.ellipse(Vector2.ZERO, BODY_RX, BODY_RY, 40)
	draw_colored_polygon(body, Color("f9c46b"))
	draw_colored_polygon(ItemArt.ellipse(Vector2(0, 16), 38, 32, 32), Color("fff1cc"))
	ItemArt.outline(self, body, line, 3.0)
	# 寝顔
	draw_arc(Vector2(-20, -10), 8, 0.2, PI - 0.2, 10, line, 3.0, true)
	draw_arc(Vector2(20, -10), 8, 0.2, PI - 0.2, 10, line, 3.0, true)
	draw_circle(Vector2(-36, 4), 7, Color(1.0, 0.55, 0.55, 0.45))
	draw_circle(Vector2(36, 4), 7, Color(1.0, 0.55, 0.55, 0.45))
	draw_arc(Vector2(0, 4), 5, 0.3, PI - 0.3, 8, line, 2.5, true)


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


func _draw_menu(bob: float) -> void:
	var c := ICON_POS + Vector2(0, bob)
	var oval := ItemArt.ellipse(c, ICON_RADIUS + 6, ICON_RADIUS - 2, 32)
	draw_colored_polygon(oval, Color.WHITE)
	ItemArt.outline(self, oval, Color("0d2738"), 3.0)
	for i in 3:
		draw_circle(c + Vector2((i - 1) * 11, 0), 3.6, Color.BLACK)


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
