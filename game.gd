extends Node2D
# Jogo: mundo, jogador, câmera, interface, polícia.

const MAP_IDS := ["casa", "banco", "hospital", "mercado"]
const PROPCOL := {"bed": Color(0.78, 0.74, 0.68), "sofa": Color(0.40, 0.12, 0.16), "tv": Color(0.05, 0.07, 0.10), "tbl": Color(0.40, 0.28, 0.17), "chr": Color(0.48, 0.35, 0.20), "cnt": Color(0.65, 0.63, 0.58), "stv": Color(0.75, 0.75, 0.76), "fri": Color(0.85, 0.86, 0.86), "bks": Color(0.25, 0.17, 0.10), "wrd": Color(0.29, 0.20, 0.14), "dsk": Color(0.35, 0.25, 0.15), "plt": Color(0.18, 0.42, 0.20), "tub": Color(0.85, 0.90, 0.91), "toi": Color(0.93, 0.93, 0.93), "wsh": Color(0.80, 0.82, 0.83), "cab": Color(0.35, 0.23, 0.15), "fpl": Color(0.42, 0.25, 0.21), "nst": Color(0.35, 0.24, 0.15), "mac": Color(0.70, 0.75, 0.77), "prt": Color(0.35, 0.35, 0.38), "c": Color(0.42, 0.29, 0.17)}

var Blood
var Sfx
var Weapons
var WeaponArt
var Actor
var Piece
var Hud
var Nav
var map: Dictionary = {}
var map_i := 0
var mw := 1600.0
var mh := 900.0
var nav = null
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
var php := 100.0
var pdead := false
var death_t := 0.0
var flash_a := 0.0
var police_called := false
var clear_t := 0.0
var win_t := 0.0
var msg_t := 0.0
var kills := 0
var ui_buttons: Array = []
var name_label: Label
var debug_label: Label
var pause_label: Label
var msg_label: Label
var warn_label: Label
var dmg_rect: ColorRect


func _ready() -> void:
	randomize()
	Blood = load("res://blood.gd")
	Sfx = load("res://sfx.gd")
	Weapons = load("res://weapons.gd")
	WeaponArt = load("res://weapon_art.gd")
	Actor = load("res://actor.gd")
	Piece = load("res://piece.gd")
	Hud = load("res://hud.gd")
	map_i = int(get_tree().root.get_meta("map_i", 0))
	var bad_opt: Array = get_meta("bad_opt", [])
	if bad_opt.is_empty():
		var maps = load("res://maps.gd").new()
		map = maps.get_map(MAP_IDS[map_i])
		Nav = load("res://nav.gd")
	if map.is_empty():
		map = _builtin_map()
	mw = float(map["w"])
	mh = float(map["h"])
	_make_soft()
	_build_world()
	_make_player()
	weapons = Weapons.new()
	weapons.main = self
	add_child(weapons)
	weapons.load_list()
	weapons.select(0)
	_spawn_wave()
	_make_ui()
	if not bad_opt.is_empty():
		warn_label.text = "AVISO: nao carregou " + ", ".join(bad_opt)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _builtin_map() -> Dictionary:
	return {"name": "Sala", "w": 1600.0, "h": 900.0, "walls": [[0.0, 0.0, 1600.0, 20.0], [0.0, 880.0, 1600.0, 20.0], [0.0, 0.0, 20.0, 900.0], [1580.0, 0.0, 20.0, 900.0], [790.0, 20.0, 20.0, 300.0], [790.0, 520.0, 20.0, 360.0]], "props": [[200.0, 600.0, 220.0, 70.0, "sofa"], [1100.0, 200.0, 160.0, 90.0, "tbl"], [1250.0, 650.0, 180.0, 120.0, "bed"]], "rooms": [], "start": [300.0, 400.0], "entry": [1500.0, 450.0], "sleepers": [], "spawns": [[900.0, 150.0], [1000.0, 450.0], [1500.0, 150.0], [1450.0, 520.0], [900.0, 800.0], [1100.0, 600.0]], "civ": 6}


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


