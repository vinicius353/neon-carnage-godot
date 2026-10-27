extends RigidBody2D
# Pedaços soltos: braço, cabeça, órgãos (coração, pulmão, intestino) e pedaços de carne.

var kind := "arm"
var skin := Color(0.85, 0.7, 0.55)
var hair := Color(0.2, 0.1, 0.05)


func setup(k: String, c: Color, h: Color) -> void:
	kind = k
	skin = c
	hair = h
	gravity_scale = 0.0
	linear_damp = 3.5
	angular_damp = 2.5
	collision_layer = 0
	collision_mask = 1
	z_index = 1
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 5.0
	cs.shape = sh
	add_child(cs)
	queue_redraw()


func _draw() -> void:
	match kind:
		"arm":
			draw_rect(Rect2(-9, -2.5, 16, 5), skin)
			draw_circle(Vector2(8, 0), 3.0, Color(0.75, 0.05, 0.08))
			draw_circle(Vector2(8, 0), 1.4, Color(0.9, 0.88, 0.8))
		"head":
			draw_circle(Vector2.ZERO, 6.0, skin)
			draw_circle(Vector2(-2, 0), 5.2, hair)
			draw_circle(Vector2(5, 0), 2.8, Color(0.7, 0.04, 0.07))
		"heart":
			draw_circle(Vector2(-2, -2), 4.0, Color(0.5, 0.05, 0.1))
			draw_circle(Vector2(2, -2), 4.0, Color(0.5, 0.05, 0.1))
			draw_colored_polygon(PackedVector2Array([Vector2(-6, -1), Vector2(6, -1), Vector2(0, 7)]), Color(0.45, 0.04, 0.09))
			draw_circle(Vector2(-1, -3), 1.2, Color(1, 0.7, 0.7, 0.5))
		"lung":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.5))
			draw_circle(Vector2(-3.5, 0), 4.0, Color(0.72, 0.38, 0.42))
			draw_circle(Vector2(3.5, 0), 4.0, Color(0.72, 0.38, 0.42))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"gut":
			for i in 6:
				draw_circle(Vector2(-10 + i * 4, sin(i * 1.3) * 2.5), 2.6, Color(0.72, 0.42, 0.45))
		"meat":
			draw_circle(Vector2.ZERO, 3.2, Color(0.5, 0.05, 0.07))
			draw_circle(Vector2(2, 1), 2.1, Color(0.62, 0.1, 0.12))
			draw_circle(Vector2(-1.5, -1.5), 1.2, Color(0.95, 0.6, 0.6, 0.6))
		_:
			draw_circle(Vector2.ZERO, 4.5, Color(0.42, 0.1, 0.08))
