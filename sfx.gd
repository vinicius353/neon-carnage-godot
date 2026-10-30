extends Node
# Sons sintetizados em código (sem arquivos de áudio).

var sounds := {}
var pool: Array = []
var loops := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	_mk("pistola", 220, 70, 0.14, 0.7, 0.8, false)
	_mk("auto", 260, 90, 0.09, 0.75, 0.7, false)
	_mk("escopeta", 120, 40, 0.28, 0.9, 0.9, false)
	_mk("rifle", 300, 60, 0.2, 0.8, 0.8, false)
	_mk("sniper", 180, 35, 0.45, 0.85, 0.9, false)
	_mk("besta", 900, 200, 0.12, 0.3, 0.5, false)
	_mk("swish", 2000, 600, 0.12, 0.95, 0.4, false)
	_mk("chop", 160, 60, 0.16, 0.7, 0.8, false)
	_mk("stab", 300, 150, 0.1, 0.6, 0.7, false)
	_mk("osso", 80, 40, 0.15, 0.5, 0.8, false)
	_mk("recarga", 1200, 500, 0.08, 0.2, 0.4, false)
	_mk("vazio", 600, 500, 0.04, 0.1, 0.4, false)
	_mk("hit", 1700, 1100, 0.05, 0.45, 0.5, false)
	_mk("ui", 900, 700, 0.05, 0.12, 0.35, false)
	_mk("serra", 90, 90, 0.25, 0.6, 0.5, true)
	_mk("fogo", 400, 300, 0.3, 0.98, 0.35, true)


func _mk(nm: String, f0: float, f1: float, dur: float, noise: float, vol: float, loop: bool) -> void:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(f0, f1, t)
		ph += TAU * f / float(rate)
		var env := 1.0
		if not loop:
			env = pow(1.0 - t, 2.0)
		var s := (sin(ph) * (1.0 - noise) + (randf() * 2.0 - 1.0) * noise) * env * vol
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	sounds[nm] = w


func play(nm: String, pitch: float = 1.0) -> void:
	if not sounds.has(nm):
		return
	for p in pool:
		if not p.playing:
			p.stream = sounds[nm]
			p.pitch_scale = pitch
			p.play()
			return


func loop_on(nm: String) -> void:
	if not sounds.has(nm):
		return
	if not loops.has(nm):
		var p := AudioStreamPlayer.new()
		p.stream = sounds[nm]
		add_child(p)
		loops[nm] = p
	if not loops[nm].playing:
		loops[nm].play()


func loop_off(nm: String) -> void:
	if loops.has(nm) and loops[nm].playing:
		loops[nm].stop()
