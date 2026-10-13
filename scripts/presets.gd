extends RefCounted
## 計算条件の保存先（設定1〜設定5）。user:// に JSON で書く（Web ではブラウザの IndexedDB に残る）。
## ユーザーが記憶していない枠には、DEFAULTS の初期設定が入る。

const Params = preload("res://scripts/params.gd")

const PATH := "user://presets.json"
const SLOT_COUNT := 5

## 枠ごとの初期設定。{"name": 設定名, "params": Params の初期値から変える項目}。null の枠は空。
## ingredients は食材枠ごとの数の配列で書く。
const DEFAULTS := [
	{
		"name": "No.25実Sいじ",
		"params": {
			"level": 25,
			"base_help_sec": 2700.0,
			"ingredient_prob": 0.207,
			"skill_prob": 0.021,
			"skill_ceiling": 78,
			"max_skill_stock": 1,
			"max_carry": 22,
			"berries_per_help": 2,
			"ingredients": [1],
			"evolutions_left": 1,
			"ribbon_sleep_hours": 0,
			"subskills": {"berry_s": true},
			"nature_up": Params.Nature.SPEED,
			"nature_down": Params.Nature.INGREDIENT,
		},
	},
	{
		"name": "回復役",
		"params": {
			"level": 25,
			"base_help_sec": 4000.0,
			"ingredient_prob": 0.25,
			"skill_prob": 0.02,
			"skill_ceiling": 40,
			"max_skill_stock": 2,
			"max_carry": 13,
			"berries_per_help": 1,
			"ingredients": [1],
			"evolutions_left": 1,
			"ribbon_sleep_hours": 0,
		},
	},
	{
		"name": "本島EXバフ",
		"params": {
			"ex_on": true,
			"ex_help_time_pct": -10.0,
			"ex_skill_mult": 1.25,
		},
	},
	{
		"name": "砂浜EXデバフ",
		"params": {
			"ex_on": true,
			"ex_help_time_pct": 35.0,
		},
	},
	null,
]

## 枠ごとの {"name": 設定名, "params": Params.to_dict() の中身（空なら null）, "user": ユーザーが記憶したか}
var slots: Array = []

var _path := PATH


func _init(path: String = PATH) -> void:
	_path = path
	load_file()


static func default_name(i: int) -> String:
	return "設定%d" % (i + 1)


## 枠 i の初期設定。Params の初期値に DEFAULTS の項目を重ねたもの（空の枠は params が null）
static func default_slot(i: int) -> Dictionary:
	var d: Variant = DEFAULTS[i] if i < DEFAULTS.size() else null
	if d == null:
		return {"name": default_name(i), "params": null, "user": false}
	var p := Params.new()
	var over: Dictionary = d["params"].duplicate(true)
	if over.has("ingredients"):
		var amounts: Array = over["ingredients"]
		over.erase("ingredients")
		for k in mini(amounts.size(), p.ingredients.size()):
			p.ingredients[k]["amount"] = amounts[k]
	p.apply_dict(over)
	p.pseudon_name = Params.clip_name(d["name"])
	return {"name": p.pseudon_name, "params": p.to_dict(), "user": false}


## 記憶した枠だけファイルから読む。記憶していない枠は初期設定
func load_file() -> void:
	slots.clear()
	for i in SLOT_COUNT:
		slots.append(default_slot(i))
	if not FileAccess.file_exists(_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path))
	if not data is Array:
		return
	for i in mini(data.size(), SLOT_COUNT):
		var s: Variant = data[i]
		if s is Dictionary and s.get("params") is Dictionary:
			var name: Variant = s.get("name")
			slots[i] = {
				"name": name if name is String and name != "" else default_name(i),
				"params": s["params"],
				"user": true,
			}


func is_saved(i: int) -> bool:
	return slots[i]["params"] != null


func slot_name(i: int) -> String:
	return slots[i]["name"]


## 枠 i に今の設定を上書きで記憶する。設定名はパチモンの名前（空なら既定名）。
## ファイルには記憶した枠だけを書く（初期設定の枠は null）。初期設定を変えたときに古い初期設定が残らないように。
func store(i: int, p: Params) -> void:
	slots[i] = {"name": p.pseudon_name if p.pseudon_name != "" else default_name(i), "params": p.to_dict(), "user": true}
	var out: Array = []
	for s in slots:
		out.append({"name": s["name"], "params": s["params"]} if s["user"] else null)
	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f == null:
		push_warning("設定を保存できませんでした: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(out))


## 枠 i の設定を p に戻す。名前は設定名にする。保存がなければ false。
func restore(i: int, p: Params) -> bool:
	if not is_saved(i):
		return false
	p.apply_dict(slots[i]["params"])
	p.pseudon_name = Params.clip_name(slot_name(i))
	return true
