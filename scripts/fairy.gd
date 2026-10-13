extends RefCounted
## 妖精1体分の状態。おてつだいはパチモンと同じ Sim で計算する。
## きのみ・食材は落とさず（タップした時点で持っていた分は消える）、メインスキルでみんなのげんきを増減させる。

const Sim = preload("res://scripts/sim.gd")
const Params = preload("res://scripts/params.gd")

## 画面に出す呼び名（妖精1・妖精2）
var label := ""
var sim: Sim
## 回復する（おてつだいをする）か。しないあいだは休んでいて、いつも「…」を出す
var heals := false
## メインスキル1回でパチモン・妖精のげんきを増やす量（負なら減らす）
var heal_amount := 5
## 回復量がマイナスのとき、パチモンのげんきは減らさない
var spare_pseudon := false
## 変身プルダウンで選んでいる枠
var preset := 0


func _init(name: String) -> void:
	label = name
	sim = Sim.new(Params.new())


## スキルのストック n 回分で増減するげんき
func heal_for(stock: int) -> int:
	return heal_amount * stock
