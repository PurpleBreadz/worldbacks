class_name WBEnemy
extends CharacterBody2D
## Shared deterministic patrol/pursuit/tell/attack/recovery state machine.
const Art = preload("res://scripts/combat/actor_art.gd")
const DATA_FILES: Dictionary = {
    "scavenger": "res://resources/enemies/scavenger.tres",
    "wolf": "res://resources/enemies/wolf.tres",
    "sentinel": "res://resources/enemies/sentinel.tres",
    "bell_warden": "res://resources/enemies/bell_warden.tres"
}
@export var enemy_type: String = "scavenger"
var persistent_id: String = ""
var data: Resource
var display_name: String = ""
var health: float = 54.0
var max_health: float = 54.0
var posture: float = 0.0
var max_posture: float = 65.0
var boss: bool = false
var phase: int = 1
var facing: float = -1.0
var action: String = "patrol"
var action_time: float = 0.0
var action_duration: float = 0.0
var visual_clock: float = 0.0
var flash: float = 0.0
var home: Vector2
var patrol_direction: float = -1.0
var cooldown: float = 0.6
var posture_delay: float = 0.0
var aggro: bool = false
var attack_index: int = 0
var attack_kind: String = "swing"
var attack_damage: float = 13.0
var attack_posture: float = 22.0
var attack_range: float = 32.0
var attack_active: float = 0.16
var attack_recovery: float = 0.65
var hit_target: bool = false
var combo_remaining: int = 0
var dead_awarded: bool = false

func configure(kind: String, id: String = "") -> void:
    enemy_type = kind if DATA_FILES.has(kind) else "scavenger"
    persistent_id = id
    data = load(DATA_FILES[enemy_type])
    display_name = data.display_name
    max_health = data.max_health
    health = max_health
    max_posture = data.max_posture
    boss = enemy_type == "bell_warden"

func _ready() -> void:
    if data == null:
        configure(enemy_type, persistent_id)
    add_to_group("enemies")
    if boss:
        add_to_group("bosses")
    home = position
    collision_layer = 4
    collision_mask = 1
    floor_snap_length = 4.0
    var collider := CollisionShape2D.new()
    var shape := CapsuleShape2D.new()
    shape.radius = 12.0 if boss else (12.0 if enemy_type == "wolf" else 8.0)
    shape.height = 54.0 if boss else (24.0 if enemy_type == "wolf" else 32.0)
    collider.shape = shape
    add_child(collider)

func is_alive() -> bool:
    return health > 0.0 and action != "dead"

func _physics_process(delta: float) -> void:
    visual_clock += delta
    flash = maxf(0.0, flash - delta)
    cooldown = maxf(0.0, cooldown - delta)
    posture_delay = maxf(0.0, posture_delay - delta)
    if not is_on_floor():
        velocity.y = minf(velocity.y + 1000.0 * delta, 620.0)
    if action == "dead":
        action_time += delta
        velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
        move_and_slide()
        queue_redraw()
        if action_time > 0.65:
            queue_free()
        return
    if not Game.active_game or not is_instance_valid(Game.player) or not Game.player.is_alive():
        velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
        move_and_slide()
        queue_redraw()
        return
    if posture_delay <= 0.0 and action not in ["broken", "tell", "active"]:
        posture = maxf(0.0, posture - (11.0 if boss else 15.0) * delta)
    _update_ai(delta)
    move_and_slide()
    queue_redraw()

func _update_ai(delta: float) -> void:
    action_time += delta
    var target: Node2D = Game.player
    var offset: Vector2 = target.global_position - global_position
    match action:
        "tell":
            velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
            if action_time >= action_duration:
                _enter("active", attack_active)
                hit_target = false
                Game.play_sound("swing")
                if attack_kind == "ground":
                    Game.effect_requested.emit(global_position + Vector2(0, 24), "slam")
        "active":
            if enemy_type == "wolf":
                velocity.x = facing * 235.0
            elif attack_kind == "ground":
                velocity.x = 0.0
            else:
                velocity.x = facing * (85.0 if attack_kind == "heavy" else 45.0)
            _try_hit_player(target)
            if action == "active" and action_time >= action_duration:
                _enter("recovery", attack_recovery)
        "recovery":
            velocity.x = move_toward(velocity.x, 0.0, 550.0 * delta)
            if action_time >= action_duration:
                if combo_remaining > 0 and absf(offset.x) < 125.0:
                    combo_remaining -= 1
                    _begin_attack(true)
                else:
                    _enter("pursue", 0.0)
                    cooldown = 0.22
        "stagger", "broken", "phase":
            velocity.x = move_toward(velocity.x, 0.0, 650.0 * delta)
            if action_time >= action_duration:
                if action == "broken":
                    posture = 0.0
                _enter("pursue", 0.0)
                cooldown = 0.35
        _:
            if boss and phase == 1 and health <= max_health * 0.5:
                phase = 2
                combo_remaining = 0
                _enter("phase", 0.9)
                Game.notify("THE BELL WARDEN — the anchor awakens")
                Game.play_sound("bell")
                Game.effect_requested.emit(global_position, "break")
                return
            if absf(offset.x) < data.detection_range and absf(offset.y) < 95.0:
                aggro = true
            elif absf(offset.x) > data.detection_range * 1.8 or absf(offset.y) > 150.0:
                aggro = false
            if aggro:
                action = "pursue"
                if absf(offset.x) > 3.0:
                    facing = signf(offset.x)
                if absf(offset.x) < data.attack_range and absf(offset.y) < 44.0 and cooldown <= 0.0:
                    _begin_attack()
                elif absf(offset.x) > data.attack_range * 0.75:
                    velocity.x = facing * data.speed * (1.15 if boss and phase == 2 else 1.0)
                else:
                    velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
            else:
                action = "patrol"
                if boss:
                    velocity.x = 0.0
                else:
                    if position.x < home.x - 38.0:
                        patrol_direction = 1.0
                    elif position.x > home.x + 38.0:
                        patrol_direction = -1.0
                    facing = patrol_direction
                    velocity.x = facing * data.speed * 0.32
            _avoid_edges()

