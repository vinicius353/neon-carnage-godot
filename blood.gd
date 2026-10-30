extends Node2D
# Camada de sangue em meia resolução: só redesenha quando há carimbos novos.
# Performance: pool de sprites (sem criar/destruir por carimbo), orçamento
# adaptativo ao tempo de frame, duas filas (combate > poças cosméticas) e
# teste de parede O(1) por grade.

const CELL := 24.0
const HI_MAX := 420
const LO_MAX := 240

var vp: SubViewport
var holder: Node2D
var disp: Sprite2D
var soft: GradientTexture2D
var splats: Array = []
var drops: Array = []
var queue: Array = []
var queue_lo: Array = []
var live: Array = []
var spare: Array = []
var spurts: Array = []
var wall_layer = null
var shown := false

var _rects: Array = []
var wall_rects: Array = []:
	set(v):
		_rects = v
		_build_grid()

var world := Vector2i(1600, 900)
var gcols := 0
var grows := 0
var grid := PackedByteArray()
var frame_avg := 0.016


func setup(sz: Vector2i, z: int, soft_tex: GradientTexture2D, splat_texs: Array = []) -> void:
	soft = soft_tex
	splats = splat_texs
	world = sz
	vp = SubViewport.new()
	vp.size = Vector2i(maxi(8, int(sz.x * 0.5)), maxi(8, int(sz.y * 0.5)))
	vp.transparent_bg = true
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	holder = Node2D.new()
	holder.scale = Vector2(0.5, 0.5)
	vp.add_child(holder)
	disp = Sprite2D.new()
	disp.texture = vp.get_texture()
	disp.centered = false
	disp.scale = Vector2(2, 2)
	disp.z_index = z
	disp.visible = false
	var mat := ShaderMaterial.new()
	mat.shader = load("res://blood.gdshader")
	disp.material = mat
	add_child(disp)


func set_walls(rects: Array) -> void:
	wall_rects = rects


func _build_grid() -> void:
	gcols = maxi(1, int(ceil(float(world.x) / CELL)))
	grows = maxi(1, int(ceil(float(world.y) / CELL)))
	grid = PackedByteArray()
	grid.resize(gcols * grows)
	grid.fill(0)
	for r in _rects:
		var rr: Rect2 = r if r is Rect2 else Rect2(r[0], r[1], r[2], r[3])
		var x0 := clampi(int(rr.position.x / CELL), 0, gcols - 1)
		var y0 := clampi(int(rr.position.y / CELL), 0, grows - 1)
		var x1 := clampi(int(rr.end.x / CELL), 0, gcols - 1)
		var y1 := clampi(int(rr.end.y / CELL), 0, grows - 1)
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				grid[y * gcols + x] = 1


func _in_wall(p: Vector2) -> bool:
	if gcols == 0:
		for r in _rects:
			var rr: Rect2 = r if r is Rect2 else Rect2(r[0], r[1], r[2], r[3])
			if rr.has_point(p):
				return true
		return false
	var x := int(p.x / CELL)
	var y := int(p.y / CELL)
	if x < 0 or y < 0 or x >= gcols or y >= grows:
		return false
	return grid[y * gcols + x] != 0


func stamp(pos: Vector2, sc: Vector2, rot: float, col: Color = Color(0.5, 0.0, 0.04, 0.9)) -> void:
	if queue.size() < HI_MAX:
		queue.append([pos, sc, rot, col])


func stamp_lo(pos: Vector2, sc: Vector2, rot: float, col: Color = Color(0.5, 0.0, 0.04, 0.9)) -> void:
	if queue.size() > HI_MAX - 140:
		return
	if queue_lo.size() < LO_MAX:
		queue_lo.append([pos, sc, rot, col])


func _tint(c: Color) -> Color:
	# Nenhum jato tem exatamente a mesma cor: oxigenado (vivo) x venoso (escuro)
	# variam a cada golpe — é isso que faz a mancha parecer suja e não pintada.
	return Color(clampf(c.r * randf_range(0.84, 1.10), 0.0, 1.0), c.g * randf_range(0.55, 1.25), c.b * randf_range(0.65, 1.40), c.a)


func splash(pos: Vector2, dir: Vector2, power: float = 1.0, col: Color = Color(0.46, 0.01, 0.025, 0.95)) -> void:
	# Padrão de impacto: poça irregular no ponto do golpe, estrias compridas no
	# sentido da força (cast-off) e névoa fina de gotas ao redor.
	var c := _tint(col)
	var a := dir.angle()
	stamp(pos, Vector2(0.24, 0.20) * power, randf() * TAU, c)
	for i in 2 + randi() % 2:
		var off: Vector2 = Vector2.from_angle(a + randf_range(-0.9, 0.9)) * randf_range(1.5, 6.0) * power
		stamp(pos + off, Vector2(0.12, 0.10) * power * randf_range(0.8, 1.5), randf() * TAU, c)
	for i in 2 + randi() % 3:
		var sa: float = a + randf_range(-0.55, 0.55)
		var sd: Vector2 = Vector2.from_angle(sa)
		for j in 2 + randi() % 2:
			var dist: float = (9.0 + randf() * 40.0) * power
			stamp(pos + sd * dist, Vector2(0.09 + randf() * 0.11, 0.04 + randf() * 0.045), sa, c)
	spray(pos, dir, int(clampf(4.0 + 6.0 * power, 4.0, 18.0)), power, c)


