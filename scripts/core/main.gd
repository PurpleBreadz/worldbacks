extends Node
## Application composition root. Rebuilds transient actors around durable Game state.
var world: Node2D
var actor: CharacterBody2D
var ui: CanvasLayer
var camera: Camera2D
var effects: Node2D
var stage: Node2D
var transition_layer: CanvasLayer
var curtain: ColorRect
var transition_tween: Tween
var dead_pending: bool = false
var shake: float = 0.0
var hitstop: float = 0.0
var interaction: Node2D

func _ready() -> void:
	stage = Node2D.new()
	stage.name = "Stage"
	add_child(stage)
	ui = load("res://scenes/ui/ui.tscn").instantiate()
	add_child(ui)
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 30
	add_child(transition_layer)
	curtain = ColorRect.new()
	curtain.color = Color(0.025, 0.04, 0.045, 0.0)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_layer.add_child(curtain)
	Game.world_requested.connect(_load_area)
	Game.menu_requested.connect(_show_menu)
	Game.player_died.connect(_on_death)
	Game.effect_requested.connect(_on_effect)
	ui.show_menu()

func _load_area(area: String, entry: String) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	hitstop = 0.0
	dead_pending = false
	interaction = null
	for child: Node in stage.get_children():
		stage.remove_child(child)
		child.queue_free()
	actor = load("res://scenes/player/player.tscn").instantiate()
	Game.player = actor
	world = load("res://scenes/world/world.tscn").instantiate()
	world.build(area)
	stage.add_child(world)
	var spawn: Vector2 = world.spawn_points.get(entry, world.spawn_points.get("default", Vector2(96, 400)))
	if entry == "saved":
		spawn = Vector2(float(Game.state.position[0]), float(Game.state.position[1]))
	elif entry == "checkpoint":
		spawn = Vector2(float(Game.state.checkpoint.position[0]), float(Game.state.checkpoint.position[1]))
	actor.position = spawn
	stage.add_child(actor)
	actor.restore(float(Game.state.health))
	actor.heals = int(Game.state.heals)
	actor.stamina = float(Game.state.stamina)
	actor.posture = float(Game.state.posture)
	Game.state.position = [spawn.x, spawn.y]
	Game.current_area = area
	Game.state.area = area
	camera = Camera2D.new()
	camera.position = Vector2(0, -45)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = int(world.bounds.position.x)
	camera.limit_top = int(world.bounds.position.y)
	camera.limit_right = int(world.bounds.end.x)
	camera.limit_bottom = int(world.bounds.end.y)
	camera.limit_smoothed = true
	actor.add_child(camera)
	camera.reset_smoothing()
	effects = load("res://scripts/core/effects.gd").new()
	effects.z_index = 25
	stage.add_child(effects)
	ui.show_game()
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
	curtain.color.a = 1.0
	transition_tween = create_tween()
	transition_tween.tween_property(curtain, "color:a", 0.0, 0.45)
	Game.state_changed.emit()

func _show_menu() -> void:
	Engine.time_scale = 1.0
	dead_pending = false
	actor = null
	world = null
	for child: Node in stage.get_children():
		stage.remove_child(child)
		child.queue_free()
	ui.show_menu()

func _process(delta: float) -> void:
	if not Game.active_game or not is_instance_valid(actor):
		return
	if hitstop > 0.0:
		hitstop -= delta / maxf(Engine.time_scale, 0.001)
		if hitstop <= 0.0:
			Engine.time_scale = 1.0
	if is_instance_valid(camera):
		shake = move_toward(shake, 0.0, delta * 18.0)
		camera.offset = Vector2(sin(Time.get_ticks_msec() * 0.057), cos(Time.get_ticks_msec() * 0.071)) * shake
	if not actor.is_alive() or ui.panel_open:
		ui.interaction_text("")
		return
	if actor.position.y > world.bounds.end.y + 80:
		actor.receive_hit(1000.0, 1000.0, null)
		return
	interaction = null
	var nearest: float = 56.0
	for node: Node in get_tree().get_nodes_in_group("interactables"):
		if not node is Node2D or not node.is_inside_tree():
			continue
		var distance: float = actor.global_position.distance_to(node.global_position)
		if distance < nearest:
			nearest = distance
			interaction = node
	ui.interaction_text(interaction.prompt if is_instance_valid(interaction) else "")
	if Input.is_action_just_pressed("interact") and is_instance_valid(interaction):
		if actor.action in ["idle", "run", "move", "fall", "jump", "block"]:
			interaction.interact(actor)

func _on_effect(point: Vector2, kind: String) -> void:
	if is_instance_valid(effects):
		effects.burst(point, kind)
	if kind in ["hit", "hurt", "parry", "deflect", "posture_break", "boss_death"]:
		shake = 2.5 if kind in ["parry", "deflect"] else 1.4
		if not get_tree().paused:
			hitstop = 0.045
			Engine.time_scale = 0.15

func _on_death() -> void:
	if dead_pending:
		return
	dead_pending = true
	Game.notify("YOU FELL · The Waystone calls you back.")
	await get_tree().create_timer(1.5, false, false, true).timeout
	if dead_pending and Game.active_game:
		Game.respawn()

func _exit_tree() -> void:
	Engine.time_scale = 1.0
