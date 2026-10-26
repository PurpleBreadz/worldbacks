class_name WBPlayer
extends CharacterBody2D
## Responsive, fixed-timestep player with explicit action locks.
signal stats_changed
signal died

const Weapon = preload("res://resources/weapons/wayfarer_sword.tres")
const Art = preload("res://scripts/combat/actor_art.gd")
const GRAVITY: float = 1000.0
const SPEED: float = 142.0
const JUMP_SPEED: float = -370.0
const COYOTE_TIME: float = 0.10
const JUMP_BUFFER: float = 0.12

var max_health: float = 100.0
var health: float = 100.0
var max_stamina: float = 100.0
var stamina: float = 100.0
var max_posture: float = 100.0
var posture: float = 0.0
var max_heals: int = 3
var heals: int = 3
var facing: float = 1.0
var action: String = "idle"
var action_time: float = 0.0
var action_duration: float = 0.0
var combo: int = 0
var combo_queued: bool = false
var struck: Array[int] = []
var invulnerability: float = 0.0
var flash: float = 0.0
var visual_clock: float = 0.0
var guard_time: float = 1.0
var guard_rearm: float = 0.0
var stamina_delay: float = 0.0
var posture_delay: float = 0.0
var coyote: float = 0.0
var jump_buffer: float = 0.0
var landing_speed: float = 0.0
var was_grounded: bool = false

func _ready() -> void:
    add_to_group("player")
    collision_layer = 2
    collision_mask = 1
    floor_snap_length = 4.0
    var shape_node := CollisionShape2D.new()
    var shape := CapsuleShape2D.new()
    shape.radius = 7.0
    shape.height = 30.0
    shape_node.shape = shape
    add_child(shape_node)
    queue_redraw()

func restore(health_value: float = 100.0) -> void:
    health = clampf(health_value, 1.0, max_health)
    stamina = max_stamina
    posture = 0.0
    heals = max_heals
    action = "idle"
    action_time = 0.0
    collision_layer = 2
    combo = 0
    combo_queued = false
    struck.clear()
    invulnerability = 0.4
    velocity = Vector2.ZERO
    stats_changed.emit()

func is_alive() -> bool:
    return health > 0.0 and action != "dead"

func _physics_process(delta: float) -> void:
    visual_clock += delta
    flash = maxf(0.0, flash - delta)
    invulnerability = maxf(0.0, invulnerability - delta)
    guard_rearm = maxf(0.0, guard_rearm - delta)
    stamina_delay = maxf(0.0, stamina_delay - delta)
    posture_delay = maxf(0.0, posture_delay - delta)
    if not is_on_floor():
        velocity.y = minf(velocity.y + GRAVITY * delta, 620.0)
    else:
        coyote = COYOTE_TIME
    coyote = maxf(0.0, coyote - delta)
    jump_buffer = maxf(0.0, jump_buffer - delta)
    if not is_alive() or not Game.active_game:
        velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
        move_and_slide()
        queue_redraw()
        return
    _read_input(delta)
    _update_action(delta)
    if stamina_delay <= 0.0 and action not in ["attack", "dodge", "heal"]:
        stamina = minf(max_stamina, stamina + (13.0 if action == "block" else 30.0) * delta)
    if posture_delay <= 0.0 and action not in ["stagger", "block"]:
        posture = maxf(0.0, posture - 30.0 * delta)
    landing_speed = velocity.y
    move_and_slide()
    if is_on_floor() and not was_grounded and landing_speed > 240.0:
        Game.effect_requested.emit(global_position + Vector2(0, 14), "dust")
    was_grounded = is_on_floor()
    stats_changed.emit()
    queue_redraw()

func _read_input(delta: float) -> void:
    if Input.is_action_just_pressed("jump"):
        jump_buffer = JUMP_BUFFER
    if Input.is_action_just_released("jump") and velocity.y < -115.0:
        velocity.y *= 0.47
    if action == "attack":
        if Input.is_action_just_pressed("attack") and combo < 2:
            combo_queued = true
        return
    if action in ["dodge", "stagger", "heal"]:
        return
    var direction: float = Input.get_axis("move_left", "move_right")
    if absf(direction) > 0.1:
        facing = signf(direction)
    if Input.is_action_just_pressed("dodge") and stamina >= 23.0:
        _start_action("dodge", 0.40)
        _spend_stamina(23.0)
        invulnerability = 0.28
        velocity.x = facing * 275.0
        Game.play_sound("dodge")
        Game.effect_requested.emit(global_position, "dust")
        return
    if Input.is_action_just_pressed("attack") and stamina >= Weapon.stamina_cost:
        combo = 0
        _attack()
        return
    if Input.is_action_just_pressed("heal"):
        heal()
        if action == "heal":
            return
    if Input.is_action_pressed("block") and is_on_floor():
        if action != "block":
            guard_time = 0.0 if guard_rearm <= 0.0 else 0.3
            guard_rearm = 0.30
            action = "block"
        guard_time += delta
        velocity.x = move_toward(velocity.x, direction * SPEED * 0.30, 1100.0 * delta)
    else:
        if action == "block":
            guard_rearm = maxf(guard_rearm, 0.12)
        action = "run" if absf(direction) > 0.1 else "idle"
        velocity.x = move_toward(velocity.x, direction * SPEED, (1050.0 if direction else 1350.0) * delta)
        if jump_buffer > 0.0 and coyote > 0.0:
            velocity.y = JUMP_SPEED
            jump_buffer = 0.0
            coyote = 0.0
            Game.play_sound("jump")
            Game.effect_requested.emit(global_position + Vector2(0, 14), "dust")