func _avoid_edges() -> void:
    if not is_on_floor() or absf(velocity.x) < 1.0:
        return
    var foot_height: float = 27.0 if boss else (12.0 if enemy_type == "wolf" else 16.0)
    var start: Vector2 = global_position + Vector2(signf(velocity.x) * 20.0, foot_height - 5.0)
    var query := PhysicsRayQueryParameters2D.create(start, start + Vector2(0, 24), 1)
    var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        velocity.x = 0.0
        patrol_direction *= -1.0

func _begin_attack(follow_up: bool = false) -> void:
    attack_kind = "swing"
    attack_damage = data.damage
    attack_posture = data.posture_damage
    attack_range = data.attack_range + 10.0
    attack_active = data.active
    attack_recovery = data.recovery
    var tell: float = data.startup
    if absf(Game.player.global_position.x - global_position.x) > 1.0:
        facing = signf(Game.player.global_position.x - global_position.x)
    if boss:
        if follow_up:
            attack_kind = "combo"
            tell = 0.30
            attack_recovery = 0.70
        else:
            attack_index += 1
            if phase == 2 and attack_index % 3 == 0:
                attack_kind = "ground"
                tell = 1.0
                attack_range = 145.0
                attack_damage = 29.0
                attack_posture = 45.0
                attack_active = 0.20
                attack_recovery = 1.1
            elif attack_index % 2 == 0:
                attack_kind = "heavy"
                tell = 0.88
                attack_damage = 28.0
                attack_posture = 42.0
                attack_range = 80.0
                attack_recovery = 1.05
            elif phase == 2:
                attack_kind = "combo"
                tell = 0.48
                combo_remaining = 1
                attack_recovery = 0.22
    _enter("tell", tell)
    Game.play_sound("telegraph")

func _try_hit_player(target: Node2D) -> void:
    if hit_target or not target.is_alive():
        return
    var offset: Vector2 = target.global_position - global_position
    var valid: bool = absf(offset.y) < (42.0 if boss else 30.0) and offset.x * facing > -10.0 and offset.x * facing <= attack_range
    if attack_kind == "ground":
        valid = target.is_on_floor() and absf(offset.x) <= attack_range and absf(offset.y) < 45.0
    if valid:
        hit_target = true
        target.receive_hit(attack_damage, attack_posture, self)

func _enter(next_action: String, duration: float) -> void:
    action = next_action
    action_time = 0.0
    action_duration = duration

func receive_hit(damage: float, posture_damage: float, source: Node2D = null) -> String:
    if not is_alive():
        return "dead"
    aggro = true
    var critical: bool = action == "broken"
    if critical:
        damage *= 2.2
        posture = 0.0
        Game.notify("POSTURE CRITICAL")
        Game.play_sound("critical")
    health = maxf(0.0, health - damage)
    posture = minf(max_posture, posture + posture_damage)
    posture_delay = 2.0
    flash = 0.15
    Game.play_sound("hit")
    if health <= 0.0:
        _die()
        return "dead"
    if posture >= max_posture:
        _break_posture()
    elif critical:
        _enter("stagger", 0.40)
    elif enemy_type in ["scavenger", "wolf"] and action not in ["active", "broken"]:
        _enter("stagger", 0.15)
    if is_instance_valid(source) and not boss:
        velocity.x = signf(global_position.x - source.global_position.x) * 72.0
    return "critical" if critical else "hit"

func receive_parry(amount: float) -> void:
    if not is_alive():
        return
    posture = minf(max_posture, posture + amount)
    posture_delay = 2.5
    combo_remaining = 0
    if posture >= max_posture:
        _break_posture()
    else:
        _enter("stagger", 0.45)
        Game.effect_requested.emit(global_position, "parry")

func _break_posture() -> void:
    posture = max_posture
    combo_remaining = 0
    _enter("broken", 2.1)
    Game.play_sound("break")
    Game.effect_requested.emit(global_position, "break")

func _die() -> void:
    _enter("dead", 0.65)
    collision_layer = 0
    if dead_awarded:
        return
    dead_awarded = true
    Game.effect_requested.emit(global_position, "death")
    Game.play_sound("enemy_death")
    if boss:
        Game.set_flag("bell_warden_defeated")
        Game.add_item("anchor_key", 1)
        Game.add_item("scrap", data.reward)
        Game.notify("WARDEN FELLED · Anchor Sigil acquired. The road to Mossback Vale opens.")
        Game.play_sound("bell")
        Game.save_game()
    else:
        Game.add_item("scrap", data.reward)

func _draw() -> void:
    if data != null:
        Art.draw_enemy(self)
