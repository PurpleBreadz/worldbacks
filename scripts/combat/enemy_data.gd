class_name WBEnemyData
extends Resource
## Reusable enemy archetype. Boss pattern selection lives in its actor state machine.
@export var display_name: String = "Rootwild Scavenger"
@export var max_health: float = 54.0
@export var max_posture: float = 65.0
@export var speed: float = 62.0
@export var damage: float = 13.0
@export var posture_damage: float = 22.0
@export var attack_range: float = 32.0
@export var detection_range: float = 190.0
@export var startup: float = 0.48
@export var active: float = 0.16
@export var recovery: float = 0.65
@export var reward: int = 2
@export var body_color: Color = Color("766c55")
