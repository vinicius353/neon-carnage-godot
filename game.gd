extends Node2D
# Jogo: mundo, jogador, câmera, interface, modos, itens e execuções. Estilo pixel (640x360).

const MAP_IDS := ["casa", "banco", "hospital", "mercado"]
const MODE_NAMES := ["MASSACRE", "HALLOWEEN", "JUGGERNAUT", "RESGATE"]
const PROPCOL := {"bed": Color(0.78, 0.74, 0.68), "sofa": Color(0.40, 0.12, 0.16), "tv": Color(0.05, 0.07, 0.10), "tbl": Color(0.40, 0.28, 0.17), "chr": Color(0.48, 0.35, 0.20), "cnt": Color(0.65, 0.63, 0.58), "stv": Color(0.75, 0.75, 0.76), "fri": Color(0.85, 0.86, 0.86), "bks": Color(0.25, 0.17, 0.10), "wrd": Color(0.29, 0.20, 0.14), "dsk": Color(0.35, 0.25, 0.15), "plt": Color(0.18, 0.42, 0.20), "tub": Color(0.85, 0.90, 0.91), "toi": Color(0.93, 0.93, 0.93), "wsh": Color(0.80, 0.82, 0.83), "cab": Color(0.35, 0.23, 0.15), "fpl": Color(0.42, 0.25, 0.21), "nst": Color(0.35, 0.24, 0.15), "mac": Color(0.70, 0.75, 0.77), "prt": Color(0.35, 0.35, 0.38), "c": Color(0.42, 0.29, 0.17)}

var Blood
var Sfx
var Weapons
var WeaponArt
var Actor
var Piece
var Hud
var Figure
var Thrown
var Exec
var Nav
var map: Dictionary = {}
var map_i := 0
var mode := 0
var low := true
var fx := false
var selftest := false
var mw := 1600.0
var mh := 900.0
var nav = null
var soft: GradientTexture2D
var blood
var wall_blood
var sfx
var weapons
var art
var fig
var exec
var player: CharacterBody2D
var light: PointLight2D = null
var cam: Camera2D
var actors: Array = []
var corpses: Array = []
var pieces: Array = []
var smokes: Array = []
var items: Array = [{"n": "Granada", "c": 3}, {"n": "Flash", "c": 2}, {"n": "Molotov", "c": 2}, {"n": "Fumaca", "c": 2}, {"n": "Isca", "c": 2}]
var item_i := 0
var decoy_pos := Vector2.ZERO
var decoy_t := 0.0
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
var php_max := 100.0
var pdead := false
var death_t := 0.0
var flash_a := 0.0
var white_a := 0.0
var last_flash := 0.0
var hud_t := 0.0
var noise := 0.0
var noise_max := 0.0
var timer_t := 0.0
var elapsed := 0.0
var police_called := false
var clear_t := 0.0
var ended := false
var end_t := 0.0
var hostages_dead := 0
var msg_t := 0.0
var kills := 0
var ui_buttons: Array = []
var name_label: Label
var debug_label: Label
var pause_label: Label
var msg_label: Label
var warn_label: Label
var dmg_rect: ColorRect
var luz_btn: Button
var st_t := 0.0
var st_w := -1
var st_i := -1


