extends Node
## Persistent campaign state. Scene actors are transient and never serialized.
signal notification(text: String)
signal state_changed
signal world_requested(area: String, entry: String)
signal menu_requested
signal player_died
signal effect_requested(position: Vector2, kind: String)

const SAVE_VERSION: int = 1
const AREAS: Array[String] = ["caravan", "road", "tower", "courtyard", "vale", "settlement"]
const BUILDING_COSTS: Dictionary = {"shelter": 3, "workbench": 4, "garden": 2}
var save_path: String = "user://worldback_save.json"
var state: Dictionary = {}
var current_area: String = "caravan"
var player: CharacterBody2D
var active_game: bool = false
var loading: bool = false

func _ready() -> void:
	state = fresh_state()

func fresh_state() -> Dictionary:
	return {
		"version": SAVE_VERSION, "area": "caravan", "position": [96.0, 400.0],
		"health": 100.0, "stamina": 100.0, "posture": 0.0, "heals": 3,
		"inventory": {"scrap": 0, "anchor_key": 0}, "flags": {}, "collected": [],
		"discovered": ["caravan"], "checkpoints": {},
		"checkpoint": {"area": "caravan", "position": [96.0, 400.0]},
		"worldbearer": {"awake": false, "location": "vale", "trust": 0,
			"condition": 100, "route_unlocked": false, "buildings": {}, "storage": {"scrap": 0}}
	}

func new_game() -> void:
	get_tree().paused = false
	state = fresh_state()
	current_area = "caravan"
	active_game = true
	world_requested.emit(current_area, "default")
	save_game()
	notify("THE FALLEN CARAVAN · Follow the old migration road.")

func continue_game() -> bool:
	var loaded: Dictionary = _read_valid_save(save_path)
	if loaded.is_empty():
		loaded = _read_valid_save(save_path + ".bak")
		if not loaded.is_empty():
			notify("Recovered the previous Waystone record from backup.")
	if loaded.is_empty():
		notify("No readable save found. Start a new journey.")
		return false
	get_tree().paused = false
	state = loaded
	current_area = str(state.area)
	active_game = true
	loading = true
	world_requested.emit(current_area, "saved")
	loading = false
	state_changed.emit()
	return true

func has_save() -> bool:
	return not _read_valid_save(save_path).is_empty() or not _read_valid_save(save_path + ".bak").is_empty()

func capture_player() -> void:
	if is_instance_valid(player) and player.is_alive():
		state.position = [player.position.x, player.position.y]
		state.health = player.health
		state.stamina = player.stamina
		state.posture = player.posture
		state.heals = player.heals
	state.area = current_area

func save_game() -> bool:
	if not active_game:
		return false
	capture_player()
	return _write_save()

func _write_save() -> bool:
	var temp: String = save_path + ".tmp"
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		notify("Could not write save. Your journey is still active.")
		return false
	file.store_string(JSON.stringify(state, "\t"))
	file.flush()
	file.close()
	# Rotate only valid previous data. A broken save must not destroy recovery data.
	if not _read_valid_save(save_path).is_empty():
		var copy_error: Error = DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(save_path + ".bak"))
		if copy_error != OK:
			notify("Could not create save backup; current save preserved.")
			return false
	var result: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(save_path))
	if result != OK:
		notify("Could not finish saving. Please try again.")
		return false
	return true

func _read_valid_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1048576:
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {}
	return validate_save(parsed)

func validate_save(data: Dictionary) -> Dictionary:
	# Fail closed on incompatible versions, bad coordinates, or invalid nested records.
	if data.get("version") != SAVE_VERSION or not str(data.get("area", "")) in AREAS:
		return {}
	for key: String in ["inventory", "flags", "checkpoints", "checkpoint", "worldbearer"]:
		if not data.get(key) is Dictionary:
			return {}
	for key: String in ["collected", "discovered"]:
		if not data.get(key) is Array:
			return {}
	if not _valid_position(data.get("position")) or not _valid_position(data.checkpoint.get("position")):
		return {}
	if not str(data.checkpoint.get("area", "")) in AREAS:
		return {}
	for key: String in ["health", "stamina", "posture", "heals"]:
		if not _is_number(data.get(key)):
			return {}
	var wb: Dictionary = data.worldbearer
	if not wb.get("buildings") is Dictionary or not wb.get("storage") is Dictionary:
		return {}
	if not wb.get("awake") is bool or not wb.get("route_unlocked") is bool:
		return {}
	if not str(wb.get("location", "")) in ["vale", "caravan"]:
		return {}
	if not _is_number(wb.get("trust")) or not _is_number(wb.get("condition")):
		return {}
	for slot: Variant in wb.buildings:
		if not str(slot) in ["0", "1", "2"] or not BUILDING_COSTS.has(wb.buildings[slot]):
			return {}
	for collection: Dictionary in [data.inventory, wb.storage]:
		for key: Variant in collection:
			if not key is String or not _is_number(collection[key]) or float(collection[key]) < 0.0:
				return {}
	for key: Variant in data.flags:
		if not key is String or not data.flags[key] is bool:
			return {}
	for area: Variant in data.discovered:
		if not str(area) in AREAS:
			return {}
	for item: Variant in data.collected:
		if not item is String:
			return {}
	for area: Variant in data.checkpoints:
		if not str(area) in AREAS or not _valid_position(data.checkpoints[area]):
			return {}
	var clean: Dictionary = data.duplicate(true)
	clean.health = clampf(float(data.health), 1.0, 100.0)
	clean.stamina = clampf(float(data.stamina), 0.0, 100.0)
	clean.posture = clampf(float(data.posture), 0.0, 100.0)
	clean.heals = clampi(int(data.heals), 0, 3)
	return clean

