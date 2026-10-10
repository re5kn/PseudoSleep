extends SceneTree
## ロジックのテスト。 godot --headless -s res://tests/test_sim.gd で実行する。
## 基礎資料「おてつだい計算モデル」の計算例その1・その2と突き合わせる。
## 計算例はレベル補正なし・最大所持数25・食材2枠なので、そのパラメータを組んで使う。

const Sim = preload("res://scripts/sim.gd")
const Params = preload("res://scripts/params.gd")

var failures := 0


func _init() -> void:
	_test_level_factor()
	_test_default_params()
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
	p.max_carry = 25
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
	print("現在の初期パラメータ（基準2600秒・Lv.60・最大所持数28・食材2/3/5個）")
	var p := Params.new()
	check(p.help_sec() == 2293.0, "2600秒×0.882=2293.2は2293秒 (got %f)" % p.help_sec())
	check(p.max_carry == 28, "最大所持数28")
	var amounts := []
	for ing in p.ingredients:
		amounts.append(ing["amount"])
	check(amounts == [2, 3, 5], "食材枠の数 2/3/5 (got %s)" % str(amounts))
	p.max_carry = 1000000
	var s := Sim.new(p)
	var r := s.advance(16 * 3600.0)
	# 57600 ÷ (2293×0.45) = 55.8…
	check(r["helps"] == 55, "げんき81以上16時間でおてつだい55回 (got %d)" % r["helps"])
	# 食材枠は3枠から等確率
	var counts := {"ing_a": 0, "ing_b": 0, "ing_c": 0}
	s.rng.seed = 42
	for i in 3000:
		s.reset()
		var items: Dictionary = s.advance(16 * 3600.0)["items"]
		counts["ing_a"] += int(items.get("ing_a", 0)) / 2
		counts["ing_b"] += int(items.get("ing_b", 0)) / 3
		counts["ing_c"] += int(items.get("ing_c", 0)) / 5
	var total := float(counts["ing_a"] + counts["ing_b"] + counts["ing_c"])
	for id in counts:
		check(_near(counts[id] / total, 1.0 / 3.0, 0.02), "%sが選ばれる割合 約1/3 (got %.3f)" % [id, counts[id] / total])


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


func _run_many(decay: bool, trials: int) -> Dictionary:
	var acc := {"ing": 0.0, "skill": 0.0, "berry_items": 0.0, "ing_items": 0.0, "skill0": 0}
	for i in trials:
		var s := _tapping_sim()
		s.rng.seed = 1000 + i
		if decay:
			s.set_genki_mode(Sim.GenkiMode.DECAY)
		var r := s.advance(16 * 3600.0)
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
