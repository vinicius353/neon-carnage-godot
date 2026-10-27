extends Node2D
# Camada de sangue em meia resolução: só redesenha quando há carimbos novos.

var vp: SubViewport
var holder: Node2D
var disp: Sprite2D
var soft: GradientTexture2D
var drops: Array = []
var queue: Array = []
var live: Array = []
var spurts: Array = []
var wall_layer = null
var wall_rects: Array = []
var shown := false


func setup(sz: Vector2i, z: int, soft_tex: GradientTexture2D) -> void:
	soft = soft_tex
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


func stamp(pos: Vector2, sc: Vector2, rot: float, col: Color = Color(0.5, 0.0, 0.04, 0.9)) -> void:
	if queue.size() < 400:
		queue.append([pos, sc, rot, col])


func spray(pos: Vector2, dir: Vector2, n: int, power: float) -> void:
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
		drops.append({"p": pos, "v": Vector2.from_angle(a) * s, "l": randf_range(0.25, 0.7), "a": a, "s": s})
	if drops.size() > 300:
		drops = drops.slice(drops.size() - 300)


func add_spurt(target: Node2D, off: Vector2, ang: float, dur: float) -> void:
	spurts.append({"t": target, "o": off, "a": ang, "d": dur * 1.4, "c": 0.0})


func _in_wall(p: Vector2) -> bool:
	for r in wall_rects:
		if r.has_point(p):
			return true
	return false


func _process(_delta: float) -> void:
	for s in live:
		s.queue_free()
	live = []
	var n: int = mini(queue.size(), 30)
	if n > 0:
		for i in n:
			var q: Array = queue.pop_front()
			var sp := Sprite2D.new()
			sp.texture = soft
			sp.position = q[0]
			sp.scale = q[1]
			sp.rotation = q[2]
			sp.modulate = q[3]
			holder.add_child(sp)
			live.append(sp)
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		if not shown:
			shown = true
			disp.visible = true


func _physics_process(delta: float) -> void:
	_update_drops(delta)
	_update_spurts(delta)


func _wall_splat(pos: Vector2, d: Dictionary) -> void:
	var a: float = float(d["a"])
	var dir: Vector2 = Vector2.from_angle(a)
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	wall_layer.stamp(pos, Vector2(0.18 + randf() * 0.12, 0.14 + randf() * 0.10), a)
	for i in 4:
		var o: Vector2 = dir * (3.0 + float(i) * 5.0) + perp * randf_range(-4.0, 4.0)
		wall_layer.stamp(pos + o, Vector2(0.07, 0.05), a)
	if randf() < 0.5:
		wall_layer.stamp(pos - dir * 6.0, Vector2(0.05, 0.05), 0.0)


func _update_drops(delta: float) -> void:
	var keep: Array = []
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
			var sx: float = 0.10 + randf() * 0.12 + float(d["s"]) * 0.0008
			target.stamp(p, Vector2(sx, 0.08 + randf() * 0.1), float(d["a"]))
			if float(d["s"]) > 250.0:
				var off: Vector2 = Vector2.from_angle(float(d["a"])) * (10.0 + randf() * 20.0)
				target.stamp(p + off, Vector2(0.05, 0.05), 0.0)
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
