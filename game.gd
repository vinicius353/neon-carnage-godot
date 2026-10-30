extends Node2D
# Jogo: mundo, jogador, câmera, interface, modos, itens e execuções. Estilo pixel (640x360).

const MAP_IDS := ["casa", "banco", "hospital", "mercado"]
const MODE_NAMES := ["MASSACRE", "HALLOWEEN", "JUGGERNAUT", "RESGATE"]
const CORPSE_MAX := 80
const BLOOD_ART := Color(0.60, 0.02, 0.05, 0.95)
const BLOOD_VEN := Color(0.26, 0.00, 0.02, 0.95)
const BLOOD_DRY := Color(0.24, 0.04, 0.03, 0.92)
const PROPCOL := {"bed": Color(0.78, 0.74, 0.68), "sofa": Color(0.40, 0.12, 0.16), "tv": Color(0.05, 0.07, 0.10), "tbl": Color(0.40, 0.28, 0.17), "chr": Color(0.48, 0.35, 0.20), "cnt": Color(0.65, 0.63, 0.58), "stv": Color(0.75, 0.75, 0.76), "fri": Color(0.85, 0.86, 0.86), "bks": Color(0.25, 0.17, 0.10), "wrd": Color(0.29, 0.20, 0.14), "dsk": Color(0.35, 0.25, 0.15), "plt": Color(0.18, 0.42, 0.20), "tub": Color(0.85, 0.90, 0.91), "toi": Color(0.93, 0.93, 0.93), "wsh": Color(0.80, 0.82, 0.83), "cab": Color(0.35, 0.23, 0.15), "fpl": Color(0.42, 0.25, 0.21), "nst": Color(0.35, 0.24, 0.15), "mac": Color(0.70, 0.75, 0.77), "prt": Color(0.35, 0.35, 0.38), "c": Color(0.42, 0.29, 0.17),
	"rug": Color(0.28, 0.13, 0.15), "crt": Color(0.56, 0.43, 0.27), "chr2": Color(0.42, 0.30, 0.18), "gur": Color(0.72, 0.74, 0.76),
	"iv": Color(0.80, 0.82, 0.84), "pic": Color(0.30, 0.24, 0.16), "lam": Color(0.55, 0.50, 0.35), "pan": Color(0.30, 0.31, 0.33), "bld": Color(0, 0, 0)}

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
var splats: Array = []
var hit_t := 0.0
var hitstop_until := 0
var dmg_dir := Vector2.ZERO
var dmg_t := 0.0
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
var smoke_t := 2.0
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
var stat_label: Label
var count_label: Label
var debug_label: Label
var pause_label: Label
var msg_label: Label
var warn_label: Label
var dmg_rect: ColorRect
var luz_btn: Button
var weapon_t := 0.0
var pause_panel: Control
var end_panel: Control
var end_title: Label
var end_info: Label
var end_shown := false
var st_t := 0.0
var st_w := -1
var st_i := -1


func _ready() -> void:
	randomize()
	Engine.time_scale = 1.0
	selftest = OS.get_cmdline_user_args().has("selftest")
	low = true
	fx = int(get_tree().root.get_meta("fx", 0)) == 1
	mode = int(get_tree().root.get_meta("mode", 0))
	var win: Window = get_window()
	# Desenho em resolução nativa: o mundo continua em 640x360 (mesmas coordenadas,
	# mesmo gameplay), mas texto, formas e respingos são rasterizados no tamanho real
	# da tela em vez de serem esticados a partir de um frame 640x360.
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
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
	weapon_t = 0.0
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
	splats = _make_splats()