func _ready() -> void:
	randomize()
	Engine.time_scale = 1.0
	selftest = OS.get_cmdline_user_args().has("selftest")
	low = int(get_tree().root.get_meta("gfx", 0)) == 0
	fx = int(get_tree().root.get_meta("fx", 0)) == 1
	mode = int(get_tree().root.get_meta("mode", 0))
	var win: Window = get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_size = Vector2i(640, 360)
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	Engine.physics_ticks_per_second = 30 if low else 60
	Blood = load("res://blood.gd")
	Sfx = load("res://sfx.gd")
	Weapons = load("res://weapons.gd")
	WeaponArt = load("res://weapon_art.gd")
	Actor = load("res://actor.gd")
	Piece = load("res://piece.gd")
	Hud = load("res://hud.gd")
	Figure = load("res://figure.gd")
	Thrown = load("res://thrown.gd")
	Exec = load("res://exec.gd")
	map_i = int(get_tree().root.get_meta("map_i", 0))
	if mode == 1:
		map_i = 0
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
	exec = Exec.new()
	exec.main = self
	add_child(exec)
	if mode == 2:
		php = 250.0
		for i in weapons.list.size():
			if weapons.list[i]["nome"] == "Minigun":
				weapons.select(i)
		timer_t = 75.0
	elif mode == 0:
		timer_t = 90.0
	php_max = php
	_spawn_wave()
	_make_ui()
	if not bad_opt.is_empty():
		warn_label.text = "AVISO: nao carregou " + ", ".join(bad_opt)
	get_viewport().size_changed.connect(_layout)
	_layout()
	msg(_objective())


func _objective() -> String:
	if mode == 0:
		return "MATE TODOS ANTES DO TEMPO"
	if mode == 1:
		return "MATE A FAMILIA EM SILENCIO"
	if mode == 2:
		return "MINIGUN. LIMPE O LUGAR"
	return "ELIMINE OS TERRORISTAS"


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
		if not low:
			var oc := LightOccluder2D.new()
			var poly := OccluderPolygon2D.new()
			poly.polygon = PackedVector2Array([Vector2(0, 0), Vector2(r.size.x, 0), r.size, Vector2(0, r.size.y)])
			oc.occluder = poly
			b.add_child(oc)
	if kind == "":
		var face := ColorRect.new()
		face.color = Color(col.r * 0.55, col.g * 0.55, col.b * 0.55, 1.0)
		face.position = Vector2(0, r.size.y)
		face.size = Vector2(r.size.x, 5.0)
		b.add_child(face)
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
	if not low:
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
	blood.disp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wall_blood.disp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	wall_blood.wall_rects = solids
	if Nav != null:
		nav = Nav.new()
		nav.build(Vector2(mw, mh), solids)


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
	art = WeaponArt.new()
	player.add_child(art)
	fig = Figure.new()
	fig.skin = Color(0.90, 0.75, 0.60)
	fig.shirt = Color(0.18, 0.40, 0.72)
	fig.pants = Color(0.14, 0.14, 0.20)
	fig.hair = Color(0.15, 0.09, 0.05)
	fig.hair_style = 0
	player.add_child(fig)
	if not low:
		light = PointLight2D.new()
		light.texture = soft
		light.texture_scale = 6.0
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


func _hold_for(a: int) -> String:
	if a == 0 or a == 19:
		return "one"
	if a == 18:
		return "dual"
	if a in [3, 5, 6, 11, 12, 15, 16, 17]:
		return "melee"
	return "two"


func _free_spot() -> Vector2:
	if nav != null:
		for i in 25:
			var p: Vector2 = nav.rand_free()
			if p.distance_to(player.global_position) > 350.0:
				return p
		return nav.rand_free()
	return Vector2(randf_range(100.0, mw - 100.0), randf_range(100.0, mh - 100.0))


func _make_civ(pos: Vector2, sleeping: bool):
	var a = Actor.new()
	add_child(a)
	a.setup(self, pos)
	a.sleeping = sleeping
	if sleeping:
		a.rotation = randf() * TAU
		a.face = a.rotation
	a.refresh()
	actors.append(a)
	return a


func _spawn_wave() -> void:
	if mode == 3:
		for i in 5:
			var h = _make_civ(_free_spot(), false)
			h.hostage = true
		for i in 3:
			var ter = _make_civ(_free_spot(), false)
			ter.terror = true
			ter.hp = 60.0
			ter.hp0 = 60.0
			ter.shirt = Color(0.45, 0.08, 0.08)
			ter.refresh()
		return
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
	if police_called:
		return
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
		a.hp0 = 70.0
		a.shirt = Color(0.10, 0.20, 0.50)
		a.skin = Color(0.85, 0.70, 0.58)
		a.hair = Color(0.10, 0.08, 0.06)
		a.refresh()
		actors.append(a)
	police_called = true
	msg("ELES CHEGARAM")
	sfx.play("recarga", 0.5)


