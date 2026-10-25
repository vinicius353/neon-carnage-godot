extends Node2D

const W := 1600
const H := 900

var weapons: Array = []
var wi := 0
var cd := 0.0
var player: CharacterBody2D
var light: PointLight2D
var blood_vp: SubViewport
var soft: GradientTexture2D
var enemies: Array = []
var corpses: Array = []
var limbs: Array = []
var drops: Array = []
var hp_label: Label
var btn: Button
var move_t := -1
var aim_t := -1
var move_o := Vector2.ZERO
var aim_o := Vector2.ZERO
var move_v := Vector2.ZERO
var aim_v := Vector2.RIGHT
var firing := false
var touch_mode := false


func _ready() -> void:
	randomize()
	_load_weapons()
	_make_soft()
	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.32, 0.27, 0.22)
	floor_rect.size = Vector2(W, H)
	floor_rect.z_index = -20
	add_child(floor_rect)
	var cm := CanvasModulate.new()
	cm.color = Color(0.30, 0.30, 0.38)
	add_child(cm)
	_make_blood_layer()
	_make_room()
	_make_player()
	for i in 6:
		_make_enemy(Vector2(randf_range(900, 1500), randf_range(120, 780)))
	_make_ui()


func _load_weapons() -> void:
	var want := ["Pistola", "Escopeta"]
	var f := FileAccess.open("res://data/weapons.json", FileAccess.READ)
	if f != null:
		var data = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			for w in data["armas"]:
				if w["nome"] in want:
					weapons.append({"name": w["nome"], "dmg": float(w["dano"]), "cd": float(w["cadencia"]) / 60.0, "pellets": int(w["projeteis"]), "spread": float(w["dispersao"])})
	if weapons.is_empty():
		weapons = [
			{"name": "Pistola", "dmg": 34.0, "cd": 0.27, "pellets": 1, "spread": 0.04},
			{"name": "Escopeta", "dmg": 15.0, "cd": 1.1, "pellets": 8, "spread": 0.22},
		]


func _make_soft() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	soft = GradientTexture2D.new()
	soft.gradient = g
	soft.fill = GradientTexture2D.FILL_RADIAL
	soft.fill_from = Vector2(0.5, 0.5)
	soft.fill_to = Vector2(0.5, 0.0)
	soft.width = 64
	soft.height = 64


func _make_blood_layer() -> void:
	blood_vp = SubViewport.new()
	blood_vp.size = Vector2i(W, H)
	blood_vp.transparent_bg = true
	blood_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	blood_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(blood_vp)
	var disp := Sprite2D.new()
	disp.texture = blood_vp.get_texture()
	disp.centered = false
	disp.z_index = -10
	var mat := ShaderMaterial.new()
	mat.shader = load("res://blood.gdshader")
	disp.material = mat
	add_child(disp)


func _wall(r: Rect2, col: Color = Color(0.20, 0.17, 0.15)) -> void:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.position = r.position
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.size / 2.0
	b.add_child(cs)
	var vis := ColorRect.new()
	vis.color = col
	vis.size = r.size
	b.add_child(vis)
	var oc := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(0, 0), Vector2(r.size.x, 0), r.size, Vector2(0, r.size.y)])
	oc.occluder = poly
	b.add_child(oc)
	add_child(b)


func _make_room() -> void:
	_wall(Rect2(0, 0, W, 20))
	_wall(Rect2(0, H - 20, W, 20))
	_wall(Rect2(0, 0, 20, H))
	_wall(Rect2(W - 20, 0, 20, H))
	_wall(Rect2(790, 20, 20, 300))
	_wall(Rect2(790, 520, 20, H - 540))
	_wall(Rect2(200, 600, 220, 70), Color(0.40, 0.12, 0.14))
	_wall(Rect2(1100, 200, 160, 90), Color(0.38, 0.26, 0.16))
	_wall(Rect2(1250, 650, 180, 120), Color(0.75, 0.72, 0.66))


func _disc(r: float, col: Color) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	p.polygon = pts
	p.color = col
	return p


