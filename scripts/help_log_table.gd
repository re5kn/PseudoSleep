extends Control
## おてつだい1回ごとの記録の表。ScrollContainer に入れて使い、見えている行だけ描く。
## header = true なら列の見出しだけを描く。

const ItemArt = preload("res://scripts/item_art.gd")
const Sim = preload("res://scripts/sim.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const ROW_H := 46.0
const FONT_SIZE := 20
const TEXT_DARK := Color("5a4632")
const TEXT_MUTED := Color("a08c74")
const STRIPE := Color(0.96, 0.9, 0.78, 0.45)
const EXCLAIM_FILL := Color("ffd93b")
const CEILING_COLOR := Color("e2483d")
## 列の左端と幅
const COL_K := Vector2(0, 56)
const COL_TIME := Vector2(68, 84)
const COL_ITEM := Vector2(166, 150)
const COL_SKILL := Vector2(330, 130)

var header := false
var entries: Array[Dictionary] = []


func _init(is_header: bool = false) -> void:
	header = is_header
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(COL_SKILL.x + COL_SKILL.y, ROW_H)


func set_log(list: Array[Dictionary]) -> void:
	entries = list
	custom_minimum_size.y = ROW_H * maxi(1, entries.size())
	queue_redraw()


func _text(s: String, col: Vector2, y: float, align: HorizontalAlignment, color: Color) -> void:
	var base := y + ROW_H / 2 + FONT_SIZE * 0.36
	draw_string(FONT, Vector2(col.x, base), s, align, col.y, FONT_SIZE, color)


func _draw() -> void:
	if header:
		_text("回", COL_K, 0, HORIZONTAL_ALIGNMENT_RIGHT, TEXT_MUTED)
		_text("経過", COL_TIME, 0, HORIZONTAL_ALIGNMENT_CENTER, TEXT_MUTED)
		_text("獲得", COL_ITEM, 0, HORIZONTAL_ALIGNMENT_LEFT, TEXT_MUTED)
		_text("スキル", COL_SKILL, 0, HORIZONTAL_ALIGNMENT_LEFT, TEXT_MUTED)
		return
	if entries.is_empty():
		_text("まだ記録がありません", Vector2(0, size.x), 0, HORIZONTAL_ALIGNMENT_CENTER, TEXT_MUTED)
		return
	# 何千行あっても重くならないよう、スクロールで見えている範囲だけ描く
	var first := 0
	var last := entries.size() - 1
	var scroll := get_parent() as ScrollContainer
	if scroll != null:
		first = clampi(int(scroll.scroll_vertical / ROW_H), 0, last)
		last = clampi(int((scroll.scroll_vertical + scroll.size.y) / ROW_H) + 1, 0, last)
	for i in range(first, last + 1):
		_draw_row(i, i * ROW_H)


func _draw_row(i: int, y: float) -> void:
	var e: Dictionary = entries[i]
	if i % 2 == 1:
		draw_rect(Rect2(0, y, size.x, ROW_H), STRIPE)
	_text(str(i + 1), COL_K, y, HORIZONTAL_ALIGNMENT_RIGHT, TEXT_DARK)
	var total_min := int(e["t"] / 60.0)
	_text("%d:%02d" % [total_min / 60, total_min % 60], COL_TIME, y, HORIZONTAL_ALIGNMENT_CENTER, TEXT_DARK)
	var cy := y + ROW_H / 2
	if e["id"] == "":
		_text("いつのまに育成", COL_ITEM, y, HORIZONTAL_ALIGNMENT_LEFT, TEXT_MUTED)
	else:
		ItemArt.draw_item(self, e["id"], Vector2(COL_ITEM.x + 18, cy + 2), 0.95)
		_text("×%d" % e["amount"], Vector2(COL_ITEM.x + 42, 100), y, HORIZONTAL_ALIGNMENT_LEFT, TEXT_DARK)
	match int(e["skill"]):
		Sim.Skill.HIT:
			_exclaim(Vector2(COL_SKILL.x + 20, cy), EXCLAIM_FILL, CEILING_COLOR)
		Sim.Skill.CEILING:
			# 天井で出た回は色を反転させ、横に「天井」と添える
			_exclaim(Vector2(COL_SKILL.x + 20, cy), CEILING_COLOR, Color.WHITE)
			_text("天井", Vector2(COL_SKILL.x + 44, 80), y, HORIZONTAL_ALIGNMENT_LEFT, CEILING_COLOR)


## パチモンの頭上に出る「!」と同じ形の小さな印
func _exclaim(c: Vector2, fill: Color, mark: Color) -> void:
	var burst := ItemArt.burst(c, 16.5)
	draw_colored_polygon(burst, fill)
	ItemArt.outline(self, burst, CEILING_COLOR, 2.0)
	draw_string(FONT, c + Vector2(-20, 8), "!", HORIZONTAL_ALIGNMENT_CENTER, 40, 24, mark)
