extends SceneTree
## ロジックのテスト。 godot --headless -s res://tests/test_sim.gd で実行する。
## 基礎資料「おてつだい計算モデル」の計算例その1・その2と突き合わせる。
## 計算例はレベル補正なし・最大所持数25・食材2枠なので、そのパラメータを組んで使う。
## 計算例は毎回タップする前提なので、スキルのストックも毎回空にしながら進める。

const Sim = preload("res://scripts/sim.gd")
const Params = preload("res://scripts/params.gd")

var failures := 0


func _init() -> void:
	_test_level_factor()
	_test_default_params()
	_test_modifiers()
	_test_slots_by_level()
	_test_subskill_slots()
	_test_skill_ceiling()
	_test_skill_ceiling_stock2()
	_test_name_width()
	_test_example1_help_count()
	_test_example2_help_count()
	_test_carry_over()
	_test_example1_distribution()
	_test_example2_distribution()
	_test_capacity()
	_test_skill_stock()
	_test_collect_limits()
	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		printerr("%d TEST(S) FAILED" % failures)
	quit(1 if failures > 0 else 0)


func check(cond: bool, label: String) -> void:
	if cond:
		print("  ok   ", label)
	else:
		failures += 1
		printerr("  FAIL ", label)


## 計算例のパラメータ（基準2600秒・レベル補正なし・最大所持数25・食材2個/3個の2枠）
func _example_params() -> Params:
	var p := Params.new()
	p.base_help_sec = 2600.0
	p.level = 1
	p.ingredient_prob = 0.25
	p.skill_prob = 0.05
	p.skill_ceiling = 78
	p.max_carry = 25
	p.berries_per_help = 2
	p.max_skill_stock = 1
	p.unlock_slots_by_level = false
	p.ingredients = [
		{"id": "ing_a", "name": "食材A", "amount": 2},
		{"id": "ing_b", "name": "食材B", "amount": 3},
	]
	return p


func _tapping_sim() -> Sim:
	# 「毎回タップ」は所持数があふれない状態なので、最大所持数を十分大きくして表す
	var p := _example_params()
	p.max_carry = 1000000
	return Sim.new(p)


func _test_level_factor() -> void:
	print("レベル補正")
	check(Params.level_factor(1) == 1.0, "Lv.1は1")
	check(_near(Params.level_factor(60), 0.882, 1e-9), "Lv.60は0.882 (got %f)" % Params.level_factor(60))
	var p := Params.new()
	p.base_help_sec = 2400.0
	p.level = 60
	check(p.help_sec() == 2116.0, "2400秒×0.882=2116.8は2116秒 (got %f)" % p.help_sec())


func _test_default_params() -> void:
	print("初期パラメータ（基準2200秒・Lv.60・最大所持数22・スキルストック2・天井65・食材1/2/4個）")
	var p := Params.new()
	check(p.help_sec() == 1940.0, "2200秒×0.882=1940.4は1940秒 (got %f)" % p.help_sec())
	check(p.carry_limit() == 22, "最大所持数22")
	check(p.max_skill_stock == 2, "スキルストック上限2")
	check(p.skill_ceiling == 65, "スキル発生天井65")
	check(_near(p.ingredient_chance(), 0.151, 1e-9) and _near(p.skill_chance(), 0.039, 1e-9), "食材確率15.1%・スキル確率3.9%")
	check(p.berry_amount() == 1, "きのみ1個")
	var amounts := []
	for ing in p.ingredients:
		amounts.append(ing["amount"])
	check(amounts == [1, 2, 4], "食材枠の数 1/2/4 (got %s)" % str(amounts))
	p.max_carry = 1000000
	var s := Sim.new(p)
	var r := s.advance(16 * 3600.0)
	# 57600 ÷ (1940×0.45) = 65.9…
	check(r["helps"] == 65, "げんき81以上16時間でおてつだい65回 (got %d)" % r["helps"])
	# 食材枠は3枠から等確率
	var counts := {"ing_a": 0, "ing_b": 0, "ing_c": 0}
	s.rng.seed = 42
	for i in 3000:
		s.reset()
		var items: Dictionary = s.advance(16 * 3600.0)["items"]
		counts["ing_a"] += int(items.get("ing_a", 0)) / 1
		counts["ing_b"] += int(items.get("ing_b", 0)) / 2
		counts["ing_c"] += int(items.get("ing_c", 0)) / 4
	var total := float(counts["ing_a"] + counts["ing_b"] + counts["ing_c"])
	for id in counts:
		check(_near(counts[id] / total, 1.0 / 3.0, 0.02), "%sが選ばれる割合 約1/3 (got %.3f)" % [id, counts[id] / total])


