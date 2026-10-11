extends RefCounted
## パチモン1体分のおてつだいパラメータ。
## 画面左の設定パネルで変えられる値（基準値）と、そこからサブスキル・せいかく・おやすみリボンなどの
## 補正をかけて実際の計算に使う値（help_sec() など）を持つ。

## せいかくで上がる／下がる能力
enum Nature { NONE, SPEED, INGREDIENT, SKILL, GENKI }

## サブスキル（id → 表示名）
const SUBSKILLS := {
	"berry_s": "きのみの数S",
	"help_bonus": "おてつだいボーナス",
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
## サブスキルによるおてつだい時間の短縮（おてつだいボーナスを含む）の上限
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
## 他のメンバーが持つおてつだいボーナスの数（0〜4）
var other_help_bonus := 0
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


## サブスキルによるおてつだい時間の短縮率（上限35%）
func speed_reduction() -> float:
	var r := 0.0
	if has_subskill("speed_m"):
		r += 0.14
	if has_subskill("speed_s"):
		r += 0.07
	var bonus := other_help_bonus + (1 if has_subskill("help_bonus") else 0)
	r += 0.05 * bonus
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


## げんき補正をかける前のおてつだい時間（秒）。
## 基準時間×レベル補正×せいかく補正×サブスキル補正×おやすみリボン補正を掛け合わせてから小数点以下を切り捨てる。
## せいかくの補正は時間に対して上昇 0.9倍／下降 1.075倍（スピード 1.11倍／0.93倍 に当たる）。
func help_sec() -> float:
	var t := base_help_sec * level_factor(level) * _nature_factor(Nature.SPEED, 0.9, 1.075) \
		* (1.0 - speed_reduction()) * ribbon_speed_factor()
	# 0.882 などが浮動小数でわずかに小さくなり、1秒ずれないように少し足してから切り捨てる
	return floorf(t + 1e-6)


## 補正後の食材確率。せいかく（1.2倍／0.8倍）と食材確率アップ（M +36%・S +18%、足し算）を掛ける。
func ingredient_chance() -> float:
	var sub := 1.0
	if has_subskill("ing_m"):
		sub += 0.36
	if has_subskill("ing_s"):
		sub += 0.18
	return clampf(ingredient_prob * _nature_factor(Nature.INGREDIENT, 1.2, 0.8) * sub, 0.0, 1.0)


## 補正後のスキル発生確率。せいかく（1.2倍／0.8倍）とスキル確率アップ（M +36%・S +18%、足し算）を掛ける。
func skill_chance() -> float:
	var sub := 1.0
	if has_subskill("skill_m"):
		sub += 0.36
	if has_subskill("skill_s"):
		sub += 0.18
	return clampf(skill_prob * _nature_factor(Nature.SKILL, 1.2, 0.8) * sub, 0.0, 1.0)


## 補正後の最大所持数（サブスキル L +18・M +12・S +6、おやすみリボン）
func carry_limit() -> int:
	var n := max_carry + ribbon_carry_bonus()
	if has_subskill("carry_l"):
		n += 18
	if has_subskill("carry_m"):
		n += 12
	if has_subskill("carry_s"):
		n += 6
	return n


## 1回で拾うきのみの数（きのみの数S で +1）
func berry_amount() -> int:
	return berries_per_help + (1 if has_subskill("berry_s") else 0)


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
