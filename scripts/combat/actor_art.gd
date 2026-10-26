class_name WBActorArt
extends RefCounted
## Original pixel-scale silhouettes. Replaceable presentation; never gameplay state.
const OUTLINE := Color("111b20")
const BONE := Color("d2c69e")
const GOLD := Color("dbb96a")
const RED := Color("d36c5b")

static func draw_player(actor: Node2D) -> void:
    var dead: bool = actor.action == "dead"
    var tint: Color = Color.WHITE
    if actor.flash > 0.0:
        tint = Color("ffe5b2")
    elif actor.invulnerability > 0.0 and int(actor.visual_clock * 30.0) % 2 == 0:
        tint.a = 0.58
    actor.draw_set_transform(Vector2.ZERO, 0.0, Vector2(actor.facing, 1.0))
    if dead:
        actor.draw_rect(Rect2(-13, 8, 27, 6), Color("5b5550"))
        actor.draw_rect(Rect2(6, 3, 9, 7), Color("84988c"))
        actor.draw_set_transform(Vector2.ZERO)
        return
    if actor.action == "dodge":
        actor.draw_circle(Vector2(0, 4), 11.0, Color("344d4a") * tint)
        actor.draw_arc(Vector2(0, 4), 11.0, actor.action_time * 20.0, actor.action_time * 20.0 + 3.4, 12, BONE * tint, 2.0)
        actor.draw_line(Vector2(-21, 8), Vector2(-12, 8), Color(0.8, 0.7, 0.4, 0.35), 2)
        actor.draw_set_transform(Vector2.ZERO)
        return
    var step: float = sin(actor.visual_clock * 18.0) * 3.0 if absf(actor.velocity.x) > 15.0 and actor.is_on_floor() else 0.0
    var cape: float = sin(actor.visual_clock * 7.0) * 2.0
    actor.draw_colored_polygon(PackedVector2Array([Vector2(-5,-10),Vector2(2,-7),Vector2(-2,10),Vector2(-13-cape,12),Vector2(-10,1)]), Color("a36747") * tint)
    actor.draw_rect(Rect2(-6 + step, 7, 5, 8), OUTLINE * tint)
    actor.draw_rect(Rect2(1 - step, 7, 5, 8), OUTLINE * tint)
    actor.draw_rect(Rect2(-7 + step, 13, 7, 3), Color("867f65") * tint)
    actor.draw_rect(Rect2(1 - step, 13, 7, 3), Color("867f65") * tint)
    actor.draw_rect(Rect2(-7, -8, 14, 17), OUTLINE * tint)
    actor.draw_rect(Rect2(-5, -7, 10, 13), Color("55736b") * tint)
    actor.draw_rect(Rect2(-3, -6, 6, 9), Color("71897b") * tint)
    actor.draw_rect(Rect2(-6, 5, 13, 3), Color("b79761") * tint)
    actor.draw_rect(Rect2(-6, -17, 12, 10), OUTLINE * tint)
    actor.draw_rect(Rect2(-4, -16, 9, 8), Color("a5b6a6") * tint)
    actor.draw_rect(Rect2(1, -13, 6, 3), Color("202d2e") * tint)
    actor.draw_rect(Rect2(3, -13, 3, 1), GOLD * tint)
    actor.draw_rect(Rect2(-7, -9, 14, 3), Color("ba7d52") * tint)
    if actor.action == "block":
        actor.draw_rect(Rect2(9, -12, 3, 26), BONE * tint)
        actor.draw_line(Vector2(5, 3), Vector2(15, 3), GOLD, 2)
        actor.draw_line(Vector2(3, -2), Vector2(10, 2), Color("71897b"), 4)
        if actor.guard_time < 0.16:
            actor.draw_arc(Vector2(7, 0), 17, -1.0, 1.0, 10, Color("fff1b0"), 2.0)
    elif actor.action == "attack":
        var angle: float = -1.6 if actor.action_time < 0.12 else lerpf(-0.65, 0.75, minf(1.0, (actor.action_time - 0.12) / 0.12))
        var tip := Vector2(7, -2) + Vector2.from_angle(angle) * 31.0
        actor.draw_line(Vector2(6, -2), tip, BONE * tint, 3.0)
        actor.draw_line(Vector2(3, 1), Vector2(12, -4), GOLD, 3.0)
        if actor.action_time >= 0.12 and actor.action_time < 0.26:
            actor.draw_arc(Vector2.ZERO, 38.0, -0.8, 0.7, 14, Color(0.93,0.84,0.59,0.8), 3.0)
            actor.draw_arc(Vector2.ZERO, 33.0, -0.6, 0.4, 12, Color(0.93,0.84,0.59,0.3), 2.0)
    elif actor.action == "heal":
        actor.draw_rect(Rect2(7, -10, 5, 8), Color("e3b875"))
        actor.draw_circle(Vector2(9, -13), 2, Color("f3db95"))
        actor.draw_arc(Vector2.ZERO, 21.0, -1.5, actor.action_time * 9.0 - 1.5, 20, Color(0.6,0.82,0.6,0.65), 1.0)
    else:
        actor.draw_line(Vector2(7, 1), Vector2(18, 18), BONE * tint, 2.0)
        actor.draw_line(Vector2(5, 4), Vector2(11, 0), GOLD, 2.0)
    actor.draw_set_transform(Vector2.ZERO)

