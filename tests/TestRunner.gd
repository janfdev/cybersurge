extends SceneTree

func _init() -> void:
	print("[TestRunner] Initializing CyberSurge Test Suite...")
	var success := run_all_tests()
	if success:
		print("[TestRunner] ALL TESTS PASSED.")
		quit(0)
	else:
		push_error("[TestRunner] TESTS FAILED.")
		quit(1)

func run_all_tests() -> bool:
	if not test_project_bootstrap():
		return false
	if not test_game_data_economy():
		return false
	if not test_nano_chip_magnet():
		return false
	return true

func test_project_bootstrap() -> bool:
	print("[TEST] test_project_bootstrap...")
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width", 0)
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height", 0)
	var stretch_mode: String = ProjectSettings.get_setting("display/window/stretch/mode", "")
	
	if width != 1280:
		print("  FAIL: Expected viewport width 1280, got ", width)
		return false
	if height != 720:
		print("  FAIL: Expected viewport height 720, got ", height)
		return false
	if stretch_mode != "canvas_items":
		print("  FAIL: Expected stretch mode canvas_items, got ", stretch_mode)
		return false
		
	print("  PASS: Project viewport configured to 1280x720 (canvas_items).")
	return true

func test_game_data_economy() -> bool:
	print("[TEST] test_game_data_economy...")
	var game_data_script = load("res://scripts/GameData.gd")
	if not game_data_script:
		print("  FAIL: scripts/GameData.gd not found.")
		return false
	var gd = game_data_script.new()
	gd.reset_run()
	if gd.nano_chips != 0 or gd.current_wave != 1:
		print("  FAIL: Initial state invalid.")
		return false
	gd.add_chips(50)
	if gd.nano_chips != 50:
		print("  FAIL: Adding chips failed.")
		return false
	if not gd.spend_chips(30) or gd.nano_chips != 20:
		print("  FAIL: Spending chips failed.")
		return false
	if gd.spend_chips(25):
		print("  FAIL: Allowed overspending chips.")
		return false
	if not gd.spend_chips(20) or gd.nano_chips != 0:
		print("  FAIL: Exact spending chips failed.")
		return false
	print("  PASS: GameData economy verified.")
	return true

func test_nano_chip_magnet() -> bool:
	print("[TEST] test_nano_chip_magnet...")
	var chip_scene = load("res://scenes/entities/drops/NanoChip.tscn")
	if not chip_scene:
		print("  FAIL: NanoChip.tscn not found.")
		return false
	var chip = chip_scene.instantiate()
	root.add_child(chip)
	chip.global_position = Vector2(100, 100)
	
	var mock_target = Node2D.new()
	root.add_child(mock_target)
	mock_target.global_position = Vector2(200, 100)
	
	chip.set_magnet_target(mock_target)
	var initial_dist = chip.global_position.distance_to(mock_target.global_position)
	
	# Simulate physics process
	chip._physics_process(0.1)
	var new_dist = chip.global_position.distance_to(mock_target.global_position)
	
	if new_dist >= initial_dist:
		print("  FAIL: NanoChip did not move closer to target under magnet.")
		chip.queue_free()
		mock_target.queue_free()
		return false
		
	print("  PASS: NanoChip magnet attraction verified (dist: ", initial_dist, " -> ", new_dist, ").")
	chip.queue_free()
	mock_target.queue_free()
	return true
