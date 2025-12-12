extends Resource
class_name Item

enum ItemType { WEAPON, TOOL, FOOD, DRINK, MATERIAL, ARMOR, MEDICAL }

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.MATERIAL
@export var max_stack: int = 99
@export var is_usable: bool = false
@export var is_equippable: bool = false

# Weapon stats
@export var damage: int = 0
@export var attack_speed: float = 1.0
@export var durability: int = 100

# Consumable stats
@export var health_restore: int = 0
@export var hunger_restore: int = 0
@export var thirst_restore: int = 0

func use(player: Player) -> bool:
	if not is_usable:
		return false
	
	match item_type:
		ItemType.FOOD:
			player.restore_hunger(hunger_restore)
			player.restore_health(health_restore)
			return true
		ItemType.DRINK:
			player.restore_thirst(thirst_restore)
			return true
		ItemType.MEDICAL:
			player.restore_health(health_restore)
			return true
	return false

func get_tooltip() -> String:
	var text = name + "\n" + description
	if damage > 0:
		text += "\nSát thương: " + str(damage)
	if health_restore > 0:
		text += "\nMáu: +" + str(health_restore)
	if hunger_restore > 0:
		text += "\nNo: +" + str(hunger_restore)
	if thirst_restore > 0:
		text += "\nKhát: +" + str(thirst_restore)
	return text
