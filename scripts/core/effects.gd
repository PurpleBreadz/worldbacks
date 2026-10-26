extends Node2D
## Decorative particles only; health and hit detection remain in combat actors.
var particles: Array[Dictionary] = []

func burst(point: Vector2, kind: String) -> void:
	var color: Color = Color("b7dcc8")
	var count: int = 12
	match kind:
		"parry", "deflect":
			color = Color("fff0ab")
			count = 24
		"hit", "hurt", "damage", "blood":
			color = Color("d78760")
		"death", "boss_death", "posture_break", "break":
			color = Color("deb86f")
			count = 30
	for index: int in range(count):
		var angle: float = TAU * float(index) / count
		var speed: float = 30.0 + float((index * 17) % 70)
		particles.append({"position": point, "velocity": Vector2.from_angle(angle) * speed, "life": 0.4, "max_life": 0.4, "color": color})
	queue_redraw()

func _process(delta: float) -> void:
	for index: int in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[index]
		particle.life -= delta
		if float(particle.life) <= 0.0:
			particles.remove_at(index)
			continue
		particle.position += particle.velocity * delta
		particle.velocity.y += 140.0 * delta
	queue_redraw()

func _draw() -> void:
	for particle: Dictionary in particles:
		var color: Color = particle.color
		color.a = float(particle.life) / float(particle.max_life)
		draw_rect(Rect2(Vector2(particle.position).round(), Vector2(2, 2)), color)
