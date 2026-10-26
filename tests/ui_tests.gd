extends SceneTree
## Native UI integration checks. Uses an isolated campaign save and restores audio settings.
## Run: godot --headless --path . --script res://tests/ui_tests.gd
## For screenshots, run with a real display and append: -- --visual
var checks: int = 0
var failures: int = 0
var app: Node
var ui: CanvasLayer
var game: Node
var visual: bool = false
var settings_existed: bool = false
var old_settings: String = ""
var test_save: String

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("UI CHECK FAILED: " + message)

func find_button(node: Node, prefix: String) -> Button:
	for child: Node in node.get_children():
		if child is Button and child.text.begins_with(prefix):
			return child
		var result: Button = find_button(child, prefix)
		if result != null:
			return result
	return null

func find_slider(node: Node) -> HSlider:
	for child: Node in node.get_children():
		if child is HSlider:
			return child
		var result: HSlider = find_slider(child)
		if result != null:
			return result
	return null

func press(prefix: String) -> void:
	var button: Button = find_button(ui.overlay if ui.panel_open else ui.menu_root, prefix)
	check(button != null, "Button exists: " + prefix)
	if button != null:
		check(not button.disabled, "Button enabled: " + prefix)
		button.pressed.emit()

func action(name: String) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	ui._unhandled_input(event)

func shot(name: String) -> void:
	if not visual:
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png("user://ui-" + name + ".png")
	check(error == OK, "Screenshot saved: " + name)

func _run() -> void:
	visual = "--visual" in OS.get_cmdline_user_args()
	settings_existed = FileAccess.file_exists("user://audio_settings.cfg")
	if settings_existed:
		old_settings = FileAccess.get_file_as_string("user://audio_settings.cfg")
	game = root.get_node("Game")
	test_save = "user://ui-test-%d.json" % OS.get_process_id()
	game.save_path = test_save
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	current_scene = app
	await process_frame
	ui = app.ui
	check(ui.mode == "menu" and ui.menu_root != null, "Menu builds")
	check(find_button(ui.menu_root, "Continue").disabled, "Continue disabled without save")
	await shot("title")
	press("Settings")
	check(ui.panel_kind == "settings" and not paused, "Title settings open")
	var slider: HSlider = find_slider(ui.overlay)
	check(slider != null, "Audio slider exists")
	slider.value = 0.4
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.4), "Master slider controls audio bus")
	check(FileAccess.file_exists("user://audio_settings.cfg"), "Audio preferences saved")
	await shot("settings")
	press("Back")
	press("Begin a new journey")
	await process_frame
	await process_frame
	check(game.active_game and ui.mode == "game" and ui.hud.visible, "New game button starts game")
	check(ui.health_bar.size.y <= 10 and ui.stamina_bar.size.y <= 7 and ui.posture_bar.size.y <= 5, "HUD bars retain compact dimensions")
	await create_timer(0.5).timeout
	await shot("caravan")
	action("pause")
	check(paused and ui.panel_kind == "pause", "Escape pauses simulation")
	await shot("pause")
	press("Save journey")
	check(not paused and not ui.panel_open and FileAccess.file_exists(test_save), "Save button saves and closes pause")
	action("inventory")
	check(paused and ui.panel_kind == "inventory", "Inventory pauses simulation")
	await shot("inventory")
	action("inventory")
	check(not paused and not ui.panel_open, "Inventory toggle resumes")
	action("map")
	check(paused and ui.panel_kind == "map", "Map opens")
	await shot("map")
	action("pause")
	check(not paused and not ui.panel_open, "Escape closes map")
	game.set_flag("bell_warden_defeated")
	game.awaken_mossback()
	game.travel("settlement")
	game.add_item("scrap", 50)
	await process_frame
	ui._on_notification("BUILD_SLOT:1")
	check(ui.selected_slot == 1 and ui.panel_kind == "building", "Building interaction selects correct slot")
	await shot("building")
	press("Root garden")
	check(game.state.worldbearer.buildings.get("1", "") == "garden", "Build button places structure")
	check(not paused and not ui.panel_open, "Successful placement resumes gameplay")
	ui._on_notification("BUILD_SLOT:1")
	check(find_button(ui.overlay, "Root garden") == null, "Occupied plot disallows duplicate placement")
	ui.close_panel()
	var carried: int = game.item_count("scrap")
	ui._on_notification("STORAGE")
	check(ui.panel_kind == "storage" and paused, "Storage pauses game")
	await shot("storage")
	press("Store all scrap")
	check(game.item_count("scrap") == 0 and game.state.worldbearer.storage.scrap == carried, "Storage deposit button transfers inventory")
	press("Take all scrap")
	check(game.item_count("scrap") == carried and game.state.worldbearer.storage.scrap == 0, "Storage withdrawal button transfers inventory")
	press("Close chest")
	ui._on_notification("A road remembered.")
	check(ui.toast.text == "A road remembered.", "Notification displays message")
	ui.interaction_text("Read the roadstone")
	check(ui.prompt.text.contains("Read the roadstone"), "Interaction prompt displays")
	action("pause")
	press("Save & return to title")
	await process_frame
	check(not paused and ui.mode == "menu" and not ui.hud.visible, "Return to title resets pause/HUD")
	check(not find_button(ui.menu_root, "Continue").disabled, "Continue enabled after save")
	press("Begin a new journey")
	check(ui.panel_kind == "confirm", "Existing save requires new-game confirmation")
	press("Keep current journey")
	check(not ui.panel_open, "Cancel preserves existing journey")
	press("Continue journey")
	await process_frame
	check(ui.mode == "game" and game.current_area == "settlement", "Continue restores saved area")
	check(game.state.worldbearer.buildings.get("1", "") == "garden", "Continue retains placed structure")
	app.queue_free()
	await process_frame
	await process_frame
	_restore_files()
	print("UI TESTS: %d passed / %d; failures=%d" % [checks - failures, checks, failures])
	if visual:
		print("Screenshots: " + ProjectSettings.globalize_path("user://ui-*.png"))
	quit(1 if failures else 0)

func _restore_files() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = ProjectSettings.globalize_path(test_save + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if settings_existed:
		var output: FileAccess = FileAccess.open("user://audio_settings.cfg", FileAccess.WRITE)
		if output != null:
			output.store_string(old_settings)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://audio_settings.cfg"))
