extends Control
## おてつだい1回ごとの記録の表。ScrollContainer に入れて使い、見えている行だけ描く。
## header = true なら列の見出しだけを描く。
## パチモンをタップした時点には、おてつだいの行のあいだに色つきの「タップ」行を挟む。

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
## タップ前（まだストックにあるだけ）のスキルの濃さ
const RESERVED_ALPHA := 0.4
const TAP_BAND := Color("d6effa")
const TAP_COLOR := Color("2f86c4")
## 列の左端と幅
const COL_K := Vector2(0, 56)
const COL_TIME := Vector2(68, 84)
const COL_ITEM := Vector2(166, 150)
const COL_SKILL := Vector2(330, 130)

var header := false
var entries: Array[Dictionary] = []
## entries の各行が何回目のおてつだいか（タップの行は 0）
var help_numbers: PackedInt32Array = []


func _init(is_header: bool = false) -> void:
	header = is_header
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(COL_SKILL.x + COL_SKILL.y, ROW_H)


func set_log(list: Array[Dictionary]) -> void:
	entries = list
	help_numbers.resize(entries.size())
	var k := 0
	for i in entries.size():
		if not Sim.is_tap(entries[i]):
			k += 1
			help_numbers[i] = k
		else:
			help_numbers[i] = 0
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
	if Sim.is_tap(e):
		_draw_tap_row(e, y)
		return
	if help_numbers[i] % 2 == 0:
		draw_rect(Rect2(0, y, size.x, ROW_H), STRIPE)
	_text(str(help_numbers[i]), COL_K, y, HORIZONTAL_ALIGNMENT_RIGHT, TEXT_DARK)
	_draw_time(e, y)
	var cy := y + ROW_H / 2
	if e["id"] == "":
		_text("いつのまに育成", COL_ITEM, y, HORIZONTAL_ALIGNMENT_LEFT, TEXT_MUTED)
	else:
		ItemArt.draw_item(self, e["id"], Vector2(COL_ITEM.x + 18, cy + 2), 0.95)
		_text("×%d" % e["amount"], Vector2(COL_ITEM.x + 42, 100), y, HORIZONTAL_ALIGNMENT_LEFT, TEXT_DARK)
	# おてつだいの行で発動したスキルはまだストックにあるだけなので、薄くして「予約」と書く
	match int(e["skill"]):
		Sim.Skill.HIT:
			_exclaim(Vector2(COL_SKILL.x + 20, cy), 1, EXCLAIM_FILL, CEILING_COLOR, RESERVED_ALPHA)
			_text("予約", Vector2(COL_SKILL.x + 44, 80), y, HORIZONTAL_ALIGNMENT_LEFT, TEXT_MUTED)
		Sim.Skill.CEILING:
			# 天井で出た回は色を反転させ、横に「天井」と添える
			_exclaim(Vector2(COL_SKILL.x + 20, cy), 1, CEILING_COLOR, Color.WHITE, RESERVED_ALPHA)
			_text("天井予約", Vector2(COL_SKILL.x + 44, 90), y, HORIZONTAL_ALIGNMENT_LEFT,
				Color(CEILING_COLOR, RESERVED_ALPHA))


func _draw_time(e: Dictionary, y: float) -> void:
	var total_min := int(e["t"] / 60.0)
	_text("%d:%02d" % [total_min / 60, total_min % 60], COL_TIME, y, HORIZONTAL_ALIGNMENT_CENTER, TEXT_DARK)


## タップした時点の行。回の列は空けて、出した数と使ったスキルのストックを書く
func _draw_tap_row(e: Dictionary, y: float) -> void:
	draw_rect(Rect2(0, y + 3, size.x, ROW_H - 6), TAP_BAND)
	draw_rect(Rect2(0, y + 3, 5, ROW_H - 6), TAP_COLOR)
	_draw_time(e, y)
	var amount := int(e["amount"])
	_text("タップ" if amount == 0 else "タップ %d個" % amount, COL_ITEM, y, HORIZONTAL_ALIGNMENT_LEFT, TAP_COLOR)
	# 使ったストックはパチモンの頭上と同じ「!」「!!」で出す
	var stock := int(e["stock"])
	if stock > 0:
		_exclaim(Vector2(COL_SKILL.x + 28, y + ROW_H / 2), stock, EXCLAIM_FILL, CEILING_COLOR)


## パチモンの頭上に出る「!」と同じ形の小さな印。n 個並べるとギザギザも横に伸ばす。alpha で薄くする
func _exclaim(c: Vector2, n: int, fill: Color, mark: Color, alpha: float = 1.0) -> void:
	var burst := ItemArt.burst(c, 14.0, 1.0 + 0.3 * (n - 1))
	draw_colored_polygon(burst, Color(fill, alpha))
	ItemArt.outline(self, burst, Color(CEILING_COLOR, alpha), 2.0)
	var w := 40.0 * n
	draw_set_transform(c, ItemArt.EXCLAIM_TILT)
	draw_string(FONT, Vector2(-w / 2, 8), "!".repeat(n), HORIZONTAL_ALIGNMENT_CENTER, w, 24, Color(mark, alpha))
	draw_set_transform(Vector2.ZERO)
