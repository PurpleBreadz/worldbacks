class_name WBUI
extends CanvasLayer
## A persistent presentation layer. Gameplay state always lives in Game/actors.

const Styles = preload("res://scripts/ui/ui_theme.gd")
const TitleBackdrop = preload("res://scripts/ui/title_backdrop.gd")
const ItemCatalog = preload("res://scripts/inventory/item_catalog.gd")
const AREA_NAMES: Dictionary = {
	"caravan": "THE FALLEN CARAVAN", "road": "THE OVERGROWN ROAD",
	"tower": "THE OLD WATCHTOWER", "courtyard": "BELLHAVEN COURTYARD",
	"vale": "MOSSBACK VALE", "settlement": "THE MOSSBACK • SHELLHAVEN"
}
const ITEM_INFO: Dictionary = {
	"scrap": ["Anchor scrap", "Salvaged imperial metal. Build structures on Mossback's shell."],
	"tonic": ["Root tonic", "A rare restorative gathered along the old migration road."],
	"anchor_key": ["The Warden's seal", "The broken guardian's oath. Opens the road to Mossback Vale."],
	"lore_fragment": ["Migration record", "The Worldbearers carried our cities before the Anchors bound them."],
	"tempered_edge": ["Tempered edge", "The watchtower's hidden blade. Strengthens your sword strikes."]
}

var mode: String = "menu"
var panel_open: bool = false
var panel_kind: String = ""
var ui_root: Control
var menu_root: Control
var hud: Control
var overlay: Control
var toast: Label
var toast_time: float = 0.0
var prompt: Label
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var posture_bar: ProgressBar
var health_text: Label
var heals_text: Label
var area_text: Label
var boss_hud: Control
var boss_bar: ProgressBar
var boss_posture: ProgressBar
var boss_text: Label
var notification_history: Array[String] = []
var selected_slot: int = 0
var settings_return: String = "menu"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = Styles.create_theme()
	add_child(ui_root)
	_build_hud()
	toast = _label(ui_root, "", Vector2(96, 67), Vector2(448, 49), 13, Styles.PAPER)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_theme_color_override("font_shadow_color", Color("080e12"))
	toast.add_theme_constant_override("shadow_offset_x", 1)
	toast.add_theme_constant_override("shadow_offset_y", 1)
	Game.notification.connect(_on_notification)
	Game.state_changed.connect(refresh)
	_load_audio_settings()
	if mode == "menu":
		show_menu()
	else:
		show_game()

func _label(parent: Node, text: String, at: Vector2, extent: Vector2, font_size: int = 12, color: Color = Styles.PAPER) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = extent
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, at: Vector2, extent: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = extent
	button.pressed.connect(callback)
	button.pressed.connect(func() -> void: Game.play_sound("ui"))
	parent.add_child(button)
	button.size = extent
	return button