func _test_modifiers() -> void:
	print("サブスキル・せいかく・おやすみリボンの補正")
	var p := Params.new()
	p.base_help_sec = 2400.0
	p.subskills = {"speed_m": true}
	# 基礎資料の計算例: 2400×0.882×0.86 = 1820.448
	check(p.help_sec() == 1820.0, "おてつだいスピードMで1820秒 (got %f)" % p.help_sec())
	p.subskills = {"speed_m": true, "speed_s": true, "help_bonus": true}
	p.other_help_bonus = 4
	# 0.14+0.07+0.05×5 = 0.46 → 上限0.35
	check(_near(p.speed_reduction(), 0.35, 1e-9), "短縮は35%%で頭打ち (got %f)" % p.speed_reduction())
	p.subskills = {"help_bonus": true}
	p.other_help_bonus = 2
	check(_near(p.speed_reduction(), 0.15, 1e-9), "おてつだいボーナス自分1＋他2で15%%")
	p.subskills = {}
	p.other_help_bonus = 0
	p.nature_up = Params.Nature.SPEED
	check(p.help_sec() == floorf(2400.0 * 0.882 * 0.9), "せいかくでおてつだいスピード上昇は時間0.9倍")
	p.nature_up = Params.Nature.NONE
	p.nature_down = Params.Nature.SPEED
	check(p.help_sec() == floorf(2400.0 * 0.882 * 1.075), "せいかくでおてつだいスピード下降は時間1.075倍")
	p.nature_down = Params.Nature.NONE
	p.ribbon_sleep_hours = 2000
	check(p.help_sec() == floorf(2400.0 * 0.882), "最終進化形はリボンで時間が変わらない")
	check(p.carry_limit() == 22 + 8, "リボン2000時間で最大所持数+8")
	p.evolutions_left = 1
	check(p.help_sec() == floorf(2400.0 * 0.882 * 0.88), "あと1回進化・2000時間で0.88倍")
	p.evolutions_left = 2
	p.ribbon_sleep_hours = 500
	check(p.help_sec() == floorf(2400.0 * 0.882 * 0.89), "あと2回進化・500時間で0.89倍")
	check(p.carry_limit() == 22 + 3, "リボン500時間で最大所持数+3")
	p.ribbon_sleep_hours = 199
	check(p.help_sec() == floorf(2400.0 * 0.882) and p.carry_limit() == 22, "200時間未満は補正なし")
	p.subskills = {"carry_l": true, "carry_m": true, "carry_s": true, "berry_s": true}
	check(p.carry_limit() == 22 + 18 + 12 + 6, "最大所持数アップL・M・S")
	check(p.berry_amount() == 2, "きのみの数Sで+1個")
	p.ingredient_prob = 0.2
	p.skill_prob = 0.05
	p.subskills = {"ing_m": true, "ing_s": true, "skill_s": true}
	p.nature_up = Params.Nature.INGREDIENT
	p.nature_down = Params.Nature.SKILL
	check(_near(p.ingredient_chance(), 0.2 * 1.2 * 1.54, 1e-9), "食材確率 = 基準×せいかく1.2×(1+0.36+0.18) (got %f)" % p.ingredient_chance())
	check(_near(p.skill_chance(), 0.05 * 0.8 * 1.18, 1e-9), "スキル確率 = 基準×せいかく0.8×(1+0.18) (got %f)" % p.skill_chance())


