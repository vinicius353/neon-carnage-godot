extends Node
# Execuções: uma sequência única de golpes para cada uma das 27 armas.

var main = null
var busy := false
var target = null
var clock := 0.0
var idx := 0
var beats: Array = []
var run_kind := ""
var run_until := 0.0
var run_acc := 0.0

# Cada passo: [tempo em segundos, tipo, parâmetro]
const DATA := {
	"Faca": [[0.5, "stab"], [1.3, "stab"], [2.2, "chop"], [2.6, "kill", 15.0]],
	"Facão": [[0.5, "chop"], [1.0, "chop"], [1.6, "cut", "head"], [1.7, "kill", 45.0]],
	"Cutelo": [[0.4, "chop"], [0.8, "chop"], [1.2, "chop"], [1.6, "chop"], [2.0, "cut", "head"], [2.1, "kill", 45.0]],
	"Tesoura": [[0.5, "stab"], [1.0, "stab"], [1.6, "cut", "arm_r"], [2.2, "kill", 20.0]],
	"Katana": [[0.6, "slomo", 0.35], [1.0, "chop"], [1.05, "cut", "head"], [1.1, "kill", 60.0]],
	"Motosserra": [[0.3, "sawrun", 1.6], [2.0, "cut", "arm_l"], [2.1, "kill", 80.0]],
	"Machado": [[0.7, "chop"], [1.4, "chop"], [1.5, "cut", "head"], [1.6, "kill", 50.0]],
	"Martelo": [[0.6, "bone"], [1.2, "bone"], [1.8, "bone"], [1.85, "kill", 70.0]],
	"Pé de Cabra": [[0.5, "bone"], [0.9, "bone"], [1.6, "bone"], [1.65, "cut", "head"], [1.7, "kill", 40.0]],
	"Pistola": [[0.8, "shot", "pistola"], [0.85, "kill", 20.0]],
	"Executor": [[1.0, "shot", "pistola"], [1.05, "kill", 50.0]],
	"Magnum .357": [[0.9, "slomo", 0.3], [1.2, "shot", "escopeta"], [1.25, "cut", "head"], [1.3, "kill", 90.0]],
	".38 Special": [[0.4, "vazio"], [0.9, "vazio"], [1.5, "shot", "pistola"], [1.55, "kill", 30.0]],
	"Gêmeas": [[0.7, "shot", "pistola"], [0.95, "shot", "pistola"], [1.0, "kill", 30.0]],
	"SMG": [[0.6, "shot", "auto"], [0.72, "shot", "auto"], [0.84, "shot", "auto"], [0.9, "kill", 30.0]],
	"Ceifador": [[0.5, "shot", "auto"], [0.6, "shot", "auto"], [0.7, "shot", "auto"], [0.8, "shot", "auto"], [0.9, "shot", "auto"], [1.0, "kill", 50.0]],
	"Moedor": [[0.4, "shotrun", 1.2], [1.8, "kill", 110.0]],
	"Minigun": [[0.4, "shotrun", 1.4], [2.0, "kill", 110.0]],
	"Rifle": [[0.5, "bone"], [1.3, "shot", "rifle"], [1.35, "kill", 40.0]],
	"Sniper": [[0.8, "slomo", 0.3], [1.5, "shot", "sniper"], [1.55, "cut", "head"], [1.6, "kill", 110.0]],
	"Besta": [[1.0, "stab"], [1.1, "kill", 30.0]],
	"Lança-chamas": [[0.4, "burn"], [2.8, "kill", 5.0]],
	"Escopeta": [[0.8, "shot", "escopeta"], [1.5, "bone"], [2.0, "kill", 50.0]],
	"Escopeta Dupla": [[0.7, "shot", "escopeta"], [1.3, "shot", "escopeta"], [1.35, "kill", 70.0]],
	"Cano Serrado": [[0.9, "shot", "escopeta"], [0.95, "cut", "head"], [1.0, "kill", 80.0]],
	"Estilhaço": [[0.8, "shot", "escopeta"], [1.2, "shot", "escopeta"], [1.25, "kill", 60.0]],
	"Escopeta Auto": [[0.6, "shot", "escopeta"], [0.9, "shot", "escopeta"], [1.2, "shot", "escopeta"], [1.25, "kill", 60.0]],
}


