class_name WBInteractable
extends Node2D
## Reusable, persistent world interaction. All durable changes flow through Game.

var kind: String = "lore"
var prompt: String = "Inspect"
var data: Dictionary = {}
var clock: float = 0.0
var used: bool = false
var display_name: String = ""

func configure(type: String, label: String, payload: Dictionary = {}) -> void:
	kind = type
	prompt = label
	display_name = label
	data = payload

func _ready() -> void:
	add_to_group("interactables")
	Game.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if kind == "treasure":
		used = Game.state.get("collected", []).has(str(data.get("id", "")))
	elif kind == "gate":
		prompt = "Take the opened passage" if Game.has_flag("shortcut_open") else "Gate barred from inside"
	elif kind == "lever":
		prompt = "Shortcut opened" if Game.has_flag("shortcut_open") else "Unbar the Rootwild shortcut"
	elif kind == "mossback":
		prompt = "Enter Mossback's settlement" if Game.state.get("worldbearer", {}).get("awake", false) else "Awaken the sleeping Worldbearer"
	elif kind == "build":
		var key: String = str(data.get("slot", 0))
		var buildings: Dictionary = Game.state.get("worldbearer", {}).get("buildings", {})
		prompt = "Building slot %d" % (int(key) + 1)
		if buildings.has(key):
			prompt = str(buildings[key]).capitalize() + " · inspect slot"
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func interact(_player: Node2D) -> void:
	match kind:
		"exit":
			var destination: String = str(data.get("area", "road"))
			if destination == "vale" and not Game.has_flag("bell_warden_defeated"):
				Game.notify("The Warden binds the road. Silence his bell to reach Mossback Vale.")
				return
			Game.travel(destination, str(data.get("entry", "default")))
		"rest":
			Game.rest(Game.current_area, position + Vector2(28, 0))
		"treasure":
			if used:
				Game.notify("Only dust remains.")
				return
			if Game.collect(str(data.get("id", "cache")), str(data.get("item", "scrap")), int(data.get("amount", 3))):
				if data.has("flag"):
					Game.set_flag(str(data.flag))
				Game.notify(str(data.get("text", "Recovered useful supplies.")))
				Game.play_sound("pickup")
				Game.save_game()
				_refresh()
		"lore":
			Game.set_flag(str(data.get("id", "lore_found")))
			Game.notify(str(data.get("text", "The stones remember.")))
			Game.save_game()
		"lever":
			Game.set_flag("shortcut_open")
			Game.notify("The old portcullis rises. A permanent passage links the road and courtyard.")
			Game.play_sound("interact")
			Game.save_game()
			_refresh()
		"gate":
			if Game.has_flag("shortcut_open"):
				Game.travel(str(data.get("area", "courtyard")), str(data.get("entry", "shortcut")))
			else:
				Game.notify("Barred from Bellhaven's inner courtyard. Seek the lever beyond its walls.")
		"mossback":
			if str(Game.state.get("worldbearer", {}).get("location", "vale")) != Game.current_area:
				Game.notify("Mossback rests at the other migration stop. Follow its footprints.")
				return
			if not Game.state.get("worldbearer", {}).get("awake", false):
				Game.awaken_mossback()
			else:
				Game.travel("settlement", "default")
		"build":
			Game.notify("BUILD_SLOT:%d" % int(data.get("slot", 0)))
		"storage":
			Game.notify("STORAGE")
		"migration":
			if not bool(Game.state.get("worldbearer", {}).get("route_unlocked", false)):
				Game.notify("No migration route charted. Seek the old wayfinding tablet beyond Mossback in the Vale.")
				return
			Game.migrate()
		"disembark":
			var location: String = str(Game.state.get("worldbearer", {}).get("location", "vale"))
			Game.travel(location, "mossback")
		"route":
			var bear: Dictionary = Game.state.get("worldbearer", {})
			bear["route_unlocked"] = true
			Game.set_flag("migration_route_found")
			Game.notify("Migration discovered: the Fallen Caravan. The shell's helm can take you there.")
			Game.save_game()