func _make_player() -> void:
	player = CharacterBody2D.new()
	player.collision_layer = 4
	player.collision_mask = 1 | 2
	player.position = Vector2(300, 400)
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0
	cs.shape = c
	player.add_child(cs)
	player.add_child(_disc(12.0, Color(0.85, 0.75, 0.6)))
	var gun := ColorRect.new()
	gun.color = Color(0.1, 0.1, 0.1)
	gun.position = Vector2(8, -2)
	gun.size = Vector2(18, 4)
	player.add_child(gun)
	light = PointLight2D.new()
	light.texture = soft
	light.texture_scale = 7.0
	light.energy = 1.3
	light.color = Color(1.0, 0.92, 0.8)
	light.shadow_enabled = true
	player.add_child(light)
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = W
	cam.limit_bottom = H
	player.add_child(cam)
	add_child(player)


func _make_enemy(pos: Vector2) -> void:
	var e := CharacterBody2D.new()
	e.collision_layer = 2
	e.collision_mask = 1 | 2 | 4
	e.position = pos
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0
	cs.shape = c
	e.add_child(cs)
	e.add_child(_disc(12.0, Color(randf_range(0.4, 0.9), randf_range(0.3, 0.7), randf_range(0.3, 0.7))))
	e.set_meta("hp", 30.0)
	e.set_meta("wander", Vector2.from_angle(randf() * TAU))
	add_child(e)
	enemies.append(e)


func _make_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	hp_label = Label.new()
	hp_label.position = Vector2(16, 12)
	cl.add_child(hp_label)
	btn = Button.new()
	btn.text = "TROCAR ARMA"
	btn.position = Vector2(1080, 12)
	btn.size = Vector2(180, 56)
	btn.pressed.connect(func(): wi = (wi + 1) % weapons.size())
	cl.add_child(btn)


func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		touch_mode = true
		if btn.get_global_rect().has_point(e.position):
			return
		var half := get_viewport().get_visible_rect().size.x * 0.5
		if e.pressed:
			if e.position.x < half and move_t == -1:
				move_t = e.index
				move_o = e.position
			elif e.position.x >= half and aim_t == -1:
				aim_t = e.index
				aim_o = e.position
				firing = true
		else:
			if e.index == move_t:
				move_t = -1
				move_v = Vector2.ZERO
			elif e.index == aim_t:
				aim_t = -1
				firing = false
	elif e is InputEventScreenDrag:
		if e.index == move_t:
			move_v = ((e.position - move_o) / 70.0).limit_length(1.0)
		elif e.index == aim_t:
			var d: Vector2 = e.position - aim_o
			if d.length() > 10.0:
				aim_v = d.normalized()


func _physics_process(delta: float) -> void:
	var mv := move_v
	if not touch_mode:
		mv = Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)), float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
		aim_v = (get_global_mouse_position() - player.global_position).normalized()
		firing = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if Input.is_key_pressed(KEY_1):
			wi = 0
		if Input.is_key_pressed(KEY_2):
			wi = min(1, weapons.size() - 1)
	player.velocity = mv.limit_length(1.0) * 170.0
	player.move_and_slide()
	player.rotation = aim_v.angle()
	light.energy = lerp(light.energy, 1.3, 0.15)
	cd -= delta
	if firing and cd <= 0.0:
		_fire()
	_update_enemies()
	_update_drops(delta)
	_update_limbs()
	_update_corpses(delta)
	hp_label.text = "%s   civis: %d" % [weapons[wi]["name"], enemies.size()]


