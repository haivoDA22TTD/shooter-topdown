extends StaticBody2D
class_name Campfire

var is_lit: bool = true

func interact(player: Player) -> void:
	# Open crafting UI with campfire station
	var crafting_ui = get_tree().current_scene.get_node_or_null("CraftingUI")
	if crafting_ui:
		crafting_ui.toggle("campfire")
