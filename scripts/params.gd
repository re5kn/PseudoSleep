extends RefCounted
## パチモン1体分のおてつだいパラメータ。

## 基準おてつだい時間（秒）
var base_help_sec := 2600.0
## レベル。おてつだい時間のレベル補正 1−0.002×(レベル−1) に使う。
var level := 60
## 食材確率（1回のおてつだいで食材を拾う確率）
var ingredient_prob := 0.25
## メインスキル発生確率
var skill_prob := 0.05
## 最大所持数（きのみ＋食材）
var max_carry := 28
## 1回のおてつだいで拾うきのみの数
var berries_per_help := 2
## メインスキルのストック上限（スキルとくいは2、それ以外は1）
var max_skill_stock := 1

var berry := {"id": "berry", "name": "きのみ"}
## 解放済みの食材枠。食材を拾うときは等確率でどれか1枠が選ばれる。
var ingredients: Array = [
	{"id": "ing_a", "name": "食材A", "amount": 2},
	{"id": "ing_b", "name": "食材B", "amount": 3},
	{"id": "ing_c", "name": "食材C", "amount": 5},
]


static func level_factor(lv: int) -> float:
	return 1.0 - 0.002 * (lv - 1)


## げんき補正をかける前のおてつだい時間（秒）。
## 基準時間×レベル補正（せいかく・サブスキル・リボン補正はなし＝1）を掛け合わせてから小数点以下を切り捨てる。
func help_sec() -> float:
	# 0.882 などが浮動小数でわずかに小さくなり、1秒ずれないように少し足してから切り捨てる
	return floorf(base_help_sec * level_factor(level) + 1e-6)


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
