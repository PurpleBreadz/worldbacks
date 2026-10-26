class_name WBEnvironmentArt
extends Node2D
## Original vector pixel scenery. Level geometry is supplied by WBWorld, never generated here.
var area_id: String = "caravan"
var width: float = 1600.0
var height: float = 540.0
var floor_y: float = 430.0
var platform_rects: Array[Rect2] = []
var _time: float = 0.0
var _drift: float = 0.0
const INK := Color("101d23")
const DEEP := Color("172b31")
const TEAL := Color("294446")
const LEAF := Color("405646")
const MOSS := Color("65734d")
const GOLD := Color("bea16a")
const ROCK := Color("344344")

func _ready() -> void:
	z_index = -20
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(player_node):
		_drift = floorf(player_node.position.x * 0.035)
	queue_redraw()

func _draw() -> void:
	var sky: Color = Color("142930") if area_id != "courtyard" else Color("1b2731")
	draw_rect(Rect2(-80, -80, width + 160, height + 160), sky)
	# Distant strata and a pale, broken moon establish depth at a fixed pixel scale.
	for band: int in range(8):
		var tint: Color = sky.lightened(0.012 * float(band))
		draw_rect(Rect2(-80, height * 0.14 + band * height * 0.1, width + 160, height * 0.11), tint)
	var moon := Vector2(width * 0.6 - _drift, height * 0.2)
	draw_circle(moon, 24, Color("8d9b8a"))
	draw_circle(moon + Vector2(12, -9), 23, sky.lightened(0.015))
	_distant_hills()
	if area_id in ["road", "caravan", "vale"]:
		_fortress(Vector2(width * 0.69 - _drift * 1.8, floor_y - 48), 0.65, Color("293c40"))
	if area_id == "tower":
		_tower_ruin()
	elif area_id == "courtyard":
		_courtyard()
	elif area_id == "vale" and _worldbearer_location() == "vale":
		_mossback(Vector2(width * 0.64, floor_y - 5), 1.0)
	if area_id == "caravan" and _worldbearer_location() == "caravan":
		_mossback(Vector2(1180, floor_y - 5), 0.8)
	for index: int in range(int(width / 155.0) + 2):
		var x: float = index * 155.0 - 60 - _drift
		_tree(Vector2(x, floor_y + 10), 140 + (index % 3) * 29, Color("263e3e"), 1.0)
	if area_id not in ["courtyard", "settlement"]:
		for index: int in range(int(width / 290.0) + 1):
			_tree(Vector2(index * 290.0 + 40, floor_y), 185 + (index % 2) * 35, Color("1b3033"), 1.2)
	for platform: Rect2 in platform_rects:
		_ground(platform)
	if area_id == "settlement":
		_shell()
	if area_id == "caravan":
		_caravan(Vector2(160, floor_y))
		_cart(Vector2(350, floor_y), true)
	if area_id == "road":
		_arch(Vector2(440, floor_y), 78, 135, Color("47504a"))
		_sign(Vector2(width * 0.55, floor_y), "BELLHAVEN")
	if area_id == "vale":
		for index: int in range(8):
			var p := Vector2(95 + index * 139, floor_y - 8)
			draw_line(p, p + Vector2(0, -22), Color("58684c"), 2)
			draw_circle(p + Vector2(0, -24), 3, Color("a1b797"))
	# Subtle drifting spores, deterministic decoration unrelated to world topology.
	for index: int in range(28):
		var x: float = fposmod(index * 97.0 + _time * 5.0, width)
		var y: float = floor_y - 35 - (index * 31 % 200) + sin(_time + index) * 8
		draw_rect(Rect2(floorf(x), floorf(y), 1, 1), Color(0.66, 0.76, 0.57, 0.35))

func _worldbearer_location() -> String:
	var game: Node = get_tree().root.get_node_or_null("Game")
	if game == null:
		return "vale"
	var state: Dictionary = game.get("state")
	var worldbearer: Dictionary = state.get("worldbearer", {})
	if not bool(worldbearer.get("awake", false)):
		return "vale"
	return str(worldbearer.get("location", "vale"))

func _distant_hills() -> void:
	for layer: int in range(3):
		var points := PackedVector2Array()
		points.append(Vector2(-80, height + 50))
		for index: int in range(int(width / 90) + 3):
			var x: float = index * 90 - 80 - _drift * (0.4 + layer * 0.35)
			var y: float = floor_y - 80 + layer * 35 - sin(index * 1.5 + layer) * 36
			points.append(Vector2(x, floorf(y)))
		points.append(Vector2(width + 80, height + 50))
		draw_colored_polygon(points, Color("30484a").darkened(layer * 0.19))