func civis_count() -> int:
	var n := 0
	for a in actors:
		if not a.cop and not a.terror:
			n += 1
	return n


func terror_count() -> int:
	var n := 0
	for a in actors:
		if a.terror:
			n += 1
	return n


func in_smoke(p: Vector2) -> bool:
	for s in smokes:
		if is_instance_valid(s) and s.state == "smoke" and s.position.distance_to(p) < 62.0:
			return true
	return false


func add_noise(v: float) -> void:
	noise = minf(120.0, noise + v)


func msg(t: String) -> void:
	msg_label.text = t
	msg_t = 3.0


func _btn(parent: Node, txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 9)
	b.pressed.connect(cb)
	parent.add_child(b)
	ui_buttons.append(b)
	return b


func _make_ui() -> void:
	if fx:
		var fl := CanvasLayer.new()
		fl.layer = 2
		add_child(fl)
		var cr := ColorRect.new()
		cr.set_anchors_preset(Control.PRESET_FULL_RECT)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sm := ShaderMaterial.new()
		sm.shader = load("res://pixel_fx.gdshader")
		cr.material = sm
		fl.add_child(cr)
	var cl := CanvasLayer.new()
	cl.layer = 5
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
	name_label.add_theme_font_size_override("font_size", 10)
	cl.add_child(name_label)
	warn_label = Label.new()
	warn_label.add_theme_font_size_override("font_size", 9)
	warn_label.position = Vector2(6, 64)
	cl.add_child(warn_label)
	debug_label = Label.new()
	debug_label.add_theme_font_size_override("font_size", 9)
	debug_label.visible = false
	debug_label.position = Vector2(6, 80)
	cl.add_child(debug_label)
	pause_label = Label.new()
	pause_label.text = "PAUSADO"
	pause_label.visible = false
	pause_label.add_theme_font_size_override("font_size", 24)
	cl.add_child(pause_label)
	msg_label = Label.new()
	msg_label.add_theme_font_size_override("font_size", 18)
	cl.add_child(msg_label)
	_btn(cl, "<", func(): weapons.select(weapons.idx - 1))
	_btn(cl, ">", func(): weapons.select(weapons.idx + 1))
	_btn(cl, "R", func(): weapons.manual_reload())
	_btn(cl, "EXEC", _exec_btn)
	_btn(cl, "ITEM", func(): item_i = (item_i + 1) % items.size())
	_btn(cl, "LANCAR", throw_item)
	_btn(cl, "MODO", _next_mode)
	_btn(cl, "MAPA", _next_map)
	luz_btn = _btn(cl, "LUZ", _toggle_gfx)
	luz_btn.text = "LUZ:N" if low else "LUZ:S"
	var fxb := _btn(cl, "FX", _toggle_fx)
	fxb.text = "FX:S" if fx else "FX:N"
	_btn(cl, "DBG", func(): debug_label.visible = not debug_label.visible)
	_btn(cl, "II", _toggle_pause)
	_btn(cl, "NOVO", _restart)


func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	var bw := 46.0
	var bh := 24.0
	var cols := 6
	var i := 0
	for b in ui_buttons:
		var col: int = i % cols
		var row: int = int(i / cols)
		b.size = Vector2(bw, bh)
		b.position = Vector2(vs.x - 6.0 - (bw + 4.0) * float(col + 1) + 4.0, 6.0 + (bh + 4.0) * float(row))
		i += 1
	name_label.position = Vector2(6, 4)
	pause_label.position = Vector2(vs.x * 0.5 - 60.0, vs.y * 0.5 - 20.0)
	msg_label.position = Vector2(vs.x * 0.5 - 130.0, vs.y * 0.3)


