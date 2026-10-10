extends Node2D
## パチモンの見た目（images/pseudon.png のおばけ）。所持数があれば頭上にアイコン、スキル発動時は「!」を出す。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")
const TEXTURE = preload("res://images/pseudon.png")

const BODY_RX := 62.0
const BODY_RY := 56.0
## 画像は高さ SPRITE_HEIGHT で、体の中心より少し上に置く
const SPRITE_HEIGHT := 190.0
const SPRITE_CENTER := Vector2(0, -8)
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
	var icon := show_icon and local.distance_to(ICON_POS + Vector2(0, -_float_y())) <= ICON_RADIUS + 12
	return body or icon


## 体が浮き上がっている量（上向きが正）
func _float_y() -> float:
	return sin(_t * 1.8) * 6.0


func _draw() -> void:
	# ふわふわ浮いて、影は浮き上がるほど小さくなる。頭上のアイコンと「!」も体と一緒に動かし、間隔を一定に保つ
	var float_y := _float_y()
	var shadow_s := 1.0 - float_y / 60.0
	draw_colored_polygon(ItemArt.ellipse(Vector2(0, BODY_RY + 8), BODY_RX * 0.8 * shadow_s, 12 * shadow_s), Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2(0, -float_y), 0.0, Vector2.ONE)
	_draw_body()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if show_icon:
		_draw_icon(-float_y)
	if exclaim_count > 0:
		_draw_exclaims(-float_y)


func _draw_body() -> void:
	var size := Vector2(TEXTURE.get_width(), TEXTURE.get_height()) * (SPRITE_HEIGHT / TEXTURE.get_height())
	draw_texture_rect(TEXTURE, Rect2(SPRITE_CENTER - size / 2, size), false)


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


func _draw_exclaims(bob: float) -> void:
	# ストック2回分なら1つの吹き出しに「!!」を並べる
	var text := "!".repeat(exclaim_count)
	var stretch := 1.0 + 0.3 * (exclaim_count - 1)
	draw_set_transform(Vector2(0, ICON_POS.y + bob), 0.0, Vector2.ONE * exclaim_anim)
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
