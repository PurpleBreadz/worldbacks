class_name WBWorld
extends Node2D
## Hand-authored layouts. Every collider, route, and encounter has an explicit position.

const InteractableScript = preload("res://scripts/world/interactable.gd")
const EnvironmentScript = preload("res://scripts/world/environment_art.gd")

var area_id: String = "caravan"
var bounds: Rect2 = Rect2(0, 0, 1600, 540)
var spawn_points: Dictionary = {}
var platform_rects: Array[Rect2] = []
var art: Node2D
var pending_enemies: Array[Dictionary] = []
var floor_y: float = 430.0
var area_title: String = "The Fallen Caravan"

func build(id: String) -> void:
	area_id = id
	name = "World_" + id
	match id:
		"caravan": _caravan()
		"road": _road()
		"tower": _tower()
		"courtyard": _courtyard()
		"vale": _vale()
		"settlement": _settlement()
		_: _caravan()
	if not spawn_points.has("left"):
		spawn_points["left"] = Vector2(84, floor_y - 16)
	if not spawn_points.has("right"):
		spawn_points["right"] = Vector2(bounds.size.x - 90, floor_y - 16)
	if not spawn_points.has("default"):
		spawn_points["default"] = spawn_points.left
	spawn_points["checkpoint"] = spawn_points.default
	_wall(-16)
	_wall(bounds.size.x + 16)
	art = EnvironmentScript.new()
	art.area_id = area_id
	art.width = bounds.size.x
	art.height = bounds.size.y
	art.floor_y = floor_y
	art.platform_rects = platform_rects
	art.z_index = -20
	add_child(art)

func _ready() -> void:
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy.tscn")
	for encounter: Dictionary in pending_enemies:
		if str(encounter.kind) == "bell_warden" and Game.has_flag("bell_warden_defeated"):
			continue
		var enemy: Node2D = enemy_scene.instantiate()
		enemy.configure(str(encounter.kind), str(encounter.id))
		enemy.position = encounter.position
		add_child(enemy)

func _ground(width: float, y: float = 430.0) -> void:
	floor_y = y
	bounds = Rect2(0, 0, width, y + 110)
	_platform(Rect2(0, y, width, 110), false)

func _platform(rect: Rect2, one_way: bool = true) -> void:
	platform_rects.append(rect)
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.position + rect.size / 2.0
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	collider.one_way_collision = one_way
	collider.one_way_collision_margin = 6.0
	body.add_child(collider)
	add_child(body)

func _wall(x: float) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = Vector2(x, bounds.size.y / 2)
	body.collision_layer = 1
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(32, bounds.size.y + 300)
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _interaction(kind: String, label: String, at: Vector2, data: Dictionary = {}) -> Node2D:
	var node: Node2D = InteractableScript.new()
	node.configure(kind, label, data)
	node.position = at
	add_child(node)
	return node

func _encounter(kind: String, x: float, y: float = -1.0, suffix: String = "") -> void:
	var pos_y: float = y if y >= 0 else floor_y - (28 if kind == "bell_warden" else 16)
	pending_enemies.append({"kind":kind, "position":Vector2(x, pos_y), "id":area_id + "_" + kind + "_" + str(int(x)) + suffix})

