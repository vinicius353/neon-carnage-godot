extends Node2D
# Inicializador: confere cada arquivo do jogo antes de iniciar e mostra na tela qual falhou.

const REQUIRED := ["game.gd", "blood.gd", "sfx.gd", "weapons.gd", "weapon_art.gd", "actor.gd", "piece.gd", "hud.gd"]
const OPTIONAL := ["maps.gd", "nav.gd"]


func _ready() -> void:
	var bad: Array = []
	for m in REQUIRED:
		var s = load("res://" + m)
		if s == null or not s.can_instantiate():
			bad.append(m)
	var bad_opt: Array = []
	for m in OPTIONAL:
		var s = load("res://" + m)
		if s == null or not s.can_instantiate():
			bad_opt.append(m)
	if bad.is_empty():
		var g = load("res://game.gd").new()
		g.set_meta("bad_opt", bad_opt)
		add_child(g)
		return
	var cl := CanvasLayer.new()
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.0, 0.0)
	bg.size = Vector2(4000, 3000)
	cl.add_child(bg)
	var l := Label.new()
	l.text = "ERRO AO CARREGAR OS ARQUIVOS:\n" + "\n".join(bad)
	l.position = Vector2(40, 40)
	l.add_theme_font_size_override("font_size", 36)
	cl.add_child(l)
