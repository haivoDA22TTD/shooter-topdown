extends ZombieBase
class_name ZombieRunner

func _ready() -> void:
	zombie_name = "Runner"
	max_health = 30
	damage = 12
	move_speed = 80.0
	chase_speed = 150.0
	detection_range = 200.0
	body_color = Color(0.5, 0.4, 0.35)
	skin_color = Color(0.6, 0.5, 0.45)
	super._ready()