func _bar(parent: Node, at: Vector2, extent: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = at
	bar.size = extent
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background: StyleBoxFlat = Styles.box(Color("172429"), Color("46514a"))
	var fill: StyleBoxFlat = Styles.box(color, color, 0)
	for style: StyleBoxFlat in [background, fill]:
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	bar.size = extent
	return bar

func _build_hud() -> void:
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(hud)
	_label(hud, "W", Vector2(14, 10), Vector2(20, 24), 22, Styles.GOLD)
	health_bar = _bar(hud, Vector2(40, 15), Vector2(152, 8), Color("b66757"))
	stamina_bar = _bar(hud, Vector2(40, 27), Vector2(152, 5), Color("88a577"))
	posture_bar = _bar(hud, Vector2(40, 36), Vector2(152, 4), Color("d0ac60"))
	health_text = _label(hud, "100 / 100", Vector2(199, 11), Vector2(70, 15), 10, Styles.MUTED)
	heals_text = _label(hud, "Q  VIALS  3", Vector2(41, 44), Vector2(150, 18), 10, Styles.GOLD)
	area_text = _label(hud, "", Vector2(325, 12), Vector2(297, 18), 11, Styles.GOLD)
	area_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var controls := _label(hud, "TAB  pack     M  map     ESC  pause", Vector2(362, 30), Vector2(260, 16), 9, Styles.MUTED)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt = _label(hud, "", Vector2(36, 328), Vector2(568, 22), 12)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color", Color("050b0d"))
	prompt.add_theme_constant_override("shadow_offset_x", 1)
	prompt.add_theme_constant_override("shadow_offset_y", 1)
	boss_hud = Control.new()
	boss_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(boss_hud)
	boss_text = _label(boss_hud, "THE BELL WARDEN", Vector2(128, 279), Vector2(384, 19), 12, Styles.PAPER)
	boss_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar = _bar(boss_hud, Vector2(130, 300), Vector2(380, 8), Color("a84e46"))
	boss_posture = _bar(boss_hud, Vector2(130, 312), Vector2(380, 3), Color("d0ac60"))
	boss_hud.hide()

func show_menu() -> void:
	mode = "menu"
	close_panel()
	hud.hide()
	toast.text = ""
	if is_instance_valid(menu_root):
		menu_root.queue_free()
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(menu_root)
	var backdrop := Control.new()
	backdrop.set_script(TitleBackdrop)
	menu_root.add_child(backdrop)
	_label(menu_root, "AN AGE OF ANCHORS. A ROAD TO FREEDOM.", Vector2(35, 42), Vector2(530, 20), 10, Styles.GOLD)
	_label(menu_root, "WORLDBACK", Vector2(32, 62), Vector2(550, 58), 43, Styles.PAPER)
	_label(menu_root, "THE ROOTWILD", Vector2(36, 119), Vector2(230, 22), 13, Styles.GOLD)
	var start := _button(menu_root, "Begin a new journey", Vector2(36, 170), Vector2(213, 29), _new_game_pressed)
	var continue_button := _button(menu_root, "Continue journey", Vector2(36, 206), Vector2(213, 29), _continue_pressed)
	continue_button.disabled = not Game.has_save()
	_button(menu_root, "Settings", Vector2(36, 242), Vector2(102, 28), func() -> void: _show_settings("menu"))
	_button(menu_root, "Quit", Vector2(146, 242), Vector2(103, 28), func() -> void: get_tree().quit())
	_label(menu_root, "Wake what the empire buried.", Vector2(337, 320), Vector2(288, 22), 12, Styles.MUTED)
	_label(menu_root, "EARLY PLAYABLE  /  0.1", Vector2(36, 320), Vector2(230, 18), 9, Styles.MUTED)
	start.grab_focus()

func show_game() -> void:
	mode = "game"
	close_panel()
	if is_instance_valid(menu_root):
		menu_root.queue_free()
		menu_root = null
	hud.show()
	refresh()

func _new_game_pressed() -> void:
	if not Game.has_save():
		Game.new_game()
		return
	var box := _open_panel("confirm", "A NEW JOURNEY", Vector2(350, 196))
	var note := _label(box, "Starting again replaces your existing journey.\nYour settings will be kept.", Vector2(22, 54), Vector2(306, 48), 12, Styles.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(box, "Keep current journey", Vector2(22, 123), Vector2(306, 26), close_panel).grab_focus()
	_button(box, "Begin anew", Vector2(22, 156), Vector2(306, 26), func() -> void:
		close_panel()
		Game.new_game())

func _continue_pressed() -> void:
	if not Game.continue_game():
		_on_notification("This save could not be loaded. Begin a new journey.")

func _process(delta: float) -> void:
	if toast_time > 0.0:
		toast_time -= delta
		toast.modulate.a = minf(1.0, toast_time)
		if toast_time <= 0.0:
			toast.text = ""
	if mode != "game":
		return
	var player: Node = Game.player
	if is_instance_valid(player):
		health_bar.max_value = player.max_health
		health_bar.value = player.health
		stamina_bar.max_value = player.max_stamina
		stamina_bar.value = player.stamina
		posture_bar.max_value = player.max_posture
		posture_bar.value = player.posture
		health_text.text = "%d / %d" % [player.health, player.max_health]
		heals_text.text = "Q  VIALS  %d / %d" % [player.heals, player.max_heals]
		posture_bar.modulate = Color("fff0c4") if player.posture > player.max_posture * 0.7 else Color.WHITE
	boss_hud.hide()
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if enemy.boss and enemy.health > 0.0 and is_instance_valid(player) and enemy.global_position.distance_to(player.global_position) < 500.0:
			boss_hud.show()
			boss_bar.max_value = enemy.max_health
			boss_bar.value = enemy.health
			boss_posture.max_value = enemy.max_posture
			boss_posture.value = enemy.posture
			boss_text.text = "THE BELL WARDEN  /  UNBOUND" if enemy.health <= enemy.max_health * 0.5 else "THE BELL WARDEN"
			break

func _unhandled_input(event: InputEvent) -> void:
	if mode != "game":
		if event.is_action_pressed("pause") and panel_open:
			close_panel()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if panel_open:
			close_panel()
		else:
			_show_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		if panel_kind == "inventory":
			close_panel()
		else:
			_show_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map"):
		if panel_kind == "map":
			close_panel()
		else:
			_show_map()
		get_viewport().set_input_as_handled()

func _open_panel(kind: String, title: String, extent: Vector2) -> Panel:
	close_panel()
	panel_open = true
	panel_kind = kind
	get_tree().paused = mode == "game"
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.035, 0.045, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var box := Panel.new()
	box.position = (Vector2(640, 360) - extent) * 0.5
	box.size = extent
	overlay.add_child(box)
	_label(box, title, Vector2(22, 15), Vector2(extent.x - 44, 28), 20, Styles.GOLD)
	return box

func close_panel() -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
		overlay = null
	panel_open = false
	panel_kind = ""
	get_tree().paused = false

func _show_pause() -> void:
	var box := _open_panel("pause", "JOURNEY PAUSED", Vector2(292, 276))
	_button(box, "Return to the road", Vector2(22, 55), Vector2(248, 28), close_panel).grab_focus()
	_button(box, "Save journey", Vector2(22, 90), Vector2(248, 28), func() -> void:
		if Game.save_game():
			_on_notification("Journey saved.")
		close_panel())
	_button(box, "Settings", Vector2(22, 125), Vector2(248, 28), func() -> void: _show_settings("pause"))
	_button(box, "Save & return to title", Vector2(22, 160), Vector2(248, 28), func() -> void:
		if Game.save_game():
			close_panel()
			Game.return_to_menu())
	var hint := _label(box, "A / D  move   SPACE  jump   SHIFT  dodge\nJ  strike   K  guard / deflect   Q  heal\nE  interact   TAB  inventory   M  map", Vector2(22, 207), Vector2(248, 56), 10, Styles.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _show_settings(back: String) -> void:
	settings_return = back
	var box := _open_panel("settings", "SOUND & SILENCE", Vector2(374, 282))
	var buses: Array[String] = ["Master", "Music", "Ambience", "SFX"]
	for i: int in range(buses.size()):
		var bus_name: String = buses[i]
		_label(box, bus_name, Vector2(24, 60 + i * 38), Vector2(90, 22), 12)
		var slider := HSlider.new()
		slider.position = Vector2(118, 61 + i * 38)
		slider.size = Vector2(226, 20)
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		var bus: int = AudioServer.get_bus_index(bus_name)
		slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus)) if bus >= 0 else 0.8
		slider.value_changed.connect(func(value: float) -> void:
			var index: int = AudioServer.get_bus_index(bus_name)
			if index >= 0:
				AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))
				AudioServer.set_bus_mute(index, value == 0.0)
			_save_audio_settings())
		box.add_child(slider)
	_button(box, "Back", Vector2(24, 232), Vector2(326, 28), func() -> void:
		if settings_return == "pause":
			_show_pause()
		else:
			close_panel()).grab_focus()

