extends SceneTree
## Native logic/integration suite. Never reads or writes the player's save.
## Run with --script res://tests/run_tests.gd; --write-save / --read-save prove
## persistence across separate Godot processes, using an isolated test filename.

var game: Node
var app: Node
var passed: int = 0
var failed: int = 0
var test_path: String
const ROUNDTRIP_PATH: String = "user://worldback_tests_roundtrip.json"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	game = root.get_node("Game")
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if "--write-save" in arguments:
		_write_roundtrip()
		_finish()
		return
	if "--read-save" in arguments:
		_read_roundtrip()
		_finish()
		return
	test_path = "user://worldback_tests_%d.json" % OS.get_process_id()
	game.save_path = test_path
	_erase_test_save(test_path)
	_test_save_schema()
	_test_campaign_state()
	_test_save_failures()
	await _test_combat()
	await _test_connected_game()
	_erase_test_save(test_path)
	_finish()

func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + description)
	else:
		failed += 1
		printerr("FAIL: " + description)

func _finish() -> void:
	paused = false
	Engine.time_scale = 1.0
	for action: String in ["move_left", "move_right", "jump", "dodge", "attack", "block", "heal", "interact"]:
		Input.action_release(action)
	print("WORLDBACK TESTS COMPLETE: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 and passed > 0 else 1)

func _erase_test_save(path: String) -> void:
	# Only the two explicit test namespaces may ever be removed.
	if not path.begins_with("user://worldback_tests_"):
		_check(false, "test cleanup refuses non-test save path")
		return
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func _frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame
	await process_frame

func _test_save_schema() -> void:
	var clean: Dictionary = game.fresh_state()
	_check(not game.validate_save(clean).is_empty(), "fresh campaign satisfies save schema")
	var bad: Dictionary = clean.duplicate(true)
	bad.version = 999
	_check(game.validate_save(bad).is_empty(), "future save version rejected")
	bad = clean.duplicate(true)
	bad.erase("inventory")
	_check(game.validate_save(bad).is_empty(), "missing required inventory rejected")
	bad = clean.duplicate(true)
	bad.area = "unreleased_region"
	_check(game.validate_save(bad).is_empty(), "unknown area rejected")
	bad = clean.duplicate(true)
	bad.position = ["bad", 5.0]
	_check(game.validate_save(bad).is_empty(), "nonnumeric player coordinate rejected")
	bad = clean.duplicate(true)
	bad.position = [INF, 5.0]
	_check(game.validate_save(bad).is_empty(), "nonfinite player coordinate rejected")
	bad = clean.duplicate(true)
	bad.checkpoint.position = [5.0]
	_check(game.validate_save(bad).is_empty(), "malformed checkpoint rejected")
	bad = clean.duplicate(true)
	bad.inventory.scrap = -2
	_check(game.validate_save(bad).is_empty(), "negative inventory rejected")
	bad = clean.duplicate(true)
	bad.flags.shortcut_open = "yes"
	_check(game.validate_save(bad).is_empty(), "nonboolean world flag rejected")
	bad = clean.duplicate(true)
	bad.worldbearer.buildings["9"] = "shelter"
	_check(game.validate_save(bad).is_empty(), "out-of-zone saved structure rejected")
	bad = clean.duplicate(true)
	bad.worldbearer.buildings["1"] = "unknown_building"
	_check(game.validate_save(bad).is_empty(), "unknown saved structure rejected")
	bad = clean.duplicate(true)
	bad.worldbearer.storage.scrap = "ten"
	_check(game.validate_save(bad).is_empty(), "malformed storage quantity rejected")
	bad = clean.duplicate(true)
	bad.health = 999
	bad.stamina = -1
	bad.heals = 20
	var clamped: Dictionary = game.validate_save(bad)
	_check(clamped.health == 100.0 and clamped.stamina == 0.0 and clamped.heals == 3, "bounded player resources normalized on load")

func _test_campaign_state() -> void:
	game.player = null
	game.new_game()
	_check(game.current_area == "caravan" and game.active_game, "new journey begins at Fallen Caravan")
	_check(game.has_save(), "new journey creates readable save")
	game.travel("vale")
	_check(game.current_area == "caravan", "migration road locked before Warden defeat")
	game.travel("settlement")
	_check(game.current_area == "caravan", "shell inaccessible before awakening")
	game.travel("not_an_area")
	_check(game.current_area == "caravan", "unknown travel destination rejected")
	game.awaken_mossback()
	_check(not game.state.worldbearer.awake, "World Anchor prevents premature awakening")
	game.travel("road", "left")
	_check(game.current_area == "road" and "road" in game.state.discovered, "valid travel records discovered area")
	game.collect("suite_cache", "scrap", 5)
	_check(game.item_count("scrap") == 5, "one-time treasure adds inventory")
	_check(not game.collect("suite_cache", "scrap", 5) and game.item_count("scrap") == 5, "repeated one-time treasure cannot duplicate reward")
	_check(not game.spend("scrap", 6) and game.item_count("scrap") == 5, "insufficient purchase leaves resources intact")
	_check(not game.spend("scrap", -1) and game.item_count("scrap") == 5, "negative purchase cannot mint resources")
	game.set_flag("shortcut_open")
	game.rest("road", Vector2(100, 414))
	_check(game.state.checkpoint.area == "road" and game.state.checkpoints.has("road"), "Waystone establishes persistent respawn")
	_check(game.state.health == 100.0 and game.state.stamina == 100.0 and game.state.heals == 3, "Waystone restores player resources")
	game.travel("courtyard")
	game.respawn()
	_check(game.current_area == "road" and game.has_flag("shortcut_open"), "respawn returns to checkpoint without clearing permanent shortcut")
	game.set_flag("bell_warden_defeated")
	game.travel("vale")
	_check(game.current_area == "vale", "defeated Warden opens migration road")
	game.awaken_mossback()
	_check(game.state.worldbearer.awake and game.has_flag("mossback_awake"), "awakening persists Worldbearer status")
	_check(not game.place_building(0, "shelter"), "building outside settlement rejected")
	game.travel("settlement")
	_check(not game.place_building(-1, "shelter") and not game.place_building(3, "shelter"), "only three authorized shell slots can be built")
	_check(not game.place_building(0, "castle"), "unsupported structure rejected")
	_check(game.place_building(0, "shelter") and game.item_count("scrap") == 2, "valid structure consumes exact resources")
	_check(not game.place_building(0, "garden") and game.item_count("scrap") == 2, "occupied slot rejects replacement without charging")
	_check(not game.place_building(1, "workbench"), "expensive structure requires enough scrap")
	game.store_scrap()
	_check(game.item_count("scrap") == 0 and game.state.worldbearer.storage.scrap == 2, "storage transfers inventory without duplication")
	game.take_scrap()
	_check(game.item_count("scrap") == 2 and game.state.worldbearer.storage.scrap == 0, "storage withdrawal restores exact quantity")
	_check(not game.migrate(), "migration stays locked until route is discovered")
	game.state.worldbearer.route_unlocked = true
	_check(game.migrate() and game.state.worldbearer.location == "caravan", "unlocked route migrates shell to Fallen Caravan")
	_check(game.state.worldbearer.buildings.get("0") == "shelter", "migration preserves placed structure")
	_check(game.migrate() and game.state.worldbearer.location == "vale", "migration supports return journey")
	game.save_game()
	game.state = game.fresh_state()
	_check(game.continue_game(), "saved campaign restores successfully")
	_check(game.has_flag("bell_warden_defeated") and game.has_flag("shortcut_open") and game.state.worldbearer.buildings.get("0") == "shelter", "load preserves boss, shortcut and settlement progression")

func _test_save_failures() -> void:
	_erase_test_save(test_path)
	_check(not game.has_save() and not game.continue_game(), "missing save handled without creating fake progress")
	game.new_game()
	game.state.inventory.scrap = 7
	_check(game.save_game(), "atomic save writes current snapshot")
	game.state.inventory.scrap = 9
	_check(game.save_game() and FileAccess.file_exists(test_path + ".bak"), "second save retains previous valid backup")
	var broken: FileAccess = FileAccess.open(test_path, FileAccess.WRITE)
	broken.store_string("{broken-json")
	broken.close()
	_check(game.continue_game() and game.item_count("scrap") == 7, "corrupt primary save recovers last valid backup")
	_erase_test_save(test_path)
	broken = FileAccess.open(test_path, FileAccess.WRITE)
	broken.store_string("[]")
	broken.close()
	_check(not game.continue_game(), "nonobject save without backup fails gracefully")
	game.new_game()
	_check(game.has_save() and game.item_count("scrap") == 0 and game.state.flags.is_empty(), "new journey replaces corrupt save and clears progress")

func _test_combat() -> void:
	game.new_game()
	var player: CharacterBody2D = load("res://scenes/player/player.tscn").instantiate()
	game.player = player
	root.add_child(player)
	player.set_physics_process(false)
	player.position = Vector2(100, 100)
	var enemy: CharacterBody2D = load("res://scenes/enemies/enemy.tscn").instantiate()
	enemy.configure("scavenger", "suite_scavenger")
	root.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.position = Vector2(130, 100)
	player.invulnerability = 0.0
	_check(player.receive_hit(17.0, 20.0, enemy) == "hit" and player.health == 83.0, "unblocked combat hit applies damage")
	_check(player.receive_hit(17.0, 20.0, enemy) == "dodge" and player.health == 83.0, "damage invulnerability prevents repeated overlapping hits")
	player.restore()
	player.invulnerability = 0.0
	player.action = "block"
	player.guard_time = 0.05
	player.facing = 1.0
	_check(player.receive_hit(20.0, 25.0, enemy) == "parry" and player.health == 100.0, "timed frontal guard performs damage-free deflection")
	_check(enemy.posture > 0.0 and enemy.action == "stagger", "deflection damages attacker posture and interrupts attack")
	player.action = "block"
	player.guard_time = 0.5
	player.posture = 0.0
	var stamina_before: float = player.stamina
	_check(player.receive_hit(20.0, 25.0, enemy) == "block" and player.health == 100.0, "late frontal guard blocks health damage")
	_check(player.stamina < stamina_before and player.posture == 25.0, "blocking consumes stamina and accumulates posture")
	player.posture = 99.0
	player.receive_hit(20.0, 25.0, enemy)
	_check(player.action == "stagger" and player.posture == player.max_posture, "full guard posture triggers punishable stagger")
	player.restore()
	player.invulnerability = 0.0
	player.action = "block"
	player.guard_time = 0.05
	enemy.position.x = 70
	_check(player.receive_hit(20.0, 25.0, enemy) == "hit" and player.health == 80.0, "rear attack bypasses forward guard")
	player.restore()
	player.health = 40.0
	player.heal()
	_check(player.action == "heal" and player.heals == 2 and player.health == 40.0, "healing commits a charge and has startup")
	player._update_action(0.7)
	_check(player.health == 88.0 and player.action == "idle", "completed healing restores expected health")
	player.action = "attack"
	var charges: int = player.heals
	player.heal()
	_check(player.heals == charges and player.action == "attack", "healing cannot cancel an active sword action")
	enemy.position.x = 130
	enemy.health = enemy.max_health
	enemy.posture = 0.0
	enemy.receive_parry(enemy.max_posture)
	_check(enemy.action == "broken", "enemy posture break opens vulnerable window")
	var health_before: float = enemy.health
	_check(enemy.receive_hit(10.0, 0.0, player) == "critical" and is_equal_approx(enemy.health, health_before - 22.0), "vulnerable-state hit receives critical multiplier")
	var scrap_before: int = game.item_count("scrap")
	enemy.receive_hit(1000.0, 0.0, player)
	var death_reward: int = game.item_count("scrap")
	enemy.receive_hit(1000.0, 0.0, player)
	_check(death_reward > scrap_before and game.item_count("scrap") == death_reward, "enemy death awards loot exactly once")
	var archetypes: Dictionary = {}
	for kind: String in ["scavenger", "wolf", "sentinel", "bell_warden"]:
		var data: Resource = load("res://resources/enemies/%s.tres" % kind)
		archetypes[kind] = data
		_check(data.max_health > 0 and data.startup > 0 and data.recovery > 0, "%s has valid data-driven combat timing" % kind)
	_check(archetypes.wolf.speed > archetypes.scavenger.speed and archetypes.sentinel.max_posture > archetypes.scavenger.max_posture, "archetypes differ in movement and armor posture")
	var boss: CharacterBody2D = load("res://scenes/enemies/enemy.tscn").instantiate()
	boss.configure("bell_warden", "suite_warden")
	root.add_child(boss)
	boss.set_physics_process(false)
	boss.position = Vector2(140, 100)
	player.restore()
	boss.health = boss.max_health * 0.5
	boss._update_ai(0.01)
	_check(boss.phase == 2 and boss.action == "phase", "Warden enters readable second phase at half health")
	boss.action = "pursue"
	boss.attack_index = 2
	boss._begin_attack()
	_check(boss.attack_kind == "ground" and boss.action == "tell" and boss.action_duration >= 0.8, "second phase ground attack has an explicit telegraph")
	boss.receive_hit(1000.0, 1000.0, player)
	_check(game.has_flag("bell_warden_defeated") and game.item_count("anchor_key") == 1, "boss defeat persists road key and world flag")
	boss.receive_hit(1000.0, 1000.0, player)
	_check(game.item_count("anchor_key") == 1, "boss cannot duplicate key reward after death")
	game.player = null
	player.queue_free()
	enemy.queue_free()
	boss.queue_free()
	await process_frame

func _find_interaction(kind: String, destination: String = "") -> Node2D:
	for candidate: Node in get_nodes_in_group("interactables"):
		if candidate.is_inside_tree() and candidate.kind == kind:
			if destination.is_empty() or str(candidate.data.get("area", "")) == destination:
				return candidate
	return null

func _use(kind: String, destination: String = "") -> bool:
	var target: Node2D = _find_interaction(kind, destination)
	if target == null:
		_check(false, "required interaction exists: %s %s" % [kind, destination])
		return false
	game.player.position = target.position
	target.interact(game.player)
	return true

func _freeze_enemies() -> void:
	for enemy: Node in get_nodes_in_group("enemies"):
		if enemy.is_inside_tree():
			enemy.set_physics_process(false)

func _test_connected_game() -> void:
	game.active_game = false
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	_check(app.ui.mode == "menu" and not app.ui.panel_open, "main scene launches into usable menu")
	game.new_game()
	await _frames(5)
	_freeze_enemies()
	_check(app.world.area_id == "caravan" and app.ui.mode == "game" and game.player.is_on_floor(), "New Game builds world, HUD, player and working floor collision")
	var start_x: float = game.player.position.x
	Input.action_press("move_right")
	await _frames(20)
	Input.action_release("move_right")
	_check(game.player.position.x > start_x + 20, "Input Map movement advances player through physics")
	var floor_height: float = game.player.position.y
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	_check(game.player.position.y < floor_height - 5 and game.player.velocity.y < 0, "jump action launches player above floor")
	await _frames(45)
	_check(game.player.is_on_floor(), "jump returns to colliding handcrafted ground")
	Input.action_press("dodge")
	await _frames(3)
	Input.action_release("dodge")
	_check(game.player.action == "dodge" and game.player.invulnerability > 0.0 and game.player.stamina < 100.0, "dodge input grants timed invulnerability and spends stamina")
	await _frames(28)
	Input.action_press("attack")
	await _frames(3)
	Input.action_release("attack")
	_check(game.player.action == "attack", "sword input enters locked attack sequence")
	await _frames(32)
	Input.action_press("block")
	await _frames(3)
	_check(game.player.action == "block", "guard input enters defensive action")
	Input.action_release("block")
	await _frames(2)
	game.player.health = 40.0
	Input.action_press("heal")
	await _frames(2)
	Input.action_release("heal")
	await _frames(45)
	_check(game.player.health == 88.0 and game.player.heals == 2, "healing input completes timed restoration in live scene")
	var event := InputEventAction.new()
	event.action = "inventory"
	event.pressed = true
	app.ui._unhandled_input(event)
	_check(paused and app.ui.panel_kind == "inventory", "inventory panel pauses active gameplay")
	app.ui.close_panel()
	_check(not paused, "closing panel resumes gameplay")
	_use("treasure")
	var loot: int = game.item_count("scrap")
	_use("treasure")
	_check(loot == 4 and game.item_count("scrap") == loot, "caravan hidden cache grants useful one-time resources")
	_use("lore")
	_check(game.has_flag("lore_caravan"), "environmental lore discovery persists")
	_use("rest")
	_check(game.player.health == 100.0 and game.player.heals == 3 and game.state.checkpoints.has("caravan"), "actual Waystone restores and saves live player")
	_use("exit", "road")
	_check(app.world.area_id == "road", "caravan exit connects to Overgrown Road")
	_use("gate")
	_check(app.world.area_id == "road", "shortcut cannot be entered from barred side")
	_use("exit", "tower")
	_check(app.world.area_id == "tower" and app.world.platform_rects.size() > 10, "optional watchtower builds vertical authored platforms")
	_use("treasure")
	_check(game.has_flag("tempered_edge") and game.item_count("scrap") >= 9, "watchtower treasure grants permanent sword upgrade")
	_use("exit", "road")
	_use("exit", "courtyard")
	_check(app.world.area_id == "courtyard", "main road reaches Bellhaven without gate shortcut")
	_use("lever")
	_check(game.has_flag("shortcut_open"), "courtyard lever opens permanent shortcut")
	_use("gate", "road")
	_use("gate", "courtyard")
	_check(app.world.area_id == "courtyard", "opened shortcut works bidirectionally")
	_use("exit", "vale")
	_check(app.world.area_id == "courtyard", "actual Vale exit respects living boss gate")
	_freeze_enemies()
	var warden: Node2D
	for enemy: Node in get_nodes_in_group("enemies"):
		if enemy.is_inside_tree() and enemy.boss:
			warden = enemy
	_check(is_instance_valid(warden), "Bell Warden exists in authored arena")
	if is_instance_valid(warden):
		warden.receive_hit(1000.0, 1000.0, game.player)
	_check(game.has_flag("bell_warden_defeated"), "arena boss death opens campaign progression")
	_use("rest")
	var live_bosses: int = 0
	var normal_enemies: int = 0
	for enemy: Node in get_nodes_in_group("enemies"):
		if enemy.is_inside_tree():
			if enemy.boss:
				live_bosses += 1
			else:
				normal_enemies += 1
	_check(live_bosses == 0 and normal_enemies > 0, "rest respawns normal enemies while keeping boss defeated")
	var checkpoint: Vector2 = Vector2(game.state.checkpoint.position[0], game.state.checkpoint.position[1])
	game.player.position = Vector2(1400, 414)
	game.player.invulnerability = 0.0
	game.player.receive_hit(1000.0, 1000.0)
	_check(not game.player.is_alive(), "lethal damage enters death state")
	await create_timer(1.7, true, false, true).timeout
	_check(game.player.is_alive() and game.player.position.distance_to(checkpoint) < 25 and game.has_flag("shortcut_open"), "death timer returns player to Waystone with permanent progress")
	_use("exit", "vale")
	_check(app.world.area_id == "vale", "defeated Warden permits travel to Mossback Vale")
	_use("mossback")
	_check(game.state.worldbearer.awake, "actual Worldbearer interaction awakens Mossback")
	_use("route")
	_check(game.has_flag("migration_route_found") and game.state.worldbearer.route_unlocked, "discovered route unlocks migration destination")
	_use("mossback")
	_check(app.world.area_id == "settlement", "awakened Mossback connects to separate shell scene")
	_use("build")
	_check(app.ui.panel_kind == "building" and paused, "designated slot opens building interface")
	app.ui.close_panel()
	_check(game.place_building(0, "garden"), "settlement slot accepts an affordable prefab")
	_use("storage")
	_check(app.ui.panel_kind == "storage", "shell storage opens functioning inventory interface")
	app.ui.close_panel()
	var carried: int = game.item_count("scrap")
	game.store_scrap()
	_check(game.state.worldbearer.storage.scrap == carried, "live settlement storage retains cargo")
	_use("migration")
	_check(app.world.area_id == "settlement" and game.state.worldbearer.location == "caravan", "shell helm migrates scene between discrete stops")
	_use("disembark")
	_check(app.world.area_id == "caravan" and _find_interaction("mossback") != null, "migrated exterior allows disembark and reboarding")
	_use("mossback")
	game.player.position = Vector2(530, 414)
	game.player.health = 73.0
	game.player.heals = 1
	game.save_game()
	game.return_to_menu()
	_check(app.ui.mode == "menu", "save and return to title closes active world")
	_check(game.continue_game(), "Continue button backend restores saved live journey")
	_check(app.world.area_id == "settlement" and game.player.health == 73.0 and game.player.heals == 1, "Continue restores area and player resources")
	_check(game.state.worldbearer.buildings.get("0") == "garden" and game.state.worldbearer.storage.scrap == carried and game.has_flag("tempered_edge"), "Continue preserves structure, storage and optional reward")
	game.active_game = false
	game.player = null
	app.queue_free()
	await process_frame

func _write_roundtrip() -> void:
	test_path = ROUNDTRIP_PATH
	game.save_path = test_path
	_erase_test_save(test_path)
	game.player = null
	game.new_game()
	game.state = game.fresh_state()
	game.current_area = "settlement"
	game.state.area = "settlement"
	game.state.position = [532.0, 414.0]
	game.state.health = 63.0
	game.state.heals = 1
	game.state.stamina = 74.0
	game.state.posture = 12.0
	game.state.inventory = {"scrap": 7, "anchor_key": 1}
	game.state.flags = {"bell_warden_defeated": true, "shortcut_open": true, "tempered_edge": true, "mossback_awake": true}
	game.state.collected = ["tower_tempered_edge", "caravan_hidden_cache"]
	game.state.discovered = ["caravan", "road", "tower", "courtyard", "vale", "settlement"]
	game.state.checkpoint = {"area": "courtyard", "position": [1128.0, 414.0]}
	game.state.checkpoints = {"courtyard": [1128.0, 414.0]}
	game.state.worldbearer = {"awake": true, "location": "caravan", "trust": 3, "condition": 100, "route_unlocked": true, "buildings": {"0": "garden", "2": "shelter"}, "storage": {"scrap": 11}}
	_check(game.save_game(), "roundtrip writer saves full progression record")
	print("ROUNDTRIP WRITER COMPLETE: " + test_path)

func _read_roundtrip() -> void:
	test_path = ROUNDTRIP_PATH
	game.save_path = test_path
	game.player = null
	_check(game.continue_game(), "fresh process opens previous process save")
	_check(game.current_area == "settlement" and game.state.position == [532.0, 414.0], "fresh process restores region and coordinates")
	_check(game.state.health == 63.0 and game.state.heals == 1 and game.state.stamina == 74.0 and game.state.posture == 12.0, "fresh process restores player combat resources")
	_check(game.item_count("scrap") == 7 and game.item_count("anchor_key") == 1, "fresh process restores inventory")
	_check(game.has_flag("bell_warden_defeated") and game.has_flag("shortcut_open") and game.has_flag("tempered_edge"), "fresh process restores permanent victories and rewards")
	_check("tower_tempered_edge" in game.state.collected and game.state.discovered.size() == 6, "fresh process restores collected and discovered content")
	_check(game.state.checkpoint.area == "courtyard" and game.state.checkpoints.has("courtyard"), "fresh process restores Waystone state")
	_check(game.state.worldbearer.awake and game.state.worldbearer.location == "caravan" and game.state.worldbearer.route_unlocked, "fresh process restores Worldbearer awakening and stop")
	_check(game.state.worldbearer.buildings.get("0") == "garden" and game.state.worldbearer.buildings.get("2") == "shelter" and game.state.worldbearer.storage.scrap == 11, "fresh process restores structures and stored cargo")
	_erase_test_save(test_path)
	print("ROUNDTRIP READER COMPLETE")
