extends RefCounted
## 計算条件の保存先（設定1〜設定5）。user:// に JSON で書く（Web ではブラウザの IndexedDB に残る）。

const Params = preload("res://scripts/params.gd")

const PATH := "user://presets.json"
const SLOT_COUNT := 5

## 枠ごとの {"name": 設定名, "params": Params.to_dict() の中身（未保存なら null）}
var slots: Array = []


var _path := PATH


func _init(path: String = PATH) -> void:
	_path = path
	load_file()


static func default_name(i: int) -> String:
	return "設定%d" % (i + 1)


func load_file() -> void:
	slots.clear()
	for i in SLOT_COUNT:
		slots.append({"name": default_name(i), "params": null})
	if not FileAccess.file_exists(_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path))
	if not data is Array:
		return
	for i in mini(data.size(), SLOT_COUNT):
		var s: Variant = data[i]
		if s is Dictionary:
			if s.get("name") is String and s["name"] != "":
				slots[i]["name"] = s["name"]
			if s.get("params") is Dictionary:
				slots[i]["params"] = s["params"]


func is_saved(i: int) -> bool:
	return slots[i]["params"] != null


func slot_name(i: int) -> String:
	return slots[i]["name"]


## 枠 i に今の設定を上書きで記憶する。設定名はパチモンの名前（空なら既定名）。
func store(i: int, p: Params) -> void:
	slots[i] = {"name": p.pseudon_name if p.pseudon_name != "" else default_name(i), "params": p.to_dict()}
	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f == null:
		push_warning("設定を保存できませんでした: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(slots))


## 枠 i の設定を p に戻す。名前は設定名にする。保存がなければ false。
func restore(i: int, p: Params) -> bool:
	if not is_saved(i):
		return false
	p.apply_dict(slots[i]["params"])
	p.pseudon_name = Params.clip_name(slot_name(i))
	return true