func _block(r: Rect2, col: Color, solid: bool, kind: String) -> void:
	var b := StaticBody2D.new()
	b.collision_layer = 1 if solid else 0
	b.position = r.position
	if solid:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		cs.shape = rs
		cs.position = r.size / 2.0
		b.add_child(cs)
		var oc := LightOccluder2D.new()
		var poly := OccluderPolygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(0, 0), Vector2(r.size.x, 0), r.size, Vector2(0, r.size.y)])
		oc.occluder = poly
		b.add_child(oc)
	var vis := ColorRect.new()
	vis.color = col
	vis.size = r.size
	b.add_child(vis)
	if r.size.x > 10.0 and r.size.y > 10.0:
		var inner := ColorRect.new()
		inner.color = col.lightened(0.12)
		inner.position = Vector2(2, 2)
		inner.size = r.size - Vector2(4, 4)
		b.add_child(inner)
	if kind == "bed":
		var pil := ColorRect.new()
		pil.color = Color(0.93, 0.91, 0.85)
		pil.position = Vector2(6, 6)
		pil.size = Vector2(r.size.x - 12.0, r.size.y * 0.25)
		b.add_child(pil)
	elif kind == "tv":
		var scr := ColorRect.new()
		scr.color = Color(0.25, 0.4, 0.6)
		scr.position = Vector2(4, 4)
		scr.size = Vector2(r.size.x - 8.0, r.size.y - 8.0)
		b.add_child(scr)
	add_child(b)


func _build_world() -> void:
	var fl := ColorRect.new()
	fl.color = Color(0.30, 0.26, 0.22)
	fl.size = Vector2(mw, mh)
	fl.z_index = -20
	add_child(fl)
	for r in map["rooms"]:
		var rr := ColorRect.new()
		rr.color = Color(str(r[4]))
		rr.position = Vector2(r[0], r[1])
		rr.size = Vector2(r[2], r[3])
		rr.z_index = -19
		add_child(rr)
	var cm := CanvasModulate.new()
	cm.color = Color(0.34, 0.34, 0.42)
	add_child(cm)
	sfx = Sfx.new()
	add_child(sfx)
	blood = Blood.new()
	add_child(blood)
	blood.setup(Vector2i(int(mw), int(mh)), -10, soft)
	wall_blood = Blood.new()
	add_child(wall_blood)
	wall_blood.setup(Vector2i(int(mw), int(mh)), 1, soft)
	blood.wall_layer = wall_blood
	var solids: Array = []
	for w in map["walls"]:
		var r1 := Rect2(w[0], w[1], w[2], w[3])
		_block(r1, Color(0.20, 0.17, 0.15), true, "")
		solids.append(r1)
	for p in map["props"]:
		var r2 := Rect2(p[0], p[1], p[2], p[3])
		var kind: String = p[4]
		var solid := kind != "bed"
		_block(r2, PROPCOL.get(kind, Color(0.4, 0.3, 0.2)), solid, kind)
		if solid:
			solids.append(r2)
	blood.wall_rects = solids
	if Nav != null:
		nav = Nav.new()
		nav.build(Vector2(mw, mh), solids)


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
	player.position = Vector2(map["start"][0], map["start"][1])
	player.z_index = 3
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0
	cs.shape = c
	player.add_child(cs)
	player.add_child(_disc(12.0, Color(0.20, 0.55, 0.85)))
	var head := _disc(6.0, Color(0.9, 0.75, 0.6))
	head.position = Vector2(1, 0)
	player.add_child(head)
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
	cam.limit_right = int(mw)
	cam.limit_bottom = int(mh)
	add_child(cam)
	cam.global_position = player.global_position
	cam.make_current()


func _free_spot() -> Vector2:
	if nav != null:
		for i in 25:
			var p: Vector2 = nav.rand_free()
			if p.distance_to(player.global_position) > 350.0:
				return p
		return nav.rand_free()
	return Vector2(randf_range(100.0, mw - 100.0), randf_range(100.0, mh - 100.0))


func _make_civ(pos: Vector2, sleeping: bool) -> void:
	var a = Actor.new()
	add_child(a)
	a.setup(self, pos)
	a.sleeping = sleeping
	if sleeping:
		a.rotation = randf() * TAU
		a.face = a.rotation
	actors.append(a)


func _spawn_wave() -> void:
	var count := int(map.get("civ", 10))
	var n := 0
	for s in map.get("sleepers", []):
		_make_civ(Vector2(s[0], s[1]), true)
		n += 1
	for s in map.get("spawns", []):
		_make_civ(Vector2(s[0], s[1]), false)
		n += 1
	while n < count:
		_make_civ(_free_spot(), false)
		n += 1


func call_police() -> void:
	var e := Vector2(map["entry"][0], map["entry"][1])
	for i in 3:
		var pos := e + Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
		if nav != null:
			pos = nav.nearest_free(pos)
		var a = Actor.new()
		add_child(a)
		a.setup(self, pos)
		a.cop = true
		a.hp = 70.0
		a.shirt = Color(0.10, 0.20, 0.50)
		a.skin = Color(0.85, 0.70, 0.58)
		a.hair = Color(0.10, 0.08, 0.06)
		actors.append(a)
	police_called = true
	msg("ELES CHEGARAM")
	sfx.play("recarga", 0.5)


func civis_count() -> int:
	var n := 0
	for a in actors:
		if not a.cop:
			n += 1
	return n


