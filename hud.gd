extends Control
# HUD: barras de vida e munição, mira, marcador de acerto, aviso de dano,
# vinheta de vida baixa e os analógicos virtuais.

var main = null


func _process(_d: float) -> void:
	if main == null:
		return
	queue_redraw()


func _draw() -> void:
	if main == null:
		return
	var vs := get_viewport_rect().size
	var mo: Vector2 = main.move_o if main.move_t != -1 else Vector2(80, vs.y - 80)
	var ao: Vector2 = main.aim_o if main.aim_t != -1 else Vector2(vs.x - 80, vs.y - 80)
	_stick(mo, main.move_pos, main.move_t != -1)
	_stick(ao, main.aim_pos, main.aim_t != -1)
	if main.player == null:
		return
	_health()
	_ammo(vs)
	_vignette(vs)
	_damage(vs)
	_crosshair()
	_popup(vs)


func _stick(o: Vector2, p: Vector2, active: bool) -> void:
	var a := 0.45 if active else 0.16
	draw_arc(o, 46.0, 0.0, TAU, 24, Color(0.85, 0.8, 0.7, a), 3.0)
	var k := Vector2.ZERO
	if active:
		k = (p - o).limit_length(46.0)
	draw_circle(o + k, 18.0, Color(0.85, 0.8, 0.7, a + 0.1))


func _health() -> void:
	var r: float = clampf(main.php / maxf(1.0, main.php_max), 0.0, 1.0)
	var p := Vector2(8, 8)
	var s := Vector2(120, 11)
	draw_rect(Rect2(p, s), Color(0, 0, 0, 0.55), true)
	if r > 0.0:
		var col := Color(0.70, 0.05, 0.09)
		if r <= 0.35:
			col = Color(0.95, 0.14, 0.06)
		draw_rect(Rect2(p, Vector2(s.x * r, s.y)), col, true)
	draw_rect(Rect2(p, s), Color(0.85, 0.8, 0.75, 0.5), false, 1.0)
	for i in range(1, 5):
		var x: float = p.x + s.x * float(i) / 5.0
		draw_line(Vector2(x, p.y + 1.0), Vector2(x, p.y + s.y - 1.0), Color(0, 0, 0, 0.35), 1.0)


func _ammo(vs: Vector2) -> void:
	if main.weapons == null or main.weapons.list.is_empty():
		return
	var w: Dictionary = main.weapons.cur()
	var p := Vector2(8, vs.y - 24)
	var s := Vector2(110, 9)
	draw_rect(Rect2(p, s), Color(0, 0, 0, 0.55), true)
	var frac := 1.0
	var col := Color(0.80, 0.62, 0.18)
	if not w["melee"] and w["tipo"] != "lanca_chamas":
		var nm: String = w["nome"]
		frac = clampf(float(main.weapons.ammo[nm]) / maxf(1.0, float(w["municao"])), 0.0, 1.0)
		if float(main.weapons.reserve[nm]) <= 0.0 and float(main.weapons.ammo[nm]) < 1.0:
			col = Color(0.55, 0.12, 0.10)
	if frac > 0.0:
		draw_rect(Rect2(p, Vector2(s.x * frac, s.y)), col, true)
	if main.weapons.reload_t > 0.0:
		var total: float = maxf(0.001, float(w["recarga"]) / 60.0)
		var pr: float = clampf(1.0 - main.weapons.reload_t / total, 0.0, 1.0)
		draw_rect(Rect2(p, Vector2(s.x * pr, s.y)), Color(0.95, 0.9, 0.85, 0.45), true)
	draw_rect(Rect2(p, s), Color(0.85, 0.8, 0.75, 0.5), false, 1.0)


func _vignette(vs: Vector2) -> void:
	var r: float = clampf(main.php / maxf(1.0, main.php_max), 0.0, 1.0)
	if r > 0.34:
		return
	var k: float = (0.34 - r) / 0.34
	var a: float = 0.10 + k * 0.35 + sin(float(Time.get_ticks_msec()) * 0.006) * 0.05
	var col := Color(0.55, 0.0, 0.02, clampf(a, 0.0, 0.7))
	draw_rect(Rect2(0, 0, vs.x, 5), col, true)
	draw_rect(Rect2(0, vs.y - 5, vs.x, 5), col, true)
	draw_rect(Rect2(0, 0, 5, vs.y), col, true)
	draw_rect(Rect2(vs.x - 5, 0, 5, vs.y), col, true)


func _damage(vs: Vector2) -> void:
	if main.dmg_t <= 0.0 or main.dmg_dir == Vector2.ZERO:
		return
	var al: float = clampf(main.dmg_t / 0.6, 0.0, 1.0)
	var c := vs * 0.5
	var a: float = main.dmg_dir.angle()
	draw_arc(c, minf(vs.x, vs.y) * 0.42, a - 0.45, a + 0.45, 12, Color(0.95, 0.12, 0.10, al * 0.85), 3.0)


func _crosshair() -> void:
	if main.touch_mode:
		return
	var p: Vector2 = get_viewport().get_mouse_position()
	var c := Color(1, 1, 1, 0.55)
	draw_line(p + Vector2(-6, 0), p + Vector2(-2, 0), c, 1.0)
	draw_line(p + Vector2(2, 0), p + Vector2(6, 0), c, 1.0)
	draw_line(p + Vector2(0, -6), p + Vector2(0, -2), c, 1.0)
	draw_line(p + Vector2(0, 2), p + Vector2(0, 6), c, 1.0)
	draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 1, 0.75), true)
	if main.hit_t > 0.0:
		var a: float = clampf(main.hit_t / 0.12, 0.0, 1.0)
		var col := Color(1.0, 0.30, 0.22, a)
		draw_line(p + Vector2(-7, -7), p + Vector2(-3, -3), col, 1.5)
		draw_line(p + Vector2(7, -7), p + Vector2(3, -3), col, 1.5)
		draw_line(p + Vector2(-7, 7), p + Vector2(-3, 3), col, 1.5)
		draw_line(p + Vector2(7, 7), p + Vector2(3, 3), col, 1.5)


func _popup(vs: Vector2) -> void:
	if main.weapon_t <= 0.0 or main.weapons == null or main.weapons.list.is_empty():
		return
	var al: float = clampf(main.weapon_t / 0.5, 0.0, 1.0)
	var nm: String = str(main.weapons.cur()["nome"]).to_upper()
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(vs.x * 0.5 - 90.0, vs.y - 46.0), nm, HORIZONTAL_ALIGNMENT_CENTER, 180.0, 16, Color(1.0, 0.92, 0.86, al))
