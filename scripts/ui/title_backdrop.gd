extends Control
## Original geometric title artwork; no external image assets.

var elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("0b141b"))
	# Layers of sky and the abandoned imperial road.
	for i: int in range(9):
		draw_rect(Rect2(0, 90 + i * 30, 640, 30), Color(0.055 + i * 0.004, 0.09 + i * 0.007, 0.12 + i * 0.004))
	draw_circle(Vector2(486, 80), 34, Color("687466"))
	draw_circle(Vector2(476, 74), 34, Color("17272e"))
	for layer: int in range(3):
		var color: Color = [Color("20393c"), Color("182e31"), Color("102225")][layer]
		for i: int in range(11):
			var x: float = float(i * 74 + layer * 24 - 24)
			var h: float = float(70 + (i * 43 + layer * 29) % 100)
			var base: float = 270.0 + layer * 30.0
			draw_rect(Rect2(x, base - h, 6 + layer * 2, h), color)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 24, base - h + 30), Vector2(x + 3, base - h - 34), Vector2(x + 32, base - h + 30)]), color)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 32, base - h + 63), Vector2(x + 3, base - h - 6), Vector2(x + 39, base - h + 63)]), color)
	# Fortress ruin behind the Worldbearer silhouette.
	draw_rect(Rect2(529, 142, 53, 125), Color("263b3c"))
	for i: int in range(4):
		draw_rect(Rect2(526 + 17 * i, 132, 10, 17), Color("263b3c"))
	draw_rect(Rect2(549, 172, 9, 34), Color("14282c"))
	draw_rect(Rect2(535, 220, 35, 5), Color("40514a"))
	# Mossback: shell, stone plates, immense neck and old trees.
	var shell: PackedVector2Array = PackedVector2Array([Vector2(332, 283), Vector2(347, 238), Vector2(386, 206), Vector2(454, 198), Vector2(515, 221), Vector2(537, 269), Vector2(521, 290)])
	draw_colored_polygon(shell, Color("344a3f"))
	draw_polyline(shell, Color("6b7750"), 3)
	draw_line(Vector2(348, 242), Vector2(517, 241), Color("162c2c"), 4)
	draw_line(Vector2(393, 208), Vector2(380, 281), Color("162c2c"), 4)
	draw_line(Vector2(457, 202), Vector2(476, 283), Color("162c2c"), 4)
	draw_rect(Rect2(353, 278, 29, 34), Color("213c38"))
	draw_rect(Rect2(476, 275, 32, 36), Color("213c38"))
	draw_colored_polygon(PackedVector2Array([Vector2(511, 260), Vector2(561, 258), Vector2(580, 273), Vector2(570, 290), Vector2(522, 286)]), Color("35524a"))
	draw_rect(Rect2(558, 269, 4, 3), Color("d6c788"))
	for i: int in range(3):
		var x: float = 381.0 + i * 46.0
		draw_rect(Rect2(x, 165 - i * 11, 7, 53), Color("263b30"))
		draw_circle(Vector2(x + 2, 166 - i * 11), 23 - i * 2, Color("486046"))
		draw_rect(Rect2(x - 17, 165 - i * 11, 37, 8), Color("40593f"))
	draw_rect(Rect2(0, 312, 640, 48), Color("0b141b"))
	for i: int in range(18):
		var x: float = fmod(float(i * 101) + elapsed * (1.0 + i % 3), 640.0)
		var y: float = 160.0 + fmod(float(i * 43) - elapsed * 3.0, 150.0)
		var alpha: float = 0.12 + 0.22 * (sin(elapsed * 1.5 + i) + 1.0) * 0.5
		draw_rect(Rect2(x, y, 2, 2), Color(0.75, 0.78, 0.49, alpha))
	# Quiet left gradient simulated with broad translucent bands.
	for i: int in range(10):
		draw_rect(Rect2(i * 32, 0, 32, 360), Color(0.025, 0.045, 0.06, 0.72 - i * 0.06))
