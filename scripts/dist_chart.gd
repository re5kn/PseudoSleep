extends Control
## 回数の確率分布の棒グラフ。横軸が回数、縦軸が確率質量。
## 実際の回数の棒を色を変えて示し、期待値の位置に縦の点線を引く。

const Dist = preload("res://scripts/dist.gd")

## 棒の数がこれを超えるときは、何回分かずつまとめて1本にする
const MAX_BARS := 60
## 表示範囲の外に残す確率（両端それぞれ）
const TAIL := 0.0005
const PAD_LEFT := 64.0
const PAD_RIGHT := 12.0
const PAD_TOP := 12.0
const PAD_BOTTOM := 44.0
const BAR_COLOR := Color("f2b56b")
const ACTUAL_COLOR := Color("d9534f")
const MEAN_COLOR := Color("4a78c2")
const AXIS_COLOR := Color("8a7660")
const TEXT_COLOR := Color("5a4632")
const FONT_SIZE := 14
## 縦軸の目盛りの区切り数（上端が 1, 2, 2.5, 5 × 10^n なので、きりのよい値になる）
const Y_TICKS := 5

var dist: Dist
var actual := 0
var mean := 0.0


func show_dist(d: Dist, actual_count: int) -> void:
	dist = d
	actual = actual_count
	mean = d.mean()
	queue_redraw()


func _draw() -> void:
	if dist == null:
		return
	var font := get_theme_default_font()
	var span := dist.span(TAIL)
	var first := mini(span.x, actual)
	var last := maxi(span.y, actual)
	var width := ceili(float(last - first + 1) / MAX_BARS)
	# まとめる単位の倍数から始めて、棒の区切りをそろえる
	first -= posmod(first, width)
	var bars := (last - first) / width + 1
	var masses := PackedFloat64Array()
	masses.resize(bars)
	for b in bars:
		for x in range(first + b * width, first + (b + 1) * width):
			masses[b] += dist.mass(x)
	var top := 0.0
	for m in masses:
		top = maxf(top, m)
	var y_max := _nice_ceil(top)

	var plot := Rect2(PAD_LEFT, PAD_TOP, size.x - PAD_LEFT - PAD_RIGHT, size.y - PAD_TOP - PAD_BOTTOM)
	var bar_w := plot.size.x / bars

	# 縦軸（確率質量、%）の目盛り
	for i in Y_TICKS + 1:
		var v := y_max * i / float(Y_TICKS)
		var y := plot.end.y - plot.size.y * i / float(Y_TICKS)
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color(AXIS_COLOR, 0.25), 1.0)
		var label := _percent(v)
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		draw_string(font, Vector2(plot.position.x - tw - 6, y + FONT_SIZE * 0.35), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)

	for b in bars:
		var h := plot.size.y * masses[b] / y_max if y_max > 0.0 else 0.0
		var lo := first + b * width
		var has_actual := actual >= lo and actual < lo + width
		var r := Rect2(plot.position.x + b * bar_w + 1, plot.end.y - h, maxf(1.0, bar_w - 2), h)
		draw_rect(r, ACTUAL_COLOR if has_actual else BAR_COLOR)

	draw_line(Vector2(plot.position.x, plot.end.y), plot.end, AXIS_COLOR, 2.0)
	draw_line(plot.position, Vector2(plot.position.x, plot.end.y), AXIS_COLOR, 2.0)

	# 期待値の位置（棒の中心が回数にあたる）
	var mx := plot.position.x + ((mean - first) / width + 0.5) * bar_w
	draw_dashed_line(Vector2(mx, plot.position.y), Vector2(mx, plot.end.y), MEAN_COLOR, 2.0, 6.0)

	# 横軸（回数）の目盛り。棒が多いときは間引く
	var step := maxi(1, ceili(bars / 8.0))
	for b in range(0, bars, step):
		var label := str(first + b * width)
		if width > 1:
			label += "〜"
		var cx := plot.position.x + (b + 0.5) * bar_w
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		draw_string(font, Vector2(cx - tw / 2, plot.end.y + FONT_SIZE + 6), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)
	var x_title := "回数"
	var xw := font.get_string_size(x_title, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, Vector2(plot.end.x - xw, size.y - 4), x_title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)


## 目盛りの上端（1, 2, 2.5, 5 × 10^n のうち v 以上の最小）
static func _nice_ceil(v: float) -> float:
	if v <= 0.0:
		return 1.0
	var e := pow(10.0, floorf(log(v) / log(10.0)))
	for m in [1.0, 2.0, 2.5, 5.0, 10.0]:
		if m * e >= v - 1e-12:
			return m * e
	return 10.0 * e


static func _percent(v: float) -> String:
	var pct := v * 100.0
	if absf(pct - roundf(pct)) < 1e-6:
		return "%d%%" % roundi(pct)
	return "%.1f%%" % pct
