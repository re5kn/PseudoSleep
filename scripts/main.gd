extends Node
## 画面全体の組み立てと操作。

const Sim = preload("res://scripts/sim.gd")
const FieldBackground = preload("res://scripts/field_background.gd")
const PseudonView = preload("res://scripts/pseudon_view.gd")
const ItemPile = preload("res://scripts/item_pile.gd")
const FlyingItem = preload("res://scripts/flying_item.gd")
const StorageBox = preload("res://scripts/storage_box.gd")
const ItemIcon = preload("res://scripts/item_icon.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const VIEW_SIZE := Vector2(720, 1280)
const FIELD_HEIGHT := 1040.0
const PSEUDON_POS := Vector2(360, 505)
const PILE_Y := 640.0
const PILE_GAP := 112.0
const BERRY_BOX_POS := Vector2(575, 745)
const INGREDIENT_BOX_POS := Vector2(150, 735)
const MIN_HOURS := 1
const MAX_HOURS := 24
const TOAST_SEC := 2.5
const CUTIN_PAUSE_SEC := 0.9
const REPEAT_DELAY_SEC := 0.4
const REPEAT_INTERVAL_SEC := 0.08

const TEXT_DARK := Color("5a4632")
const CREAM := Color("fff7e6")

var sim: Sim
var hours := 3
var last_result := {}
var piles := {}
var cutin_active := false
var cutin_closable := false
## なぞり回収中か、直前の指の位置、このなぞりで回収済みの山
var swiping := false
var swipe_last := Vector2.ZERO
var swiped := {}

var ui_theme: Theme
var actor_root: Node2D
var pseudon: PseudonView
var berry_box: StorageBox
var ingredient_box: StorageBox
var dim: ColorRect
var hud_label: Label
var hours_label: Label
var advance_button: Button
var genki_button: Button
var stock_button: Button
var status_label: Label
var toast_box: VBoxContainer
var box_popup: PanelContainer
var box_popup_label: Label
var box_popup_timer: SceneTreeTimer
var bubble: PanelContainer
var bubble_label: Label
var blocker: Control


func _ready() -> void:
	sim = Sim.new()
	ui_theme = Theme.new()
	ui_theme.default_font = FONT
	ui_theme.default_font_size = 22
	_build_field()
	_build_panel()
	_build_overlays()
	_refresh()


# ---------------------------------------------------------------- 画面の組み立て

func _layer(n: int) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = n
	add_child(layer)
	return layer


func _build_field() -> void:
	var field := _layer(0)
	field.add_child(FieldBackground.new())

	ingredient_box = StorageBox.new()
	ingredient_box.kind = StorageBox.Kind.INGREDIENT
	ingredient_box.label = "食材収容箱"
	ingredient_box.position = INGREDIENT_BOX_POS
	field.add_child(ingredient_box)

	berry_box = StorageBox.new()
	berry_box.kind = StorageBox.Kind.BERRY
	berry_box.label = "きのみ収容箱"
	berry_box.position = BERRY_BOX_POS
	field.add_child(berry_box)

	var hud := PanelContainer.new()
	hud.theme = ui_theme
	hud.position = Vector2(16, 16)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.85), 20, 8))
	hud_label = _label("", 20)
	hud.add_child(hud_label)
	field.add_child(hud)

	# 暗転はUIパネルも含めて画面全体にかける
	var dim_layer := _layer(2)
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = VIEW_SIZE
	dim.modulate.a = 0.0
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_layer.add_child(dim)

	# パチモンとドロップは暗転より手前に出す
	var actors := _layer(3)
	actor_root = Node2D.new()
	actors.add_child(actor_root)
	pseudon = PseudonView.new()
	pseudon.position = PSEUDON_POS
	actor_root.add_child(pseudon)


func _build_panel() -> void:
	var layer := _layer(1)
	var panel := PanelContainer.new()
	panel.theme = ui_theme
	panel.position = Vector2(0, FIELD_HEIGHT)
	panel.size = Vector2(VIEW_SIZE.x, VIEW_SIZE.y - FIELD_HEIGHT)
	var sb := _style(CREAM, 0, 14)
	sb.corner_radius_top_left = 28
	sb.corner_radius_top_right = 28
	sb.border_width_top = 4
	sb.border_color = Color("f0d9a8")
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	v.add_child(row1)
	var minus := _button("－", Color("ffe9bf"), TEXT_DARK)
	minus.custom_minimum_size = Vector2(56, 56)
	_add_hold_repeat(minus, _change_hours.bind(-1))
	row1.add_child(minus)
	hours_label = _label("", 24)
	hours_label.custom_minimum_size = Vector2(92, 0)
	hours_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row1.add_child(hours_label)
	var plus := _button("＋", Color("ffe9bf"), TEXT_DARK)
	plus.custom_minimum_size = Vector2(56, 56)
	_add_hold_repeat(plus, _change_hours.bind(1))
	row1.add_child(plus)
	advance_button = _button("", Color("4fbf6a"), Color.WHITE)
	advance_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	advance_button.add_theme_font_size_override("font_size", 26)
	advance_button.pressed.connect(_on_advance)
	row1.add_child(advance_button)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	v.add_child(row2)
	# タップで切り替えるトグル
	genki_button = _toggle()
	genki_button.pressed.connect(_on_genki_toggled)
	row2.add_child(genki_button)
	stock_button = _toggle()
	stock_button.pressed.connect(_on_stock_toggled)
	row2.add_child(stock_button)
	var reset := _button("リセット", Color("e5534b"), Color.WHITE)
	reset.add_theme_font_size_override("font_size", 18)
	reset.pressed.connect(_on_reset)
	row2.add_child(reset)

	status_label = _label("", 17)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(status_label)


