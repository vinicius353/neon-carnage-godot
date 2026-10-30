extends Node2D
# Desenho de cada arma, em código. Aponta para +x.
# Além do tiro, tem três animações: entrada na mão ao trocar de arma, recarga
# (carregador, tambor, cartucho, ferrolho — cada família tem a sua) e recuo.

var art := 0
var wname := ""
var swing := 0.0
var flash := 0.0
var recoil := 0.0
var reload_p := -1.0
var equip := 0.0

const MUZZLE := {0: 24, 1: 30, 2: 36, 4: 42, 7: 34, 13: 52, 14: 26, 18: 24, 19: 22, 20: 32, 21: 30}
const RSTYLE := {0: "mag", 1: "mag", 2: "shell", 4: "mag", 7: "tank", 13: "bolt", 14: "string", 18: "mag", 19: "cyl", 20: "shell", 21: "mag"}


func set_art(a: int) -> void:
	art = a
	queue_redraw()


func equip_now(nm: String) -> void:
	# Troca de arma: dispara a animação de entrada e guarda o nome.
	wname = nm
	equip = 1.0
	reload_p = -1.0
	queue_redraw()


func _process(delta: float) -> void:
	var ch := false
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
		ch = true
	if recoil > 0.0:
		recoil = maxf(0.0, recoil - delta * 10.0)
		ch = true
	if swing > 0.0:
		swing = maxf(0.0, swing - delta * 5.0)
		ch = true
	if equip > 0.0:
		equip = maxf(0.0, equip - delta * 3.4)
		ch = true
	if reload_p >= 0.0:
		ch = true
	if ch or art == 10:
		# art 10 (motosserra) tem animação própria: precisa de redraw contínuo
		queue_redraw()


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


