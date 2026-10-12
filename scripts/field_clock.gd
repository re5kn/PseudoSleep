extends Node2D
## フィールド右上のアナログ時計と、時刻から決まる昼・夕方・夜の区分。
## 時計は「すすめる」で時間が進んだとき、短針・長針が回って新しい時刻まで動く。

enum Phase { DAY, EVENING, NIGHT }

const DAY_SEC := 86400.0
## 起動時・リセット時の時刻（朝4:00）
const START_SEC := 4 * 3600.0
## 日付が変わる時刻（朝4:00）
const DAY_CHANGE_SEC := 4 * 3600.0
## 昼 7:00〜16:00、夕方 16:00〜18:00、夜 18:00〜翌7:00
const DAY_START_SEC := 7 * 3600.0
const EVENING_START_SEC := 16 * 3600.0
const NIGHT_START_SEC := 18 * 3600.0
const RADIUS := 50.0
## 針が回る時間。1時間あたり＋最低限
const SWEEP_SEC_PER_HOUR := 0.06
const SWEEP_MIN_SEC := 0.35
const SWEEP_MAX_SEC := 1.4

const FACE := Color("fffaf0")
const RIM := Color("e8b878")
const RIM_DARK := Color("a8794a")
const HAND := Color("5a4632")
const MINUTE_HAND := Color("7a5c40")

## 時計に表示している時刻（初日の 0:00 からの通算秒）
var shown_sec := START_SEC:
	set(v):
		shown_sec = v
		queue_redraw()
		time_shown.emit(v)

var _tween: Tween

## 表示中の時刻が変わるたびに通算秒で知らせる（背景の色合わせ用）
signal time_shown(sec: float)


## 通算秒をその日の 0〜86400 秒に直す
static func time_of_day(sec: float) -> float:
	return fposmod(sec, DAY_SEC)


## 何日目か（朝4:00 で日付が変わる。初日の 4:00 からが1日目）
static func day_number(sec: float) -> int:
	return int(floor((sec - DAY_CHANGE_SEC) / DAY_SEC)) + 1


## リセットからの経過秒を「n日目」と「H:MM」にする
static func day_and_clock(elapsed_sec: float) -> Array:
	var sec := START_SEC + elapsed_sec
	var total_min := int(time_of_day(sec) / 60.0)
	return [day_number(sec), "%d:%02d" % [total_min / 60, total_min % 60]]


static func phase_at(sec: float) -> int:
	var t := time_of_day(sec)
	if t >= DAY_START_SEC and t < EVENING_START_SEC:
		return Phase.DAY
	if t >= EVENING_START_SEC and t < NIGHT_START_SEC:
		return Phase.EVENING
	return Phase.NIGHT


## sim の経過秒に合う時刻まで針を回す。animate=false ならすぐ合わせる（リセットなど）
func show_elapsed(elapsed_sec: float, animate := true) -> void:
	var target := START_SEC + elapsed_sec
	if _tween != null:
		_tween.kill()
		_tween = null
	if not animate or target <= shown_sec:
		shown_sec = target
		return
	var hours := (target - shown_sec) / 3600.0
	var dur := clampf(SWEEP_MIN_SEC + hours * SWEEP_SEC_PER_HOUR, SWEEP_MIN_SEC, SWEEP_MAX_SEC)
	_tween = create_tween()
	_tween.tween_property(self, "shown_sec", target, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _draw() -> void:
	var c := Vector2.ZERO
	draw_circle(c + Vector2(0, 4), RADIUS + 2, Color(0, 0, 0, 0.15))
	draw_circle(c, RADIUS + 2, RIM_DARK)
	draw_circle(c, RADIUS, RIM)
	draw_circle(c, RADIUS - 6, FACE)
	# 目盛り（3・6・9・12 は太く）
	for i in 12:
		var a := TAU * i / 12.0
		var dir := Vector2(sin(a), -cos(a))
		var major := i % 3 == 0
		var r0 := RADIUS - (15.0 if major else 12.0)
		draw_line(c + dir * r0, c + dir * (RADIUS - 9), HAND if major else RIM_DARK, 3.0 if major else 2.0, true)
	var t := time_of_day(shown_sec)
	var minute_a := TAU * fmod(t, 3600.0) / 3600.0
	var hour_a := TAU * fmod(t, 43200.0) / 43200.0
	_draw_hand(hour_a, RADIUS * 0.5, 6.0, HAND)
	_draw_hand(minute_a, RADIUS * 0.74, 4.0, MINUTE_HAND)
	draw_circle(c, 5.0, HAND)
	draw_circle(c, 2.0, RIM)


func _draw_hand(angle: float, length: float, width: float, color: Color) -> void:
	var dir := Vector2(sin(angle), -cos(angle))
	draw_line(-dir * 6.0, dir * length, color, width, true)
	draw_circle(dir * length, width / 2.0, color)