func _build_overlays() -> void:
	var layer := _layer(4)

	toast_box = VBoxContainer.new()
	toast_box.theme = ui_theme
	toast_box.position = Vector2(VIEW_SIZE.x - 236, 84)
	toast_box.size = Vector2(220, 0)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_theme_constant_override("separation", 8)
	layer.add_child(toast_box)

	box_popup = PanelContainer.new()
	box_popup.theme = ui_theme
	box_popup.visible = false
	box_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var popup_style := _style(Color.WHITE, 18, 12)
	popup_style.set_border_width_all(3)
	popup_style.border_color = Color("f0a43a")
	box_popup.add_theme_stylebox_override("panel", popup_style)
	box_popup_label = _label("", 19)
	box_popup.add_child(box_popup_label)
	layer.add_child(box_popup)

	bubble = PanelContainer.new()
	bubble.theme = ui_theme
	bubble.visible = false
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.position = Vector2(40, 1060)
	bubble.size = Vector2(640, 170)
	bubble.pivot_offset = Vector2(320, 0)
	var bubble_style := _style(Color.WHITE, 36, 18)
	bubble_style.set_border_width_all(4)
	bubble_style.border_color = Color("f0a43a")
	bubble.add_theme_stylebox_override("panel", bubble_style)
	bubble_label = _label("", 24)
	bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble.add_child(bubble_label)
	layer.add_child(bubble)

	# カットイン中はタップをここで受け止める
	var blocker_layer := _layer(5)
	blocker = Control.new()
	blocker.size = VIEW_SIZE
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.visible = false
	blocker.gui_input.connect(_on_blocker_input)
	blocker_layer.add_child(blocker)