func _make_splats() -> Array:
	# Respingos irregulares gerados na hora: mancha de borda rasgada + gotas soltas.
	# Cada textura é diferente — antes a variável de imagem ficava fora do laço e o
	# jogo usava praticamente uma mancha só, o que deixava todo respingo idêntico.
	var out: Array = []
	for v in 6:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 0))
		var p0 := randf() * TAU
		var p1 := randf() * TAU
		var p2 := randf() * TAU
		var w0 := 1.0 + randf() * 2.0
		var w1 := 2.0 + randf() * 3.0
		var w2 := 4.0 + randf() * 4.0
		for y in 64:
			for x in 64:
				var dx := (float(x) - 31.5) / 32.0
				var dy := (float(y) - 31.5) / 32.0
				var d := sqrt(dx * dx + dy * dy)
				var ang := atan2(dy, dx)
				var wob := sin(ang * w0 + p0) * 0.11 + sin(ang * w1 + p1) * 0.06 + sin(ang * w2 + p2) * 0.035
				var lim := 0.70 + wob
				# Borda nítida: sangue espalhado tem contorno definido, não esfumaçado.
				# O miolo sai denso e a beirada vira película fina — o shader lê a densidade.
				var e: float = clampf((lim - d) / 0.045, 0.0, 1.0)
				var a: float = e * (0.42 + 0.58 * clampf((lim - d) / maxf(0.05, lim * 0.7), 0.0, 1.0))
				if a > 0.01:
					img.set_pixel(x, y, Color(1, 1, 1, a))
		# gotas satélite: arremesso nenhum é uma mancha só
		for i in 12:
			var sa := randf() * TAU
			var sr := 0.80 + randf() * 0.45
			var cx := 31.5 + cos(sa) * sr * 27.0
			var cy := 31.5 + sin(sa) * sr * 27.0
			var rr := 0.7 + randf() * 2.2
			var al := randf_range(0.45, 0.95)
			var x0 := maxi(0, int(cx - rr - 1.0))
			var x1 := mini(63, int(cx + rr + 1.0))
			var y0 := maxi(0, int(cy - rr - 1.0))
			var y1 := mini(63, int(cy + rr + 1.0))
			for yy in range(y0, y1 + 1):
				for xx in range(x0, x1 + 1):
					var ddx := float(xx) - cx
					var ddy := float(yy) - cy
					var dd := sqrt(ddx * ddx + ddy * ddy)
					if dd <= rr:
						# a 1 px do chão a gota não borra: borda dura
						var aa: float = clampf((rr - dd) / 0.8, 0.0, 1.0) * al
						if img.get_pixel(xx, yy).a < aa:
							img.set_pixel(xx, yy, Color(1, 1, 1, aa))
		out.append(ImageTexture.create_from_image(img))
	return out



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
	elif kind == "rug":
		# Tapete: listras gastadas, sem colisão (dá para pisar e escorregar nele).
		for i in 4:
			var st := ColorRect.new()
			st.color = col.lightened(0.22)
			st.position = Vector2(8.0 + float(i) * (r.size.x - 16.0) / 4.0, 8.0)
			st.size = Vector2(3.0, r.size.y - 16.0)
			b.add_child(st)
	elif kind == "crt":
		# Caixa de papelão com fita.
		var tp := ColorRect.new()
		tp.color = Color(0.72, 0.66, 0.55)
		tp.position = Vector2(2.0, r.size.y * 0.5 - 2.0)
		tp.size = Vector2(r.size.x - 4.0, 4.0)
		b.add_child(tp)
	elif kind == "chr2":
		# Cadeira caída: assento de um lado, encosto para o outro.
		var st2 := ColorRect.new()
		st2.color = col.lightened(0.16)
		st2.size = Vector2(r.size.x * 0.6, r.size.y * 0.6)
		b.add_child(st2)
		var bk2 := ColorRect.new()
		bk2.color = col.darkened(0.24)
		bk2.position = Vector2(r.size.x * 0.6, 0)
		bk2.size = Vector2(r.size.x * 0.4, r.size.y)
		b.add_child(bk2)
	elif kind == "gur":
		# Maca de hospital: colchão claro e rodinhas.
		var mt := ColorRect.new()
		mt.color = Color(0.90, 0.90, 0.88)
		mt.position = Vector2(3, 3)
		mt.size = r.size - Vector2(6, 6)
		b.add_child(mt)
		for i in 2:
			var wl := ColorRect.new()
			wl.color = Color(0.25, 0.25, 0.28)
			wl.position = Vector2(4.0 + float(i) * (r.size.x - 12.0), r.size.y - 4.0)
			wl.size = Vector2(8, 4)
			b.add_child(wl)
	elif kind == "iv":
		# Suporte de soro.
		var pole := ColorRect.new()
		pole.color = Color(0.70, 0.72, 0.75)
		pole.position = Vector2(r.size.x * 0.5 - 1.5, 0)
		pole.size = Vector2(3.0, r.size.y)
		b.add_child(pole)
		var bag := ColorRect.new()
		bag.color = Color(0.90, 0.92, 0.86, 0.92)
		bag.position = Vector2(r.size.x * 0.5 - 5.0, 4)
		bag.size = Vector2(10, 14)
		b.add_child(bag)
	elif kind == "pic":
		# Quadro caído no chão.
		var gl := ColorRect.new()
		gl.color = Color(0.16, 0.20, 0.26)
		gl.position = Vector2(3, 3)
		gl.size = r.size - Vector2(6, 6)
		b.add_child(gl)
	elif kind == "pan":
		var gl2 := ColorRect.new()
		gl2.color = col.lightened(0.30)
		gl2.position = Vector2(r.size.x * 0.25, r.size.y * 0.25)
		gl2.size = r.size * 0.5
		b.add_child(gl2)
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
	blood.setup(Vector2i(int(mw), int(mh)), -10, soft, splats)
	wall_blood = Blood.new()
	add_child(wall_blood)
	wall_blood.setup(Vector2i(int(mw), int(mh)), 1, soft, splats)
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
		if kind == "bld":
			# Sangue antigo já no cenário: cada mapa é uma cena de crime.
			blood.stamp(r2.get_center(), Vector2(maxf(0.5, r2.size.x / 95.0), maxf(0.45, r2.size.y / 95.0)), randf() * TAU, BLOOD_DRY)
			continue
		var solid: bool = kind != "bed" and kind != "rug"
		_block(r2, PROPCOL.get(kind, Color(0.4, 0.3, 0.2)), solid, kind)
		if solid:
			solids.append(r2)
	blood.set_walls(solids)
	wall_blood.set_walls(solids)
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


