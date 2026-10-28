extends Node2D
# Itens arremessáveis: granada, flash, molotov, fumaça e isca sonora.

var main = null
var kind := "Granada"
var vel := Vector2.ZERO
var fuse := 1.2
var state := "fly"
var life := 0.0
var t := 0.0


func _ready() -> void:
	z_index = 3
	if kind == "Molotov" or kind == "Fumaca" or kind == "Isca":
		fuse = 0.7


func _physics_process(delta: float) -> void:
	t += delta
	if state == "fly":
		var np: Vector2 = position + vel * delta
		if main.blood._in_wall(np):
			vel = -vel * 0.3
		else:
			position = np
		vel *= pow(0.05, delta)
		fuse -= delta
		if fuse <= 0.0:
			_land()
	else:
		life -= delta
		_area(delta)
		if life <= 0.0:
			queue_free()
	queue_redraw()


func _land() -> void:
	if kind == "Granada":
		_boom()
		queue_free()
	elif kind == "Flash":
		_flash()
		queue_free()
	elif kind == "Molotov":
		state = "fire"
		life = 6.0
		main.sfx.play("vazio", 0.6)
	elif kind == "Fumaca":
		state = "smoke"
		life = 10.0
		main.smokes.append(self)
	else:
		state = "decoy"
		life = 8.0
		main.decoy_pos = position
		main.decoy_t = 8.0


func _boom() -> void:
	main.sfx.play("escopeta", 0.6)
	main.shake(9.0)
	main.add_noise(25.0)
	main.blood.stamp(position, Vector2(1.3, 1.3), randf() * TAU, Color(0.04, 0.04, 0.04, 0.85))
	for a in main.actors.duplicate():
		if a.dead:
			continue
		var d: float = a.global_position.distance_to(position)
		if d < 120.0:
			var dir: Vector2 = (a.global_position - position).normalized()
			a.hit(140.0 * (1.0 - d / 140.0), dir, a.global_position, 0.7)
	var dp: float = main.player.global_position.distance_to(position)
	if dp < 90.0:
		main.hurt_player(30.0 * (1.0 - dp / 100.0))


func _flash() -> void:
	main.sfx.play("pistola", 0.4)
	main.add_noise(10.0)
	for a in main.actors:
		if a.global_position.distance_to(position) < 220.0:
			a.stun = 4.0
	if main.player.global_position.distance_to(position) < 160.0:
		main.white_a = 0.9


func _area(delta: float) -> void:
	if state == "fire":
		for a in main.actors:
			if not a.dead and a.global_position.distance_to(position) < 40.0:
				a.burn = 4.0
		if main.player.global_position.distance_to(position) < 30.0:
			main.hurt_player(20.0 * delta)
	elif state == "decoy":
		main.decoy_t = life


func _draw() -> void:
	if state == "fly":
		var c := Color(0.8, 0.8, 0.9)
		if kind == "Granada":
			c = Color(0.2, 0.3, 0.2)
		draw_circle(Vector2.ZERO, 2.5, c)
	elif state == "fire":
		for i in 5:
			var r: float = 7.0 + randf() * 8.0
			draw_circle(Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0)), r, Color(1.0, 0.4 + randf() * 0.4, 0.05, 0.55))
	elif state == "smoke":
		var al: float = clampf(life / 10.0, 0.0, 1.0) * 0.55
		draw_circle(Vector2.ZERO, 62.0, Color(0.7, 0.72, 0.76, al))
		draw_circle(Vector2(12, -8), 46.0, Color(0.8, 0.82, 0.86, al))
	elif state == "decoy":
		draw_arc(Vector2.ZERO, 8.0 + fmod(t * 20.0, 24.0), 0.0, TAU, 16, Color(1.0, 0.85, 0.3, 0.7), 1.5)