func _test_slots_by_level() -> void:
	print("レベルによる食材枠の解放")
	var p := Params.new()
	p.level = 29
	check(p.active_ingredients().size() == 1, "Lv.29は1枠")
	p.level = 30
	check(p.active_ingredients().size() == 2, "Lv.30で2枠")
	p.level = 60
	check(p.active_ingredients().size() == 3, "Lv.60で3枠")
	p.level = 10
	p.ingredient_prob = 1.0
	p.max_carry = 1000000
	var s := Sim.new(p)
	var items: Dictionary = s.advance(16 * 3600.0)["items"]
	check(not items.has("ing_b") and not items.has("ing_c"), "未解放の枠の食材は出ない")


func _test_subskill_slots() -> void:
	print("サブスキルを選べる数")
	var p := Params.new()
	var expect := {1: 0, 9: 0, 10: 1, 24: 1, 25: 2, 49: 2, 50: 3, 69: 3, 70: 4, 79: 4, 80: 5, 100: 5}
	for lv in expect:
		p.level = lv
		check(p.subskill_slots() == expect[lv], "Lv.%dは%d個 (got %d)" % [lv, expect[lv], p.subskill_slots()])
	p.level = 80
	p.subskills = {"berry_s": true, "speed_m": true, "ing_s": true, "carry_l": true, "carry_s": true}
	p.level = 50
	p.trim_subskills()
	check(p.subskills.keys() == ["berry_s", "speed_m", "ing_s"], "Lv.50に下げると下の項目から外れる (got %s)" % str(p.subskills.keys()))
	p.level = 80
	p.trim_subskills()
	check(p.subskills.size() == 3, "レベルを上げても自動では付かない")


func _test_skill_ceiling() -> void:
	print("スキル発生の天井")
	var p := Params.new()
	p.max_carry = 1000000
	p.skill_prob = 0.0
	p.skill_ceiling = 5
	p.max_skill_stock = 1
	var s := Sim.new(p)
	var r := s.advance(p.help_sec() * 0.45 * 5 + 1)
	check(r["helps"] == 5 and r["skills"] == 0 and s.skill_miss == 5, "5回続けて不発 (helps %d, skills %d)" % [r["helps"], r["skills"]])
	r = s.advance(p.help_sec() * 0.45)
	check(r["skills"] == 1 and r["skill_ceiling_hits"] == 1, "天井5なら6回目で必ず発動")
	check(s.ceiling_stock == 1, "天井で出たストックを覚えている")
	r = s.advance(p.help_sec() * 0.45 * 20)
	check(r["skills"] == 0 and s.skill_miss == 0, "ストックが上限のあいだは抽選せず、不発カウントも0のまま")
	var d := s.drop()
	check(d["ceiling"] == 1 and s.ceiling_stock == 0, "タップで天井分を知らせて消費")
	r = s.advance(p.help_sec() * 0.45 * 5)
	check(r["skills"] == 0, "タップ後も5回目までは発動しない (got %d)" % r["skills"])
	r = s.advance(p.help_sec() * 0.45)
	check(r["skills"] == 1, "タップ後はまた6回目で発動 (got %d)" % r["skills"])


## ストック2: 1回目は天井で発動、そのあと不発カウントは0から数え直し、2回目は天井に届く前に通常の抽選で発動する
func _test_skill_ceiling_stock2() -> void:
	print("スキル天井 ストック2（1回目が天井、2回目は天井前）")
	var p := Params.new()
	p.max_carry = 1000000
	p.skill_prob = 0.0
	p.skill_ceiling = 5
	p.max_skill_stock = 2
	var s := Sim.new(p)
	var t := p.help_sec() * 0.45
	var r := s.advance(t * 5 + 1)
	check(r["skills"] == 0 and s.skill_miss == 5, "5回続けて不発 (miss %d)" % s.skill_miss)
	r = s.advance(t)
	check(r["skills"] == 1 and r["skill_ceiling_hits"] == 1, "6回目に天井で1回目が発動")
	check(s.skill_stock == 1 and s.ceiling_stock == 1, "ストック1、うち天井1")
	check(s.skill_miss == 0, "天井で発動したら不発カウントは0に戻る (miss %d)" % s.skill_miss)
	r = s.advance(t * 3)
	check(r["skills"] == 0 and s.skill_miss == 3, "ストックに空きがあるので抽選が続き、0から数え直して3回不発 (miss %d)" % s.skill_miss)
	p.skill_prob = 1.0
	r = s.advance(t)
	check(r["skills"] == 1 and r["skill_ceiling_hits"] == 0, "2回目は天井に届く前（不発3回の次）に通常の抽選で発動")
	check(s.skill_stock == 2 and s.ceiling_stock == 1, "ストック2、うち天井は1回目の1つだけ (stock %d, ceiling %d)" % [s.skill_stock, s.ceiling_stock])
	check(s.skill_miss == 0, "通常の発動でも不発カウントは0に戻る")
	r = s.advance(t * 10)
	check(r["skills"] == 0 and s.skill_miss == 0, "ストックが上限になったら抽選せず、不発カウントも増えない")
	var d := s.drop()
	check(d["stock"] == 2 and d["ceiling"] == 1, "タップでストック2、うち天井1を知らせる (stock %d, ceiling %d)" % [d["stock"], d["ceiling"]])