func _show_inventory() -> void:
	var box := _open_panel("inventory", "THE TRAVELER'S PACK", Vector2(548, 316))
	_label(box, "EQUIPPED", Vector2(23, 49), Vector2(200, 19), 10, Styles.MUTED)
	_label(box, "Wayfarer's sword" + ("  +  TEMPERED EDGE" if Game.has_flag("tempered_edge") else ""), Vector2(23, 68), Vector2(502, 21), 13, Styles.GOLD)
	_label(box, "A practical blade. Precision deflections break an enemy's posture.", Vector2(23, 89), Vector2(502, 20), 11, Styles.MUTED)
	var inventory: Dictionary = Game.state.get("inventory", {})
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(23, 119)
	scroll.size = Vector2(502, 146)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var items := VBoxContainer.new()
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items.add_theme_constant_override("separation", 9)
	scroll.add_child(items)
	var item_ids: Array = inventory.keys()
	item_ids.sort()
	item_ids.erase("scrap")
	item_ids.push_front("scrap")
	for key: String in item_ids:
		var amount: int = int(inventory.get(key, 0))
		if amount <= 0 and key != "scrap":
			continue
		var metadata: Resource = ItemCatalog.get_item(key)
		var info: Array = [metadata.display_name, metadata.description] if metadata != null else ITEM_INFO.get(key, [key.capitalize(), "A discovery from the old road."])
		var item := VBoxContainer.new()
		items.add_child(item)
		var title := Label.new()
		title.text = "%s  × %d" % [info[0], amount]
		item.add_child(title)
		var description := Label.new()
		description.text = str(info[1])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 10)
		description.add_theme_color_override("font_color", Styles.MUTED)
		item.add_child(description)
	_button(box, "Close pack  [TAB]", Vector2(326, 276), Vector2(199, 26), close_panel).grab_focus()

