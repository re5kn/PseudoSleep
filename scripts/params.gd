extends RefCounted
## パチモン1体分のおてつだいパラメータ。
## 画面左の設定パネルで変えられる値（基準値）と、そこからサブスキル・せいかく・おやすみリボンなどの
## 補正をかけて実際の計算に使う値（help_sec() など）を持つ。

## せいかくで上がる／下がる能力
enum Nature { NONE, SPEED, INGREDIENT, SKILL, GENKI }

## サブスキル（id → 表示名）
const SUBSKILLS := {
	"berry_s": "きのみの数S",
	"speed_m": "おてつだいスピードM",
	"speed_s": "おてつだいスピードS",
	"ing_m": "食材確率アップM",
	"ing_s": "食材確率アップS",
	"skill_m": "スキル確率アップM",
	"skill_s": "スキル確率アップS",
	"carry_l": "最大所持数アップL",
	"carry_m": "最大所持数アップM",
	"carry_s": "最大所持数アップS",
}

## サブスキルを選べる数が1つ増えるレベル（最大5つ）
const SUBSKILL_SLOT_LEVELS: Array[int] = [10, 25, 50, 70, 80]
## サブスキルとおてつだいボーナスによるおてつだい時間の短縮の上限
const SPEED_REDUCTION_CAP := 0.35
## 食材枠2・3が解放されるレベル
const SLOT_UNLOCK_LEVELS: Array[int] = [1, 30, 60]
## 名前の長さの上限（半角1・全角2で数える。全角なら6文字、半角なら12文字）
const NAME_MAX_WIDTH := 12

var pseudon_name := "ベアビヲ9"
## 基準おてつだい時間（秒）
var base_help_sec := 2200.0
## レベル。おてつだい時間のレベル補正 1−0.002×(レベル−1) と食材枠の解放に使う。
var level := 60
## 食材確率（補正前。1回のおてつだいで食材を拾う確率）
var ingredient_prob := 0.151
## メインスキル発生確率（補正前）
var skill_prob := 0.039
## スキル連続不発上限。抽選にこの回数続けて外れると、次のおてつだいで必ず発動する（20なら21回目）。
var skill_ceiling := 65
## メインスキルのストック上限
var max_skill_stock := 2
## 最大所持数（きのみ＋食材。補正前）
var max_carry := 22
## 1回のおてつだいで拾うきのみの数（補正前）
var berries_per_help := 1
## あと何回進化できるか（0〜2）。おやすみリボンのおてつだい時間補正に使う。
var evolutions_left := 0
## 一緒に寝た累計睡眠時間（おやすみリボン）
var ribbon_sleep_hours := 0
## チェックの入っているサブスキル（id → true）
var subskills := {}
var nature_up: int = Nature.NONE
var nature_down: int = Nature.NONE
## チーム全体のおてつだいボーナスの数（0〜5）。画面下部で決め、パチモンと妖精の全員に同じ値が入る
var help_bonus_count := 0
## イベント補正（ON のときだけ効く）
var event_on := false
## イベント: 1回で拾うきのみの数の増加数
var event_berry_add := 0
## イベント: 1回で拾う食材の数の増加数
var event_ingredient_add := 0
## イベント: スキル発生確率の倍率
var event_skill_mult := 1.0
## イベント: 最大所持数の増加数
var event_carry_add := 0
## イベント: 最大所持数の倍率
var event_carry_mult := 1.0
## EXモード補正（ON のときだけ効く）
var ex_on := false
## EXモード: おてつだい時間の補正（%）。−10 なら時間が 0.9倍
var ex_help_time_pct := 0.0
## EXモード: 1回で拾う食材の数の増加数
var ex_ingredient_add := 0
## EXモード: 食材をたまに追加で持ってくる数
var ex_extra_ingredient := 0
## EXモード: 食材を追加で持ってくる確率（食材を拾ったおてつだいごと）
var ex_extra_ingredient_prob := 0.0
## EXモード: スキル発生確率の倍率
var ex_skill_mult := 1.0
## いいキャンプチケット（最大所持数 1.2倍・おてつだいスピード 1.2倍）。画面下部で決め、全員に同じ値が入る
var camp_ticket := false
## false にすると、レベルに関係なくすべての食材枠を使う（テスト用）
var unlock_slots_by_level := true

var berry := {"id": "berry", "name": "きのみ"}
## 食材枠。食材を拾うときは解放済みの枠から等確率でどれか1枠が選ばれる。
var ingredients: Array = [
	{"id": "ing_a", "name": "食材A", "amount": 1},
	{"id": "ing_b", "name": "食材B", "amount": 2},
	{"id": "ing_c", "name": "食材C", "amount": 4},
]


static func level_factor(lv: int) -> float:
	return 1.0 - 0.002 * (lv - 1)


## 名前の長さ。ASCII と半角カナは1、それ以外（全角）は2で数える。
static func name_width(s: String) -> int:
	var w := 0
	for i in s.length():
		w += _char_width(s.unicode_at(i))
	return w


