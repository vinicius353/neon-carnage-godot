extends Node
# Armas guiadas por data/weapons.json (mesmos dados da versão HTML).

var main = null
var list: Array = []
var idx := 0
var ammo := {}
var reserve := {}
var cd := 0.0
var reload_t := 0.0
var flame: CPUParticles2D = null
var arrows: Array = []

const CUT := {"Faca": 0.3, "Facão": 0.5, "Tesoura": 0.3, "Katana": 0.75, "Cutelo": 0.5, "Machado": 0.65, "Martelo": 0.1, "Pé de Cabra": 0.12, "Motosserra": 0.45, "Escopeta Dupla": 0.55, "Cano Serrado": 0.55, "Sniper": 0.6, "Magnum .357": 0.35, "Executor": 0.35, "Escopeta": 0.4, "Estilhaço": 0.4, "Escopeta Auto": 0.3}


func load_list() -> void:
	var f := FileAccess.open("res://data/weapons.json", FileAccess.READ)
	if f != null:
		var data = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			list = data["armas"]
	if list.is_empty():
		list = [{"nome": "Pistola", "tipo": "pistola", "melee": false, "municao": 12, "recarga": 70, "dano": 34, "cadencia": 16, "dispersao": 0.04, "projeteis": 1, "velocidade": 12, "alcance_frames": 60, "peso": 1, "arte": 0}]
	for w in list:
		var m := 0
		if w["municao"] != null:
			m = int(w["municao"])
		ammo[w["nome"]] = float(m)
		reserve[w["nome"]] = m * 2


func cur() -> Dictionary:
	return list[idx]


func select(i: int) -> void:
	idx = wrapi(i, 0, list.size())
	cd = 0.0
	reload_t = 0.0
	main.sfx.loop_off("serra")
	_flame_off()
	main.art.set_art(int(list[idx]["arte"]))


func manual_reload() -> void:
	var w: Dictionary = list[idx]
	var nm: String = w["nome"]
	if w["melee"] or w["tipo"] == "lanca_chamas" or reload_t > 0.0:
		return
	if reserve[nm] > 0 and ammo[nm] < float(w["municao"]):
		_start_reload(w)


func _start_reload(w: Dictionary) -> void:
	reload_t = float(w["recarga"]) / 60.0
	main.sfx.play("recarga")


func update(delta: float, firing: bool, aim: Vector2, origin: Vector2) -> void:
	cd -= delta
	var w: Dictionary = list[idx]
	var nm: String = w["nome"]
	if reload_t > 0.0:
		reload_t -= delta
		if reload_t <= 0.0:
			var take: int = mini(int(w["municao"]), int(reserve[nm]))
			reserve[nm] = int(reserve[nm]) - take
			ammo[nm] = float(take)
		_flame_off()
		return
	if w["tipo"] == "lanca_chamas":
		_flame(delta, firing, aim, origin, w)
		return
	_flame_off()
	if nm == "Motosserra":
		if firing:
			main.sfx.loop_on("serra")
		else:
			main.sfx.loop_off("serra")
	if not firing or cd > 0.0:
		return
	cd = float(w["cadencia"]) / 60.0
	if w["melee"]:
		_melee(aim, origin, w, nm)
		return
	if ammo[nm] < 1.0:
		if reserve[nm] > 0:
			_start_reload(w)
		else:
			main.sfx.play("vazio")
			cd = 0.4
		return
	ammo[nm] -= 1.0
	_shoot(aim, origin, w, nm)
	if ammo[nm] < 1.0 and reserve[nm] > 0:
		_start_reload(w)


func _shoot(aim: Vector2, origin: Vector2, w: Dictionary, nm: String) -> void:
	var snd := "pistola"
	var tipo: String = w["tipo"]
	if tipo == "escopeta":
		snd = "escopeta"
	elif tipo == "automatica":
		snd = "auto"
	elif tipo == "rifle":
		snd = "rifle"
	if nm == "Sniper":
		snd = "sniper"
	elif nm == "Besta":
		snd = "besta"
	main.sfx.play(snd, randf_range(0.95, 1.05))
	main.shoot_fx()
	var rng: float = minf(1100.0, float(w["velocidade"]) * float(w["alcance_frames"]))
	var pen: int = 0
	if nm == "Sniper":
		pen = 3
	var cut: float = CUT.get(nm, 0.0)
	var spread: float = float(w["dispersao"])
	for i in int(w["projeteis"]):
		var dir: Vector2 = aim.rotated(randf_range(-spread, spread))
		_ray(origin, dir, rng, float(w["dano"]), pen, cut, nm == "Besta", tipo == "escopeta")


