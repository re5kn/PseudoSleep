extends Control
## UI に並べる小さなきのみ・食材アイコン。

const ItemArt = preload("res://scripts/item_art.gd")

var item_id := ""


func _init(id: String = "") -> void:
	item_id = id
	custom_minimum_size = Vector2(34, 34)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	ItemArt.draw_item(self, item_id, size / 2 + Vector2(0, 2), 0.95)
