extends Node
## 画面全体の組み立てと操作。

const Sim = preload("res://scripts/sim.gd")
const FieldBackground = preload("res://scripts/field_background.gd")
const PseudonView = preload("res://scripts/pseudon_view.gd")
const ItemPile = preload("res://scripts/item_pile.gd")
const FlyingItem = preload("res://scripts/flying_item.gd")
const StorageBox = preload("res://scripts/storage_box.gd")
const ItemIcon = preload("res://scripts/item_icon.gd")
const SettingsPanel = preload("res://scripts/settings_panel.gd")
const HelpLogTable = preload("res://scripts/help_log_table.gd")
const FONT = preload("res://fonts/MPLUSRounded1c-Bold.ttf")

const VIEW_SIZE := Vector2(720, 1280)
const FIELD_HEIGHT := 1040.0
const PSEUDON_POS := Vector2(360, 505)
const PILE_Y := 636.0
const PILE_GAP := 100.0
const BERRY_BOX_POS := Vector2(575, 745)
const INGREDIENT_BOX_POS := Vector2(150, 735)
const MIN_HOURS := 1
const MAX_HOURS := 24
const TOAST_SEC := 2.5
const CUTIN_PAUSE_SEC := 0.9
const REPEAT_DELAY_SEC := 0.4
const REPEAT_INTERVAL_SEC := 0.08
## 設定パネルの幅。ブラウザの幅が VIEW_SIZE.x + これ以上あれば、フィールドと並べて表示する
const SETTINGS_W := 470.0
const SETTINGS_SLIDE_SEC := 0.22
## おてつだいの記録パネルの幅（画面右からせり出す）
const LOG_W := 540.0

const TEXT_DARK := Color("5a4632")
const CREAM := Color("fff7e6")
## 天井で出たスキルの目印の色
const CEILING_COLOR := Color("e2483d")

var sim: Sim
var hours := 3
var piles := {}
var cutin_active := false
var cutin_closable := false
## なぞり回収中か、直前の指の位置、このなぞりで回収済みの山
var swiping := false
var swipe_last := Vector2.ZERO
var swiped := {}

## 縦長の画面（VIEW_SIZE）をブラウザの中央に置くため、全レイヤーを同じだけずらす
var layers: Array[CanvasLayer] = []
var ui_theme: Theme
var actor_root: Node2D
var pseudon: PseudonView
var berry_box: StorageBox
var ingredient_box: StorageBox
var dim: ColorRect
var hud: PanelContainer
var hud_label: RichTextLabel
var log_panel: PanelContainer
var log_scrim: ColorRect
var log_open := false
var log_slide := 0.0
var log_tween: Tween
var log_title: Label
var log_scroll: ScrollContainer
var log_table: HelpLogTable
var hours_label: Label
var advance_button: Button
var genki_button: Button
var status_label: RichTextLabel
var toast_box: VBoxContainer
var box_popup: PanelContainer
var box_popup_label: Label
var box_popup_timer: SceneTreeTimer
var bubble: PanelContainer
var bubble_label: Label
var blocker: Control
var settings: SettingsPanel
var settings_scrim: ColorRect
var settings_open := false
## 0＝閉じている、1＝せり出しきった状態
var settings_slide := 0.0
var settings_tween: Tween


func _ready() -> void:
	sim = Sim.new()
	ui_theme = Theme.new()
	ui_theme.default_font = FONT
	ui_theme.default_font_size = 22
	_build_field()
	_build_panel()
	_build_overlays()
	_build_log_view()
	_build_settings()
	_refresh()
	get_viewport().size_changed.connect(_center_layers)
	_center_layers()


# ---------------------------------------------------------------- 画面の組み立て

## 縦長の画面を中央に置く。横に余った領域は背景色のまま。
## 幅が広く設定パネル（左）・記録パネル（右）を並べて出せるときは、残りの幅の中央にフィールドを置く。
func _center_layers() -> void:
	var view := get_viewport().get_visible_rect().size
	var offset := ((view - VIEW_SIZE) / 2).floor()
	var wide := _is_wide()
	if wide:
		var left := SETTINGS_W * settings_slide
		var right := LOG_W * log_slide
		offset.x = floorf(left + (view.x - left - right - VIEW_SIZE.x) / 2)
	for layer in layers:
		layer.offset = offset
	if settings != null:
		settings.size = Vector2(_side_width(SETTINGS_W), view.y)
		settings.position = Vector2(-settings.size.x * (1.0 - settings_slide), 0)
		settings.visible = settings_slide > 0.0
		settings_scrim.size = view
		settings_scrim.visible = settings_open and not wide
		settings_scrim.modulate.a = settings_slide
	if log_panel != null:
		log_panel.size = Vector2(_side_width(LOG_W), view.y)
		log_panel.position = Vector2(view.x - log_panel.size.x * log_slide, 0)
		log_panel.visible = log_slide > 0.0
		log_scrim.size = view
		log_scrim.visible = log_open and not wide
		log_scrim.modulate.a = log_slide


