# Different zombie types for different zones

extends ZombieBase
class_name ZombieWalker

func _ready() -> void:
	zombie_name = "Walker"
	max_health = 40
	damage = 8
	move_speed = 50.0
	chase_speed = 80.0
	body_color = Color(0.35, 0.45, 0.3)
	skin_color = Color(0.5, 0.55, 0.4)
	super._ready()
