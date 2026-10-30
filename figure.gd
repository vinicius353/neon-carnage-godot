extends Node2D
# Modelo de personagem desenhado em código (visto de cima, olhando para +x).
# Serve para o jogador, civis e policiais.

var skin := Color(0.85, 0.70, 0.55)
var shirt := Color(0.50, 0.40, 0.50)
var pants := Color(0.18, 0.18, 0.24)
var hair := Color(0.20, 0.12, 0.06)
var hair_style := 0
var is_cop := false
var has_head := true
var arm_l := true
var arm_r := true
var leg_l := true
var leg_r := true
var fall_rot := 2.5
var dead := false
var sleeping := false
var moving := false
var phase := 0.0
var hold := "none"
var swing := 0.0
var recoil := 0.0
var blood := 0.0
var kick := Vector2.ZERO
var fall_t := 0.0
var seed_v := 0.0
var t := 0.0
var redraw_t := 0.0


func _process(delta: float) -> void:
	t += delta
	kick = kick.move_toward(Vector2.ZERO, delta * 30.0)
	if fall_t > 0.0:
		fall_t = maxf(0.0, fall_t - delta)
		if fall_t == 0.0 and dead:
			# cadáver já caiu: não há mais nada para animar
			set_process(false)
			return
	redraw_t -= delta
	if redraw_t > 0.0:
		return
	var anim: bool = moving or swing > 0.0 or recoil > 0.0 or fall_t > 0.0 or kick != Vector2.ZERO
	if anim:
		# personagem em ação: anima a 14 fps (suficiente para o pixel)
		redraw_t = 0.07
		queue_redraw()
	elif not dead:
		# parado e vivo: só a respiração, a 4 fps
		redraw_t = 0.25
		queue_redraw()


func _dk(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, 1.0)


func _leg(p: Vector2, c: Color) -> void:
	draw_rect(Rect2(p.x - 4.0, p.y - 2.8, 6.0, 5.6), c)
	draw_rect(Rect2(p.x + 2.0, p.y - 2.8, 4.0, 5.6), Color(0.07, 0.07, 0.09))


func _leg_stump(p: Vector2) -> void:
	draw_circle(p, 3.0, Color(0.55, 0.03, 0.06))
	draw_circle(p, 1.4, Color(0.9, 0.88, 0.8))


func _blood_spots() -> void:
	if blood <= 0.02:
		return
	var n: int = int(blood * 7.0) + 1
	for i in n:
		var a: float = seed_v + float(i) * 2.3
		var p: Vector2 = Vector2(cos(a) * 4.0, sin(a * 1.7) * 7.0)
		draw_circle(p, 1.6 + float(i % 3) * 0.7, Color(0.55, 0.02, 0.05, 0.85))


func _hands() -> Array:
	var sw: float = 0.0
	if moving and not dead and not sleeping:
		sw = sin(phase) * 5.0
	var rc: float = recoil * 3.0
	var hl: Vector2 = Vector2(3.0 + sw, -12.0)
	var hr: Vector2 = Vector2(3.0 - sw, 12.0)
	if hold == "one":
		hl = Vector2(15.0 - rc, -1.5)
		hr = Vector2(14.0 - rc, 2.0)
	elif hold == "two":
		hl = Vector2(21.0 - rc, -2.0)
		hr = Vector2(9.0 - rc, 4.0)
	elif hold == "dual":
		hl = Vector2(15.0 - rc, -7.0)
		hr = Vector2(15.0 - rc, 7.0)
	elif hold == "melee":
		hl = Vector2(3.0, -9.0)
		hr = Vector2(8.0, 8.0)
	if dead or sleeping:
		hl = Vector2(2.0, -11.0)
		hr = Vector2(2.0, 11.0)
	return [hl, hr]


func _arm(sh: Vector2, hand: Vector2, side: float, k: float) -> void:
	var el: Vector2 = (sh + hand) * 0.5 + Vector2(-1.0, side * 3.0)
	draw_line(sh, el, _dk(shirt, k * 0.9), 4.6)
	draw_line(el, hand, _dk(skin, k), 3.6)
	draw_circle(hand, 2.4, _dk(skin, k))