static func _char_width(c: int) -> int:
	if c < 0x80 or (c >= 0xFF61 and c <= 0xFF9F):
		return 1
	return 2


## 長さが NAME_MAX_WIDTH を超える分を後ろから削る
static func clip_name(s: String) -> String:
	var w := 0
	for i in s.length():
		w += _char_width(s.unicode_at(i))
		if w > NAME_MAX_WIDTH:
			return s.substr(0, i)
	return s


func has_subskill(id: String) -> bool:
	return bool(subskills.get(id, false))


## 今のレベルで選べるサブスキルの数
func subskill_slots() -> int:
	var n := 0
	for lv in SUBSKILL_SLOT_LEVELS:
		if level >= lv:
			n += 1
	return n


## 選べる数を超えている分のサブスキルを、一覧の下の項目から外す
func trim_subskills() -> void:
	var ids: Array = SUBSKILLS.keys()
	ids.reverse()
	for id in ids:
		if subskills.size() <= subskill_slots():
			return
		subskills.erase(id)


## せいかくの補正倍率。up / down はその能力が上がるとき／下がるときの値。
func _nature_factor(kind: int, up: float, down: float) -> float:
	var f := 1.0
	if nature_up == kind:
		f *= up
	if nature_down == kind:
		f *= down
	return f


## サブスキルとおてつだいボーナスによるおてつだい時間の短縮率（上限35%）
func speed_reduction() -> float:
	var r := 0.0
	if has_subskill("speed_m"):
		r += 0.14
	if has_subskill("speed_s"):
		r += 0.07
	r += 0.05 * help_bonus_count
	return minf(r, SPEED_REDUCTION_CAP)


## おやすみリボンのおてつだい時間補正（あと何回進化できるかと累計睡眠時間で決まる）
func ribbon_speed_factor() -> float:
	if evolutions_left <= 0 or ribbon_sleep_hours < 500:
		return 1.0
	var two := evolutions_left >= 2
	if ribbon_sleep_hours >= 2000:
		return 0.75 if two else 0.88
	return 0.89 if two else 0.95


## おやすみリボンの最大所持数ボーナス
func ribbon_carry_bonus() -> int:
	if ribbon_sleep_hours >= 2000:
		return 8
	if ribbon_sleep_hours >= 1000:
		return 6
	if ribbon_sleep_hours >= 500:
		return 3
	if ribbon_sleep_hours >= 200:
		return 1
	return 0


## おやすみリボンの段階（0: なし、1: 200時間〜、2: 500時間〜、3: 1000時間〜、4: 2000時間〜）
func ribbon_tier() -> int:
	if ribbon_sleep_hours >= 2000:
		return 4
	if ribbon_sleep_hours >= 1000:
		return 3
	if ribbon_sleep_hours >= 500:
		return 2
	if ribbon_sleep_hours >= 200:
		return 1
	return 0


## EXモードのおてつだい時間の倍率
func ex_time_factor() -> float:
	return maxf(0.01, 1.0 + ex_help_time_pct / 100.0) if ex_on else 1.0


## いいキャンプチケットの倍率（所持数・おてつだいスピード）
func camp_factor() -> float:
	return 1.2 if camp_ticket else 1.0


## げんき補正をかける前のおてつだい時間（秒）。
## 基準時間×レベル補正×せいかく補正×サブスキル補正×おやすみリボン補正×EXモード補正÷いいキャンプチケット(1.2)
## を掛け合わせてから小数点以下を切り捨てる。
## せいかくの補正は時間に対して上昇 0.9倍／下降 1.075倍（スピード 1.11倍／0.93倍 に当たる）。
func help_sec() -> float:
	var t := base_help_sec * level_factor(level) * _nature_factor(Nature.SPEED, 0.9, 1.075) \
		* (1.0 - speed_reduction()) * ribbon_speed_factor() * ex_time_factor() / camp_factor()
	# 0.882 などが浮動小数でわずかに小さくなり、1秒ずれないように少し足してから切り捨てる
	return floorf(t + 1e-6)


## せいかくのげんき回復量の倍率（上昇 1.2倍／下降 0.88倍）
func genki_recovery_factor() -> float:
	return _nature_factor(Nature.GENKI, 1.2, 0.88)


## 補正後の食材確率。せいかく（1.2倍／0.8倍）と食材確率アップ（M +36%・S +18%、足し算）を掛ける。
func ingredient_chance() -> float:
	var sub := 1.0
	if has_subskill("ing_m"):
		sub += 0.36
	if has_subskill("ing_s"):
		sub += 0.18
	return clampf(ingredient_prob * _nature_factor(Nature.INGREDIENT, 1.2, 0.8) * sub, 0.0, 1.0)