func _ray(origin: Vector2, dir: Vector2, rng: float, dmg: float, pen: int, cut: float, arrow: bool, close_only: bool) -> void:
	var space: PhysicsDirectSpaceState2D = main.get_world_2d().direct_space_state
	var from: Vector2 = origin
	var excl: Array = [main.player.get_rid()]
	var d: float = dmg
	for n in pen + 1:
		var q: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, origin + dir * rng, 1 | 2)
		q.exclude = excl
		var res: Dictionary = space.intersect_ray(q)
		if res.is_empty():
			return
		var col = res["collider"]
		var pos: Vector2 = res["position"]
		if col.has_method("hit") and not col.dead:
			var c: float = cut
			if close_only and origin.distance_to(pos) > 130.0:
				c = 0.0
			col.hit(d, dir, pos, c)
			excl.append(col.get_rid())
			d *= 0.6
			from = pos + dir * 2.0
			if arrow:
				_arrow(pos, dir)
				return
		else:
			if arrow:
				_arrow(pos, dir)
			return


func _arrow(pos: Vector2, dir: Vector2) -> void:
	var l := Line2D.new()
	l.points = PackedVector2Array([pos - dir * 14.0, pos + dir * 3.0])
	l.width = 1.6
	l.default_color = Color(0.8, 0.72, 0.54)
	l.z_index = 3
	main.add_child(l)
	arrows.append(l)
	if arrows.size() > 60:
		var old = arrows.pop_front()
		old.queue_free()


func _melee(aim: Vector2, origin: Vector2, w: Dictionary, nm: String) -> void:
	main.art.swing = 1.0
	var snd := "swish"
	if nm in ["Machado", "Facão", "Cutelo", "Katana"]:
		snd = "chop"
	elif nm in ["Faca", "Tesoura"]:
		snd = "stab"
	elif nm in ["Martelo", "Pé de Cabra"]:
		snd = "osso"
	if nm != "Motosserra":
		main.sfx.play(snd)
	var cut: float = CUT.get(nm, 0.2)
	for a in main.actors.duplicate():
		if a.dead:
			continue
		var dv: Vector2 = a.global_position - origin
		if dv.length() < 56.0 and absf(angle_difference(aim.angle(), dv.angle())) < 1.0:
			a.hit(float(w["dano"]), aim, a.to_global(Vector2(randf_range(-8, 8), randf_range(-11, 11))), cut)
			main.shake(3.0)
			if nm == "Motosserra":
				main.blood.spray(a.global_position, aim, 8, 1.2)
			if nm == "Pé de Cabra" or nm == "Martelo":
				a.global_position += aim * 14.0


func _flame(delta: float, firing: bool, aim: Vector2, origin: Vector2, w: Dictionary) -> void:
	var nm: String = w["nome"]
	if firing and ammo[nm] > 0.0:
		if flame == null:
			_make_flame()
		flame.emitting = true
		flame.global_position = origin
		flame.rotation = aim.angle()
		main.sfx.loop_on("fogo")
		ammo[nm] -= delta * 8.0
		for a in main.actors.duplicate():
			if a.dead:
				continue
			var dv: Vector2 = a.global_position - origin
			if dv.length() < 230.0 and absf(angle_difference(aim.angle(), dv.angle())) < 0.3:
				a.burn = 4.0
				a.hp -= 70.0 * delta
				if a.hp <= 0.0:
					a.die(aim, 0.0)
	else:
		_flame_off()
		if ammo[nm] <= 0.0 and reserve[nm] > 0:
			_start_reload(w)


func _make_flame() -> void:
	flame = CPUParticles2D.new()
	flame.amount = 70
	flame.lifetime = 0.45
	flame.emitting = false
	flame.direction = Vector2(1, 0)
	flame.spread = 14.0
	flame.gravity = Vector2.ZERO
	flame.initial_velocity_min = 380.0
	flame.initial_velocity_max = 520.0
	flame.scale_amount_min = 0.15
	flame.scale_amount_max = 0.35
	flame.texture = main.soft
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.9, 0.4, 0.9))
	g.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	flame.color_ramp = g
	flame.z_index = 3
	main.add_child(flame)


func _flame_off() -> void:
	if flame != null:
		flame.emitting = false
	main.sfx.loop_off("fogo")
