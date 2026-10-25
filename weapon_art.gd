extends Node2D
# Desenho de cada arma, em código. Aponta para +x.

var art := 0
var swing := 0.0
var flash := 0.0
var recoil := 0.0

const MUZZLE := {0: 24, 1: 30, 2: 36, 4: 42, 7: 34, 13: 52, 14: 26, 18: 24, 19: 22, 20: 32, 21: 30}


func set_art(a: int) -> void:
	art = a
	queue_redraw()


func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	recoil = maxf(0.0, recoil - delta * 10.0)
	swing = maxf(0.0, swing - delta * 5.0)
	queue_redraw()


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	var dk := Color(0.12, 0.12, 0.13)
	var steel := Color(0.78, 0.8, 0.82)
	var wood := Color(0.35, 0.22, 0.12)
	var rc := recoil * 3.0
	var is_melee := art in [3, 5, 6, 11, 12, 15, 16, 17]
	if is_melee:
		var sa := 0.7
		if swing > 0.0:
			sa = -1.2 + (1.0 - swing) * 2.4
		draw_set_transform(Vector2(8, 8), sa, Vector2.ONE)
	else:
		draw_set_transform(Vector2(-rc, 0), 0.0, Vector2.ONE)
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
	if flash > 0.0 and MUZZLE.has(art):
		var m := float(MUZZLE[art])
		draw_colored_polygon(PackedVector2Array([Vector2(m, 0), Vector2(m + 9, -4), Vector2(m + 18, 0), Vector2(m + 9, 4)]), Color(1.0, 0.9, 0.5))