func _label(text: String, at: Vector2, muted: bool = false) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", 11 if not muted else 9)
	label.add_theme_color_override("font_color", Color("c8c7a3") if not muted else Color("8eaa96"))
	label.add_theme_color_override("font_shadow_color", Color("102022"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

func _caravan() -> void:
	area_title = "The Fallen Caravan"
	_ground(1480)
	spawn_points = {"default":Vector2(90, 414), "left":Vector2(90, 414), "right":Vector2(1370, 414), "mossback":Vector2(1180, 414)}
	_interaction("rest", "Rest at the Waystone", Vector2(185, 414))
	_label("THE FALLEN CARAVAN", Vector2(74, 316))
	_label("A / D  move     SPACE  jump", Vector2(74, 343), true)
	_label("E  rest / interact     ESC  pause", Vector2(74, 357), true)
	_platform(Rect2(350, 379, 150, 15))
	_interaction("treasure", "Search beneath the broken wagon", Vector2(426, 414), {"id":"caravan_hidden_cache", "item":"scrap", "amount":4, "text":"A caravan cache: 4 anchor scraps. These can raise a home on a Worldbearer's back."})
	_interaction("lore", "Read the caravan keeper's tablet", Vector2(620, 414), {"id":"lore_caravan", "text":"'We built our roads along their footprints. Then the Crown taught us to chain the feet.' — last caravan keeper"})
	_label("J  sword     K  guard / timed deflect", Vector2(710, 325), true)
	_label("SHIFT  dodge     Q  heal", Vector2(710, 339), true)
	_encounter("scavenger", 900)
	_label("The Overgrown Road  →", Vector2(1210, 348), true)
	_interaction("exit", "Travel to the Overgrown Road", Vector2(1410, 414), {"area":"road", "entry":"left"})
	if Game.state.get("worldbearer", {}).get("awake", false) and Game.state.get("worldbearer", {}).get("location", "vale") == "caravan":
		_interaction("mossback", "Board Mossback", Vector2(1190, 414))

func _road() -> void:
	area_title = "The Overgrown Road"
	_ground(1900)
	spawn_points = {"default":Vector2(100, 414), "left":Vector2(100, 414), "right":Vector2(1790, 414), "tower":Vector2(860, 414), "shortcut":Vector2(1530, 414), "mossback":Vector2(1320, 414)}
	_interaction("exit", "Return to the Fallen Caravan", Vector2(40, 414), {"area":"caravan", "entry":"right", "direction":-1})
	_label("THE OVERGROWN ROAD", Vector2(190, 332))
	_label("Follow the iron bell. Or climb above its shadow.", Vector2(190, 350), true)
	_encounter("scavenger", 460)
	_encounter("wolf", 680)
	_platform(Rect2(780, 375, 135, 16))
	_platform(Rect2(900, 322, 190, 16))
	_interaction("exit", "Climb to the Old Watchtower", Vector2(840, 414), {"area":"tower", "entry":"default"})
	_label("↑ OLD WATCHTOWER", Vector2(780, 340), true)
	_interaction("treasure", "Recover the scout's satchel", Vector2(1030, 306), {"id":"road_satchel", "item":"scrap", "amount":3, "text":"Three anchor scraps, tucked beneath a scout's broken lens."})
	_encounter("wolf", 1220)
	_interaction("lore", "Trace the old migration map", Vector2(1350, 414), {"id":"lore_migration", "text":"Bellhaven's bell once marked safe passage. Its Warden now keeps every road shut. Beyond its walls, Mossback still dreams."})
	_interaction("gate", "Gate barred from inside", Vector2(1520, 414), {"area":"courtyard", "entry":"shortcut"})
	_label("INNER PASSAGE", Vector2(1465, 338), true)
	_interaction("exit", "Enter Bellhaven Courtyard", Vector2(1830, 414), {"area":"courtyard", "entry":"left"})
	_label("BELLHAVEN  →", Vector2(1720, 348), true)

func _tower() -> void:
	area_title = "The Old Watchtower"
	_ground(1400, 750)
	spawn_points = {"default":Vector2(105, 734), "left":Vector2(105, 734), "right":Vector2(105, 734)}
	_interaction("exit", "Descend to the Overgrown Road", Vector2(40, 734), {"area":"road", "entry":"tower", "direction":-1})
	_label("THE OLD WATCHTOWER", Vector2(90, 650))
	_label("An optional ascent. A forgotten edge awaits above.", Vector2(90, 669), true)
	_encounter("scavenger", 210)
	# Eleven fixed, overlapping stair ledges. Each rise is within the starting jump.
	for i: int in range(10):
		_platform(Rect2(290 + i * 70, 695 - i * 55, 120, 12))
	_platform(Rect2(980, 145, 330, 18))
	_encounter("sentinel", 1130, 129)
	_interaction("treasure", "Claim the watchkeeper's tempered edge", Vector2(1250, 129), {"id":"tower_tempered_edge", "item":"scrap", "amount":5, "flag":"tempered_edge", "text":"TEMPERED EDGE — your sword now deals more damage. Recovered 5 anchor scraps. The Rootwild opens beneath you."})
	_interaction("lore", "Read the watchkeeper's vow", Vector2(1000, 129), {"id":"lore_tower", "text":"'When the iron bell falls silent, wake the hill that breathes. Let no crown ever bind its road again.'"})
	_label("A road once walked by giants", Vector2(1000, 105), true)

func _courtyard() -> void:
	area_title = "Bellhaven Courtyard"
	_ground(2020)
	spawn_points = {"default":Vector2(100, 414), "left":Vector2(100, 414), "right":Vector2(1910, 414), "shortcut":Vector2(690, 414)}
	_interaction("exit", "Leave through Bellhaven's outer gate", Vector2(40, 414), {"area":"road", "entry":"right", "direction":-1})
	_label("BELLHAVEN COURTYARD", Vector2(120, 324))
	_interaction("rest", "Rest at the outer Waystone", Vector2(210, 414))
	_encounter("sentinel", 460)
	_interaction("lever", "Unbar the Rootwild shortcut", Vector2(650, 414))
	_interaction("gate", "Take the opened passage", Vector2(745, 414), {"area":"road", "entry":"shortcut"})
	_platform(Rect2(580, 375, 140, 14))
	_encounter("scavenger", 900)
	_interaction("rest", "Rest before the Bell Warden", Vector2(1100, 414))
	_interaction("lore", "Read the Bell Oath", Vector2(1210, 414), {"id":"lore_bell", "text":"'Guard the chain until the Crown returns.' His oath outlived its empire. Deflect the blade, watch the ground, punish the silence."})
	_label("THE BELL WARDEN", Vector2(1380, 302))
	_label("A bright tell heralds the strike. Deflect at the last moment.", Vector2(1270, 327), true)
	_encounter("bell_warden", 1530)
	_interaction("exit", "Open the migration road to Mossback Vale", Vector2(1945, 414), {"area":"vale", "entry":"left"})
	_label("MOSSBACK VALE  →", Vector2(1810, 348), true)

func _vale() -> void:
	area_title = "Mossback Vale"
	_ground(1600)
	spawn_points = {"default":Vector2(100, 414), "left":Vector2(100, 414), "mossback":Vector2(1020, 414), "right":Vector2(1470, 414)}
	_interaction("exit", "Return to Bellhaven", Vector2(40, 414), {"area":"courtyard", "entry":"right", "direction":-1})
	_label("MOSSBACK VALE", Vector2(170, 324))
	_label("The hill breathes.", Vector2(170, 347), true)
	_interaction("rest", "Rest beneath the ancient boughs", Vector2(400, 414))
	_interaction("lore", "Touch the World Anchor's remains", Vector2(650, 414), {"id":"lore_anchor", "text":"The broken anchor hums against your key. Beneath moss and centuries, a colossal heart answers. The migration can begin again."})
	if str(Game.state.get("worldbearer", {}).get("location", "vale")) == "vale":
		_interaction("mossback", "Awaken the sleeping Worldbearer", Vector2(1040, 414))
	else:
		_interaction("lore", "Inspect Mossback's resting hollow", Vector2(1040, 414), {"id":"lore_empty_vale", "text":"Deep prints lead toward the Fallen Caravan. Mossback rests at the other migration stop."})
	_interaction("route", "Discover a forgotten migration stop", Vector2(1380, 414))
	_label("THE FIRST WORLDBEARER", Vector2(920, 348), true)

func _settlement() -> void:
	area_title = "Mossback's Crown"
	_ground(1280)
	spawn_points = {"default":Vector2(120, 414), "left":Vector2(120, 414), "right":Vector2(1150, 414)}
	_interaction("disembark", "Climb down from Mossback", Vector2(45, 414), {"direction":-1})
	_label("MOSSBACK'S CROWN", Vector2(125, 324))
	_label("A home above the broken world.", Vector2(125, 344), true)
	_interaction("rest", "Rest at the shell Waystone", Vector2(235, 414))
	_interaction("storage", "Open shared storage", Vector2(360, 414))
	_interaction("build", "Building slot 1", Vector2(530, 414), {"slot":0})
	_interaction("build", "Building slot 2", Vector2(710, 414), {"slot":1})
	_interaction("build", "Building slot 3", Vector2(890, 414), {"slot":2})
	_label("DESIGNATED BUILDING SLOTS", Vector2(570, 353), true)
	_interaction("migration", "Guide Mossback along the old road", Vector2(1110, 414))
	_label("MIGRATION HELM", Vector2(1055, 348), true)