func _fire() -> void:
	var w: Dictionary = weapons[wi]
	cd = w["cd"]
	light.energy = 2.6
	var space := get_world_2d().direct_space_state
	var from := player.global_position + aim_v * 14.0
	for i in int(w["pellets"]):
		var dir := aim_v.rotated(randf_range(-w["spread"], w["spread"]))
		var q := PhysicsRayQueryParameters2D.create(from, from + dir * 1100.0, 1 | 2)
		q.exclude = [player.get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var col = hit["collider"]
		if col is Node and col.has_meta("hp"):
			_hurt(col, float(w["dmg"]), dir, hit["position"], wi == 1)


func _hurt(n: Node2D, dmg: float, dir: Vector2, pos: Vector2, shotgun: bool) -> void:
	var hp: float = n.get_meta("hp") - dmg
	n.set_meta("hp", hp)
	_spray(pos, dir, 10 if hp > 0.0 else 28)
	_stamp(pos, Vector2(0.35, 0.35), randf() * TAU, Color(0.45, 0.0, 0.03, 0.9))
	if hp <= 0.0:
		_kill(n, dir, shotgun)


func _kill(n: Node2D, dir: Vector2, shotgun: bool) -> void:
	enemies.erase(n)
	n.set_meta("hp", -1.0)
	var body := n as CharacterBody2D
	body.collision_layer = 0
	body.modulate = Color(0.55, 0.45, 0.45)
	body.rotation = randf() * TAU
	corpses.append({"n": n, "t": 9.0})
	if shotgun and randf() < 0.7:
		_limb(n.global_position, dir)


func _limb(pos: Vector2, dir: Vector2) -> void:
	var r := RigidBody2D.new()
	r.gravity_scale = 0.0
	r.linear_damp = 3.5
	r.angular_damp = 2.0
	r.collision_layer = 0
	r.collision_mask = 1
	r.position = pos
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 5.0
	cs.shape = c
	r.add_child(cs)
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([Vector2(-9, -3), Vector2(9, -3), Vector2(9, 3), Vector2(-9, 3)])
	p.color = Color(0.85, 0.7, 0.55)
	r.add_child(p)
	add_child(r)
	r.apply_impulse(dir.rotated(randf_range(-0.5, 0.5)) * randf_range(180.0, 320.0))
	r.angular_velocity = randf_range(-8.0, 8.0)
	limbs.append(r)


func _spray(pos: Vector2, dir: Vector2, n: int) -> void:
	var lobes: Array = []
	for i in 1 + randi() % 3:
		lobes.append(randf_range(-0.75, 0.75))
	for i in n:
		var back := randf() < 0.18
		var a := dir.angle()
		if back:
			a += PI + randf_range(-0.8, 0.8)
		else:
			a += float(lobes[randi() % lobes.size()]) + randf_range(-0.25, 0.25)
		var s := (0.6 if back else 1.0) * (60.0 + pow(randf(), 2.2) * 520.0)
		drops.append({"p": pos, "v": Vector2.from_angle(a) * s, "l": randf_range(0.25, 0.7), "a": a, "s": s})
	if drops.size() > 400:
		drops = drops.slice(drops.size() - 400)


func _update_drops(delta: float) -> void:
	var keep: Array = []
	for d in drops:
		d["p"] += d["v"] * delta
		d["v"] *= pow(0.02, delta)
		d["l"] -= delta
		if d["l"] <= 0.0 or d["v"].length() < 25.0:
			var sx: float = 0.10 + randf() * 0.12 + float(d["s"]) * 0.0008
			_stamp(d["p"], Vector2(sx, 0.08 + randf() * 0.1), float(d["a"]), Color(0.5, 0.0, 0.04, 0.9))
			if float(d["s"]) > 250.0:
				var off: Vector2 = Vector2.from_angle(float(d["a"])) * (10.0 + randf() * 20.0)
				_stamp(d["p"] + off, Vector2(0.05, 0.05), 0.0, Color(0.5, 0.0, 0.04, 0.9))
		else:
			keep.append(d)
	drops = keep


func _update_limbs() -> void:
	for l in limbs:
		if is_instance_valid(l) and l.linear_velocity.length() > 25.0 and randf() < 0.4:
			_stamp(l.global_position + Vector2(randf_range(-4, 4), randf_range(-4, 4)), Vector2(0.14, 0.14), randf() * TAU, Color(0.5, 0.0, 0.04, 0.9))


func _update_corpses(delta: float) -> void:
	var keep: Array = []
	for c in corpses:
		c["t"] -= delta
		if c["t"] > 0.0:
			if randf() < 0.15:
				var p: Vector2 = c["n"].global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
				_stamp(p, Vector2(0.3 + randf() * 0.3, 0.3 + randf() * 0.3), randf() * TAU, Color(0.45, 0.0, 0.03, 0.9))
			keep.append(c)
	corpses = keep


func _update_enemies() -> void:
	for e in enemies:
		var away: Vector2 = e.global_position - player.global_position
		if away.length() < 260.0:
			e.velocity = away.normalized() * 150.0 + Vector2.from_angle(randf() * TAU) * 30.0
		else:
			if randf() < 0.01:
				e.set_meta("wander", Vector2.from_angle(randf() * TAU))
			e.velocity = (e.get_meta("wander") as Vector2) * 35.0
		e.move_and_slide()


func _stamp(pos: Vector2, sc: Vector2, rot: float, col: Color) -> void:
	var s := Sprite2D.new()
	s.texture = soft
	s.position = pos
	s.scale = sc
	s.rotation = rot
	s.modulate = col
	blood_vp.add_child(s)
	_free_later(s)


func _free_later(s: Node) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(s):
		s.queue_free()