func msg(t: String) -> void:
	msg_label.text = t
	msg_t = 2.5


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
	dmg_rect = ColorRect.new()
	dmg_rect.color = Color(0.7, 0.0, 0.0, 0.0)
	dmg_rect.size = Vector2(4000, 3000)
	dmg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(dmg_rect)
	var hud = Hud.new()
	hud.main = self
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(hud)
	name_label = Label.new()
	cl.add_child(name_label)
	warn_label = Label.new()
	warn_label.position = Vector2(14, 100)
	cl.add_child(warn_label)
	debug_label = Label.new()
	debug_label.visible = false
	debug_label.position = Vector2(14, 130)
	cl.add_child(debug_label)
	pause_label = Label.new()
	pause_label.text = "PAUSADO"
	pause_label.visible = false
	pause_label.add_theme_font_size_override("font_size", 48)
	cl.add_child(pause_label)
	msg_label = Label.new()
	msg_label.add_theme_font_size_override("font_size", 40)
	cl.add_child(msg_label)
	_btn(cl, "<", func(): weapons.select(weapons.idx - 1))
	_btn(cl, ">", func(): weapons.select(weapons.idx + 1))
	_btn(cl, "R", func(): weapons.manual_reload())
	_btn(cl, "MAPA", _next_map)
	_btn(cl, "POLICIA", _police_btn)
	_btn(cl, "DBG", func(): debug_label.visible = not debug_label.visible)
	_btn(cl, "II", _toggle_pause)
	_btn(cl, "NOVO", _restart)


func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	var bw := 78.0
	var x := vs.x - 10.0 - bw
	var y := 10.0
	for b in ui_buttons:
		if x < 10.0:
			x = vs.x - 10.0 - bw
			y += 58.0
		b.size = Vector2(bw, 52)
		b.position = Vector2(x, y)
		x -= bw + 8.0
	name_label.position = Vector2(14, 10)
	pause_label.position = Vector2(vs.x * 0.5 - 130.0, vs.y * 0.5 - 40.0)
	msg_label.position = Vector2(vs.x * 0.5 - 200.0, vs.y * 0.35)


func _next_map() -> void:
	get_tree().root.set_meta("map_i", (map_i + 1) % MAP_IDS.size())
	_restart()


func _police_btn() -> void:
	if not pdead:
		call_police()


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


func hurt_player(d: float) -> void:
	if pdead:
		return
	php -= d
	flash_a = 0.45
	shake(4.0)
	blood.stamp(player.global_position, Vector2(0.3, 0.3), randf() * TAU)
	blood.spray(player.global_position, Vector2.from_angle(randf() * TAU), 5, 0.8)
	if php <= 0.0:
		pdead = true
		death_t = 2.5
		msg("FIM.")


func tracer(a: Vector2, b: Vector2) -> void:
	var l := Line2D.new()
	l.points = PackedVector2Array([a, b])
	l.width = 1.5
	l.default_color = Color(1.0, 0.9, 0.5, 0.8)
	l.z_index = 4
	add_child(l)
	get_tree().create_timer(0.06).timeout.connect(l.queue_free)


func cop_shot(from: Vector2, to: Vector2) -> void:
	tracer(from, to)
	sfx.play("pistola", 1.2)
	if randf() < 0.65:
		hurt_player(8.0)


func _physics_process(delta: float) -> void:
	flash_a = maxf(0.0, flash_a - delta * 1.5)
	dmg_rect.color = Color(0.7, 0.0, 0.0, flash_a)
	if pdead:
		death_t -= delta
		if death_t <= 0.0:
			_restart()
		return
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
	if not police_called and civis_count() == 0:
		clear_t += delta
		if clear_t > 2.0:
			call_police()
	if police_called and actors.is_empty():
		win_t += delta
		msg("NAO SOBROU NINGUEM")
		if win_t > 4.0:
			_restart()
	var am := ""
	if w["melee"]:
		am = "corpo a corpo"
	else:
		var nm: String = w["nome"]
		am = "%d/%d" % [int(weapons.ammo[nm]), int(weapons.reserve[nm])]
		if weapons.reload_t > 0.0:
			am += " recarregando"
	name_label.text = "HP %d   %s   %s   civis: %d   mortes: %d" % [int(php), w["nome"], am, civis_count(), kills]


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
	msg_t -= delta
	if msg_t <= 0.0 and not pdead and win_t == 0.0:
		msg_label.text = ""
	if debug_label.visible:
		debug_label.text = "FPS %d\nmapa %s\nautores %d  pedacos %d\ngotas %d  fila %d  carimbos %d" % [Engine.get_frames_per_second(), str(map.get("name", "?")), actors.size(), pieces.size(), blood.drops.size(), blood.queue.size(), blood.live.size()]


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
