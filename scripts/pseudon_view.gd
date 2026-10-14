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


func _draw_icon(bob: float) -> void:
	HeadMark.draw_icon(self, ICON_POS + Vector2(0, bob), icon_full)


func _draw_menu(bob: float) -> void:
	HeadMark.draw_menu(self, ICON_POS + Vector2(0, bob))


func _draw_exclaims() -> void:
	HeadMark.draw_exclaims(self, Vector2(0, ICON_POS.y), exclaim_count, exclaim_anim)