func _next_map() -> void:
	get_tree().root.set_meta("map_i", (map_i + 1) % MAP_IDS.size())
	_restart()


func _next_mode() -> void:
	get_tree().root.set_meta("mode", (mode + 1) % MODE_NAMES.size())
	_restart()


func _toggle_gfx() -> void:
	get_tree().root.set_meta("gfx", 1 if low else 0)
	_restart()


func _toggle_fx() -> void:
	get_tree().root.set_meta("fx", 0 if fx else 1)
	_restart()


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_label.visible = get_tree().paused


func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func throw_item() -> void:
	if pdead or exec.busy:
		return
	var it: Dictionary = items[item_i]
	if int(it["c"]) <= 0:
		msg("SEM ITEM")
		return
	it["c"] = int(it["c"]) - 1
	var t = Thrown.new()
	t.main = self
	t.kind = str(it["n"])
	t.position = player.global_position + aim_v * 16.0
	t.vel = aim_v * 320.0
	add_child(t)
	sfx.play("swish")


func _exec_btn() -> void:
	if exec.busy or pdead:
		return
	var best = null
	var bd := 50.0
	for a in actors:
		if a.dead or a.held:
			continue
		var d: float = a.global_position.distance_to(player.global_position)
		if d < bd and (a.sleeping or a.legs_dmg >= 40.0 or a.stun > 0.0 or a.hp < 14.0):
			bd = d
			best = a
	if best == null:
		msg("SEM ALVO")
		return
	if not exec.begin(best, str(weapons.cur()["nome"])):
		msg("SEM EXECUCAO")


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
			move_v = ((e.position - move_o) / 36.0).limit_length(1.0)
		elif e.index == aim_t:
			aim_pos = e.position
			var d: Vector2 = e.position - aim_o
			if d.length() > 6.0:
				aim_v = d.normalized()
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_Q:
			weapons.select(weapons.idx - 1)
		elif e.keycode == KEY_E:
			weapons.select(weapons.idx + 1)
		elif e.keycode == KEY_R:
			weapons.manual_reload()
		elif e.keycode == KEY_F:
			_exec_btn()
		elif e.keycode == KEY_G:
			throw_item()
		elif e.keycode == KEY_P:
			_toggle_pause()


func hurt_player(d: float) -> void:
	if pdead:
		return
	php -= d
	flash_a = 0.45
	shake(4.0)
	fig.kick = Vector2.from_angle(randf() * TAU) * 3.0
	blood.stamp(player.global_position, Vector2(0.3, 0.3), randf() * TAU)
	blood.spray(player.global_position, Vector2.from_angle(randf() * TAU), 5, 0.8)
	if php <= 0.0:
		pdead = true
		death_t = 2.5
		fig.dead = true
		fig.fall_t = 0.25
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


func _update_label() -> void:
	var w: Dictionary = weapons.cur()
	var am := ""
	if w["melee"]:
		am = "corpo a corpo"
	else:
		var nm: String = w["nome"]
		am = "%d/%d" % [int(weapons.ammo[nm]), int(weapons.reserve[nm])]
		if weapons.reload_t > 0.0:
			am += " recarregando"
	var extra := ""
	if mode == 1:
		extra = "ruido %d%%" % int(noise)
	elif mode == 3:
		extra = "refens mortos %d/2 terroristas %d" % [hostages_dead, terror_count()]
	elif timer_t > 0.0 and not police_called:
		extra = "tempo %d" % int(timer_t)
	var it: Dictionary = items[item_i]
	name_label.text = "HP %d  %s  %s\n%s  %s  civis %d  item %s x%d" % [int(php), w["nome"], am, MODE_NAMES[mode], extra, civis_count(), it["n"], int(it["c"])]


