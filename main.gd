extends Node2D

const W := 1600
const H := 900
const Blood = preload("res://blood.gd")
const Sfx = preload("res://sfx.gd")
const Weapons = preload("res://weapons.gd")
const WeaponArt = preload("res://weapon_art.gd")
const Actor = preload("res://actor.gd")
const Piece = preload("res://piece.gd")
const Hud = preload("res://hud.gd")

var soft: GradientTexture2D
var blood
var wall_blood
var sfx
var weapons
var art
var player: CharacterBody2D
var light: PointLight2D
var cam: Camera2D
var actors: Array = []
var corpses: Array = []
var pieces: Array = []
var move_t := -1
var aim_t := -1
var move_o := Vector2.ZERO
var aim_o := Vector2.ZERO
var move_pos := Vector2.ZERO
var aim_pos := Vector2.ZERO
var move_v := Vector2.ZERO
var aim_v := Vector2.RIGHT
var firing := false
var touch_mode := false
var shake_v := 0.0
var wave_t := 0.0
var ui_buttons: Array = []
var name_label: Label
var debug_label: Label
var pause_label: Label
var b_prev: Button
var b_next: Button
var b_reload: Button
var b_dbg: Button
var b_pause: Button
var b_new: Button
var kills := 0


func _ready() -> void:
	randomize()
	_make_soft()
	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.32, 0.27, 0.22)
	floor_rect.size = Vector2(W, H)
	floor_rect.z_index = -20
	add_child(floor_rect)
	var cm := CanvasModulate.new()
	cm.color = Color(0.30, 0.30, 0.38)
	add_child(cm)
	sfx = Sfx.new()
	add_child(sfx)
	blood = Blood.new()
	add_child(blood)
	blood.setup(Vector2i(W, H), -10, soft)
	wall_blood = Blood.new()
	add_child(wall_blood)
	wall_blood.setup(Vector2i(W, H), 1, soft)
	blood.wall_layer = wall_blood
	_make_room()
	_make_player()
	weapons = Weapons.new()
	weapons.main = self
	add_child(weapons)
	weapons.load_list()
	weapons.select(0)
	_spawn_wave()
	_make_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()


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


func _wall(r: Rect2, col: Color, rects: Array) -> void:
	rects.append(r)
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
	var rects: Array = []
	var wc := Color(0.20, 0.17, 0.15)
	_wall(Rect2(0, 0, W, 20), wc, rects)
	_wall(Rect2(0, H - 20, W, 20), wc, rects)
	_wall(Rect2(0, 0, 20, H), wc, rects)
	_wall(Rect2(W - 20, 0, 20, H), wc, rects)
	_wall(Rect2(790, 20, 20, 300), wc, rects)
	_wall(Rect2(790, 520, 20, H - 540), wc, rects)
	_wall(Rect2(200, 600, 220, 70), Color(0.40, 0.12, 0.14), rects)
	_wall(Rect2(1100, 200, 160, 90), Color(0.38, 0.26, 0.16), rects)
	_wall(Rect2(1250, 650, 180, 120), Color(0.75, 0.72, 0.66), rects)
	blood.wall_rects = rects


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
	player.z_index = 3
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0
	cs.shape = c
	player.add_child(cs)
	player.add_child(_disc(12.0, Color(0.85, 0.75, 0.6)))
	art = WeaponArt.new()
	player.add_child(art)
	light = PointLight2D.new()
	light.texture = soft
	light.texture_scale = 7.0
	light.energy = 1.3
	light.color = Color(1.0, 0.92, 0.8)
	light.shadow_enabled = true
	player.add_child(light)
	add_child(player)
	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = W
	cam.limit_bottom = H
	add_child(cam)
	cam.global_position = player.global_position
	cam.make_current()


func _spawn_wave() -> void:
	var spots := [Vector2(900, 150), Vector2(1000, 450), Vector2(1500, 150), Vector2(1450, 520), Vector2(900, 800), Vector2(1100, 600), Vector2(1350, 380), Vector2(1000, 250)]
	for s in spots:
		var a = Actor.new()
		add_child(a)
		a.setup(self, s + Vector2(randf_range(-20, 20), randf_range(-20, 20)))
		actors.append(a)


func _btn(parent: Node, txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	ui_buttons.append(b)
	return b


func _make_ui() -> void:
	var cl := CanvasLayer.new()
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cl)
	var hud = Hud.new()
	hud.main = self
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(hud)
	name_label = Label.new()
	cl.add_child(name_label)
	debug_label = Label.new()
	debug_label.visible = false
	debug_label.position = Vector2(14, 70)
	cl.add_child(debug_label)
	pause_label = Label.new()
	pause_label.text = "PAUSADO"
	pause_label.visible = false
	pause_label.add_theme_font_size_override("font_size", 48)
	cl.add_child(pause_label)
	b_prev = _btn(cl, "<", func(): weapons.select(weapons.idx - 1))
	b_next = _btn(cl, ">", func(): weapons.select(weapons.idx + 1))
	b_reload = _btn(cl, "R", func(): weapons.manual_reload())
	b_dbg = _btn(cl, "DBG", func(): debug_label.visible = not debug_label.visible)
	b_pause = _btn(cl, "II", _toggle_pause)
	b_new = _btn(cl, "NOVO", _restart)


