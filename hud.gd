extends Control
# Analógicos virtuais desenhados na tela (tamanho para a tela pixel de 640x360).

var main = null


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	if main == null:
		return
	var vs := get_viewport_rect().size
	var mo: Vector2 = main.move_o if main.move_t != -1 else Vector2(80, vs.y - 80)
	var ao: Vector2 = main.aim_o if main.aim_t != -1 else Vector2(vs.x - 80, vs.y - 80)
	_stick(mo, main.move_pos, main.move_t != -1)
	_stick(ao, main.aim_pos, main.aim_t != -1)


func _stick(o: Vector2, p: Vector2, active: bool) -> void:
	var a := 0.45 if active else 0.16
	draw_arc(o, 36.0, 0.0, TAU, 20, Color(0.85, 0.8, 0.7, a), 2.0)
	var k := Vector2.ZERO
	if active:
		k = (p - o).limit_length(36.0)
	draw_circle(o + k, 14.0, Color(0.85, 0.8, 0.7, a + 0.1))