## 補正後のスキル発生確率。せいかく（1.2倍／0.8倍）とスキル確率アップ（M +36%・S +18%、足し算）、
## イベント・EXモードの倍率を掛ける。
func skill_chance() -> float:
	var sub := 1.0
	if has_subskill("skill_m"):
		sub += 0.36
	if has_subskill("skill_s"):
		sub += 0.18
	var mult := (event_skill_mult if event_on else 1.0) * (ex_skill_mult if ex_on else 1.0)
	return clampf(skill_prob * _nature_factor(Nature.SKILL, 1.2, 0.8) * sub * mult, 0.0, 1.0)


## 補正後の最大所持数。サブスキル（L +18・M +12・S +6）・おやすみリボン・イベントの増加数を足してから、
## イベントの倍率といいキャンプチケット（1.2倍）を掛けて小数点以下を切り上げる。
func carry_limit() -> int:
	var n := max_carry + ribbon_carry_bonus()
	if has_subskill("carry_l"):
		n += 18
	if has_subskill("carry_m"):
		n += 12
	if has_subskill("carry_s"):
		n += 6
	var mult := camp_factor()
	if event_on:
		n += event_carry_add
		mult *= event_carry_mult
	# 25×1.2=30.0 などが浮動小数でわずかに大きくなり、1つ増えないように少し引いてから切り上げる
	return maxi(1, int(ceil(n * mult - 1e-6)))


## 1回で拾うきのみの数（きのみの数S で +1、イベントの増加数）
func berry_amount() -> int:
	return berries_per_help + (1 if has_subskill("berry_s") else 0) + (event_berry_add if event_on else 0)


## 食材枠の食材を拾うときの数（イベント・EXモードの増加数を足す。たまに追加で持ってくる分は含まない）
func ingredient_amount(ing: Dictionary) -> int:
	return int(ing["amount"]) + (event_ingredient_add if event_on else 0) + (ex_ingredient_add if ex_on else 0)


## EXモードで食材をたまに追加で持ってくるか（確率と数が 0 なら抽選しない）
func has_extra_ingredient() -> bool:
	return ex_on and ex_extra_ingredient > 0 and ex_extra_ingredient_prob > 0.0


## 今のレベルで解放されている食材枠
func active_ingredients() -> Array:
	if not unlock_slots_by_level:
		return ingredients
	var out: Array = []
	for i in ingredients.size():
		if i >= SLOT_UNLOCK_LEVELS.size() or level >= SLOT_UNLOCK_LEVELS[i]:
			out.append(ingredients[i])
	return out


func item_ids() -> Array:
	var ids: Array = [berry["id"]]
	for ing in ingredients:
		ids.append(ing["id"])
	return ids


func item_name(id: String) -> String:
	if id == berry["id"]:
		return berry["name"]
	for ing in ingredients:
		if ing["id"] == id:
			return ing["name"]
	return id


func is_berry(id: String) -> bool:
	return id == berry["id"]


## 設定の保存で書き出さない項目。おてつだいボーナス数といいキャンプチケットはチーム全体の設定なので、
## 変身しても変わらない
const NOT_SAVED := ["berry", "unlock_slots_by_level", "help_bonus_count", "camp_ticket"]


## 保存用に、設定パネルで変えられる値をまとめて取り出す（JSON にできる形）
func to_dict() -> Dictionary:
	var d := {}
	for prop in get_property_list():
		if not (prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE) or prop["name"] in NOT_SAVED:
			continue
		var v: Variant = get(prop["name"])
		if v is Array or v is Dictionary:
			v = v.duplicate(true)
		d[prop["name"]] = v
	return d


## to_dict で取り出した値を戻す。知らない項目や型の違う項目は無視し、ない項目は今の値のまま。
## JSON を通ると数はすべて小数になるので、今の値の型に合わせて戻す。
func apply_dict(d: Dictionary) -> void:
	for key in d:
		if key in NOT_SAVED:
			continue
		var cur: Variant = get(key)
		if cur == null:
			continue
		var v: Variant = d[key]
		match typeof(cur):
			TYPE_INT:
				if v is float or v is int:
					set(key, int(round(v)))
			TYPE_FLOAT:
				if v is float or v is int:
					set(key, float(v))
			TYPE_BOOL:
				if v is bool:
					set(key, v)
			TYPE_STRING:
				if v is String:
					set(key, clip_name(v) if key == "pseudon_name" else v)
			TYPE_DICTIONARY:
				if v is Dictionary:
					var dv: Dictionary = v.duplicate(true)
					if key == "subskills":
						# サブスキルから外した項目（おてつだいボーナスなど）は読み捨てる
						for id in dv.keys():
							if not SUBSKILLS.has(id):
								dv.erase(id)
					set(key, dv)
			TYPE_ARRAY:
				if v is Array and key == "ingredients":
					for i in mini(v.size(), ingredients.size()):
						if v[i] is Dictionary and v[i].has("amount"):
							ingredients[i]["amount"] = int(round(float(v[i]["amount"])))