func _test_name_width() -> void:
	print("名前の長さ（全角6文字・半角12文字まで）")
	check(Params.name_width("ベアビヲ9") == 9, "全角4＋半角1で9 (got %d)" % Params.name_width("ベアビヲ9"))
	check(Params.clip_name("あいうえおか") == "あいうえおか", "全角6文字はそのまま")
	check(Params.clip_name("あいうえおかき") == "あいうえおか", "全角7文字目は削る")
	check(Params.clip_name("abcdefghijkl") == "abcdefghijkl", "半角12文字はそのまま")
	check(Params.clip_name("abcdefghijklm") == "abcdefghijkl", "半角13文字目は削る")
	check(Params.clip_name("ベアビヲ9abcd") == "ベアビヲ9abc", "混在は合計12まで (got %s)" % Params.clip_name("ベアビヲ9abcd"))
	check(Params.clip_name("ｱｲｳｴｵｶｷｸｹｺｻｼｽ") == "ｱｲｳｴｵｶｷｸｹｺｻｼ", "半角カナは半角として数える")


func _test_example1_help_count() -> void:
	print("その1: げんき常に81以上 16時間")
	var s := _tapping_sim()
	var r := s.advance(16 * 3600.0)
	check(r["helps"] == 49, "おてつだい49回 (got %d)" % r["helps"])


func _test_example2_help_count() -> void:
	print("その2: げんき100から減少 16時間")
	var s := _tapping_sim()
	s.set_genki_mode(Sim.GenkiMode.DECAY)
	s.reset()
	var r := s.advance(16 * 3600.0)
	check(r["helps"] == 39, "おてつだい39回 (got %d)" % r["helps"])
	check(s.genki_at(16 * 3600.0) == 4, "16時間後のげんき4 (got %d)" % s.genki_at(16 * 3600.0))


func _test_carry_over() -> void:
	print("途中まで進んだおてつだいの持ち越し")
	var s := _tapping_sim()
	var n := 0
	for i in 16:
		n += int(s.advance(3600.0)["helps"])
	check(n == 49, "1時間×16回でも49回 (got %d)" % n)


## おてつだい1回ごとにタップする（おてつだい間隔より短い刻みで進め、そのたびにストックを空にする）
func _advance_tapping(s: Sim, seconds: float) -> Dictionary:
	var step := 1100.0
	var t := 0.0
	while t < seconds:
		var d := minf(step, seconds - t)
		s.advance(d)
		s.drop()
		t += d
	return s.totals


func _run_many(decay: bool, trials: int) -> Dictionary:
	var acc := {"ing": 0.0, "skill": 0.0, "berry_items": 0.0, "ing_items": 0.0, "skill0": 0}
	for i in trials:
		var s := _tapping_sim()
		s.rng.seed = 1000 + i
		if decay:
			s.set_genki_mode(Sim.GenkiMode.DECAY)
		var r := _advance_tapping(s, 16 * 3600.0)
		acc["ing"] += r["ingredient_helps"]
		acc["skill"] += r["skills"]
		var items: Dictionary = r["items"]
		acc["berry_items"] += int(items.get("berry", 0))
		acc["ing_items"] += int(items.get("ing_a", 0)) + int(items.get("ing_b", 0))
		if r["skills"] == 0:
			acc["skill0"] += 1
	for k in ["ing", "skill", "berry_items", "ing_items"]:
		acc[k] /= trials
	acc["skill0"] = float(acc["skill0"]) / trials
	return acc


