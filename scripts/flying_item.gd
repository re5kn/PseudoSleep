extends Node2D
## パチモンから山へ飛んでいく途中のきのみ・食材。

const ItemArt = preload("res://scripts/item_art.gd")

var item_id := ""


func _draw() -> void:
	ItemArt.draw_item(self, item_id, Vector2.ZERO, 1.0)