func _show_map() -> void:
	var box := _open_panel("map", "THE ROOTWILD / KNOWN ROADS", Vector2(562, 310))
	_label(box, "A remembered path, not a command to follow.", Vector2(22, 48), Vector2(518, 20), 11, Styles.MUTED)
	var discovered: Array = Game.state.get("discovered", [Game.current_area])
	var locations: Dictionary = {
		"caravan": Vector2(22, 154), "road": Vector2(193, 154),
		"tower": Vector2(193, 86), "courtyard": Vector2(366, 154),
		"vale": Vector2(366, 222), "settlement": Vector2(193, 222)
	}
	var edges: Array = [["caravan", "road"], ["road", "tower"], ["road", "courtyard"], ["courtyard", "vale"], ["vale", "settlement"]]
	for edge: Array in edges:
		var a: Vector2 = locations[edge[0]] + Vector2(77, 18)
		var b: Vector2 = locations[edge[1]] + Vector2(77, 18)
		var line := ColorRect.new()
		line.color = Color("4b5d4f")
		line.position = Vector2(minf(a.x, b.x), minf(a.y, b.y))
		line.size = Vector2(maxf(absf(a.x - b.x), 2), maxf(absf(a.y - b.y), 2))
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(line)
	for id: String in locations:
		var known: bool = id in discovered or id == Game.current_area
		var tile := Panel.new()
		tile.position = locations[id]
		tile.size = Vector2(154, 37)
		tile.add_theme_stylebox_override("panel", Styles.box(Color("20332e") if id == Game.current_area else Styles.INK, Styles.GOLD if known else Color("34433c")))
		box.add_child(tile)
		var label := _label(tile, str(AREA_NAMES[id]).replace("THE ", "").replace("MOSSBACK • SHELLHAVEN", "SHELLHAVEN") if known else "UNEXPLORED", Vector2(4, 5), Vector2(146, 27), 9, Styles.PAPER if known else Styles.MUTED)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(box, "◇  YOU ARE HERE     /     Discover paths by exploring.", Vector2(22, 272), Vector2(337, 18), 9, Styles.MUTED)
	_button(box, "Close map  [M]", Vector2(366, 270), Vector2(174, 26), close_panel).grab_focus()

