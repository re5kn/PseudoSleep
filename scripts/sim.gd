extends RefCounted
## おてつだいの試行シミュレーション。
##
## 期待値ではなく、1回ごとに乱数で結果を決める。
## - おてつだいの間隔 = おてつだい時間 × げんき補正（そのおてつだいを始めた時点のげんき）
##   おてつだい時間 = 基準時間 × レベル・せいかく・サブスキル・おやすみリボン補正 を小数点以下切り捨て（Params.help_sec）
## - 1回のおてつだいで、確率 p で食材（解放済みの枠から等確率）、1−p できのみ
## - それとは独立に、確率 q でメインスキルが発動してストックに入る
##   ストックが上限のあいだは抽選しない。抽選に (天井−1) 回続けて外れると次は必ず発動する
## - 所持数（パチモンが持っている分＋フィールドに残っている分）が最大所持数に達していると
##   「いつのまに育成」になり、きのみはカビゴンへ自動で渡され、食材もスキルも出ない
## - 途中まで進んだおてつだいは次の「すすめる」に持ち越す

const Params = preload("res://scripts/params.gd")

enum GenkiMode { ALWAYS_HIGH, DECAY }

const BERRY_BOX_MAX := 99999
const INGREDIENT_BOX_MAX := 800
const GENKI_START := 100
const GENKI_DECAY_SEC := 600.0

var params: Params
var rng := RandomNumberGenerator.new()
var genki_mode: int = GenkiMode.ALWAYS_HIGH
## DECAY モードでげんきが GENKI_START だった時刻
var genki_origin_sec := 0.0

var elapsed_sec := 0.0
## 進行中のおてつだいが終わる時刻
var next_help_at := 0.0
## まだタップしていない（パチモンが持っている）分
var pending := {}
## タップ済みでフィールドに残っている分
var on_field := {}
var berry_box := {}
var ingredient_box := {}
var skill_stock := 0
## メインスキルの抽選に続けて外れた回数（天井用）
var skill_miss := 0
var totals := {}


func _init(p: Params = null) -> void:
	params = p if p != null else Params.new()
	rng.randomize()
	reset()


func reset() -> void:
	elapsed_sec = 0.0
	genki_origin_sec = 0.0
	pending.clear()
	on_field.clear()
	berry_box.clear()
	ingredient_box.clear()
	skill_stock = 0
	skill_miss = 0
	totals = new_stats()
	next_help_at = help_interval_at(0.0)


func new_stats() -> Dictionary:
	return {
		"seconds": 0.0,
		"helps": 0,
		"berry_helps": 0,
		"ingredient_helps": 0,
		"skills": 0,
		"skill_ceiling_hits": 0,
		"full_helps": 0,
		"auto_fed": 0,
		"carry_lost": 0,
		"items": {},
	}


func set_genki_mode(mode: int) -> void:
	genki_mode = mode
	genki_origin_sec = elapsed_sec


func genki_at(t: float) -> int:
	if genki_mode == GenkiMode.ALWAYS_HIGH:
		return GENKI_START
	return maxi(0, GENKI_START - int(floor((t - genki_origin_sec) / GENKI_DECAY_SEC)))


static func genki_multiplier(genki: int) -> float:
	if genki >= 81:
		return 0.45
	if genki >= 61:
		return 0.52
	if genki >= 41:
		return 0.58
	if genki >= 1:
		return 0.66
	return 1.0


func help_interval_at(t: float) -> float:
	return params.help_sec() * genki_multiplier(genki_at(t))


## seconds 秒ぶんおてつだいを進め、その間の結果を返す。
func advance(seconds: float) -> Dictionary:
	var r := new_stats()
	r["seconds"] = seconds
	var end := elapsed_sec + seconds
	while next_help_at <= end + 1e-6:
		var t := next_help_at
		_do_help(r)
		next_help_at = t + help_interval_at(t)
	elapsed_sec = end
	_accumulate(r)
	return r


func _do_help(r: Dictionary) -> void:
	r["helps"] += 1
	var held := held_count()
	var limit := params.carry_limit()
	if held >= limit:
		r["full_helps"] += 1
		r["auto_fed"] += params.berry_amount()
		return
	var room := limit - held
	var slots := params.active_ingredients()
	if not slots.is_empty() and rng.randf() < params.ingredient_chance():
		var ing: Dictionary = slots[rng.randi_range(0, slots.size() - 1)]
		r["ingredient_helps"] += 1
		_gain(r, ing["id"], ing["amount"], room)
	else:
		r["berry_helps"] += 1
		_gain(r, params.berry["id"], params.berry_amount(), room)
	_skill_lottery(r)


func _skill_lottery(r: Dictionary) -> void:
	if skill_stock >= params.max_skill_stock:
		return
	var by_ceiling := skill_miss >= params.skill_ceiling - 1
	if rng.randf() < params.skill_chance() or by_ceiling:
		r["skills"] += 1
		if by_ceiling:
			r["skill_ceiling_hits"] += 1
		skill_stock += 1
		skill_miss = 0
	else:
		skill_miss += 1


func _gain(r: Dictionary, id: String, amount: int, room: int) -> void:
	var got := mini(amount, room)
	pending[id] = int(pending.get(id, 0)) + got
	var items: Dictionary = r["items"]
	items[id] = int(items.get(id, 0)) + got
	r["carry_lost"] += amount - got


func _accumulate(r: Dictionary) -> void:
	for key in r:
		if key == "items":
			var items: Dictionary = totals["items"]
			for id in r["items"]:
				items[id] = int(items.get(id, 0)) + int(r["items"][id])
		else:
			totals[key] += r[key]


static func sum(d: Dictionary) -> int:
	var n := 0
	for k in d:
		n += int(d[k])
	return n


## 現在の所持数。フィールドに残したままの分も含む。
func held_count() -> int:
	return sum(pending) + sum(on_field)


func pending_count() -> int:
	return sum(pending)


func is_full() -> bool:
	return held_count() >= params.carry_limit()


## パチモンの上にアイコンを出すかどうか。
func has_icon() -> bool:
	return pending_count() > 0 or skill_stock > 0


## タップしたときの処理。持っている分をフィールドへ出し、スキルのストックを消費する。
func drop() -> Dictionary:
	var result := {"items": pending.duplicate(), "stock": skill_stock}
	for id in pending:
		on_field[id] = int(on_field.get(id, 0)) + int(pending[id])
	pending.clear()
	skill_stock = 0
	return result


func box_for(id: String) -> Dictionary:
	return berry_box if params.is_berry(id) else ingredient_box


func box_max_for(id: String) -> int:
	return BERRY_BOX_MAX if params.is_berry(id) else INGREDIENT_BOX_MAX


## フィールド上の id を収容箱へ入れる。入った数を返す（箱に入りきらない分はフィールドに残る）。
func collect(id: String) -> int:
	var n := int(on_field.get(id, 0))
	if n <= 0:
		return 0
	var box := box_for(id)
	var take := mini(n, box_max_for(id) - sum(box))
	if take <= 0:
		return 0
	box[id] = int(box.get(id, 0)) + take
	if n - take > 0:
		on_field[id] = n - take
	else:
		on_field.erase(id)
	return take
