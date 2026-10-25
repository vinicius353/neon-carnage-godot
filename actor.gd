extends CharacterBody2D
# Civil: ferimento por zona (cabeça, braços, pernas), desmembramento e fuga.

var main = null
var hp := 40.0
var has_head := true
var arm_l := true
var arm_r := true
var arm_dmg := [0.0, 0.0]
var legs_dmg := 0.0
var dead := false
var burn := 0.0
var skin := Color(0.85, 0.7, 0.55)
var shirt := Color(0.5, 0.4, 0.5)
var hair := Color(0.2, 0.12, 0.06)
var ph := 0.0
var wander := Vector2.RIGHT
var face := 0.0


func setup(m, pos: Vector2) -> void:
	main = m
	position = pos
	collision_layer = 2
	collision_mask = 1 | 2 | 4
	z_index = 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0
	cs.shape = c
	add_child(cs)
	skin = Color(randf_range(0.55, 0.95), randf_range(0.4, 0.75), randf_range(0.3, 0.6))
	shirt = Color(randf_range(0.2, 0.8), randf_range(0.2, 0.7), randf_range(0.2, 0.8))
	hair = Color(randf_range(0.05, 0.5), randf_range(0.03, 0.3), randf_range(0.02, 0.2))
	wander = Vector2.from_angle(randf() * TAU)


func _dk(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, 1.0)


func _draw() -> void:
	var k := 0.55 if dead else 1.0
	if not dead:
		var s := sin(ph) * 4.0
		draw_rect(Rect2(-5 + s, -7, 7, 5), Color(0.15, 0.15, 0.2))
		draw_rect(Rect2(-5 - s, 2, 7, 5), Color(0.15, 0.15, 0.2))
	draw_circle(Vector2.ZERO, 10.0, _dk(shirt, k))
	for side in [-1, 1]:
		var ok: bool = arm_l if side < 0 else arm_r
		var base := Vector2(0, 9.0 * side)
		if ok:
			draw_line(base, base + Vector2(9, 2.0 * side), _dk(skin, k), 4.0)
		else:
			draw_circle(base, 3.0, Color(0.6, 0.03, 0.06))
			draw_circle(base, 1.4, Color(0.9, 0.88, 0.8))
	if has_head:
		draw_circle(Vector2(1, 0), 6.0, _dk(skin, k))
		draw_arc(Vector2.ZERO, 6.0, PI * 0.6, PI * 1.4, 8, _dk(hair, k), 4.0)
	else:
		draw_circle(Vector2(1, 0), 4.5, Color(0.55, 0.03, 0.06))
		draw_circle(Vector2(1, 0), 2.0, Color(0.9, 0.88, 0.8))


func hit(dmg: float, dir: Vector2, gpos: Vector2, cut: float) -> void:
	if dead:
		return
	var lp := to_local(gpos + dir * randf_range(3.0, 10.0))
	var d := dmg
	var zone := "torso"
	var si := 0
	if lp.length() < 5.5:
		zone = "head"
		d = dmg * 3.0
	elif absf(lp.y) > 6.5:
		zone = "arm"
		si = 0 if lp.y < 0.0 else 1
		arm_dmg[si] += dmg
	elif randf() < 0.18:
		zone = "legs"
		legs_dmg += dmg
	hp -= d
	main.blood.spray(gpos, dir, 6 if hp > 0.0 else 16, 1.0)
	main.blood.stamp(gpos, Vector2(0.3, 0.3), randf() * TAU)
	main.blood.stamp(global_position + dir * 9.0, Vector2(0.4, 0.3), dir.angle())
	if zone == "arm" and cut > 0.0 and randf() < cut + float(arm_dmg[si]) / 100.0:
		sever("arm_l" if si == 0 else "arm_r", dir)
	elif zone == "head" and cut >= 0.5 and randf() < cut:
		sever("head", dir)
	elif cut >= 0.4 and randf() < cut * 0.3:
		sever("arm_l" if randf() < 0.5 else "arm_r", dir)
	if hp <= 0.0 and not dead:
		die(dir, -hp)


func sever(part: String, dir: Vector2) -> void:
	var off := Vector2.ZERO
	var kind := "arm"
	if part == "arm_l":
		if not arm_l:
			return
		arm_l = false
		off = Vector2(0, -9)
	elif part == "arm_r":
		if not arm_r:
			return
		arm_r = false
		off = Vector2(0, 9)
	else:
		if not has_head:
			return
		has_head = false
		kind = "head"
	main.spawn_piece(kind, to_global(off), dir, skin, hair)
	main.blood.add_spurt(self, off, off.angle(), 7.0)
	main.sfx.play("osso")
	queue_redraw()
	if part == "head" and not dead:
		die(dir, 40.0)


func die(dir: Vector2, over: float) -> void:
	dead = true
	collision_layer = 0
	z_index = 0
	main.on_death(self, dir, over)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if dead:
		return
	if burn > 0.0:
		burn -= delta
		hp -= 18.0 * delta
		if randf() < 0.1:
			main.blood.stamp(global_position, Vector2(0.15, 0.15), randf() * TAU, Color(0.05, 0.03, 0.02, 0.8))
		if hp <= 0.0:
			die(Vector2.RIGHT, 0.0)
			return
	var away: Vector2 = global_position - main.player.global_position
	var spd := 150.0
	if legs_dmg >= 40.0:
		spd = 45.0
		if randf() < 0.2:
			main.blood.stamp(global_position, Vector2(0.2, 0.15), face)
	if burn > 0.0:
		spd *= 1.3
	if away.length() < 260.0 or burn > 0.0:
		velocity = away.normalized() * spd + Vector2.from_angle(randf() * TAU) * 30.0
	else:
		if randf() < 0.01:
			wander = Vector2.from_angle(randf() * TAU)
		velocity = wander * 35.0
	move_and_slide()
	if hp < 20.0 and randf() < 0.15:
		main.blood.stamp(global_position, Vector2(0.12, 0.12), randf() * TAU)
	if velocity.length() > 5.0:
		face = lerp_angle(face, velocity.angle(), 0.2)
		rotation = face
		ph += velocity.length() * delta * 0.12
		queue_redraw()