func _horde_logic(delta: float) -> void:
	if timer_t > 0.0 and not police_called:
		timer_t -= delta
		if timer_t <= 0.0:
			call_police()
	if mode == 1 and not police_called and noise >= 100.0:
		msg("OUVIRAM TUDO")
		call_police()
	if not police_called and civis_count() == 0 and not ended:
		if mode == 1:
			_finish_halloween()
		else:
			clear_t += delta
			if clear_t > 2.0:
				call_police()
	if police_called and actors.is_empty() and not ended:
		ended = true
		end_t = 4.0
		msg("NAO SOBROU NINGUEM")
	if ended:
		end_t -= delta
		if end_t <= 0.0:
			_restart()


func _finish_halloween() -> void:
	ended = true
	end_t = 5.0
	var sil: int = 100 - int(noise_max)
	var pts: int = sil * 5 + maxi(0, 300 - int(elapsed))
	var g := "C"
	if pts >= 750:
		g = "S"
	elif pts >= 600:
		g = "A"
	elif pts >= 450:
		g = "B"
	msg("NOTA %s  silencio %d%%" % [g, sil])


func _resgate_logic(delta: float) -> void:
	if not ended:
		if terror_count() == 0:
			ended = true
			end_t = 4.0
			msg("RESGATE CONCLUIDO")
		elif hostages_dead >= 2:
			ended = true
			end_t = 4.0
			msg("REFENS MORTOS")
	else:
		end_t -= delta
		if end_t <= 0.0:
			_restart()


func _selftest(delta: float) -> void:
	st_t += delta
	var best = null
	var bd := 1000000.0
	for a in actors:
		var d: float = a.global_position.distance_to(player.global_position)
		if d < bd and not a.dead:
			bd = d
			best = a
	if best != null:
		aim_v = (best.global_position - player.global_position).normalized()
		if bd > 60.0 and not exec.busy:
			player.global_position = player.global_position.move_toward(best.global_position, 120.0 * delta)
	firing = true
	var wi: int = int(st_t / 1.0) % weapons.list.size()
	if wi != st_w:
		st_w = wi
		weapons.select(wi)
	var si: int = int(st_t * 2.0)
	if si != st_i:
		st_i = si
		if si % 4 == 0:
			item_i = (item_i + 1) % items.size()
			items[item_i]["c"] = 3
			throw_item()
		if si % 9 == 0 and best != null:
			best.sleeping = true
			_exec_btn()
	if st_t > 8.0 and not police_called and mode != 3:
		call_police()


func _physics_process(delta: float) -> void:
	flash_a = maxf(0.0, flash_a - delta * 1.5)
	white_a = maxf(0.0, white_a - delta * 1.2)
	if flash_a > 0.0 or white_a > 0.0 or last_flash > 0.0:
		if white_a > 0.0:
			dmg_rect.color = Color(1, 1, 1, white_a)
		else:
			dmg_rect.color = Color(0.7, 0.0, 0.0, flash_a)
	last_flash = maxf(flash_a, white_a)
	decoy_t = maxf(0.0, decoy_t - delta)
	noise = maxf(0.0, noise - delta * 1.5)
	noise_max = maxf(noise_max, noise)
	if pdead:
		death_t -= delta
		if death_t <= 0.0:
			_restart()
		return
	if exec.busy:
		exec.update(delta)
		fig.moving = false
		player.velocity = Vector2.ZERO
		return
	var mv := move_v
	if not touch_mode:
		mv = Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)), float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
		aim_v = (get_global_mouse_position() - player.global_position).normalized()
		firing = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if selftest:
		_selftest(delta)
	var w: Dictionary = weapons.cur()
	player.velocity = mv.limit_length(1.0) * 170.0 * (0.7 + 0.3 * float(w["peso"]))
	player.move_and_slide()
	player.rotation = aim_v.angle()
	fig.moving = mv.length() > 0.1
	fig.phase += player.velocity.length() * delta * 0.12
	fig.hold = _hold_for(art.art)
	fig.swing = art.swing
	fig.recoil = art.recoil
	fig.blood = clampf(1.0 - php / php_max, 0.0, 1.0)
	if light != null:
		light.energy = lerpf(light.energy, 1.3, 0.15)
	weapons.update(delta, firing, aim_v, player.global_position + aim_v * 14.0)
	_update_pieces()
	_update_corpses(delta)
	elapsed += delta
	if mode == 3:
		_resgate_logic(delta)
	else:
		_horde_logic(delta)
	hud_t -= delta
	if hud_t <= 0.0:
		hud_t = 0.2
		_update_label()


