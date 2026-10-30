extends CharacterBody2D
# Civil, refém, policial ou terrorista: ferimento por zona, desmembramento, fuga e perseguição.
# O desenho do corpo fica no figure.gd.

var main = null
var fig = null
var hp := 40.0
var hp0 := 40.0
var has_head := true
var arm_l := true
var arm_r := true
var leg_l := true
var leg_r := true
var arm_dmg := [0.0, 0.0]
var legs_dmg := 0.0
var dead := false
var burn := 0.0
var cop := false
var terror := false
var hostage := false
var held := false
var seen := false
var stun := 0.0
var sleeping := false
var alert_t := 0.0
var path: Array = []
var repath := 0.0
var shoot_t := 1.0
var skin := Color(0.85, 0.7, 0.55)
var shirt := Color(0.5, 0.4, 0.5)
var hair := Color(0.2, 0.12, 0.06)
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
	fig = m.Figure.new()
	fig.pants = Color(randf_range(0.10, 0.35), randf_range(0.10, 0.30), randf_range(0.15, 0.40))
	fig.hair_style = randi() % 3
	fig.seed_v = randf() * 10.0
	add_child(fig)
	refresh()


func refresh() -> void:
	fig.has_head = has_head
	fig.arm_l = arm_l
	fig.arm_r = arm_r
	fig.leg_l = leg_l
	fig.leg_r = leg_r
	fig.dead = dead
	fig.sleeping = sleeping
	fig.is_cop = cop
	fig.skin = skin
	fig.shirt = shirt
	fig.hair = hair
	fig.hold = "one" if (cop or terror) else "none"
	fig.blood = clampf(1.0 - hp / hp0, 0.0, 1.0)
	fig.queue_redraw()


func hit(dmg: float, dir: Vector2, gpos: Vector2, cut: float) -> void:
	if dead:
		return
	sleeping = false
	alert_t = 4.0
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
	fig.kick = dir * 3.0
	var bcol: Color = main.BLOOD_ART if zone == "head" else main.BLOOD_VEN
	# impacto completo: poça + estrias no sentido do golpe + névoa de gotas
	main.blood.splash(gpos, dir, 1.15 if hp <= 0.0 else 0.9, bcol)
	main.on_hit()
	if zone == "arm" and cut > 0.0 and randf() < cut + float(arm_dmg[si]) / 100.0:
		sever("arm_l" if si == 0 else "arm_r", dir)
	elif zone == "head" and cut >= 0.5 and randf() < cut:
		sever("head", dir)
	elif zone == "legs" and cut > 0.0 and randf() < cut * 0.55:
		sever("leg_l" if randf() < 0.5 else "leg_r", dir)
	elif cut >= 0.4 and randf() < cut * 0.3:
		sever("arm_l" if randf() < 0.5 else "arm_r", dir)
	refresh()
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
	elif part == "leg_l":
		if not leg_l:
			return
		leg_l = false
		legs_dmg = 100.0
		off = Vector2(-6.0, -6.0)
		kind = "leg"
	elif part == "leg_r":
		if not leg_r:
			return
		leg_r = false
		legs_dmg = 100.0
		off = Vector2(-6.0, 6.0)
		kind = "leg"
	else:
		if not has_head:
			return
		has_head = false
		kind = "head"
	main.spawn_piece(kind, to_global(off), dir, skin, hair)
	main.blood.add_spurt(self, off, off.angle(), 7.0)
	main.sfx.play("osso")
	refresh()
	if part == "head" and not dead:
		die(dir, 40.0)


func die(dir: Vector2, over: float) -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	z_index = 0
	set_physics_process(false)
	refresh()
	fig.fall_t = 0.25
	fig.fall_rot = randf_range(1.8, 3.0) * (1.0 if randf() < 0.5 else -1.0)
	fig.moving = false
	main.on_death(self, dir, over)


func _los(p: Vector2) -> bool:
	if main.in_smoke(p):
		return false
	var q := PhysicsRayQueryParameters2D.create(global_position, p, 1)
	var h := get_world_2d().direct_space_state.intersect_ray(q)
	return h.is_empty()


func _follow(spd: float) -> void:
	if path.is_empty():
		velocity = Vector2.ZERO
		return
	var t: Vector2 = path[0]
	var d := t - global_position
	if d.length() < 10.0:
		path.remove_at(0)
		return
	velocity = d.normalized() * spd


func _civ_ai(delta: float, p: Vector2, dist: float, away: Vector2) -> void:
	if hostage:
		velocity = Vector2.ZERO
		return
	var spd := 150.0
	if legs_dmg >= 40.0:
		spd = 45.0
		if randf() < 0.2:
			main.blood.stamp(global_position, Vector2(0.2, 0.15), face)
	if burn > 0.0:
		spd *= 1.3
	if dist < 280.0 or burn > 0.0:
		alert_t = 4.0
	if alert_t > 0.0:
		alert_t -= delta
		if main.nav != null:
			repath -= delta
			if repath <= 0.0:
				repath = 0.5
				path = main.nav.flee_path(global_position, p)
			_follow(spd)
		else:
			velocity = away.normalized() * spd + Vector2.from_angle(randf() * TAU) * 30.0
	else:
		if randf() < 0.01:
			wander = Vector2.from_angle(randf() * TAU)
		velocity = wander * 35.0


func _cop_ai(delta: float, p: Vector2, dist: float) -> void:
	shoot_t -= delta
	repath -= delta
	var sees: bool = dist < 440.0 and _los(p)
	if sees:
		seen = true
	if terror and not seen:
		velocity = Vector2.ZERO
		return
	if sees:
		face = (p - global_position).angle()
		rotation = face
		if shoot_t <= 0.0:
			shoot_t = 0.9 + randf() * 0.4
			main.cop_shot(global_position, p)
		if dist < 170.0:
			velocity = Vector2.ZERO
			return
	var tgt: Vector2 = p
	if not sees and main.decoy_t > 0.0:
		tgt = main.decoy_pos
	if main.nav != null:
		if repath <= 0.0:
			repath = 0.5
			path = main.nav.path(global_position, tgt)
		_follow(110.0)
	else:
		velocity = (tgt - global_position).normalized() * 110.0


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
	if held:
		velocity = Vector2.ZERO
		fig.moving = false
		return
	if stun > 0.0:
		stun -= delta
		velocity = Vector2.ZERO
		fig.moving = false
		return
	var p: Vector2 = main.player.global_position
	var away: Vector2 = global_position - p
	var dist := away.length()
	if sleeping:
		if dist < 110.0:
			sleeping = false
			alert_t = 4.0
			refresh()
		else:
			return
	if cop or terror:
		_cop_ai(delta, p, dist)
	else:
		_civ_ai(delta, p, dist, away)
	move_and_slide()
	if hp < 20.0 and randf() < 0.15:
		main.blood.stamp(global_position, Vector2(0.12, 0.12), randf() * TAU)
	var sp := velocity.length()
	fig.moving = sp > 5.0
	if sp > 5.0:
		if not (cop or terror) or not _los(p):
			face = lerp_angle(face, velocity.angle(), 0.2)
			rotation = face
		fig.phase += sp * delta * 0.12
