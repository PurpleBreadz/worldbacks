extends SceneTree
## Movement-only traversal regression. Enemies intentionally removed to isolate jumps.
var failures: int = 0
var passed: int = 0
func _initialize() -> void:
	call_deferred("_run")
func verify(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS ", message)
	else:
		push_error(message)
		failures += 1
func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
func _run() -> void:
	var game: Node = root.get_node("Game")
	game.active_game = true
	game.save_path = "user://worldback_tests_traversal.json"
	for area: String in ["caravan", "road", "tower", "courtyard", "vale", "settlement"]:
		var world: Node2D = load("res://scripts/world/world.gd").new()
		world.build(area)
		world.pending_enemies.clear()
		root.add_child(world)
		await process_frame
		verify(world.spawn_points.has("default") and world.platform_rects.size() > 0, "world initialized " + area)
		world.queue_free()
		await process_frame
	var tower: Node2D = load("res://scripts/world/world.gd").new()
	tower.build("tower")
	tower.pending_enemies.clear()
	var player: CharacterBody2D = load("res://scenes/player/player.tscn").instantiate()
	player.position = Vector2(340, 734)
	game.player = player
	root.add_child(tower)
	root.add_child(player)
	await frames(5)
	verify(player.is_on_floor(), "player grounded at tower foot")
	for stair: int in range(11):
		var target_x: float = 340 + stair * 70 if stair < 10 else 1030
		var target_y: float = 695 - stair * 55 if stair < 10 else 145
		Input.action_press("jump")
		for tick: int in range(38):
			if player.position.x < target_x - 2:
				Input.action_press("move_right")
			else:
				Input.action_release("move_right")
			await physics_frame
		Input.action_release("jump")
		Input.action_release("move_right")
		await frames(5)
		verify(player.is_on_floor() and absf(player.position.y - (target_y - 15)) < 3, "tower jump %d at %s" % [stair + 1, str(player.position)])
	game.player = null
	game.active_game = false
	player.queue_free()
	tower.queue_free()
	await process_frame
	print("TRAVERSAL COMPLETE: %d passed, %d failed" % [passed, failures])
	quit(failures)
