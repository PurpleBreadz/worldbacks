extends SceneTree
## Input-only combat regression with starting equipment; reads AI tells for timing.
## This demonstrates feasibility, not human difficulty or playtime.
var game: Node
var player: Node
var enemy: Node
var frames: int = 0
var attacks: int = 0
var parries: int = 0
var jumps: int = 0
var healed: int = 0
var previous_enemy_action: String = ""
var attack_down: bool = false
var block_down: bool = false
var heal_down: bool = false
var jump_down: bool = false
var left_down: bool = false
var right_down: bool = false
var boss_hp: float = 0
func _initialize() -> void:
    call_deferred("run")
func set_action(name: String, value: bool) -> void:
    if value and not Input.is_action_pressed(name):
        Input.action_press(name)
    elif not value and Input.is_action_pressed(name):
        Input.action_release(name)
func run() -> void:
    game = root.get_node("Game")
    game.save_path = "user://worldback_tests_combat_bot_%d.json" % OS.get_process_id()
    game.active_game = true
    game.state = game.fresh_state()
    game.effect_requested.connect(func(_position:Vector2,kind:String):
        if kind == "parry":
            parries += 1
    )
    var floor_body := StaticBody2D.new()
    floor_body.position = Vector2(500,310)
    var collider := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(1000,20)
    collider.shape = shape
    floor_body.add_child(collider)
    root.add_child(floor_body)
    player = load("res://scenes/player/player.tscn").instantiate()
    player.position = Vector2(160,285)
    game.player = player
    root.add_child(player)
    enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
    enemy.configure("scavenger", "bot_scavenger")
    enemy.position = Vector2(195,284)
    root.add_child(enemy)
    while is_instance_valid(enemy) and enemy.is_alive() and frames < 1200 and player.is_alive():
        bot()
        await physics_frame
        frames += 1
    print("SCAVENGER INPUT RESULT: defeated=",not is_instance_valid(enemy) or not enemy.is_alive()," player_hp=",player.health," frames=",frames," attacks=",attacks)
    if is_instance_valid(enemy) and enemy.is_alive():
        finish(false)
        return
    for action: String in ["attack","block","move_left","move_right","jump","heal"]:
        Input.action_release(action)
    if is_instance_valid(enemy):
        enemy.queue_free()
    await physics_frame
    # No restoration: carry any scavenger damage and all remaining flasks into the boss fight.
    enemy = load("res://scenes/bosses/bell_warden.tscn").instantiate()
    enemy.position = Vector2(player.position.x + 72,273)
    root.add_child(enemy)
    frames = 0
    while is_instance_valid(enemy) and enemy.is_alive() and frames < 5400 and player.is_alive():
        bot()
        await physics_frame
        frames += 1
    var won: bool = game.has_flag("bell_warden_defeated")
    print("BOSS INPUT RESULT: won=",won," frames=",frames," sim_seconds=",frames/60.0," player_hp=",player.health," flasks=",player.heals," attacks=",attacks," parry_effects=",parries," jump_attempts=",jumps," phase=",enemy.phase if is_instance_valid(enemy) else 2," boss_hp=",enemy.health if is_instance_valid(enemy) else 0)
    for action: String in ["attack","block","move_left","move_right","jump","heal"]:
        Input.action_release(action)
    game.active_game = false
    game.player = null
    finish(won)
func bot() -> void:
    var offset: float = enemy.position.x - player.position.x
    var idle: bool = player.action in ["idle","run","block"]
    var tell: bool = enemy.action == "tell"
    var remaining: float = enemy.action_duration - enemy.action_time
    var ground: bool = enemy.attack_kind == "ground"
    var want_block: bool = tell and not ground and remaining <= 0.13
    if enemy.action == "active" and not ground:
        want_block = true
    var want_jump: bool = tell and ground and remaining <= 0.18
    var safe_window: bool = enemy.action in ["broken","stagger","recovery"] and (remaining >= 0.45 or enemy.action != "recovery")
    var want_heal: bool = idle and player.health <= 42 and player.heals > 0 and (enemy.action == "broken" or (enemy.action == "recovery" and remaining > 0.70))
    var want_attack: bool = idle and not want_block and not want_heal and safe_window and absf(offset) < 43 and player.stamina >= 18
    # If input attack was just pressed last frame release it once to preserve edges.
    if Input.is_action_pressed("attack"):
        want_attack = false
    if Input.is_action_pressed("heal"):
        want_heal = false
    if Input.is_action_pressed("jump"):
        want_jump = false
    if want_attack:
        attacks += 1
    if want_jump:
        jumps += 1
    if want_heal:
        healed += 1
    var approach: bool = idle and not want_block and not want_jump and absf(offset) > 34 and not (enemy.action == "active")
    # Tap movement toward the foe to face its attacks, then stop within sword range.
    if idle and signf(offset) != player.facing:
        approach = true
    set_action("move_left", approach and offset < 0)
    set_action("move_right", approach and offset > 0)
    set_action("attack", want_attack)
    set_action("block", want_block)
    set_action("heal", want_heal)
    set_action("jump", want_jump)

func finish(won: bool) -> void:
    for action: String in ["attack", "block", "move_left", "move_right", "jump", "heal"]:
        Input.action_release(action)
    for suffix: String in ["", ".bak", ".tmp"]:
        var path: String = game.save_path + suffix
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("COMBAT BOT COMPLETE: ", "PASS" if won else "FAIL")
    quit(0 if won else 1)