## 開いているパネルをすべてフィールドの横に並べられるか
func _is_wide() -> bool:
	var need := VIEW_SIZE.x
	if settings_open:
		need += SETTINGS_W
	if log_open:
		need += LOG_W
	return get_viewport().get_visible_rect().size.x >= need


func _side_width(w: float) -> float:
	# 狭い画面では外側をタップして閉じられるよう、反対側に少し隙間を残す
	return minf(w, get_viewport().get_visible_rect().size.x - 80.0)


func _layer(n: int) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = n
	add_child(layer)
	layers.append(layer)
	return layer


func _build_field() -> void:
	var field := _layer(0)
	# 背景の波や影がフィールドの外へはみ出さないよう切り取る
	var field_clip := Control.new()
	field_clip.size = Vector2(VIEW_SIZE.x, FIELD_HEIGHT)
	field_clip.clip_contents = true
	field_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field_clip.add_child(FieldBackground.new())
	field.add_child(field_clip)

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

	hud = PanelContainer.new()
	hud.theme = ui_theme
	hud.position = Vector2(16, 16)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.85), 20, 8))
	hud_label = RichTextLabel.new()
	hud_label.bbcode_enabled = true
	hud_label.fit_content = true
	hud_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	hud_label.scroll_active = false
	hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_label.add_theme_font_size_override("normal_font_size", 20)
	hud_label.add_theme_color_override("default_color", TEXT_DARK)
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
	var reset := _button("リセット", Color("e5534b"), Color.WHITE)
	reset.add_theme_font_size_override("font_size", 18)
	reset.pressed.connect(_on_reset)
	row2.add_child(reset)

	status_label = RichTextLabel.new()
	status_label.bbcode_enabled = true
	status_label.scroll_active = false
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label.add_theme_font_size_override("normal_font_size", 17)
	status_label.add_theme_color_override("default_color", TEXT_DARK)
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