func _show_building(slot: int) -> void:
	selected_slot = slot
	var box := _open_panel("building", "SHELLHAVEN / PLOT %d" % (slot + 1), Vector2(432, 292))
	_label(box, "Anchor scrap available: %d" % Game.item_count("scrap"), Vector2(22, 51), Vector2(388, 21), 12, Styles.MUTED)
	var definitions: Array = [
		["shelter", "Wayfarer's shelter", 3, "A place to belong on a living road."],
		["workbench", "Anchor workbench", 4, "The foundation for future equipment crafting."],
		["garden", "Root garden", 2, "Carry a small piece of the Rootwild with you."]
	]
	var worldbearer: Dictionary = Game.state.get("worldbearer", {})
	var buildings: Dictionary = worldbearer.get("buildings", {})
	var occupied: bool = buildings.has(str(slot))
	if occupied:
		_label(box, "This plot contains: %s" % str(buildings[str(slot)]).capitalize(), Vector2(22, 82), Vector2(388, 50), 14, Styles.GOLD)
	else:
		for i: int in range(definitions.size()):
			var info: Array = definitions[i]
			var kind: String = str(info[0])
			var button := _button(box, "%s  /  %d scrap" % [info[1], info[2]], Vector2(22, 85 + i * 50), Vector2(388, 27), func() -> void:
				if Game.place_building(selected_slot, kind):
					close_panel())
			button.disabled = Game.item_count("scrap") < int(info[2])
			_label(box, str(info[3]), Vector2(27, 118 + i * 50), Vector2(378, 17), 10, Styles.MUTED)
	_button(box, "Leave plot", Vector2(22, 246), Vector2(388, 27), close_panel).grab_focus()

func _show_storage() -> void:
	var box := _open_panel("storage", "MOSSBACK / TRAVEL CHEST", Vector2(398, 238))
	var worldbearer: Dictionary = Game.state.get("worldbearer", {})
	var storage: Dictionary = worldbearer.get("storage", {})
	_label(box, "Carried scrap: %d    •    Stored scrap: %d" % [Game.item_count("scrap"), int(storage.get("scrap", 0))], Vector2(22, 57), Vector2(354, 24), 12, Styles.GOLD)
	_label(box, "Your cargo travels with Mossback between migration stops.", Vector2(22, 85), Vector2(354, 30), 10, Styles.MUTED)
	_button(box, "Store all scrap", Vector2(22, 125), Vector2(172, 28), func() -> void:
		Game.store_scrap()
		_show_storage())
	_button(box, "Take all scrap", Vector2(204, 125), Vector2(172, 28), func() -> void:
		Game.take_scrap()
		_show_storage())
	_button(box, "Close chest", Vector2(22, 185), Vector2(354, 28), close_panel).grab_focus()

func interaction_text(text: String) -> void:
	prompt.text = "[ E ]  " + text if not text.is_empty() and not panel_open else ""

func refresh() -> void:
	if is_instance_valid(area_text):
		area_text.text = AREA_NAMES.get(Game.current_area, Game.current_area.to_upper())

func _on_notification(text: String) -> void:
	if text.begins_with("BUILD_SLOT:"):
		_show_building(int(text.get_slice(":", 1)))
		return
	if text == "STORAGE":
		_show_storage()
		return
	notification_history.append(text)
	if notification_history.size() > 12:
		notification_history.pop_front()
	toast.text = text
	toast.modulate.a = 1.0
	toast_time = maxf(4.0, float(text.length()) * 0.045)
	# Keep notifications visible above modal panels.
	ui_root.move_child(toast, -1)

func _load_audio_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://audio_settings.cfg") != OK:
		return
	for bus_name: String in ["Master", "Music", "Ambience", "SFX"]:
		var index: int = AudioServer.get_bus_index(bus_name)
		if index >= 0:
			var value: float = clampf(float(config.get_value("audio", bus_name, 0.8)), 0.0, 1.0)
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))
			AudioServer.set_bus_mute(index, value == 0.0)

func _save_audio_settings() -> void:
	var config := ConfigFile.new()
	for bus_name: String in ["Master", "Music", "Ambience", "SFX"]:
		var index: int = AudioServer.get_bus_index(bus_name)
		if index >= 0:
			config.set_value("audio", bus_name, 0.0 if AudioServer.is_bus_mute(index) else db_to_linear(AudioServer.get_bus_volume_db(index)))
	var error: Error = config.save("user://audio_settings.cfg")
	if error != OK:
		push_warning("Audio settings could not be saved: %s" % error_string(error))