func _update_action(delta: float) -> void:
    if action not in ["attack", "dodge", "stagger", "heal"]:
        return
    action_time += delta
    match action:
        "attack":
            velocity.x = move_toward(velocity.x, 0.0, 650.0 * delta)
            if action_time >= Weapon.startup and action_time < Weapon.startup + Weapon.active:
                _hit_enemies()
            if action_time >= action_duration:
                if combo_queued and combo < 2 and stamina >= Weapon.stamina_cost:
                    combo += 1
                    _attack()
                else:
                    action = "idle"
                    combo = 0
        "dodge":
            velocity.x = facing * (275.0 if action_time < 0.28 else 110.0)
            if action_time >= action_duration:
                action = "idle"
        "stagger":
            velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
            if action_time >= action_duration:
                action = "idle"
                posture = minf(posture, 30.0)
        "heal":
            velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
            if action_time >= action_duration:
                health = minf(max_health, health + 48.0)
                Game.effect_requested.emit(global_position, "heal")
                Game.play_sound("heal")
                action = "idle"

func _start_action(next_action: String, duration: float) -> void:
    action = next_action
    action_time = 0.0
    action_duration = duration

func _spend_stamina(amount: float) -> void:
    stamina = maxf(0.0, stamina - amount)
    stamina_delay = 0.40

func _attack() -> void:
    _start_action("attack", Weapon.startup + Weapon.active + Weapon.recovery + (0.08 if combo == 2 else 0.0))
    combo_queued = false
    struck.clear()
    _spend_stamina(Weapon.stamina_cost + (4.0 if combo == 2 else 0.0))
    velocity.x = facing * 58.0
    Game.play_sound("swing")

func _hit_enemies() -> void:
    for enemy: Node in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy) or not enemy.is_alive() or struck.has(enemy.get_instance_id()):
            continue
        var offset: Vector2 = enemy.global_position - global_position
        var reach: float = Weapon.reach + (10.0 if enemy.boss else 0.0)
        if offset.x * facing >= -9.0 and offset.x * facing <= reach and absf(offset.y) < 36.0:
            struck.append(enemy.get_instance_id())
            var damage: float = Weapon.damage + (8.0 if combo == 2 else 0.0) + (6.0 if Game.has_flag("tempered_edge") else 0.0)
            enemy.receive_hit(damage, Weapon.posture_damage + (12.0 if combo == 2 else 0.0), self)
            Game.effect_requested.emit((global_position + enemy.global_position) * 0.5, "hit")

func heal() -> void:
    if not is_alive() or action in ["attack", "dodge", "stagger", "heal"]:
        return
    if heals <= 0:
        Game.notify("No ember flasks. Rest at a Waystone to refill.")
        return
    if health >= max_health:
        return
    heals -= 1
    _start_action("heal", 0.65)
    stats_changed.emit()

func receive_hit(damage: float, posture_damage: float, source: Node2D = null) -> String:
    if not is_alive():
        return "dead"
    if invulnerability > 0.0:
        return "dodge"
    var incoming: float = -facing
    if is_instance_valid(source):
        incoming = signf(source.global_position.x - global_position.x)
    var guarded: bool = action == "block" and incoming * facing >= 0.0
    if guarded and guard_time <= 0.16:
        stamina = minf(max_stamina, stamina + 12.0)
        posture = maxf(0.0, posture - 12.0)
        flash = 0.15
        Game.play_sound("parry")
        Game.effect_requested.emit(global_position + Vector2(facing * 14.0, -3.0), "parry")
        if is_instance_valid(source) and source.has_method("receive_parry"):
            source.receive_parry(42.0)
        return "parry"
    if guarded:
        _spend_stamina(posture_damage * 0.60)
        posture += posture_damage
        posture_delay = 1.5
        velocity.x = -facing * 72.0
        Game.play_sound("block")
        Game.effect_requested.emit(global_position + Vector2(facing * 14.0, 0.0), "block")
        if posture >= max_posture or stamina <= 0.0:
            posture = max_posture
            _start_action("stagger", 0.95)
            Game.notify("GUARD BROKEN — retreat and recover")
            Game.effect_requested.emit(global_position, "break")
        return "block"
    health = maxf(0.0, health - damage)
    posture = minf(max_posture, posture + posture_damage * 0.4)
    posture_delay = 1.25
    flash = 0.2
    invulnerability = 0.50
    velocity.x = -incoming * 150.0
    velocity.y = minf(velocity.y, -65.0)
    Game.play_sound("hurt")
    Game.effect_requested.emit(global_position, "hurt")
    if health <= 0.0:
        _die()
        return "dead"
    _start_action("stagger", 0.25)
    stats_changed.emit()
    return "hit"

func _die() -> void:
    action = "dead"
    velocity.x = 0.0
    collision_layer = 0
    Game.play_sound("death")
    Game.effect_requested.emit(global_position, "death")
    died.emit()
    Game.player_died.emit()
    stats_changed.emit()

func _draw() -> void:
    Art.draw_player(self)
