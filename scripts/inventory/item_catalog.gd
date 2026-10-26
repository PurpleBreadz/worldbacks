class_name WBItemCatalog
extends RefCounted
## Extend this catalog with Resources; saves contain IDs and quantities only.
const ITEMS: Dictionary = {
	"scrap": preload("res://resources/items/anchor_scrap.tres"),
	"anchor_key": preload("res://resources/items/warden_seal.tres"),
	"tempered_edge": preload("res://resources/items/tempered_edge.tres")
}

static func get_item(id: String) -> Resource:
	return ITEMS.get(id)
