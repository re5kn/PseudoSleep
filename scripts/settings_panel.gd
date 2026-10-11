extends PanelContainer
## パチモンの計算条件を設定するパネル。画面左からせり出す。
## 値を変えるとすぐ Params に書き込み、changed を出す（次の「すすめる」から反映される）。

const Params = preload("res://scripts/params.gd")

signal changed
signal close_requested

const TEXT_DARK := Color("5a4632")
const TEXT_SUB := Color("8a7660")
const CREAM := Color("fff7e6")
const ACCENT := Color("f0a43a")
const LINE := Color("e6cf9f")

## 数値の行: [ラベル, Params の項目, 単位, 最小, 最大, 刻み, 画面の値＝Params の値×scale]
const NUMBER_ROWS := [
	["LV", "level", "", 1, 100, 1, 1.0],
	["基準おてつだい時間", "base_help_sec", "秒", 1, 99999, 1, 1.0],
	["食材確率", "ingredient_prob", "%", 0, 100, 0.1, 100.0],
	["スキル発生確率", "skill_prob", "%", 0, 100, 0.1, 100.0],
	["スキル発生天井", "skill_ceiling", "回", 1, 9999, 1, 1.0],
	["スキルストック数", "max_skill_stock", "回", 1, 10, 1, 1.0],
	["最大所持数", "max_carry", "個", 1, 999, 1, 1.0],
	["きのみの数", "berries_per_help", "個", 1, 99, 1, 1.0],
	["食材枠1の数", "slot0", "個", 1, 99, 1, 1.0],
	["食材枠2の数（Lv.30〜）", "slot1", "個", 1, 99, 1, 1.0],
	["食材枠3の数（Lv.60〜）", "slot2", "個", 1, 99, 1, 1.0],
	["進化できる回数", "evolutions_left", "回", 0, 2, 1, 1.0],
	["睡眠時間（おやすみリボン）", "ribbon_sleep_hours", "時間", 0, 99999, 1, 1.0],
]

const NATURE_OPTIONS := [
	[Params.Nature.SPEED, "おてつだいスピード"],
	[Params.Nature.INGREDIENT, "食材確率"],
	[Params.Nature.SKILL, "スキル確率"],
	[Params.Nature.GENKI, "げんき回復"],
]

var params: Params
var summary_label: Label
var subskill_title: Label
## サブスキル id → CheckBox
var subskill_boxes := {}
## Params.Nature → CheckBox
var up_buttons := {}
var down_buttons := {}
var up_group := ButtonGroup.new()
var down_group := ButtonGroup.new()


func setup(p: Params, base_theme: Theme) -> void:
	params = p
	theme = _make_theme(base_theme)
	add_theme_stylebox_override("panel", _panel_style())
	_build()
	_update_nature_lock()
	_update_subskill_boxes()
	_update_summary()


# ---------------------------------------------------------------- 組み立て

func _build() -> void:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)

	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := _label("パチモンの設定", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "×"
	close.custom_minimum_size = Vector2(56, 56)
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 28)
	close.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close)

	summary_label = _label("", 16)
	summary_label.add_theme_color_override("font_color", TEXT_SUB)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(summary_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	scroll.add_child(v)

	var name_row := _row(v, "名前")
	var name_edit := LineEdit.new()
	name_edit.text = params.pseudon_name
	name_edit.max_length = 20
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_changed.connect(func(t: String) -> void:
		params.pseudon_name = t
		changed.emit())
	name_row.add_child(name_edit)

	_section(v, "パラメータ")
	for spec in NUMBER_ROWS:
		_number_row(v, spec)

	subskill_title = _section(v, "サブスキル")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	v.add_child(grid)
	for id in Params.SUBSKILLS:
		var cb := CheckBox.new()
		cb.text = Params.SUBSKILLS[id]
		cb.button_pressed = params.has_subskill(id)
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.focus_mode = Control.FOCUS_NONE
		cb.add_theme_font_size_override("font_size", 17)
		cb.toggled.connect(func(on: bool) -> void:
			if on:
				params.subskills[id] = true
			else:
				params.subskills.erase(id)
			_update_subskill_boxes()
			_on_changed())
		subskill_boxes[id] = cb
		grid.add_child(cb)

	_section(v, "せいかく")
	up_group.allow_unpress = true
	down_group.allow_unpress = true
	_nature_row(v, "上昇", up_group, up_buttons, true)
	_nature_row(v, "下降", down_group, down_buttons, false)

	_section(v, "その他")
	_number_row(v, ["他のメンバーのおてつだいボーナス数", "other_help_bonus", "", 0, 4, 1, 1.0])

	var note := _label("変更は次の「すすめる」から反映されます。", 15)
	note.add_theme_color_override("font_color", TEXT_SUB)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)