## 画面上部の累計をタップすると、画面右からせり出す、おてつだい1回ごとの記録。
## 設定パネルと同じく中央寄せのずらし（_layer）は使わず、画面右端に付ける
func _build_log_view() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	# 狭い画面ではパネルがフィールドに重なる。外側のタップはここで受けて閉じる
	log_scrim = ColorRect.new()
	log_scrim.color = Color(0, 0, 0, 0.35)
	log_scrim.visible = false
	log_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	log_scrim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_set_log_open(false))
	layer.add_child(log_scrim)

	log_panel = PanelContainer.new()
	log_panel.theme = ui_theme
	log_panel.visible = false
	var sb := _style(CREAM, 0, 18)
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	sb.corner_radius_top_left = 28
	sb.corner_radius_bottom_left = 28
	sb.border_width_left = 4
	sb.border_color = Color("e6cf9f")
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 12
	log_panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(log_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	log_panel.add_child(v)

	var top := HBoxContainer.new()
	v.add_child(top)
	log_title = _label("", 24)
	log_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(log_title)
	var close := _button("×", Color("ffe9bf"), TEXT_DARK)
	close.custom_minimum_size = Vector2(56, 56)
	close.add_theme_font_size_override("font_size", 28)
	close.pressed.connect(_set_log_open.bind(false))
	top.add_child(close)

	v.add_child(HelpLogTable.new(true))
	log_scroll = ScrollContainer.new()
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(log_scroll)
	log_table = HelpLogTable.new()
	log_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_scroll.add_child(log_table)
	log_scroll.get_v_scroll_bar().value_changed.connect(func(_v: float) -> void: log_table.queue_redraw())
	log_scroll.resized.connect(log_table.queue_redraw)


func _set_log_open(open: bool) -> void:
	if open == log_open:
		return
	log_open = open
	if open:
		_update_log()
		log_scroll.scroll_vertical = 0
	if log_tween != null:
		log_tween.kill()
	log_tween = create_tween()
	log_tween.tween_method(_set_log_slide, log_slide, 1.0 if open else 0.0, SETTINGS_SLIDE_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_center_layers()


func _set_log_slide(t: float) -> void:
	log_slide = t
	_center_layers()


## 開いたままでも「すすめる」やリセットに合わせて記録を更新する
func _update_log() -> void:
	log_title.text = "おてつだいの記録（全%d回）" % sim.help_log.size()
	log_table.set_log(sim.help_log)


## 設定パネルは画面の左端に付けるので、中央寄せのずらし（_layer）は使わない
func _build_settings() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	# 狭い画面ではパネルがフィールドに重なる。外側のタップはここで受けて閉じる
	settings_scrim = ColorRect.new()
	settings_scrim.color = Color(0, 0, 0, 0.35)
	settings_scrim.visible = false
	settings_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_scrim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_set_settings_open(false))
	layer.add_child(settings_scrim)
	settings = SettingsPanel.new()
	settings.setup(sim.params, ui_theme)
	settings.visible = false
	settings.changed.connect(_on_params_changed)
	settings.close_requested.connect(_set_settings_open.bind(false))
	layer.add_child(settings)


func _set_settings_open(open: bool) -> void:
	if open == settings_open:
		return
	settings_open = open
	_refresh()
	if not open:
		# 入力途中の数値を確定させる
		get_viewport().gui_release_focus()
	if settings_tween != null:
		settings_tween.kill()
	settings_tween = create_tween()
	settings_tween.tween_method(_set_settings_slide, settings_slide, 1.0 if open else 0.0, SETTINGS_SLIDE_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_center_layers()


func _set_settings_slide(t: float) -> void:
	settings_slide = t
	_center_layers()


func _on_params_changed() -> void:
	sim.clamp_stock()
	_refresh()


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
	sim.advance(hours * 3600.0)
	_refresh()


func _on_genki_toggled() -> void:
	var decay := sim.genki_mode == Sim.GenkiMode.ALWAYS_HIGH
	sim.set_genki_mode(Sim.GenkiMode.DECAY if decay else Sim.GenkiMode.ALWAYS_HIGH)
	_refresh()


func _on_reset() -> void:
	if cutin_active:
		return
	sim.reset()
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
	# 設定パネルの入力欄を編集中なら確定させる
	get_viewport().gui_release_focus()
	# 押したままフィールド上をなぞると、通った山を回収する
	swiping = true
	swipe_last = p
	swiped.clear()
	var had_popup := box_popup.visible
	_hide_box_popup()
	if Rect2(hud.position, hud.size).has_point(p):
		swiping = false
		_set_log_open(not log_open)
		return
	for id in piles:
		if piles[id].hit(p):
			swiped[id] = true
			_collect(id)
			return
	if pseudon.hit(p):
		# アイコンが出ていなければ設定パネルを開け閉めする
		if sim.has_icon():
			_on_pseudon_tap()
		else:
			_set_settings_open(not settings_open)
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
		_start_cutin(stock, result["ceiling"])
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

func _start_cutin(stock: int, by_ceiling: int) -> void:
	cutin_active = true
	cutin_closable = false
	_hide_box_popup()
	blocker.visible = true
	create_tween().tween_property(dim, "modulate:a", 1.0, 0.15)
	pseudon.show_exclaims(stock)
	await get_tree().create_timer(CUTIN_PAUSE_SEC).timeout
	if not cutin_active:
		return
	var lines := PackedStringArray(["%sのメインスキル！" % sim.params.pseudon_name])
	if by_ceiling > 0:
		lines.append("スキル天井をたたいた！")
	lines.append("肌のツヤが%dポイントアップ！" % stock)
	bubble_label.text = "\n".join(lines)
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
	var genki := "81以上" if sim.genki_mode == Sim.GenkiMode.ALWAYS_HIGH else str(sim.genki_at(sim.elapsed_sec))
	# おてつだいの累計（リセットで 0 に戻る）
	var t := sim.totals
	var ceiling_hits := "（天井%d）" % t["skill_ceiling_hits"]
	if t["skill_ceiling_hits"] > 0:
		ceiling_hits = "[color=%s]%s[/color]" % [CEILING_COLOR.to_html(false), ceiling_hits]
	# 「○回」の縦位置をそろえるため、項目名・回数・天井の3列の表にする
	var rows := [
		["おてつだい回数", t["helps"], ""],
		["きのみ回数", t["berry_helps"], ""],
		["食材回数", t["ingredient_helps"], ""],
		["スキル回数", t["skills"], ceiling_hits],
		["いつのまに育成回数", t["full_helps"], ""],
	]
	var table := "[table=3]"
	for row in rows:
		table += "[cell padding=0,0,16,0]%s[/cell][cell][right]%d回[/right][/cell][cell]%s[/cell]" % row
	table += "[/table]"
	hud_label.text = "%s（Lv.%d）\n経過 %s ・ げんき %s\n%s\n[font_size=15][color=#a08c74]タップで1回ごとの記録[/color][/font_size]" % [
		sim.params.pseudon_name, sim.params.level, _format_hours(sim.elapsed_sec), genki, table]

	pseudon.show_icon = sim.has_icon()
	pseudon.show_menu = not pseudon.show_icon and not settings_open
	pseudon.icon_full = sim.is_full()

	var lines: Array[String] = []
	if sim.elapsed_sec == 0.0:
		lines.append("「すすめる」でおてつだいを進めます。")
		lines.append("パチモンのアイコンをタップすると結果が出ます。")
	var stock_note := ""
	if sim.ceiling_stock > 0:
		stock_note = " [bgcolor=%s][color=#ffffff] 天井%s [/color][/bgcolor]" % [
			CEILING_COLOR.to_html(false), "" if sim.ceiling_stock == sim.skill_stock else "×%d" % sim.ceiling_stock]
	lines.append("所持 %d/%d　スキルストック %d/%d%s　スキル天井まで あと%d回" % [
		sim.held_count(), sim.params.carry_limit(), sim.skill_stock, sim.params.max_skill_stock, stock_note,
		maxi(1, sim.params.skill_ceiling + 1 - sim.skill_miss)])
	status_label.text = "\n".join(lines)
	if log_open:
		_update_log()
