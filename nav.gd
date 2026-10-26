extends RefCounted
# Navegação em grade (AStarGrid2D do Godot) para civis e policiais.

const CS := 24.0
var astar := AStarGrid2D.new()
var cols := 0
var rows := 0


func build(size: Vector2, solids: Array) -> void:
	cols = int(ceil(size.x / CS))
	rows = int(ceil(size.y / CS))
	astar.region = Rect2i(0, 0, cols, rows)
	astar.cell_size = Vector2(CS, CS)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for x in cols:
		for y in rows:
			var c := Vector2(x * CS + CS * 0.5, y * CS + CS * 0.5)
			for r in solids:
				if r.grow(8.0).has_point(c):
					astar.set_point_solid(Vector2i(x, y), true)
					break


func cell(p: Vector2) -> Vector2i:
	return Vector2i(clampi(int(p.x / CS), 0, cols - 1), clampi(int(p.y / CS), 0, rows - 1))


func center(c: Vector2i) -> Vector2:
	return Vector2(c.x * CS + CS * 0.5, c.y * CS + CS * 0.5)


func rand_free() -> Vector2:
	for i in 40:
		var c := Vector2i(randi() % cols, randi() % rows)
		if not astar.is_point_solid(c):
			return center(c)
	return Vector2(100, 100)


func nearest_free(p: Vector2) -> Vector2:
	var c := cell(p)
	if not astar.is_point_solid(c):
		return center(c)
	for r in range(1, 12):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var q := Vector2i(c.x + dx, c.y + dy)
				if q.x >= 0 and q.y >= 0 and q.x < cols and q.y < rows and not astar.is_point_solid(q):
					return center(q)
	return p


func path(from: Vector2, to: Vector2) -> Array:
	var a := cell(from)
	var b := cell(to)
	if astar.is_point_solid(a):
		a = cell(nearest_free(from))
	if astar.is_point_solid(b):
		b = cell(nearest_free(to))
	var ids: Array = astar.get_id_path(a, b)
	var out: Array = []
	for i in range(1, ids.size()):
		out.append(center(ids[i]))
	return out


func flee_path(from: Vector2, threat: Vector2) -> Array:
	var best := from
	var bs := -1000000.0
	for i in 12:
		var c := rand_free()
		var s := c.distance_to(threat) - 0.6 * c.distance_to(from)
		if s > bs:
			bs = s
			best = c
	return path(from, best)