func _room_spot() -> Vector2:
	# Spawn dentro de cômodos de verdade (em vez de ponto solto no mapa).
	var rooms: Array = map.get("rooms", [])
	if rooms.is_empty():
		return _free_spot()
	for i in 14:
		var r: Array = rooms[randi() % rooms.size()]
		var p := Vector2(randf_range(float(r[0]) + 28.0, float(r[0]) + float(r[2]) - 28.0), randf_range(float(r[1]) + 28.0, float(r[1]) + float(r[3]) - 28.0))
		if nav != null:
			p = nav.nearest_free(p)
		if p.distance_to(player.global_position) > 320.0:
			return p
	return _free_spot()


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
			var h = _make_civ(_room_spot(), false)
			h.hostage = true
		for i in 3:
			var ter = _make_civ(_room_spot(), false)
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
		_make_civ(_room_spot(), false)
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


func _prune_smokes() -> void:
	if smokes.is_empty():
		return
	var keep: Array = []
	for s in smokes:
		if is_instance_valid(s):
			keep.append(s)
	smokes = keep


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


func _btn(parent: Node, txt: String, cb: Callable, hot: bool = false) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color(0.96, 0.93, 0.89))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.90, 0.86))
	var base := Color(0.42, 0.045, 0.05, 0.82) if hot else Color(0.06, 0.05, 0.055, 0.72)
	var edge := Color(1.0, 0.40, 0.32, 0.85) if hot else Color(0.86, 0.72, 0.66, 0.42)
	b.add_theme_stylebox_override("normal", _round_box(base, edge))
	b.add_theme_stylebox_override("hover", _round_box(base.lightened(0.12), edge))
	b.add_theme_stylebox_override("pressed", _round_box(base.lightened(0.30), edge.lightened(0.35)))
	b.pressed.connect(cb)
	b.pressed.connect(func(): if sfx != null: sfx.play("ui", 1.1))
	parent.add_child(b)
	ui_buttons.append(b)
	return b