func _style(color: Color, radius: int, pad: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad * 1.5
	sb.content_margin_right = pad * 1.5
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	return sb


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", TEXT_DARK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _apply_button_styles(b: Control, color: Color, text_color: Color) -> void:
	b.add_theme_stylebox_override("normal", _style(color, 18, 8))
	b.add_theme_stylebox_override("hover", _style(color.lightened(0.08), 18, 8))
	b.add_theme_stylebox_override("pressed", _style(color.darkened(0.12), 18, 8))
	b.add_theme_stylebox_override("disabled", _style(color.darkened(0.25), 18, 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, text_color)
	b.focus_mode = Control.FOCUS_NONE


func _button(text: String, color: Color, text_color: Color) -> Button:
	var b := Button.new()
	b.text = text
	_apply_button_styles(b, color, text_color)
	return b


# 押した瞬間に1回反応し、押しっぱなしならしばらく待ってから連続で反応させる
func _add_hold_repeat(b: Button, action: Callable) -> void:
	var timer := Timer.new()
	b.add_child(timer)
	timer.timeout.connect(func() -> void:
		timer.start(REPEAT_INTERVAL_SEC)
		action.call())
	b.button_down.connect(func() -> void:
		action.call()
		timer.start(REPEAT_DELAY_SEC))
	b.button_up.connect(timer.stop)


func _toggle() -> Button:
	var b := _button("", Color("ffe9bf"), TEXT_DARK)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 18)
	return b


# ---------------------------------------------------------------- 操作

func _change_hours(delta: int) -> void:
	hours = clampi(hours + delta, MIN_HOURS, MAX_HOURS)
	_refresh()


func _on_advance() -> void:
	if cutin_active:
		return
	_hide_box_popup()
	last_result = sim.advance(hours * 3600.0)
	_refresh()


func _on_genki_toggled() -> void:
	var decay := sim.genki_mode == Sim.GenkiMode.ALWAYS_HIGH
	sim.set_genki_mode(Sim.GenkiMode.DECAY if decay else Sim.GenkiMode.ALWAYS_HIGH)
	_refresh()


func _on_stock_toggled() -> void:
	sim.params.max_skill_stock = 2 if sim.params.max_skill_stock == 1 else 1
	sim.skill_stock = mini(sim.skill_stock, sim.params.max_skill_stock)
	_refresh()


func _on_reset() -> void:
	if cutin_active:
		return
	sim.reset()
	last_result = {}
	for id in piles:
		piles[id].queue_free()
	piles.clear()
	for t in toast_box.get_children():
		t.queue_free()
	_hide_box_popup()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		swiping = false
		return
	if event is InputEventMouseMotion and swiping and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_on_swipe(_field_pos(event))
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var p := _field_pos(event)
	if p.y > FIELD_HEIGHT or cutin_active:
		return
	get_viewport().set_input_as_handled()
	# 押したままフィールド上をなぞると、通った山を回収する
	swiping = true
	swipe_last = p
	swiped.clear()
	var had_popup := box_popup.visible
	_hide_box_popup()
	for id in piles:
		if piles[id].hit(p):
			swiped[id] = true
			_collect(id)
			return
	if pseudon.hit(p) and sim.has_icon():
		_on_pseudon_tap()
		return
	if berry_box.hit(p):
		if not had_popup or box_popup.get_meta("kind", -1) != StorageBox.Kind.BERRY:
			_show_box_popup(berry_box)
		return
	if ingredient_box.hit(p):
		if not had_popup or box_popup.get_meta("kind", -1) != StorageBox.Kind.INGREDIENT:
			_show_box_popup(ingredient_box)
		return


func _field_pos(event: InputEventMouse) -> Vector2:
	return actor_root.get_global_transform_with_canvas().affine_inverse() * event.position


func _on_swipe(p: Vector2) -> void:
	if cutin_active:
		swiping = false
		return
	get_viewport().set_input_as_handled()
	# 速くなぞっても取りこぼさないよう、前回の位置との間を細かく調べる
	var steps := maxi(1, ceili(swipe_last.distance_to(p) / (ItemPile.HIT_RADIUS * 0.5)))
	for i in range(1, steps + 1):
		var q := swipe_last.lerp(p, float(i) / steps)
		if q.y > FIELD_HEIGHT:
			continue
		for id in piles:
			if not swiped.has(id) and piles[id].hit(q):
				swiped[id] = true
				_collect(id)
	swipe_last = p


func _on_pseudon_tap() -> void:
	var result := sim.drop()
	var stock: int = result["stock"]
	_spawn_drops(result["items"])
	if stock > 0:
		_start_cutin(stock)
	_refresh()


func _collect(id: String) -> void:
	var pile: ItemPile = piles[id]
	var got := sim.collect(id)
	if got > 0:
		pile.set_count(pile.count - got)
		_toast(id, "×%d" % got)
	else:
		var box_name := "きのみ収容箱" if sim.params.is_berry(id) else "食材収容箱"
		_toast(id, "%sがいっぱい" % box_name)
		pile.bounce()
	_refresh()


# ---------------------------------------------------------------- ぽこぽこ

func _pile_position(id: String) -> Vector2:
	var ids := sim.params.item_ids()
	var i := ids.find(id)
	return Vector2(PSEUDON_POS.x + (i - (ids.size() - 1) / 2.0) * PILE_GAP, PILE_Y)


func _get_pile(id: String) -> ItemPile:
	if not piles.has(id):
		var pile := ItemPile.new()
		pile.item_id = id
		pile.position = _pile_position(id)
		actor_root.add_child(pile)
		actor_root.move_child(pile, 0)
		piles[id] = pile
	return piles[id]


func _spawn_drops(items: Dictionary) -> void:
	var delay := 0.0
	for id in sim.params.item_ids():
		var n := int(items.get(id, 0))
		if n <= 0:
			continue
		var pile := _get_pile(id)
		# 個数が多いときは何個かずつまとめて飛ばす
		var hops := mini(n, 6)
		for k in hops:
			var amount := n / hops + (1 if k < n % hops else 0)
			_launch(id, amount, pile, delay, k)
			delay += 0.11


func _launch(id: String, amount: int, pile: ItemPile, delay: float, k: int) -> void:
	var fly := FlyingItem.new()
	fly.item_id = id
	fly.visible = false
	var from := PSEUDON_POS + Vector2(0, 10)
	var to := pile.position + Vector2((k % 3 - 1) * 10, -8)
	fly.position = from
	actor_root.add_child(fly)
	var tw := fly.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func(): fly.visible = true)
	tw.tween_method(func(t: float): fly.position = _arc(from, to, t), 0.0, 1.0, 0.42)
	tw.tween_callback(func():
		var on_field := int(sim.on_field.get(id, 0))
		pile.set_count(mini(pile.count + amount, on_field))
		pile.bounce()
		fly.queue_free()
	)


func _arc(from: Vector2, to: Vector2, t: float) -> Vector2:
	var p := from.lerp(to, t)
	p.y -= sin(t * PI) * 90.0
	return p


