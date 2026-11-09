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