func _round_box(bg: Color, edge: Color) -> StyleBoxFlat:
	# Botão redondo: raio 23 = metade do lado 46 usado pelo layout de anel.
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(23)
	return sb


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
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.88))
	cl.add_child(name_label)
	stat_label = Label.new()
	stat_label.add_theme_font_size_override("font_size", 9)
	stat_label.add_theme_color_override("font_color", Color(0.92, 0.60, 0.55))
	cl.add_child(stat_label)
	count_label = Label.new()
	count_label.add_theme_font_size_override("font_size", 9)
	count_label.add_theme_color_override("font_color", Color(0.80, 0.78, 0.74))
	cl.add_child(count_label)
	warn_label = Label.new()
	warn_label.add_theme_font_size_override("font_size", 9)
	cl.add_child(warn_label)
	debug_label = Label.new()
	debug_label.add_theme_font_size_override("font_size", 9)
	debug_label.visible = false
	cl.add_child(debug_label)
	msg_label = Label.new()
	msg_label.add_theme_font_size_override("font_size", 18)
	cl.add_child(msg_label)
	_btn(cl, "<", func(): weapons.select(weapons.idx - 1))
	_btn(cl, ">", func(): weapons.select(weapons.idx + 1))
	_btn(cl, "REC", func(): weapons.manual_reload())
	_btn(cl, "EXEC", _exec_btn, true)
	_btn(cl, "ITEM", func(): item_i = (item_i + 1) % items.size())
	_btn(cl, "USA", throw_item)
	_btn(cl, "II", _toggle_pause)
	pause_panel = _make_panel(cl, 200.0, 170.0)
	var pl := Label.new()
	pl.text = "PAUSADO"
	pl.add_theme_font_size_override("font_size", 16)
	pl.position = Vector2(15, 8)
	pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.add_child(pl)
	_panel_btn(pause_panel, "CONTINUAR", _toggle_pause, 38.0)
	_panel_btn(pause_panel, "NOVO", _restart, 64.0)
	_panel_btn(pause_panel, "TROCAR MAPA", _next_map, 90.0)
	_panel_btn(pause_panel, "TROCAR MODO", _next_mode, 116.0)
	_panel_btn(pause_panel, "MENU", _to_menu, 142.0)
	end_panel = _make_panel(cl, 260.0, 140.0)
	end_title = Label.new()
	end_title.add_theme_font_size_override("font_size", 16)
	end_title.position = Vector2(15, 8)
	end_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_panel.add_child(end_title)
	end_info = Label.new()
	end_info.add_theme_font_size_override("font_size", 9)
	end_info.position = Vector2(15, 32)
	end_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_panel.add_child(end_info)
	_panel_btn(end_panel, "NOVO", _restart, 62.0)
	_panel_btn(end_panel, "MENU", _to_menu, 88.0)


func _aim_center(vs: Vector2) -> Vector2:
	# Centro do analógico de mirar: é o eixo do anel de botões e o ponto onde o
	# polegar direito descansa por padrão.
	return Vector2(vs.x - 108.0, vs.y - 108.0)


func _layout() -> void:
	# Celular: o polegar direito mora no analógico de mirar, então as ações formam
	# um anel em volta dele — arma, recarga, execução, item e arremesso ficam a um
	# deslize do dedo, sem soltar o stick.
	var vs := get_viewport().get_visible_rect().size
	var center := _aim_center(vs)
	if ui_buttons.size() >= 7:
		var dia := 46.0
		for i in 6:
			var b: Button = ui_buttons[i]
			var ang := deg_to_rad(163.0 + 25.4 * float(i))
			var c: Vector2 = center + Vector2.from_angle(ang) * 104.0
			b.size = Vector2(dia, dia)
			b.position = c - Vector2(dia, dia) * 0.5
			b.set_meta("hit", dia * 0.5 + 5.0)
		ui_buttons[6].size = Vector2(46, 46)
		ui_buttons[6].position = Vector2(vs.x - 56, 8)
		ui_buttons[6].set_meta("hit", 28.0)
	name_label.position = Vector2(8, 22)
	stat_label.position = Vector2(8, 37)
	count_label.position = Vector2(8, 51)
	warn_label.position = Vector2(8, 68)
	debug_label.position = Vector2(8, 92)
	msg_label.position = Vector2(vs.x * 0.5 - 150.0, vs.y * 0.30)
	msg_label.size = Vector2(300, 24)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pause_panel != null:
		pause_panel.position = Vector2(vs.x * 0.5 - pause_panel.size.x * 0.5, vs.y * 0.5 - pause_panel.size.y * 0.5)
	if end_panel != null:
		end_panel.position = Vector2(vs.x * 0.5 - end_panel.size.x * 0.5, vs.y * 0.5 - end_panel.size.y * 0.5)


func _make_panel(parent: Node, w: float, h: float) -> Control:
	var p := Control.new()
	p.size = Vector2(w, h)
	p.visible = false
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(p)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.03, 0.94)
	bg.size = Vector2(w, h)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(bg)
	var line := ColorRect.new()
	line.color = Color(0.55, 0.05, 0.08, 0.9)
	line.size = Vector2(w, 2)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(line)
	return p


func _panel_btn(p: Control, txt: String, cb: Callable, y: float) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 10)
	b.size = Vector2(170, 22)
	b.position = Vector2(15, y)
	b.pressed.connect(cb)
	p.add_child(b)
	return b


func _show_end(t: String, info: String) -> void:
	if end_shown:
		return
	end_shown = true
	ended = true
	end_title.text = t
	end_info.text = info
	pause_panel.visible = false
	end_panel.visible = true
	get_tree().paused = true