static func draw_enemy(actor: Node2D) -> void:
    var color: Color = actor.data.body_color
    if actor.flash > 0.0:
        color = Color("f3e1b7")
    if actor.action == "dead":
        color.a = maxf(0.0, 1.0 - actor.action_time / 0.65)
    actor.draw_set_transform(Vector2.ZERO, 0.0, Vector2(actor.facing, 1.0))
    var step: float = sin(actor.visual_clock * 13.0) * 3.0 if absf(actor.velocity.x) > 10.0 else 0.0
    if actor.enemy_type == "wolf":
        actor.draw_colored_polygon(PackedVector2Array([Vector2(-18,-4),Vector2(-9,-10),Vector2(4,-8),Vector2(11,-14),Vector2(17,-7),Vector2(23,-3),Vector2(20,3),Vector2(6,5),Vector2(-12,5)]), color)
        actor.draw_colored_polygon(PackedVector2Array([Vector2(-14,-5),Vector2(-26,-11),Vector2(-19,0)]), Color("333e3b"))
        actor.draw_rect(Rect2(-11+step, 3, 4, 10), color)
        actor.draw_rect(Rect2(7-step, 3, 4, 10), color)
        actor.draw_rect(Rect2(12,-7,3,2), Color("f2ac72"))
        actor.draw_line(Vector2(-4,-8), Vector2(-7,-16), Color("a1ac83"), 2.0)
        actor.draw_line(Vector2(0,-8), Vector2(1,-15), Color("a1ac83"), 2.0)
    elif actor.boss:
        _draw_warden(actor, color, step)
    else:
        var armored: bool = actor.enemy_type == "sentinel"
        actor.draw_rect(Rect2(-8 + step, 7, 6, 9), OUTLINE)
        actor.draw_rect(Rect2(3 - step, 7, 6, 9), OUTLINE)
        actor.draw_colored_polygon(PackedVector2Array([Vector2(-9,-10),Vector2(8,-10),Vector2(11,9),Vector2(-12,9)]), color)
        actor.draw_rect(Rect2(-6,-18,12,10), color.lightened(0.12))
        actor.draw_rect(Rect2(0,-14,7,3), OUTLINE)
        actor.draw_rect(Rect2(3,-14,3,1), RED)
        if armored:
            actor.draw_rect(Rect2(-12,-10,7,6), color.lightened(0.18))
            actor.draw_rect(Rect2(5,-10,7,6), color.lightened(0.18))
            actor.draw_rect(Rect2(-5,-4,10,2), GOLD.darkened(0.4))
            actor.draw_line(Vector2(0,-18),Vector2(-6,-25),Color("617566"),3.0)
        else:
            actor.draw_colored_polygon(PackedVector2Array([Vector2(-7,-17),Vector2(-3,-23),Vector2(6,-18)]),Color("6a7653"))
            actor.draw_line(Vector2(-9,0),Vector2(-14,13),Color("534f3e"),4.0)
        var weapon_tip: Vector2 = Vector2(13,-27) if actor.action == "tell" else Vector2(34,3) if actor.action == "active" else Vector2(18,19)
        actor.draw_line(Vector2(8,0),weapon_tip, BONE.darkened(0.23),3.0 if armored else 2.0)
    if actor.action == "tell":
        var progress: float = clampf(actor.action_time / maxf(0.01, actor.action_duration), 0.0, 1.0)
        var height: float = -42.0 if actor.boss else -29.0
        var warning: Color = RED if actor.attack_kind == "ground" else GOLD
        actor.draw_colored_polygon(PackedVector2Array([Vector2(0,height-5),Vector2(4,height),Vector2(0,height+5),Vector2(-4,height)]),warning)
        actor.draw_arc(Vector2(0,height), 8.0, -PI * 0.5, -PI * 0.5 + progress * TAU, 16, warning, 1.0)
        if actor.attack_kind == "ground":
            actor.draw_line(Vector2(-145,26),Vector2(145,26),Color(0.84,0.43,0.31,0.35+progress*0.4),2.0)
    if actor.action == "active" and actor.enemy_type != "wolf":
        if actor.attack_kind == "ground":
            actor.draw_arc(Vector2(0,25),actor.attack_range,-PI,0,20,Color(0.96,0.65,0.38,0.7),3.0)
        else:
            actor.draw_arc(Vector2.ZERO,actor.attack_range-7,-0.8,0.6,16,Color(0.87,0.70,0.43,0.8),3.0)
    actor.draw_set_transform(Vector2.ZERO)
    if actor.action == "broken":
        var y: float = -42.0 if actor.boss else -29.0
        for i in 3:
            var point: Vector2 = Vector2(cos(actor.visual_clock*5+i*TAU/3)*12,y+sin(actor.visual_clock*5+i*TAU/3)*3)
            actor.draw_rect(Rect2(point,Vector2(3,3)),GOLD)
    if not actor.boss and actor.health < actor.max_health and actor.health > 0:
        actor.draw_rect(Rect2(-16,-29,32,3),Color("192225"))
        actor.draw_rect(Rect2(-16,-29,32*actor.health/actor.max_health,3),Color("b56e59"))
        if actor.posture > 0:
            actor.draw_rect(Rect2(-16,-25,32*actor.posture/actor.max_posture,1),GOLD)