func _tree(base: Vector2, tall: float, color: Color, scale_value: float) -> void:
	var trunk: float = 10 * scale_value
	draw_rect(Rect2(base.x - trunk / 2, base.y - tall, trunk, tall), color)
	draw_line(base + Vector2(0, -tall * 0.5), base + Vector2(-35, -tall * 0.8), color, 5 * scale_value)
	draw_line(base + Vector2(0, -tall * 0.7), base + Vector2(38, -tall * 0.92), color, 5 * scale_value)
	for crown: int in range(4):
		var spread: float = (30 + crown * 9) * scale_value
		var y: float = base.y - tall - 18 + crown * 20
		draw_colored_polygon(PackedVector2Array([Vector2(base.x, y - 35), Vector2(base.x - spread, y + 28), Vector2(base.x + spread, y + 28)]), color)
	draw_line(base + Vector2(-15, 0), base + Vector2(0, -12), color, 4)
	draw_line(base + Vector2(18, 0), base + Vector2(0, -12), color, 4)

func _ground(rect: Rect2) -> void:
	draw_rect(rect, Color("1d292b"))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color("5d6c4e"))
	draw_rect(Rect2(rect.position + Vector2(0, 5), Vector2(rect.size.x, 5)), Color("394c3b"))
	for index: int in range(int(rect.size.x / 26.0)):
		var x: float = rect.position.x + index * 26
		var y: float = rect.position.y
		if index % 3 == 0:
			draw_rect(Rect2(x + 4, y + 16 + index % 7, 14, 4), Color("35403b"))
		draw_line(Vector2(x + 10, y), Vector2(x + 8, y - 5 - index % 4), Color("72805b"), 1)
		draw_line(Vector2(x + 12, y), Vector2(x + 15, y - 4), Color("536a47"), 1)
	if rect.size.y <= 30:
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 4), Vector2(rect.size.x, 4)), Color("111d21"))

func _fortress(base: Vector2, scale_value: float, color: Color) -> void:
	for index: int in range(5):
		var x: float = base.x + (index - 2) * 47 * scale_value
		var h: float = (100 + (index % 2) * 42) * scale_value
		draw_rect(Rect2(x, base.y - h, 35 * scale_value, h), color)
		for tooth: int in range(3):
			draw_rect(Rect2(x + tooth * 14 * scale_value, base.y - h - 9 * scale_value, 7 * scale_value, 12 * scale_value), color)
		draw_rect(Rect2(x + 15 * scale_value, base.y - h + 20 * scale_value, 5 * scale_value, 20 * scale_value), color.darkened(0.3))
	draw_rect(Rect2(base.x - 94 * scale_value, base.y - 55 * scale_value, 220 * scale_value, 55 * scale_value), color)

func _arch(base: Vector2, wide: float, tall: float, color: Color) -> void:
	draw_rect(Rect2(base.x - wide / 2, base.y - tall, 16, tall), color)
	draw_rect(Rect2(base.x + wide / 2 - 16, base.y - tall + 12, 16, tall - 12), color)
	draw_rect(Rect2(base.x - wide / 2 - 5, base.y - tall, wide + 10, 14), color.lightened(0.08))
	for step: int in range(1, int(tall / 18)):
		draw_line(Vector2(base.x - wide / 2, base.y - step * 18), Vector2(base.x - wide / 2 + 16, base.y - step * 18), color.darkened(0.32), 1)
		draw_line(Vector2(base.x + wide / 2 - 16, base.y - step * 18), Vector2(base.x + wide / 2, base.y - step * 18), color.darkened(0.32), 1)
	draw_rect(Rect2(base.x - wide / 2 - 4, base.y - tall, 23, 4), MOSS)

func _tower_ruin() -> void:
	var center: float = width * 0.52
	draw_rect(Rect2(center - 95, 65, 190, floor_y - 65), Color("25373a"))
	for row: int in range(int(floor_y / 30)):
		draw_line(Vector2(center - 95, 65 + row * 30), Vector2(center + 95, 65 + row * 30), Color("324448"), 1)
		for col: int in range(4):
			var x: float = center - 95 + col * 58 + (row % 2) * 28
			draw_line(Vector2(x, 65 + row * 30), Vector2(x, 94 + row * 30), Color("324448"), 1)
	for window: int in range(4):
		draw_rect(Rect2(center - 12, 110 + window * 160, 24, 54), INK)
		draw_rect(Rect2(center - 17, 160 + window * 160, 34, 6), ROCK)
	for index: int in range(5):
		draw_rect(Rect2(center - 95 + index * 43, 48 + (index % 2) * 8, 20, 25), Color("33484a"))
	draw_line(Vector2(center + 64, 50), Vector2(center + 64, 7), ROCK, 3)
	draw_colored_polygon(PackedVector2Array([Vector2(center + 66, 8), Vector2(center + 112, 19), Vector2(center + 88, 34), Vector2(center + 66, 30)]), Color("755942"))