func spray(pos: Vector2, dir: Vector2, n: int, power: float, col: Color = Color(0.5, 0.0, 0.04, 0.9)) -> void:
	col = _tint(col)
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
		var s: float = (0.6 if back else 1.0) * power * (60.0 + pow(randf(), 2.2) * 520.0)
		drops.append({"p": pos, "v": Vector2.from_angle(a) * s, "l": randf_range(0.25, 0.7), "a": a, "s": s, "c": col})
	if drops.size() > 300:
		drops = drops.slice(drops.size() - 300)


func add_spurt(target: Node2D, off: Vector2, ang: float, dur: float) -> void:
	spurts.append({"t": target, "o": off, "a": ang, "d": dur * 1.4, "c": 0.0})


func _process(delta: float) -> void:
	frame_avg = lerpf(frame_avg, delta, 0.08)
	for s in live:
		s.visible = false
		spare.append(s)
	live.clear()
	if queue.is_empty() and queue_lo.is_empty():
		return
	var budget := _budget()
	var n := 0
	while n < budget and not queue.is_empty():
		_draw_stamp(queue.pop_front())
		n += 1
	while n < budget and not queue_lo.is_empty():
		_draw_stamp(queue_lo.pop_front())
		n += 1
	if n > 0:
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		if not shown:
			shown = true
			disp.visible = true


func _budget() -> int:
	if frame_avg > 0.032:
		return 8
	if frame_avg > 0.024:
		return 16
	if frame_avg > 0.019:
		return 24
	return 34


func _draw_stamp(q: Array) -> void:
	var sp: Sprite2D
	if spare.is_empty():
		sp = Sprite2D.new()
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		holder.add_child(sp)
	else:
		sp = spare.pop_back()
	sp.texture = soft if splats.is_empty() else splats[randi() % splats.size()]
	sp.position = q[0]
	sp.scale = q[1]
	sp.rotation = q[2]
	sp.modulate = q[3]
	sp.visible = true
	live.append(sp)


func _physics_process(delta: float) -> void:
	_update_drops(delta)
	_update_spurts(delta)


func _wall_splat(pos: Vector2, d: Dictionary) -> void:
	var a: float = float(d["a"])
	var col: Color = d["c"]
	var dir: Vector2 = Vector2.from_angle(a)
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	wall_layer.stamp(pos, Vector2(0.18 + randf() * 0.12, 0.14 + randf() * 0.10), a, col)
	for i in 4:
		var o: Vector2 = dir * (3.0 + float(i) * 5.0) + perp * randf_range(-4.0, 4.0)
		wall_layer.stamp(pos + o, Vector2(0.07, 0.05), a, col)
	if randf() < 0.5:
		wall_layer.stamp(pos - dir * 6.0, Vector2(0.05, 0.05), 0.0, col)
	# escorrido: sangue desce pela parede
	wall_layer.stamp_lo(pos + Vector2(randf_range(-3.0, 3.0), 6.0), Vector2(0.05, 0.22), 0.0, col)
	wall_layer.stamp_lo(pos + Vector2(randf_range(-3.0, 3.0), 14.0), Vector2(0.04, 0.16), 0.0, col)


func _update_drops(delta: float) -> void:
	var keep: Array = []
	var busy: bool = queue.size() > HI_MAX - 160
	for d in drops:
		var np: Vector2 = d["p"] + d["v"] * delta
		if wall_layer != null and _in_wall(np) and not _in_wall(d["p"]):
			_wall_splat(np, d)
			continue
		d["p"] = np
		d["v"] *= pow(0.02, delta)
		d["l"] -= delta
		if d["l"] <= 0.0 or d["v"].length() < 25.0:
			var p: Vector2 = d["p"]
			var target = self
			if wall_layer != null and _in_wall(p):
				target = wall_layer
			var col: Color = d["c"]
			# Gota rápida marca estria comprida no sentido da viagem; devagar vira pingo
			# redondo. É o alongamento que dá leitura de velocidade, não o tamanho.
			var spd: float = float(d["s"])
			var st: float = clampf(spd / 420.0, 0.1, 1.0)
			var sx: float = (0.07 + randf() * 0.08 + spd * 0.0006) * (1.0 + st * 2.1)
			var sy: float = (0.05 + randf() * 0.06) * (1.0 - st * 0.3)
			var sc := Vector2(sx, sy)
			var vm: Vector2 = d["v"]
			var rot: float = vm.angle() if vm.length() > 1.0 else float(d["a"])
			if busy:
				target.stamp_lo(p, sc, rot, col)
			else:
				target.stamp(p, sc, rot, col)
			if float(d["s"]) > 250.0:
				var off: Vector2 = Vector2.from_angle(float(d["a"])) * (10.0 + randf() * 20.0)
				target.stamp_lo(p + off, Vector2(0.05, 0.05), 0.0, col)
		else:
			keep.append(d)
	drops = keep


func _update_spurts(delta: float) -> void:
	var keep: Array = []
	for sp in spurts:
		sp["d"] -= delta
		sp["c"] += delta
		var t = sp["t"]
		if sp["d"] > 0.0 and is_instance_valid(t):
			var pos: Vector2 = t.to_global(sp["o"])
			var ang: float = float(sp["a"])
			if sp["o"] == Vector2.ZERO:
				ang = randf() * TAU
			var dir: Vector2 = Vector2.from_angle(ang).rotated(t.global_rotation)
			if sp["c"] >= 0.45:
				sp["c"] = 0.0
				spray(pos, dir, 11, 1.3)
			elif randf() < 0.2:
				stamp(pos + dir * randf_range(2.0, 10.0), Vector2(0.1, 0.1), randf() * TAU)
			keep.append(sp)
	spurts = keep