static func _draw_warden(actor: Node2D, color: Color, step: float) -> void:
    actor.draw_colored_polygon(PackedVector2Array([Vector2(-14,-14),Vector2(8,-15),Vector2(10,23),Vector2(-21,26)]),Color("574f43"))
    actor.draw_rect(Rect2(-10+step,12,8,15),Color("263334"))
    actor.draw_rect(Rect2(3-step,12,8,15),Color("263334"))
    actor.draw_rect(Rect2(-15,-15,29,29),color)
    actor.draw_rect(Rect2(-20,-17,10,9),color.lightened(0.16))
    actor.draw_rect(Rect2(9,-17,12,9),color.lightened(0.16))
    actor.draw_rect(Rect2(-7,-28,16,15),color.lightened(0.1))
    actor.draw_rect(Rect2(0,-23,11,4),OUTLINE)
    actor.draw_rect(Rect2(4,-23,6,1),Color("e9a76b"))
    actor.draw_line(Vector2(-6,-27),Vector2(-13,-37),GOLD.darkened(0.3),3.0)
    actor.draw_line(Vector2(6,-27),Vector2(12,-38),GOLD.darkened(0.3),3.0)
    actor.draw_rect(Rect2(-10,-11,19,3),GOLD.darkened(0.3))
    actor.draw_circle(Vector2(-1,0),5.0,Color("272f2d"))
    actor.draw_arc(Vector2(-1,0),4.0,PI,TAU,10,GOLD,2.0)
    actor.draw_rect(Rect2(-5,1,8,2),GOLD)
    var tip: Vector2 = Vector2(14,-52) if actor.action == "tell" else Vector2(59,1) if actor.action == "active" else Vector2(25,30)
    actor.draw_line(Vector2(14,-3),tip,Color("b4b8a2"),5.0)
    actor.draw_line(Vector2(8,0),Vector2(21,-8),GOLD,4.0)
    if actor.phase == 2:
        actor.draw_line(Vector2(-3,-10),Vector2(2,10),Color("e4b76b"),2.0)
        actor.draw_circle(Vector2(-1,0),2,Color("fff0a6"))