func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	var bw := 74.0
	var x := vs.x - 10.0 - bw
	for b in [b_pause, b_new, b_dbg, b_reload, b_next, b_prev]:
		b.size = Vector2(bw, 52)
		b.position = Vector2(x, 10)
		x -= bw + 8.0
	name_label.position = Vector2(14, 10)
	pause_label.position = Vector2(vs.x * 0.5 - 130.0, vs.y * 0.5 - 40.0)


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_label.visible = get_tree().paused


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _over_button(p: Vector2) -> bool:
	for b in ui_buttons:
		if b.get_global_rect().has_point(p):
			return true
	return false


func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		touch_mode = true
		if _over_button(e.position):
			return
		var half := get_viewport().get_visible_rect().size.x * 0.5
		if e.pressed:
			if e.position.x < half and move_t == -1:
				move_t = e.index
				move_o = e.position
				move_pos = e.position
			elif e.position.x >= half and aim_t == -1:
				aim_t = e.index
				aim_o = e.position
				aim_pos = e.position
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
			move_pos = e.position
			move_v = ((e.position - move_o) / 70.0).limit_length(1.0)
		elif e.index == aim_t:
			aim_pos = e.position
			var d: Vector2 = e.position - aim_o
			if d.length() > 10.0:
				aim_v = d.normalized()
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_Q:
			weapons.select(weapons.idx - 1)
		elif e.keycode == KEY_E:
			weapons.select(weapons.idx + 1)
		elif e.keycode == KEY_R:
			weapons.manual_reload()
		elif e.keycode == KEY_P:
			_toggle_pause()


func _physics_process(delta: float) -> void:
	var mv := move_v
	if not touch_mode:
		mv = Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)), float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
		aim_v = (get_global_mouse_position() - player.global_position).normalized()
		firing = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var w: Dictionary = weapons.cur()
	player.velocity = mv.limit_length(1.0) * 170.0 * (0.7 + 0.3 * float(w["peso"]))
	player.move_and_slide()
	player.rotation = aim_v.angle()
	light.energy = lerpf(light.energy, 1.3, 0.15)
	weapons.update(delta, firing, aim_v, player.global_position + aim_v * 14.0)
	_update_pieces()
	_update_corpses(delta)
	if actors.is_empty():
		wave_t += delta
		if wave_t > 3.0:
			wave_t = 0.0
			_spawn_wave()
	var am := ""
	if w["melee"]:
		am = "corpo a corpo"
	else:
		var nm: String = w["nome"]
		am = "%d/%d" % [int(weapons.ammo[nm]), int(weapons.reserve[nm])]
		if weapons.reload_t > 0.0:
			am += "  recarregando"
	name_label.text = "%s   %s   civis: %d   mortes: %d" % [w["nome"], am, actors.size(), kills]


func _process(delta: float) -> void:
	var vs := get_viewport().get_visible_rect().size
	var land := vs.x > vs.y
	cam.zoom = Vector2.ONE * (1.0 if land else 1.4)
	var look := 110.0
	if weapons.cur()["nome"] == "Sniper":
		look = 260.0
	var target := player.global_position + aim_v * look
	cam.global_position = cam.global_position.lerp(target, 1.0 - exp(-8.0 * delta))
	shake_v = maxf(0.0, shake_v - delta * 30.0)
	cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_v
	if debug_label.visible:
		debug_label.text = "FPS %d\ncivis %d  pedacos %d\ngotas %d  fila %d  carimbos %d\nparede: fila %d" % [Engine.get_frames_per_second(), actors.size(), pieces.size(), blood.drops.size(), blood.queue.size(), blood.live.size(), wall_blood.queue.size()]


func shake(v: float) -> void:
	shake_v = maxf(shake_v, v)


func shoot_fx() -> void:
	light.energy = 2.6
	art.flash = 0.06
	art.recoil = 1.0
	shake(1.5)


func on_death(a, dir: Vector2, over: float) -> void:
	actors.erase(a)
	kills += 1
	corpses.append({"n": a, "t": 9.0})
	blood.spray(a.global_position, dir, 14, 1.0)
	if over > 40.0:
		for i in 1 + randi() % 3:
			spawn_piece(["heart", "lung", "gut"][randi() % 3], a.global_position, dir, a.skin, a.hair)


func spawn_piece(kind: String, pos: Vector2, dir: Vector2, skin: Color, hair: Color) -> void:
	var p = Piece.new()
	p.position = pos
	add_child(p)
	p.setup(kind, skin, hair)
	p.apply_impulse(dir.rotated(randf_range(-0.6, 0.6)) * randf_range(140.0, 280.0))
	p.angular_velocity = randf_range(-8.0, 8.0)
	pieces.append(p)
	if pieces.size() > 80:
		pieces.pop_front().queue_free()


func _update_pieces() -> void:
	for p in pieces:
		if is_instance_valid(p) and p.linear_velocity.length() > 25.0 and randf() < 0.4:
			blood.stamp(p.global_position + Vector2(randf_range(-4, 4), randf_range(-4, 4)), Vector2(0.14, 0.14), randf() * TAU)


func _update_corpses(delta: float) -> void:
	var keep: Array = []
	for c in corpses:
		c["t"] -= delta
		if c["t"] > 0.0 and is_instance_valid(c["n"]):
			if randf() < 0.15:
				var p: Vector2 = c["n"].global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
				blood.stamp(p, Vector2(0.3 + randf() * 0.3, 0.3 + randf() * 0.3), randf() * TAU)
			keep.append(c)
	corpses = keep
