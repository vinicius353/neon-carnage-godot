extends Node2D
# Inicializador: confere cada arquivo do jogo, mostra o menu e inicia a partida.

const REQUIRED := ["game.gd", "blood.gd", "sfx.gd", "weapons.gd", "weapon_art.gd", "actor.gd", "piece.gd", "hud.gd", "figure.gd", "thrown.gd", "exec.gd"]
const OPTIONAL := ["maps.gd", "nav.gd"]
const MODE_NAMES := ["MASSACRE", "HALLOWEEN", "JUGGERNAUT", "RESGATE"]
const MAP_NAMES := ["CASA", "BANCO", "HOSPITAL", "MERCADO"]

var bad: Array = []
var bad_opt: Array = []
var menu: CanvasLayer = null
var menu_root: Control = null
var title_lbl: Label = null
var sub_lbl: Label = null
var hint_lbl: Label = null
var mode_lbl: Label = null
var map_lbl: Label = null
var play_btn: Button = null
var mode_btn: Button = null
var map_btn: Button = null
var quit_btn: Button = null
var game = null


func _ready() -> void:
	var root := get_tree().root
	if not root.has_meta("gfx"):
		root.set_meta("gfx", 0)
	if not root.has_meta("fx"):
		root.set_meta("fx", 1)
	if not root.has_meta("mode"):
		root.set_meta("mode", 0)
	if not root.has_meta("map_i"):
		root.set_meta("map_i", 0)
	for m in REQUIRED:
		var s = load("res://" + m)
		if s == null or not s.can_instantiate():
			bad.append(m)
	for m in OPTIONAL:
		var s = load("res://" + m)
		if s == null or not s.can_instantiate():
			bad_opt.append(m)
	if not bad.is_empty():
		_error_screen()
		return
	if bool(root.get_meta("in_game", false)) or OS.get_cmdline_user_args().has("selftest"):
		_start_game()
	else:
		_build_menu()


func _error_screen() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.0, 0.0)
	bg.size = Vector2(4000, 3000)
	cl.add_child(bg)
	var l := Label.new()
	l.text = "ERRO AO CARREGAR OS ARQUIVOS:\n" + "\n".join(bad)
	l.position = Vector2(20, 20)
	l.add_theme_font_size_override("font_size", 20)
	cl.add_child(l)


func _start_game() -> void:
	if menu != null:
		menu.visible = false
	get_tree().root.set_meta("in_game", true)
	var g = load("res://game.gd").new()
	g.set_meta("bad_opt", bad_opt)
	add_child(g)
	game = g


func back_to_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().root.set_meta("in_game", false)
	if game != null and is_instance_valid(game):
		game.queue_free()
	game = null
	if menu == null:
		_build_menu()
	else:
		menu.visible = true
		_sync_menu()


func _build_menu() -> void:
	var root := get_tree().root
	menu = CanvasLayer.new()
	menu.layer = 20
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu)
	menu_root = Control.new()
	menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(menu_root)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.02, 0.03, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(bg)
	var strip := ColorRect.new()
	strip.color = Color(0.42, 0.02, 0.05, 0.55)
	strip.size = Vector2(4000, 3)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(strip)
	title_lbl = Label.new()
	title_lbl.text = "NEON CARNAGE"
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.82))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(title_lbl)
	sub_lbl = Label.new()
	sub_lbl.text = "SANGUE   CHUMBO   PIXEL"
	sub_lbl.add_theme_font_size_override("font_size", 9)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.10, 0.12))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(sub_lbl)
	play_btn = _menu_btn("JOGAR", _on_play)
	mode_btn = _menu_btn("MODO", _on_mode)
	map_btn = _menu_btn("MAPA", _on_map)
	quit_btn = _menu_btn("SAIR", _on_quit)
	hint_lbl = Label.new()
	hint_lbl.text = "NO CELULAR: TOQUE A ESQUERDA PRA ANDAR, A DIREITA PRA MIRAR   |   TECLADO: WASD MIRAR Q/E ARMA R RECARGA F EXECUTAR G ITEM P PAUSA"
	hint_lbl.add_theme_font_size_override("font_size", 8)
	hint_lbl.add_theme_color_override("font_color", Color(0.62, 0.58, 0.55))
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(hint_lbl)
	_sync_menu()
	get_viewport().size_changed.connect(_layout_menu)
	_layout_menu()


func _menu_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(cb)
	menu_root.add_child(b)
	return b


func _layout_menu() -> void:
	if menu_root == null:
		return
	var vs := get_viewport().get_visible_rect().size
	title_lbl.position = Vector2(vs.x * 0.5 - 150.0, vs.y * 0.16)
	title_lbl.size = Vector2(300, 40)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.position = Vector2(vs.x * 0.5 - 150.0, vs.y * 0.16 + 42.0)
	sub_lbl.size = Vector2(300, 14)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var y: float = vs.y * 0.34
	var bw := 210.0
	var bh := 32.0
	for b in [play_btn, mode_btn, map_btn, quit_btn]:
		if b == null:
			continue
		b.size = Vector2(bw, bh)
		b.position = Vector2(vs.x * 0.5 - bw * 0.5, y)
		y += bh + 7.0
	hint_lbl.position = Vector2(vs.x * 0.5 - 300.0, vs.y - 22.0)
	hint_lbl.size = Vector2(600, 16)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _sync_menu() -> void:
	var root := get_tree().root
	var m := int(root.get_meta("mode", 0))
	var mi := int(root.get_meta("map_i", 0))
	if mode_lbl != null:
		mode_lbl.text = MODE_NAMES[wrapi(m, 0, MODE_NAMES.size())]
	if map_lbl != null:
		map_lbl.text = MAP_NAMES[wrapi(mi, 0, MAP_NAMES.size())]
	if mode_btn != null:
		mode_btn.text = "MODO: " + MODE_NAMES[wrapi(m, 0, MODE_NAMES.size())]
	if map_btn != null:
		map_btn.text = "MAPA: " + MAP_NAMES[wrapi(mi, 0, MAP_NAMES.size())]


func _on_play() -> void:
	_start_game()


func _on_mode() -> void:
	var root := get_tree().root
	root.set_meta("mode", (int(root.get_meta("mode", 0)) + 1) % MODE_NAMES.size())
	_sync_menu()


func _on_map() -> void:
	var root := get_tree().root
	root.set_meta("map_i", (int(root.get_meta("map_i", 0)) + 1) % MAP_NAMES.size())
	_sync_menu()


func _on_quit() -> void:
	get_tree().quit()