func _process(delta: float) -> void:
	var vs := get_viewport().get_visible_rect().size
	var land := vs.x > vs.y
	cam.zoom = Vector2.ONE * (0.8 if land else 1.2)
	var look := 70.0
	if weapons.cur()["nome"] == "Sniper":
		look = 170.0
	var target := player.global_position + aim_v * look
	var np: Vector2 = cam.global_position.lerp(target, 1.0 - exp(-8.0 * delta))
	cam.global_position = Vector2(roundf(np.x), roundf(np.y))
	shake_v = maxf(0.0, shake_v - delta * 30.0)
	cam.offset = Vector2(roundf(randf_range(-1.0, 1.0) * shake_v), roundf(randf_range(-1.0, 1.0) * shake_v))
	msg_t -= delta
	if msg_t <= 0.0 and not pdead and not ended:
		msg_label.text = ""
	if debug_label.visible:
		debug_label.text = "FPS %d  luz %s fx %s\nmapa %s modo %s\nautores %d  pedacos %d\ngotas %d  fila %d  carimbos %d" % [Engine.get_frames_per_second(), "n" if low else "s", "s" if fx else "n", str(map.get("name", "?")), MODE_NAMES[mode], actors.size(), pieces.size(), blood.drops.size(), blood.queue.size(), blood.live.size()]


func shake(v: float) -> void:
	shake_v = maxf(shake_v, v)


func shoot_fx() -> void:
	if light != null:
		light.energy = 2.6
	art.flash = 0.06
	art.recoil = 1.0
	add_noise(4.0)
	shake(1.5)


func on_death(a, dir: Vector2, over: float) -> void:
	actors.erase(a)
	kills += 1
	add_noise(3.0)
	if a.hostage:
		hostages_dead += 1
		msg("REFEM MORTO")
	corpses.append({"n": a, "t": 12.0})
	blood.spray(a.global_position, dir, 14, 1.0)
	blood.stamp(a.global_position, Vector2(0.9, 0.7), randf() * TAU)
	if over > 15.0:
		for i in int(clampf(over / 20.0, 1.0, 5.0)):
			spawn_piece("meat", a.global_position, dir, a.skin, a.hair)
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
	if pieces.size() > 60:
		var old = pieces.pop_front()
		old.queue_free()


func _update_pieces() -> void:
	for p in pieces:
		if is_instance_valid(p) and p.linear_velocity.length() > 25.0 and randf() < 0.4:
			blood.stamp(p.global_position + Vector2(randf_range(-4, 4), randf_range(-4, 4)), Vector2(0.14, 0.14), randf() * TAU)


func _update_corpses(delta: float) -> void:
	var keep: Array = []
	for c in corpses:
		c["t"] -= delta
		if c["t"] > 0.0 and is_instance_valid(c["n"]):
			if randf() < 0.2:
				var age: float = 1.0 - float(c["t"]) / 12.0
				var col := Color(0.5 - 0.18 * age, 0.0, 0.04, 0.9)
				var p: Vector2 = c["n"].global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12))
				blood.stamp(p, Vector2(0.35 + randf() * 0.45, 0.35 + randf() * 0.45), randf() * TAU, col)
			keep.append(c)
	corpses = keep