func _section(parent: Control, text: String) -> Label:
	var l := _label(text, 20)
	l.add_theme_color_override("font_color", Color("c27a12"))
	var box := MarginContainer.new()
	box.add_theme_constant_override("margin_top", 10)
	box.add_child(l)
	parent.add_child(box)
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", _line_style())
	parent.add_child(sep)
	return l


func _row(parent: Control, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var l := _label(text, 18)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(l)
	return row


func _number_row(parent: Control, spec: Array) -> void:
	var key: String = spec[1]
	var scale: float = spec[6]
	var row := _row(parent, spec[0])
	var spin := SpinBox.new()
	spin.min_value = spec[3]
	spin.max_value = spec[4]
	spin.step = spec[5]
	spin.custom_minimum_size = Vector2(138, 0)
	spin.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	spin.select_all_on_focus = true
	spin.value = _get_value(key) * scale
	spin.value_changed.connect(func(x: float) -> void:
		_set_value(key, x / scale)
		if key == "level":
			# レベルを下げて選べる数が減ったら、下の項目から外す（増えても自動では付けない）
			params.trim_subskills()
			_update_subskill_boxes()
		_on_changed())
	row.add_child(spin)
	var unit := _label(spec[2], 18)
	unit.custom_minimum_size = Vector2(40, 0)
	row.add_child(unit)


func _nature_row(parent: Control, text: String, group: ButtonGroup, buttons: Dictionary, is_up: bool) -> void:
	parent.add_child(_label(text, 18))
	var grid := GridContainer.new()
	grid.columns = 2
	parent.add_child(grid)
	var current: int = params.nature_up if is_up else params.nature_down
	for opt in NATURE_OPTIONS:
		var kind: int = opt[0]
		var cb := CheckBox.new()
		cb.text = opt[1]
		cb.button_group = group
		cb.button_pressed = current == kind
		cb.focus_mode = Control.FOCUS_NONE
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.add_theme_font_size_override("font_size", 17)
		cb.toggled.connect(func(_on: bool) -> void:
			var pressed := group.get_pressed_button()
			var value: int = Params.Nature.NONE
			for k in buttons:
				if buttons[k] == pressed:
					value = k
			if is_up:
				params.nature_up = value
			else:
				params.nature_down = value
			_update_nature_lock()
			_on_changed())
		buttons[kind] = cb
		grid.add_child(cb)


## チェックの状態をそろえ、選べる数に達していたら残りを選べなくする
func _update_subskill_boxes() -> void:
	var slots := params.subskill_slots()
	var full := params.subskills.size() >= slots
	for id in subskill_boxes:
		var cb: CheckBox = subskill_boxes[id]
		cb.set_pressed_no_signal(params.has_subskill(id))
		cb.disabled = full and not cb.button_pressed
	subskill_title.text = "サブスキル（%d/%d）" % [params.subskills.size(), slots]


## 上昇で選んだ能力は下降で選べない（逆も同じ）
func _update_nature_lock() -> void:
	for k in up_buttons:
		up_buttons[k].disabled = params.nature_down == k
	for k in down_buttons:
		down_buttons[k].disabled = params.nature_up == k


func _get_value(key: String) -> float:
	if key.begins_with("slot"):
		return params.ingredients[int(key.substr(4))]["amount"]
	return float(params.get(key))


func _set_value(key: String, x: float) -> void:
	if key.begins_with("slot"):
		params.ingredients[int(key.substr(4))]["amount"] = int(round(x))
	elif typeof(params.get(key)) == TYPE_INT:
		params.set(key, int(round(x)))
	else:
		params.set(key, x)


func _on_changed() -> void:
	_update_summary()
	changed.emit()


func _update_summary() -> void:
	var p := params
	var slots := p.active_ingredients().size()
	summary_label.text = "計算に使う値：おてつだい時間 %d秒（げんき81以上で %d秒）・食材 %.1f%%・スキル %.1f%%・最大所持数 %d・きのみ %d個・食材枠 %d枠" % [
		int(p.help_sec()), int(floor(p.help_sec() * 0.45)), p.ingredient_chance() * 100.0,
		p.skill_chance() * 100.0, p.carry_limit(), p.berry_amount(), slots]


# ---------------------------------------------------------------- 見た目

func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", TEXT_DARK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _box(color: Color, radius: int, pad: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad * 0.6
	sb.content_margin_bottom = pad * 0.6
	return sb


func _panel_style() -> StyleBoxFlat:
	var sb := _box(CREAM, 0, 18)
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	sb.corner_radius_top_right = 28
	sb.corner_radius_bottom_right = 28
	sb.border_width_right = 4
	sb.border_color = LINE
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 12
	return sb


func _line_style() -> StyleBoxLine:
	var sb := StyleBoxLine.new()
	sb.color = LINE
	sb.thickness = 2
	return sb


func _make_theme(base: Theme) -> Theme:
	var t := Theme.new()
	t.default_font = base.default_font
	t.default_font_size = 20

	var field := _box(Color.WHITE, 12, 10)
	field.set_border_width_all(2)
	field.border_color = LINE
	var field_focus := field.duplicate()
	field_focus.border_color = ACCENT
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", field_focus)
	t.set_stylebox("read_only", "LineEdit", field)
	t.set_color("font_color", "LineEdit", TEXT_DARK)
	t.set_color("caret_color", "LineEdit", TEXT_DARK)
	t.set_color("selection_color", "LineEdit", Color(ACCENT, 0.35))
	t.set_font_size("font_size", "LineEdit", 20)

	var btn := _box(Color("ffe9bf"), 14, 8)
	t.set_stylebox("normal", "Button", btn)
	t.set_stylebox("hover", "Button", _box(Color("ffe9bf").lightened(0.08), 14, 8))
	t.set_stylebox("pressed", "Button", _box(Color("ffe9bf").darkened(0.12), 14, 8))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(key, "Button", TEXT_DARK)

	var flat := StyleBoxEmpty.new()
	flat.content_margin_top = 6
	flat.content_margin_bottom = 6
	for s in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		t.set_stylebox(s, "CheckBox", flat)
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(key, "CheckBox", TEXT_DARK)
	t.set_color("font_disabled_color", "CheckBox", Color(TEXT_DARK, 0.35))
	t.set_constant("h_separation", "CheckBox", 6)
	var off := Color.WHITE
	var dim := Color(0.93, 0.91, 0.87)
	t.set_icon("unchecked", "CheckBox", _check_icon(false, false, off, LINE.darkened(0.2)))
	t.set_icon("checked", "CheckBox", _check_icon(true, false, ACCENT, ACCENT.darkened(0.15)))
	t.set_icon("unchecked_disabled", "CheckBox", _check_icon(false, false, dim, LINE))
	t.set_icon("checked_disabled", "CheckBox", _check_icon(true, false, LINE, LINE))
	t.set_icon("radio_unchecked", "CheckBox", _check_icon(false, true, off, LINE.darkened(0.2)))
	t.set_icon("radio_checked", "CheckBox", _check_icon(true, true, off, ACCENT))
	t.set_icon("radio_unchecked_disabled", "CheckBox", _check_icon(false, true, dim, LINE))
	t.set_icon("radio_checked_disabled", "CheckBox", _check_icon(true, true, dim, LINE))

	# SpinBox の上下ボタンを指でも押しやすい大きさ・見える色にする
	t.set_constant("buttons_width", "SpinBox", 30)
	for key in ["up_icon_modulate", "up_hover_icon_modulate", "up_pressed_icon_modulate",
			"down_icon_modulate", "down_hover_icon_modulate", "down_pressed_icon_modulate"]:
		t.set_color(key, "SpinBox", TEXT_SUB)
	t.set_color("up_disabled_icon_modulate", "SpinBox", LINE)
	t.set_color("down_disabled_icon_modulate", "SpinBox", LINE)

	var vbar := StyleBoxFlat.new()
	vbar.bg_color = Color(LINE, 0.4)
	vbar.set_corner_radius_all(4)
	vbar.content_margin_left = 6
	vbar.content_margin_right = 6
	var grab := _box(LINE.darkened(0.1), 4, 0)
	t.set_stylebox("scroll", "VScrollBar", vbar)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	return t


## チェックボックス／ラジオボタンの絵を描く（四角に✓、または丸に点）
static func _check_icon(on: bool, radio: bool, fill: Color, border: Color) -> ImageTexture:
	var n := 30
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n, n) / 2.0
	for y in n:
		for x in n:
			var p := Vector2(x + 0.5, y + 0.5)
			var col := Color(0, 0, 0, 0)
			if radio:
				var d := p.distance_to(c)
				if d <= 13.5:
					col = border if d > 11.0 else fill
				if on and d <= 6.5:
					col = border
			else:
				var q := (p - c).abs()
				var corner := maxf(q.x - 8.5, 0.0) * maxf(q.x - 8.5, 0.0) + maxf(q.y - 8.5, 0.0) * maxf(q.y - 8.5, 0.0)
				if q.x <= 13.5 and q.y <= 13.5 and corner <= 25.0:
					var inner := q.x <= 11.0 and q.y <= 11.0
					col = fill if inner and not on else (fill if on else border)
					if not on and not inner:
						col = border
				if on and (_seg_dist(p, Vector2(8, 15), Vector2(13, 20)) <= 2.0 or _seg_dist(p, Vector2(13, 20), Vector2(22, 10)) <= 2.0):
					col = Color.WHITE
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
