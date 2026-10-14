extends RefCounted
## パチモン・妖精の頭上に出す印（おてつだいアイコン・「…」の吹き出し・スキルの「!」）。
## どの CanvasItem の _draw からでも呼べる。s は大きさの倍率。

const ItemArt = preload("res://scripts/item_art.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const ICON_RADIUS := 27.0
const FULL_COLOR := Color("e2483d")
const ICON_COLOR := Color("f0a43a")


## おてつだいアイコン（きのみ入りの丸に下向きの三角）。full なら赤くして「MAX」
static func draw_icon(ci: CanvasItem, c: Vector2, full: bool, s: float = 1.0) -> void:
	ci.draw_set_transform(c, 0.0, Vector2.ONE * s)
	var border := FULL_COLOR if full else ICON_COLOR
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(-9, ICON_RADIUS - 4), Vector2(9, ICON_RADIUS - 4), Vector2(0, ICON_RADIUS + 12),
	]), border)
	ci.draw_circle(Vector2.ZERO, ICON_RADIUS + 3, border)
	ci.draw_circle(Vector2.ZERO, ICON_RADIUS - 1, Color.WHITE)
	ItemArt.draw_item(ci, "berry", Vector2(0, 2), 1.15)
	if full:
		var pos := Vector2(-40, -ICON_RADIUS - 8)
		ci.draw_string_outline(FONT, pos, "MAX", HORIZONTAL_ALIGNMENT_CENTER, 80, 18, 6, Color.WHITE)
		ci.draw_string(FONT, pos, "MAX", HORIZONTAL_ALIGNMENT_CENTER, 80, 18, border)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 設定を開ける印（「…」の吹き出し）
static func draw_menu(ci: CanvasItem, c: Vector2, s: float = 1.0) -> void:
	ci.draw_set_transform(c, 0.0, Vector2.ONE * s)
	var oval := ItemArt.rounded_rect(Vector2.ZERO, Vector2(ICON_RADIUS + 4, ICON_RADIUS - 6), 10)
	ci.draw_colored_polygon(oval, Color.WHITE)
	ItemArt.outline(ci, oval, Color("0d2738"), 3.0)
	for i in 3:
		ci.draw_circle(Vector2((i - 1) * 11, 0), 3.6, Color.BLACK)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## メインスキルの「!」。ストック2回分なら1つのギザギザに「!!」を並べる。anim は出てくるときの大きさ（0〜1）
static func draw_exclaims(ci: CanvasItem, c: Vector2, count: int, anim: float, s: float = 1.0) -> void:
	var text := "!".repeat(count)
	var stretch := 1.0 + 0.3 * (count - 1)
	ci.draw_set_transform(c, 0.0, Vector2.ONE * anim * s)
	var burst := ItemArt.burst(Vector2.ZERO, 27.0, stretch)
	ci.draw_colored_polygon(burst, Color("ffd93b"))
	ItemArt.outline(ci, burst, FULL_COLOR, 3.0)
	var w := 60.0 * count
	var pos := Vector2(-w / 2, 13)
	ci.draw_set_transform(c, ItemArt.EXCLAIM_TILT, Vector2.ONE * anim * s)
	ci.draw_string_outline(FONT, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, 38, 6, Color.WHITE)
	ci.draw_string(FONT, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, 38, FULL_COLOR)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