# ---------------------------------------------------------------- メインスキルのカットイン

func _start_cutin(stock: int) -> void:
	cutin_active = true
	cutin_closable = false
	_hide_box_popup()
	blocker.visible = true
	create_tween().tween_property(dim, "modulate:a", 1.0, 0.15)
	pseudon.show_exclaims(stock)
	await get_tree().create_timer(CUTIN_PAUSE_SEC).timeout
	if not cutin_active:
		return
	bubble_label.text = "メインスキルが発動した！\nストック %d回分\n\n（タップでとじる）" % stock
	bubble.visible = true
	bubble.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(bubble, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cutin_closable = true


func _on_blocker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and cutin_closable:
		_end_cutin()


func _end_cutin() -> void:
	cutin_active = false
	cutin_closable = false
	bubble.visible = false
	pseudon.show_exclaims(0)
	create_tween().tween_property(dim, "modulate:a", 0.0, 0.2)
	blocker.visible = false


# ---------------------------------------------------------------- 表示

func _toast(id: String, text: String) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.92), 20, 6))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ItemIcon.new(id))
	row.add_child(_label("%s %s" % [sim.params.item_name(id), text], 18))
	panel.add_child(row)
	toast_box.add_child(panel)
	var tw := panel.create_tween()
	tw.tween_interval(TOAST_SEC)
	tw.tween_property(panel, "modulate:a", 0.0, 0.4)
	tw.tween_callback(panel.queue_free)


func _show_box_popup(box: StorageBox) -> void:
	var lines: Array[String] = []
	if box.kind == StorageBox.Kind.BERRY:
		lines.append("きのみ収容箱")
		lines.append("%d / %d" % [Sim.sum(sim.berry_box), Sim.BERRY_BOX_MAX])
	else:
		lines.append("食材収容箱")
		lines.append("%d / %d" % [Sim.sum(sim.ingredient_box), Sim.INGREDIENT_BOX_MAX])
		for ing in sim.params.ingredients:
			lines.append("%s %d" % [ing["name"], int(sim.ingredient_box.get(ing["id"], 0))])
	box_popup_label.text = "\n".join(lines)
	box_popup.set_meta("kind", box.kind)
	box_popup.reset_size()
	box_popup.visible = true
	var s := box_popup.get_combined_minimum_size()
	var x := clampf(box.position.x - s.x / 2, 12, VIEW_SIZE.x - s.x - 12)
	box_popup.position = Vector2(x, box.position.y - 70 - s.y)
	var timer := get_tree().create_timer(3.0)
	box_popup_timer = timer
	timer.timeout.connect(func():
		if box_popup_timer == timer:
			_hide_box_popup()
	)


func _hide_box_popup() -> void:
	box_popup.visible = false
	box_popup_timer = null


func _format_hours(sec: float) -> String:
	var total_min := int(round(sec / 60.0))
	return "%d時間%02d分" % [total_min / 60, total_min % 60]


func _refresh() -> void:
	hours_label.text = "%d時間" % hours
	advance_button.text = "%d時間分すすめる" % hours
	genki_button.text = "げんき：81以上で固定" if sim.genki_mode == Sim.GenkiMode.ALWAYS_HIGH else "げんき：100から減少"
	stock_button.text = "ストック上限：%d" % sim.params.max_skill_stock
	var genki := "81以上" if sim.genki_mode == Sim.GenkiMode.ALWAYS_HIGH else str(sim.genki_at(sim.elapsed_sec))
	hud_label.text = "経過 %s ・ げんき %s" % [_format_hours(sim.elapsed_sec), genki]

	pseudon.show_icon = sim.has_icon()
	pseudon.icon_full = sim.is_full()

	var lines: Array[String] = []
	if last_result.is_empty():
		lines.append("「すすめる」でおてつだいを進めます。")
		lines.append("パチモンのアイコンをタップすると結果が出ます。")
	else:
		var r := last_result
		lines.append("前回%d時間：おてつだい%d回（きのみ%d・食材%d）スキル%d回" % [
			int(r["seconds"] / 3600.0), r["helps"], r["berry_helps"], r["ingredient_helps"], r["skills"]])
		var parts: Array[String] = []
		for id in sim.params.item_ids():
			parts.append("%s %d" % [sim.params.item_name(id), int(r["items"].get(id, 0))])
		var extra := ""
		if r["full_helps"] > 0:
			extra = "　いつのまに育成%d回" % r["full_helps"]
		lines.append("獲得：" + "・".join(parts) + extra)
	lines.append("所持 %d/%d　スキルストック %d/%d" % [
		sim.held_count(), sim.params.max_carry, sim.skill_stock, sim.params.max_skill_stock])
	status_label.text = "\n".join(lines)
