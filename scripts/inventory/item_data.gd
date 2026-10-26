class_name WBItemData
extends Resource
## Stable item metadata shared by inventory UI and future loot/crafting systems.
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("material", "key", "upgrade", "lore") var category: String = "material"
@export var rarity_color: Color = Color("d0ac60")
@export var stackable: bool = true