func _reload_fx(pos: Vector2, rot: float) -> void:
	# A mão trabalha na arma: cada família recarrega de um jeito diferente.
	var p: float = clampf(reload_p, 0.0, 1.0)
	var ins: float = sin(p * PI)
	draw_set_transform(pos, rot, Vector2.ONE)
	match str(RSTYLE.get(art, "mag")):
		"mag":
			var y: float = 7.0 * ins
			_r(8, 2 + y, 7, 9, Color(0.16, 0.16, 0.18))
			_r(8, 2 + y, 7, 2, Color(0.55, 0.56, 0.60))
			if p > 0.55:
				var b: float = clampf((p - 0.55) / 0.25, 0.0, 1.0)
				_r(11 - 5.0 * b, -4, 6, 2, Color(0.62, 0.64, 0.68))
		"cyl":
			var sw: float = 7.0 * ins
			draw_circle(Vector2(10 - sw, 0), 5.0, Color(0.26, 0.26, 0.30))
			for i in 6:
				var a: float = p * 9.0 + float(i) * TAU / 6.0
				draw_circle(Vector2(10 - sw, 0) + Vector2.from_angle(a) * 3.1, 1.1, Color(0.85, 0.70, 0.24))
		"shell":
			for i in 1 + int(p * 4.5):
				_r(5.0 + float(i) * 3.2, 2.5, 2.4, 5.0, Color(0.72, 0.13, 0.10))
			_r(12.0 - 6.0 * ins, -5.0, 11.0, 2.2, Color(0.30, 0.30, 0.34))
		"bolt":
			var b: float = sin(p * TAU)
			draw_line(Vector2(26, 0), Vector2(26 - 6.0 * absf(b), -3.5 * b), Color(0.70, 0.72, 0.76), 1.6)
			draw_circle(Vector2(26 - 6.0 * absf(b), -3.5 * b), 1.6, Color(0.50, 0.52, 0.56))
		"string":
			draw_line(Vector2(4, -8), Vector2(4 + 7.0 * ins, 0), Color(0.85, 0.85, 0.85, 0.75), 1.0)
			draw_line(Vector2(4, 8), Vector2(4 + 7.0 * ins, 0), Color(0.85, 0.85, 0.85, 0.75), 1.0)
		"tank":
			_r(2, -7 - 2.0 * ins, 12, 13, Color(0.34, 0.31, 0.23))
			_r(4, -4 - 2.0 * ins, 8, 3, Color(0.55, 0.20, 0.14))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	var dk := Color(0.12, 0.12, 0.13)
	var steel := Color(0.78, 0.80, 0.82)
	var wood := Color(0.35, 0.22, 0.12)
	var rc := recoil * 3.4
	var is_melee: bool = art in [3, 5, 6, 11, 12, 15, 16, 17]
	# Entrada na mão: cada família chega de um jeito (coldre, sobe do quadril,
	# lâmina girando, motosserra pesada).
	var e: float = clampf(equip, 0.0, 1.0)
	var base := Vector2(-rc, 0.0)
	var brot := 0.0
	if e > 0.0:
		if is_melee:
			base += Vector2(-7.0 * e, 5.0 * e)
			brot += -2.2 * e
		elif art in [2, 4, 13]:
			base += Vector2(-4.0 * e, 13.0 * e)
			brot += 0.30 * e
		elif art == 10:
			base += Vector2(-9.0 * e, 7.0 * e)
			brot += 0.55 * e
		elif art == 7:
			base += Vector2(-3.0 * e, 10.0 * e)
			brot += 0.22 * e
		else:
			base += Vector2(-9.0 * e, 8.0 * e)
			brot += -0.45 * e
	# Recarregando: a arma baixa e vira de lado para a mão chegar no carregador.
	if reload_p >= 0.0:
		var ins: float = sin(clampf(reload_p, 0.0, 1.0) * PI)
		brot += 0.42 * ins
		base += Vector2(-3.0 * ins, 2.5 * ins)
	if is_melee:
		var sa := 0.7
		if swing > 0.0:
			sa = -1.2 + (1.0 - swing) * 2.4
		draw_set_transform(base + Vector2(8, 8), sa + brot, Vector2.ONE)
	else:
		draw_set_transform(base, brot, Vector2.ONE)
	match art:
		0:
			_r(10, -2, 12, 4, dk)
			_r(8, 1, 4, 6, wood)
		1, 21:
			_r(8, -2.5, 20, 5, dk)
			_r(14, 2, 4, 9, dk)
		2:
			_r(6, -2, 28, 4, dk)
			_r(0, -2.5, 10, 5, wood)
		3:
			_r(4, -2, 6, 4, wood)
			_r(10, -1.5, 22, 3, steel)
		4:
			_r(4, -2, 36, 4, dk)
			_r(0, -2.5, 10, 5, wood)
		5:
			_r(4, -1.5, 26, 3, wood)
			_r(26, -8, 8, 16, Color(0.55, 0.57, 0.6))
		6:
			_r(4, -1.5, 6, 3, wood)
			_r(10, -1.0, 14, 2, steel)
		7:
			_r(0, -5, 9, 10, Color(0.7, 0.15, 0.1))
			_r(9, -2, 24, 4, Color(0.4, 0.4, 0.42))
		10:
			var shake := 0.8 * float(Time.get_ticks_msec() % 2)
			_r(2, -4 + shake, 12, 8, Color(0.78, 0.32, 0.1))
			_r(14, -2.2 + shake, 28, 4.4, Color(0.6, 0.62, 0.65))
			for i in 9:
				var on := (Time.get_ticks_msec() / 60 + i) % 2 == 0
				_r(15 + i * 3, -3.2 + shake, 1.5, 6.4, Color(0.2, 0.2, 0.2) if on else Color(0.85, 0.85, 0.85))
		11:
			_r(4, -3, 5, 2, Color(0.55, 0.12, 0.12))
			_r(4, 1, 5, 2, Color(0.55, 0.12, 0.12))
			draw_line(Vector2(9, -1), Vector2(28, -3), steel, 2.0)
			draw_line(Vector2(9, 1), Vector2(28, 3), steel, 2.0)
		12:
			_r(4, -1.6, 22, 3.2, wood)
			_r(22, -6, 9, 12, Color(0.42, 0.44, 0.48))
		13:
			_r(4, -2, 46, 4, dk)
			_r(16, -6, 14, 3, dk)
			draw_line(Vector2(52, 0), Vector2(620, 0), Color(1, 0.15, 0.15, 0.25), 1.0)
		14:
			_r(0, -2, 24, 4, wood)
			draw_line(Vector2(16, -9), Vector2(4, 0), Color(0.6, 0.6, 0.62), 1.5)
			draw_line(Vector2(16, 9), Vector2(4, 0), Color(0.6, 0.6, 0.62), 1.5)
			_r(16, -9, 2.5, 18, dk)
		15:
			_r(2, -1.6, 9, 3.2, dk)
			_r(11, -3.5, 2, 7, Color(0.72, 0.56, 0.16))
			_r(13, -1.2, 32, 2.4, Color(0.85, 0.87, 0.9))
		16:
			_r(4, -1.5, 30, 3, Color(0.38, 0.4, 0.44))
			_r(28, -7, 3, 6, Color(0.38, 0.4, 0.44))
		17:
			_r(4, -1.5, 7, 3, wood)
			_r(11, -6, 18, 11, Color(0.72, 0.74, 0.77))
			_r(27, -6, 2, 11, Color(0.5, 0.1, 0.12))
		18:
			_r(10, -8, 12, 4, dk)
			_r(10, 4, 12, 4, dk)
		19:
			_r(4, -2, 9, 4, dk)
			_r(13, -1.4, 10, 2.8, Color(0.55, 0.57, 0.6))
			draw_circle(Vector2(8, 0), 3.4, Color(0.35, 0.36, 0.4))
		20:
			_r(0, -2.2, 12, 4.4, wood)
			_r(12, -2.6, 22, 2.2, dk)
			_r(12, 0.4, 22, 2.2, dk)
		_:
			_r(8, -2, 16, 4, dk)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if reload_p >= 0.0 and not is_melee:
		_reload_fx(base, brot)
	if flash > 0.0 and MUZZLE.has(art):
		var m := float(MUZZLE[art])
		draw_colored_polygon(PackedVector2Array([Vector2(m, 0), Vector2(m + 9, -4), Vector2(m + 18, 0), Vector2(m + 9, 4)]), Color(1.0, 0.9, 0.5))