func _next_map() -> void:
	get_tree().root.set_meta("map_i", (map_i + 1) % MAP_IDS.size())
	_restart()


func _next_mode() -> void:
	get_tree().root.set_meta("mode", (mode + 1) % MODE_NAMES.size())
	_restart()


func _toggle_pause() -> void:
	if end_shown:
		return
	var p: bool = not get_tree().paused
	get_tree().paused = p
	pause_panel.visible = p


func _to_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	var p = get_parent()
	if p != null and p.has_method("back_to_menu"):
		p.back_to_menu()
	else:
		_restart()


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
		var hr: float = float(b.get_meta("hit", 0.0))
		if hr > 0.0:
			# botão redondo acerta pelo círculo: os cantos da caixa não contam
			if b.get_global_rect().get_center().distance_to(p) <= hr:
				return true
		elif b.get_global_rect().grow(6.0).has_point(p):
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
			move_v = ((e.position - move_o) / 46.0).limit_length(1.0)
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
		elif e.keycode == KEY_F1:
			debug_label.visible = not debug_label.visible


func hurt_player(d: float, from: Vector2 = Vector2.ZERO) -> void:
	if pdead:
		return
	if from != Vector2.ZERO:
		dmg_dir = (player.global_position - from).normalized()
	php -= d
	flash_a = 0.45
	shake(4.0)
	fig.kick = Vector2.from_angle(randf() * TAU) * 3.0
	blood.splash(player.global_position, Vector2.from_angle(randf() * TAU), 0.75, BLOOD_ART)
	if php <= 0.0:
		pdead = true
		death_t = 2.5
		fig.dead = true
		fig.fall_t = 0.25
		fig.lie_sign = 1.0 if randf() < 0.5 else -1.0
		fig.fall_rot = 2.5 * fig.lie_sign
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
		hurt_player(8.0, from)


func on_hit() -> void:
	# marcador de acerto com som curto, sem metralhar o áudio ao acertar vários
	if hit_t <= 0.0 and sfx != null:
		sfx.play("hit", randf_range(0.92, 1.12))
	hit_t = 0.12


func hitstop(sec: float) -> void:
	# Congela por alguns milissegundos no impacto: dá peso ao golpe.
	if exec != null and exec.busy:
		return
	if hitstop_until > Time.get_ticks_msec():
		return
	hitstop_until = Time.get_ticks_msec() + int(sec * 1000.0)
	Engine.time_scale = 0.05


func _update_label() -> void:
	# Três linhas separadas: arma, situação do modo e contadores. Antes era tudo
	# numa linha só de 9 px, ilegível em tela de celular.
	var w: Dictionary = weapons.cur()
	var am := ""
	if w["melee"]:
		am = "CORPO A CORPO"
	else:
		var nm: String = w["nome"]
		am = "%d/%d" % [int(weapons.ammo[nm]), int(weapons.reserve[nm])]
		if weapons.reload_t > 0.0:
			am = "RECARREGANDO"
	name_label.text = "%s   %s" % [str(w["nome"]).to_upper(), am]
	var extra := ""
	if mode == 1:
		extra = "ruido %d%%" % int(noise)
	elif mode == 3:
		extra = "refens %d/2  terroristas %d" % [hostages_dead, terror_count()]
	elif timer_t > 0.0 and not police_called:
		extra = "tempo %d" % int(timer_t)
	stat_label.text = "%s   %s" % [MODE_NAMES[mode], extra]
	var it: Dictionary = items[item_i]
	count_label.text = "ABATES %d   CIVIS %d   %s x%d" % [kills, civis_count(), it["n"], int(it["c"])]


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
		msg("NAO SOBROU NINGUEM")
		_show_end("NAO SOBROU NINGUEM", "abates %d   tempo %ds" % [kills, int(elapsed)])


func _finish_halloween() -> void:
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
	_show_end("NOTA " + g, "silencio %d%%   pontos %d   tempo %ds" % [sil, pts, int(elapsed)])


