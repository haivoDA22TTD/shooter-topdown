extends StaticBody2D
class_name StorageBox

var storage_inventory: Inventory

func _ready() -> void:
	storage_inventory = Inventory.new()
	storage_inventory.slots_count = 30
	add_child(storage_inventory)

func interact(_player: Player) -> void:
	# TODO: Open storage UI
	print("Storage box opened - implement storage UI")