func _is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _valid_position(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _is_number(value[0]) and _is_number(value[1]) and absf(float(value[0])) < 100000.0 and absf(float(value[1])) < 100000.0

func return_to_menu() -> void:
	save_game()
	get_tree().paused = false
	active_game = false
	player = null
	menu_requested.emit()

func travel(area: String, entry: String = "default") -> void:
	if not area in AREAS:
		return
	if area == "vale" and not has_flag("bell_warden_defeated"):
		notify("The Bell Warden holds the migration road. Silence its bell.")
		return
	if area == "settlement" and not bool(state.worldbearer.awake):
		notify("The Mossback is still dreaming.")
		return
	capture_player()
	current_area = area
	state.area = area
	if not area in state.discovered:
		state.discovered.append(area)
	world_requested.emit(area, entry)
	save_game()
	state_changed.emit()

func rest(area: String, point: Vector2) -> void:
	state.checkpoint = {"area": area, "position": [point.x, point.y]}
	state.checkpoints[area] = [point.x, point.y]
	state.health = 100.0
	state.stamina = 100.0
	state.posture = 0.0
	state.heals = 3
	current_area = area
	world_requested.emit(area, "checkpoint")
	save_game()
	play_sound("waystone")
	notify("WAYSTONE KINDLED · Vitality restored. The Rootwild stirs again.")
	state_changed.emit()

func respawn() -> void:
	state.health = 100.0
	state.stamina = 100.0
	state.posture = 0.0
	state.heals = 3
	current_area = str(state.checkpoint.area)
	world_requested.emit(current_area, "checkpoint")
	save_game()
	notify("The Waystone remembers you.")

func notify(text: String) -> void:
	notification.emit(text)

func has_flag(id: String) -> bool:
	return bool(state.get("flags", {}).get(id, false))

func set_flag(id: String, value: bool = true) -> void:
	state.flags[id] = value
	state_changed.emit()
	if active_game:
		save_game()

func item_count(item: String) -> int:
	return int(state.inventory.get(item, 0))

func add_item(item: String, amount: int = 1) -> void:
	state.inventory[item] = maxi(0, item_count(item) + amount)
	state_changed.emit()

func spend(item: String, amount: int) -> bool:
	if amount < 0 or item_count(item) < amount:
		return false
	add_item(item, -amount)
	return true

func collect(id: String, item: String, amount: int = 1) -> bool:
	if id in state.collected:
		return false
	state.collected.append(id)
	add_item(item, amount)
	save_game()
	play_sound("pickup")
	return true

func awaken_mossback() -> void:
	if not has_flag("bell_warden_defeated"):
		notify("The World Anchor still binds this dreamer.")
		return
	state.worldbearer.awake = true
	state.worldbearer.trust = 1
	set_flag("mossback_awake")
	play_sound("awaken")
	notify("MOSSBACK AWAKENS · A living refuge. Climb onto its shell.")
	save_game()

func place_building(slot: int, kind: String) -> bool:
	if current_area != "settlement" or not bool(state.worldbearer.awake) or slot < 0 or slot > 2 or not BUILDING_COSTS.has(kind):
		return false
	var key: String = str(slot)
	if state.worldbearer.buildings.has(key):
		notify("This shell platform already holds a structure.")
		return false
	if not spend("scrap", int(BUILDING_COSTS[kind])):
		notify("Not enough ironwood scrap. Explore and defeat enemies to gather more.")
		return false
	state.worldbearer.buildings[key] = kind
	save_game()
	play_sound("build")
	state_changed.emit()
	notify("%s built on shell platform %d." % [kind.capitalize(), slot + 1])
	return true

func migrate() -> bool:
	if current_area != "settlement" or not bool(state.worldbearer.route_unlocked):
		return false
	state.worldbearer.location = "caravan" if state.worldbearer.location == "vale" else "vale"
	state.worldbearer.trust = int(state.worldbearer.trust) + 1
	capture_player()
	world_requested.emit("settlement", "default")
	save_game()
	notify("MIGRATION COMPLETE · Mossback rests at " + str(state.worldbearer.location).capitalize() + ".")
	return true

func store_scrap() -> void:
	var amount: int = item_count("scrap")
	state.worldbearer.storage.scrap = int(state.worldbearer.storage.get("scrap", 0)) + amount
	state.inventory.scrap = 0
	save_game()
	state_changed.emit()
	notify("Stored %d ironwood scrap." % amount)

func take_scrap() -> void:
	var amount: int = int(state.worldbearer.storage.get("scrap", 0))
	state.worldbearer.storage.scrap = 0
	add_item("scrap", amount)
	save_game()
	state_changed.emit()
	notify("Withdrew %d ironwood scrap." % amount)

func play_sound(kind: String) -> void:
	if has_node("/root/Sound"):
		get_node("/root/Sound").play(kind)