func _stump(sh: Vector2) -> void:
	draw_circle(sh, 3.2, Color(0.6, 0.03, 0.06))
	draw_circle(sh, 1.5, Color(0.9, 0.88, 0.8))


func _head(k: float) -> void:
	var hp: Vector2 = Vector2(1.5, 0.0)
	if not has_head:
		draw_circle(hp, 4.5, Color(0.55, 0.03, 0.06))
		draw_circle(hp, 2.0, Color(0.9, 0.88, 0.8))
		return
	draw_circle(hp, 6.2, Color(0, 0, 0, 0.5))
	draw_circle(hp, 5.6, _dk(skin, k))
	if is_cop:
		draw_circle(hp, 5.6, _dk(Color(0.08, 0.12, 0.30), k))
		draw_rect(Rect2(hp.x + 3.0, -3.6, 4.0, 7.2), _dk(Color(0.05, 0.08, 0.2), k))
		return
	if hair_style == 0:
		draw_arc(hp, 5.0, PI * 0.55, PI * 1.45, 10, _dk(hair, k), 4.2)
	elif hair_style == 1:
		draw_circle(hp + Vector2(-2.0, 0.0), 5.6, _dk(hair, k))
		draw_circle(hp + Vector2(1.5, 0.0), 4.4, _dk(skin, k))
	if dead or sleeping:
		draw_line(hp + Vector2(3.0, -3.0), hp + Vector2(4.2, -1.6), Color(0.1, 0.05, 0.05), 1.0)
		draw_line(hp + Vector2(3.0, 3.0), hp + Vector2(4.2, 1.6), Color(0.1, 0.05, 0.05), 1.0)
	else:
		draw_circle(hp + Vector2(3.6, -2.2), 0.8, Color(0.08, 0.05, 0.05))
		draw_circle(hp + Vector2(3.6, 2.2), 0.8, Color(0.08, 0.05, 0.05))


func _draw() -> void:
	var k: float = 1.0
	if dead:
		k = 0.55
	elif sleeping:
		k = 0.8
	var fk: float = 1.0 - fall_t * 1.2
	var base_rot: float = fall_t * fall_rot
	var sc: Vector2 = Vector2(fk, fk)
	var step: float = 0.0
	if moving and not dead and not sleeping:
		step = sin(phase)
	var breathe: float = 1.0
	if not dead and not moving:
		breathe = 1.0 + sin(t * 3.0) * 0.03
	var twist: float = 0.0
	if hold == "melee":
		twist = (swing - 0.3) * 0.25
	draw_set_transform(kick, base_rot, sc)
	if not dead:
		if leg_l:
			_leg(Vector2(step * 5.0, -4.5), _dk(pants, k))
		else:
			_leg_stump(Vector2(-2.0, -4.5))
		if leg_r:
			_leg(Vector2(-step * 5.0, 4.5), _dk(pants, k))
		else:
			_leg_stump(Vector2(-2.0, 4.5))
	draw_set_transform(kick, base_rot + twist, Vector2(fk * 0.78, fk * 1.25 * breathe))
	draw_circle(Vector2.ZERO, 9.0, _dk(shirt, k))
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 20, Color(0, 0, 0, 0.5), 1.2)
	draw_circle(Vector2(-1.5, 0.0), 5.5, _dk(shirt.lightened(0.1), k))
	draw_set_transform(kick, base_rot, sc)
	_blood_spots()
	if is_cop:
		draw_circle(Vector2(2.5, -4.5), 1.4, Color(0.9, 0.8, 0.2))
	var hs: Array = _hands()
	var hl: Vector2 = hs[0]
	var hr: Vector2 = hs[1]
	if is_cop and not dead:
		draw_rect(Rect2(hr.x, hr.y - 1.2, 9.0, 2.4), Color(0.1, 0.1, 0.1))
	if arm_l:
		_arm(Vector2(0, -9.5), hl, -1.0, k)
	else:
		_stump(Vector2(0, -9.5))
	if arm_r:
		_arm(Vector2(0, 9.5), hr, 1.0, k)
	else:
		_stump(Vector2(0, 9.5))
	_head(k)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