func _courtyard() -> void:
	for index: int in range(int(width / 160) + 1):
		_arch(Vector2(index * 160 + 80, floor_y), 125, 210, Color("314044"))
		for brick: int in range(6):
			draw_rect(Rect2(index * 160, floor_y - 245 + brick * 7, 160, 2), Color("3b4949"))
	var bell := Vector2(width * 0.76, floor_y - 185)
	draw_line(bell + Vector2(0, -70), bell, Color("84775a"), 3)
	draw_colored_polygon(PackedVector2Array([bell + Vector2(-20, 0), bell + Vector2(20, 0), bell + Vector2(27, 40), bell + Vector2(-27, 40)]), Color("87764e"))
	draw_rect(Rect2(bell + Vector2(-31, 38), Vector2(62, 7)), Color("b19b60"))
	draw_circle(bell + Vector2(0, 48), 4, Color("514b3e"))

func _cart(base: Vector2, broken: bool) -> void:
	draw_circle(base + Vector2(-25, -9), 12, Color("0f1c20"))
	draw_circle(base + Vector2(27, -9), 12, Color("0f1c20"))
	draw_circle(base + Vector2(-25, -9), 7, Color("625542"), false, 2)
	draw_circle(base + Vector2(27, -9), 7, Color("625542"), false, 2)
	draw_rect(Rect2(base + Vector2(-40, -38), Vector2(78, 22)), Color("5c5140"))
	for slat: int in range(4):
		draw_line(base + Vector2(-40, -35 + slat * 5), base + Vector2(38, -35 + slat * 5), Color("302f29"), 1)
	if broken:
		draw_line(base + Vector2(-36, -38), base + Vector2(-48, -69), Color("69604a"), 3)
		draw_colored_polygon(PackedVector2Array([base + Vector2(-48, -67), base + Vector2(12, -59), base + Vector2(31, -37), base + Vector2(-17, -44)]), Color("73694f"))

func _caravan(base: Vector2) -> void:
	_cart(base, false)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-43, -39), base + Vector2(-27, -75), base + Vector2(22, -75), base + Vector2(43, -39)]), Color("827451"))
	draw_rect(Rect2(base + Vector2(-10, -73), Vector2(3, 33)), Color("4b4939"))
	var tent := base + Vector2(-90, 0)
	draw_colored_polygon(PackedVector2Array([tent + Vector2(-35, 0), tent + Vector2(0, -45), tent + Vector2(33, 0)]), Color("4b5b4b"))
	draw_colored_polygon(PackedVector2Array([tent + Vector2(-10, 0), tent + Vector2(0, -33), tent + Vector2(10, 0)]), INK)

func _mossback(base: Vector2, scale_value: float) -> void:
	# Exterior representation; settlement collision never moves with this silhouette.
	var shell: Color = Color("405549")
	draw_circle(base + Vector2(0, -80) * scale_value, 115 * scale_value, shell)
	draw_rect(Rect2(base + Vector2(-120, -76) * scale_value, Vector2(245, 79) * scale_value), shell)
	draw_rect(Rect2(base + Vector2(111, -51) * scale_value, Vector2(92, 42) * scale_value), Color("52634e"))
	draw_rect(Rect2(base + Vector2(175, -33) * scale_value, Vector2(35, 22) * scale_value), Color("596850"))
	draw_rect(Rect2(base + Vector2(166, -45) * scale_value, Vector2(6, 3) * scale_value), GOLD)
	for index: int in range(5):
		var x: float = base.x - 100 * scale_value + index * 48 * scale_value
		draw_line(Vector2(x, base.y - 73 * scale_value), Vector2(x + 14 * scale_value, base.y - 133 * scale_value), Color("2b413b"), 3)
	for index: int in range(3):
		_tree(base + Vector2(-66 + index * 60, -169 + abs(index - 1) * 15) * scale_value, 65 * scale_value, Color("526749"), 0.65 * scale_value)
	draw_rect(Rect2(base + Vector2(-121, -2) * scale_value, Vector2(50, 21) * scale_value), Color("354b40"))
	draw_rect(Rect2(base + Vector2(65, -2) * scale_value, Vector2(50, 21) * scale_value), Color("354b40"))

func _shell() -> void:
	draw_rect(Rect2(-40, floor_y + 8, width + 80, 130), Color("3c4f43"))
	for index: int in range(int(width / 80) + 1):
		var x: float = index * 80
		draw_colored_polygon(PackedVector2Array([Vector2(x, floor_y + 14), Vector2(x + 48, floor_y + 12), Vector2(x + 70, floor_y + 48), Vector2(x + 35, floor_y + 76), Vector2(x - 10, floor_y + 53)]), Color("566447"))
		_tree(Vector2(x + 25, floor_y), 35 + index % 3 * 13, Color("526746"), 0.45)

func _sign(base: Vector2, label: String) -> void:
	draw_rect(Rect2(base + Vector2(-2, -56), Vector2(4, 56)), Color("615844"))
	draw_rect(Rect2(base + Vector2(-28, -60), Vector2(65, 15)), Color("605b45"))
	draw_string(ThemeDB.fallback_font, base + Vector2(-24, -49), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("c2b58b"))