func has_exec(wname: String) -> bool:
	return DATA.has(wname)


func begin(a, wname: String) -> bool:
	if busy or not DATA.has(wname):
		return false
	busy = true
	target = a
	clock = 0.0
	idx = 0
	run_kind = ""
	beats = DATA[wname]
	a.held = true
	a.sleeping = false
	a.refresh()
	var dv: Vector2 = a.global_position - main.player.global_position
	main.aim_v = dv.normalized()
	main.player.rotation = main.aim_v.angle()
	return true


func update(delta: float) -> void:
	if not busy:
		return
	if not is_instance_valid(target):
		_end()
		return
	clock += delta
	if run_kind != "":
		run_acc += delta
		if clock >= run_until:
			run_kind = ""
			main.sfx.loop_off("serra")
		elif run_acc >= 0.1:
			run_acc = 0.0
			_pulse()
	while busy and idx < beats.size() and float(beats[idx][0]) <= clock:
		var b: Array = beats[idx]
		idx += 1
		_do(b)


func _pulse() -> void:
	var a = target
	var dir: Vector2 = (a.global_position - main.player.global_position).normalized()
	if run_kind == "saw":
		main.blood.spray(a.global_position, dir, 5, 1.0)
		main.blood.stamp(a.global_position, Vector2(0.25, 0.25), randf() * TAU)
		main.shake(1.5)
		main.add_noise(0.6)
	else:
		_shot("auto", dir, a.global_position)


func _shot(snd: String, dir: Vector2, pos: Vector2) -> void:
	main.sfx.play(snd)
	main.art.flash = 0.06
	main.art.recoil = 1.0
	main.blood.spray(pos, dir, 12, 1.3)
	main.blood.stamp(pos, Vector2(0.35, 0.35), randf() * TAU)
	main.shake(5.0)
	main.add_noise(8.0)


func _do(b: Array) -> void:
	var tp: String = b[1]
	var a = target
	var dir: Vector2 = (a.global_position - main.player.global_position).normalized()
	var pos: Vector2 = a.global_position
	if tp == "stab":
		main.sfx.play("stab")
		main.blood.spray(pos, dir, 5, 0.8)
		main.blood.stamp(pos, Vector2(0.25, 0.25), randf() * TAU)
		main.shake(2.0)
		main.art.swing = 1.0
	elif tp == "chop":
		main.sfx.play("chop")
		main.blood.spray(pos, dir, 9, 1.1)
		main.shake(3.5)
		main.art.swing = 1.0
	elif tp == "bone":
		main.sfx.play("osso")
		main.blood.spray(pos, dir, 6, 0.9)
		main.shake(3.0)
		main.art.swing = 1.0
	elif tp == "shot":
		_shot(str(b[2]), dir, pos)
	elif tp == "vazio":
		main.sfx.play("vazio")
	elif tp == "cut":
		a.sever(str(b[2]), dir)
	elif tp == "burn":
		a.burn = 4.0
		main.sfx.loop_on("fogo")
	elif tp == "sawrun":
		run_kind = "saw"
		run_until = clock + float(b[2])
		main.sfx.loop_on("serra")
	elif tp == "shotrun":
		run_kind = "gun"
		run_until = clock + float(b[2])
	elif tp == "slomo":
		Engine.time_scale = float(b[2])
	elif tp == "kill":
		var over: float = float(b[2])
		_end()
		if not a.dead:
			a.die(dir, over)
		main.hitstop(0.07)


func _end() -> void:
	busy = false
	run_kind = ""
	Engine.time_scale = 1.0
	main.sfx.loop_off("serra")
	main.sfx.loop_off("fogo")
	if target != null and is_instance_valid(target):
		target.held = false
	target = null