func _resgate_logic(delta: float) -> void:
	if ended:
		return
	if terror_count() == 0:
		msg("RESGATE CONCLUIDO")
		_show_end("RESGATE CONCLUIDO", "abates %d   refens mortos %d" % [kills, hostages_dead])
	elif hostages_dead >= 2:
		msg("REFENS MORTOS")
		_show_end("REFENS MORTOS", "abates %d" % kills)


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
	hit_t = maxf(0.0, hit_t - delta)
	dmg_t = maxf(0.0, dmg_t - delta)
	if hitstop_until > 0 and Time.get_ticks_msec() >= hitstop_until:
		hitstop_until = 0
		if exec == null or not exec.busy:
			Engine.time_scale = 1.0
	if flash_a > 0.0 or white_a > 0.0 or last_flash > 0.0:
		if white_a > 0.0:
			dmg_rect.color = Color(1, 1, 1, white_a)
		else:
			dmg_rect.color = Color(0.7, 0.0, 0.0, flash_a)
	last_flash = maxf(flash_a, white_a)
	decoy_t = maxf(0.0, decoy_t - delta)
	smoke_t -= delta
	if smoke_t <= 0.0:
		smoke_t = 2.0
		_prune_smokes()
	noise = maxf(0.0, noise - delta * 1.5)
	noise_max = maxf(noise_max, noise)
	if pdead:
		death_t -= delta
		if death_t <= 0.0:
			_show_end("VOCE MORREU", "abates %d   tempo %ds" % [kills, int(elapsed)])
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
	fig.reload_p = art.reload_p
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
	weapon_t = maxf(0.0, weapon_t - delta)
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


func shoot_fx(peso: float = 1.0) -> void:
	if light != null:
		light.energy = 2.6
	art.flash = 0.06
	art.recoil = 1.0
	add_noise(3.0 + peso * 1.5)
	# Arma pesada chacoalha mais: dá peso ao tiro sem exagerar no leve.
	shake(0.8 + peso * 1.1)


func on_death(a, dir: Vector2, over: float) -> void:
	actors.erase(a)
	kills += 1
	add_noise(3.0)
	if a.hostage:
		hostages_dead += 1
		msg("REFEM MORTO")
	# O corpo fica para sempre: nada de cadáver evaporando na frente do jogador.
	corpses.append({"n": a, "pool": 0.0, "age": 0.0})
	blood.splash(a.global_position, dir, 1.5, BLOOD_ART)
	blood.stamp(a.global_position, Vector2(1.05, 0.85), randf() * TAU, BLOOD_ART)
	# jorro arterial: escorre para longe do corpo, no sentido do golpe
	blood.stamp(a.global_position + dir * randf_range(16.0, 30.0), Vector2(0.8, 0.3), dir.angle(), BLOOD_ART)
	hitstop(0.05)
	# abate violento empurra a câmera: fecha o golpe
	shake(3.0 + minf(over * 0.12, 5.0))
	if over > 8.0:
		for i in int(clampf(over / 16.0, 1.0, 6.0)):
			spawn_piece("meat", a.global_position, dir, a.skin, a.hair)
	if over > 26.0:
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
			blood.stamp(p.global_position + Vector2(randf_range(-4, 4), randf_range(-4, 4)), Vector2(0.14, 0.14), randf() * TAU, BLOOD_VEN)


func _update_corpses(delta: float) -> void:
	var keep: Array = []
	for c in corpses:
		var a = c["n"]
		if not is_instance_valid(a):
			continue
		# A poça embaixo do corpo cresce e seca com a idade, mas o corpo NUNCA
		# desaparece: só sai do mundo se passar do teto e já estar longe da câmera.
		c["pool"] += delta
		if float(c["pool"]) >= 0.6 and float(c["age"]) < 1.0:
			c["pool"] = 0.0
			c["age"] = minf(1.0, float(c["age"]) + 0.11)
			var age: float = c["age"]
			var r: float = 0.45 + age * 1.25
			var col := Color(0.46 - 0.16 * age, 0.0, 0.03, 0.9)
			var p: Vector2 = a.global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
			blood.stamp_lo(p, Vector2(r, r * randf_range(0.7, 1.0)), randf() * TAU, col)
			if age > 0.35 and randf() < 0.4:
				var ed: Vector2 = Vector2.from_angle(randf() * TAU)
				blood.stamp_lo(a.global_position + ed * randf_range(14.0, 32.0), Vector2(0.35, 0.17), ed.angle(), col)
		keep.append(c)
	corpses = keep
	while corpses.size() > CORPSE_MAX:
		var old = corpses[0]
		if not is_instance_valid(old["n"]):
			corpses.pop_front()
			continue
		if old["n"].global_position.distance_to(player.global_position) < 700.0:
			break
		corpses.pop_front()
		old["n"].queue_free()
