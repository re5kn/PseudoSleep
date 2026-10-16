extends RefCounted
## 回数の確率分布（確率質量関数）。p[i] が「offset + i 回」になる確率。
## 「すすめる」ごとの分布をたたみ込んで、リセットからの累計回数の分布にする。

## これより小さい両端の確率は捨てる（長く進めても配列が伸びすぎないように）
const TRIM := 1e-12

var offset := 0
var p := PackedFloat64Array([1.0])


func reset() -> void:
	offset = 0
	p = PackedFloat64Array([1.0])


## 独立な回数（0回からの分布 q）を足したときの分布にする
func add(q: PackedFloat64Array) -> void:
	# 計算を軽くするため、q の両端の小さい確率は先に捨てる
	var lo := 0
	while lo < q.size() - 1 and q[lo] < TRIM:
		lo += 1
	var hi := q.size() - 1
	while hi > lo and q[hi] < TRIM:
		hi -= 1
	q = q.slice(lo, hi + 1)
	offset += lo
	var out := PackedFloat64Array()
	out.resize(p.size() + q.size() - 1)
	for i in p.size():
		var a := p[i]
		if a == 0.0:
			continue
		for j in q.size():
			out[i + j] += a * q[j]
	p = out
	_trim()


func _trim() -> void:
	var lo := 0
	while lo < p.size() - 1 and p[lo] < TRIM:
		lo += 1
	var hi := p.size() - 1
	while hi > lo and p[hi] < TRIM:
		hi -= 1
	if lo > 0 or hi < p.size() - 1:
		p = p.slice(lo, hi + 1)
		offset += lo


func mass(x: int) -> float:
	var i := x - offset
	return p[i] if i >= 0 and i < p.size() else 0.0


func mean() -> float:
	var m := 0.0
	for i in p.size():
		m += (offset + i) * p[i]
	return m


## x 回以下になる確率
func at_most(x: int) -> float:
	var s := 0.0
	for i in p.size():
		if offset + i > x:
			break
		s += p[i]
	return minf(s, 1.0)


## x 回以上になる確率
func at_least(x: int) -> float:
	var s := 0.0
	for i in range(p.size() - 1, -1, -1):
		if offset + i < x:
			break
		s += p[i]
	return minf(s, 1.0)


## 下側・上側の端からそれぞれ確率 tail ぶんを除いた回数の範囲（グラフの表示範囲用）
func span(tail: float) -> Vector2i:
	var s := 0.0
	var first := offset
	for i in p.size():
		s += p[i]
		if s >= tail:
			first = offset + i
			break
	s = 0.0
	var last := offset + p.size() - 1
	for i in range(p.size() - 1, -1, -1):
		s += p[i]
		if s >= tail:
			last = offset + i
			break
	return Vector2i(first, last)


## 二項分布 B(k, q) の確率質量（0〜k 回）。大きな k でもあふれないよう対数で求める
static func binomial(k: int, q: float) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(k + 1)
	if q <= 0.0:
		out[0] = 1.0
		return out
	if q >= 1.0:
		out[k] = 1.0
		return out
	var lr := log(q) - log(1.0 - q)
	var lp := k * log(1.0 - q)
	for i in k + 1:
		out[i] = exp(lp)
		lp += log(float(k - i)) - log(float(i + 1)) + lr if i < k else 0.0
	return out
