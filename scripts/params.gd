extends RefCounted
## ポケモン1体分のおてつだいパラメータ。
## 初期値は基礎資料「おてつだい計算モデル」の計算例に合わせている。

## 基準おてつだい時間（秒）
var base_help_sec := 2600.0
## 食材確率（1回のおてつだいで食材を拾う確率）
var ingredient_prob := 0.25
## メインスキル発生確率
var skill_prob := 0.05
## 最大所持数（きのみ＋食材）
var max_carry := 25
## 1回のおてつだいで拾うきのみの数
var berries_per_help := 2
## メインスキルのストック上限（スキルとくいは2、それ以外は1）
var max_skill_stock := 1

var berry := {"id": "berry", "name": "きのみ"}
## 解放済みの食材枠。食材を拾うときは等確率でどれか1枠が選ばれる。
var ingredients: Array = [
	{"id": "ing_a", "name": "食材A", "amount": 2},
	{"id": "ing_b", "name": "食材B", "amount": 3},
]


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