func _near(x: float, expected: float, tol: float) -> bool:
	return absf(x - expected) <= tol


func _test_example1_distribution() -> void:
	print("その1: 20000回試行の平均")
	var a := _run_many(false, 20000)
	check(_near(a["ing"], 12.25, 0.1), "食材の回数 平均12.25 (got %.3f)" % a["ing"])
	check(_near(a["skill"], 2.45, 0.05), "スキルの回数 平均2.45 (got %.3f)" % a["skill"])
	check(_near(a["berry_items"], 73.5, 0.3), "きのみ 平均73.5個 (got %.3f)" % a["berry_items"])
	check(_near(a["ing_items"], 30.6, 0.3), "食材 平均約30.6個 (got %.3f)" % a["ing_items"])
	check(_near(a["skill0"], 0.081, 0.01), "スキル0回 約8%% (got %.3f)" % a["skill0"])


func _test_example2_distribution() -> void:
	print("その2: 20000回試行の平均")
	var a := _run_many(true, 20000)
	check(_near(a["ing"], 9.75, 0.1), "食材の回数 平均9.75 (got %.3f)" % a["ing"])
	check(_near(a["skill"], 1.95, 0.05), "スキルの回数 平均1.95 (got %.3f)" % a["skill"])
	check(_near(a["ing_items"], 24.4, 0.3), "食材 平均約24.4個 (got %.3f)" % a["ing_items"])
	check(_near(a["skill0"], 0.135, 0.01), "スキル0回 約13.5%% (got %.3f)" % a["skill0"])


func _test_capacity() -> void:
	print("最大所持数25・タップなし")
	var s := Sim.new(_example_params())
	s.rng.seed = 7
	var r := s.advance(16 * 3600.0)
	check(s.held_count() == 25, "所持数は25で止まる (got %d)" % s.held_count())
	check(r["full_helps"] > 0, "いつのまに育成が発生 (got %d)" % r["full_helps"])
	check(r["auto_fed"] == r["full_helps"] * 2, "いつのまに育成のきのみ数")
	# タップしてもフィールドに残したままなら所持数は減らない
	s.drop()
	check(s.held_count() == 25, "フィールドに残した分も所持数に入る")
	var r2 := s.advance(3600.0 * 4)
	check(r2["helps"] == r2["full_helps"], "残置中はすべていつのまに育成")
	for id in s.on_field.keys():
		s.collect(id)
	check(s.held_count() == 0, "回収すると所持数0")


func _test_skill_stock() -> void:
	print("スキルのストック上限")
	var p := Params.new()
	p.max_carry = 1000000
	p.max_skill_stock = 1
	p.skill_prob = 1.0
	var s := Sim.new(p)
	s.advance(3600.0 * 5)
	check(s.skill_stock == 1, "通常は1回まで (got %d)" % s.skill_stock)
	p.max_skill_stock = 2
	s.reset()
	s.advance(3600.0 * 5)
	check(s.skill_stock == 2, "スキルとくいは2回まで (got %d)" % s.skill_stock)
	var d := s.drop()
	check(d["stock"] == 2 and s.skill_stock == 0, "タップでストックを消費")


func _test_collect_limits() -> void:
	print("収容箱の上限")
	var s := Sim.new()
	s.on_field = {"berry": 10, "ing_a": 6}
	s.berry_box = {"berry": Sim.BERRY_BOX_MAX - 4}
	s.ingredient_box = {"ing_b": Sim.INGREDIENT_BOX_MAX}
	var got := s.collect("berry")
	check(got == 4, "きのみは空き4個だけ入る (got %d)" % got)
	check(int(s.on_field.get("berry", 0)) == 6, "入りきらない6個はフィールドに残る")
	check(s.collect("ing_a") == 0, "食材箱が800で満杯なら入らない")
	check(int(s.on_field.get("ing_a", 0)) == 6, "食材はフィールドに残る")