func _draw() -> void:
	var gold: Color = Color("d3ad66")
	var pale: Color = Color("e2dbb7")
	var dark: Color = Color("182c30")
	match kind:
		"rest":
			draw_circle(Vector2(0, -11), 29, Color(0.46, 0.75, 0.64, 0.06 + 0.025 * sin(clock * 2.0)))
			draw_rect(Rect2(-12, 13, 24, 4), Color("405348"))
			draw_colored_polygon(PackedVector2Array([Vector2(-9, 12), Vector2(-7, -23), Vector2(0, -30), Vector2(8, -24), Vector2(11, 12)]), Color("5b6960"))
			draw_line(Vector2(0, -19), Vector2(0, 6), Color("a7dfbb"), 2)
			draw_line(Vector2(-5, -8), Vector2(5, -8), Color("a7dfbb"), 2)
			draw_circle(Vector2(0, -12), 3, Color("d3f4bf"))
		"treasure", "storage":
			var tint: Color = Color("5c4534") if used else Color("987744")
			draw_rect(Rect2(-13, 1, 26, 14), dark)
			draw_rect(Rect2(-12, 0 if not used else -7, 24, 9), tint)
			draw_rect(Rect2(-12, 9, 24, 7), Color("493d32"))
			draw_rect(Rect2(-7, 0, 3, 16), gold)
			draw_rect(Rect2(5, 0, 3, 16), gold)
			if not used:
				draw_rect(Rect2(-1, 5, 3, 4), pale)
		"lore", "route":
			draw_rect(Rect2(-10, -13, 20, 29), Color("485148"))
			draw_rect(Rect2(-12, 12, 24, 5), Color("293e3d"))
			for i: int in range(4):
				draw_line(Vector2(-5, -7 + i * 4), Vector2(6 - i % 2 * 4, -7 + i * 4), gold, 1)
		"exit", "disembark":
			draw_line(Vector2(0, -22), Vector2(0, 15), Color("5b5240"), 4)
			var direction: float = float(data.get("direction", 1))
			draw_colored_polygon(PackedVector2Array([Vector2(-13, -22), Vector2(10, -22), Vector2(17, -17), Vector2(10, -12), Vector2(-13, -12)]) * Transform2D(Vector2(direction, 0), Vector2(0, 1), Vector2.ZERO), Color("6c6046"))
			draw_line(Vector2(-8 * direction, -17), Vector2(8 * direction, -17), gold, 1)
		"gate", "lever":
			var open: bool = Game.has_flag("shortcut_open")
			if kind == "lever":
				draw_rect(Rect2(-9, 5, 18, 11), Color("4e5850"))
				draw_line(Vector2(0, 6), Vector2(10 if open else -10, -13), gold, 3)
				draw_circle(Vector2(10 if open else -10, -13), 4, pale)
			else:
				draw_rect(Rect2(-27, -52, 8, 68), Color("475348"))
				draw_rect(Rect2(19, -52, 8, 68), Color("475348"))
				draw_rect(Rect2(-27, -57, 54, 8), Color("69705c"))
				for i: int in range(5):
					draw_line(Vector2(-16 + i * 8, -48), Vector2(-16 + i * 8, -33 if open else 15), Color("8c8a69"), 2)
		"mossback":
			draw_circle(Vector2(0, -10), 20 + sin(clock) * 2, Color(0.65, 0.84, 0.58, 0.08))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -25), Vector2(10, -8), Vector2(0, 8), Vector2(-10, -8)]), gold)
			draw_circle(Vector2(0, -8), 4, Color("edf1bd"))
		"build":
			_draw_building()
		"migration":
			draw_line(Vector2(0, -10), Vector2(0, 16), Color("887247"), 4)
			draw_arc(Vector2(0, -12), 16, 0, TAU, 16, gold, 3)
			for i: int in range(6):
				var vec: Vector2 = Vector2.from_angle(i * TAU / 6.0)
				draw_line(Vector2(0, -12) + vec * 5, Vector2(0, -12) + vec * 21, gold, 2)
	# A faint moted glimmer makes discoveries readable without a quest marker.
	if kind in ["treasure", "rest", "mossback", "route"] and not used:
		var mote: Vector2 = Vector2(sin(clock * 1.4) * 9, -28 - fmod(clock * 7, 18))
		draw_rect(Rect2(mote, Vector2(2, 2)), Color(gold, 0.6))

func _draw_building() -> void:
	var structures: Dictionary = Game.state.get("worldbearer", {}).get("buildings", {})
	var key: String = str(data.get("slot", 0))
	var structure: String = str(structures.get(key, ""))
	var wood: Color = Color("6e6046")
	var gold: Color = Color("cab474")
	if structure.is_empty():
		draw_rect(Rect2(-35, 12, 70, 3), Color("718263"))
		for x: int in [-34, 34]:
			draw_line(Vector2(x, 12), Vector2(x, -5), wood, 2)
			draw_rect(Rect2(x - 3, -9, 7, 4), gold)
		draw_line(Vector2(-5, -5), Vector2(5, -5), gold, 2)
		draw_line(Vector2(0, -10), Vector2(0, 0), gold, 2)
	elif structure == "shelter":
		draw_colored_polygon(PackedVector2Array([Vector2(-35, 13), Vector2(-5, -45), Vector2(34, 13)]), Color("51665b"))
		draw_colored_polygon(PackedVector2Array([Vector2(-5, -45), Vector2(4, 13), Vector2(34, 13)]), Color("79917a"))
		draw_colored_polygon(PackedVector2Array([Vector2(-21, 13), Vector2(-5, -24), Vector2(4, 13)]), Color("142b2b"))
		draw_line(Vector2(-5, -45), Vector2(4, 13), gold, 2)
	elif structure == "workbench":
		draw_rect(Rect2(-31, -7, 62, 8), wood)
		draw_rect(Rect2(-26, 1, 5, 14), wood)
		draw_rect(Rect2(21, 1, 5, 14), wood)
		draw_rect(Rect2(-14, -14, 22, 7), Color("657377"))
		draw_line(Vector2(12, -9), Vector2(20, -24), gold, 3)
		draw_rect(Rect2(12, -28, 15, 7), Color("a8b0a3"))
	elif structure == "garden":
		draw_rect(Rect2(-34, 5, 68, 12), wood)
		draw_rect(Rect2(-31, 4, 62, 5), Color("2c362e"))
		for i: int in range(5):
			var x: float = -25 + i * 12
			draw_line(Vector2(x, 4), Vector2(x, -10 - i % 2 * 6), Color("839657"), 2)
			draw_line(Vector2(x, -5), Vector2(x - 6, -12), Color("9dae6c"), 2)
			draw_line(Vector2(x, -2), Vector2(x + 6, -9), Color("647e49"), 2)
