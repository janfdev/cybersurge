extends CanvasLayer
class_name GameOverModal

signal restarted()

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var stats_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsLabel
@onready var restart_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton

func _ready() -> void:
	visible = false
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)

func show_result(is_victory: bool, kills: int, chips: int) -> void:
	visible = true
	if title_label:
		if is_victory:
			title_label.text = "MISSION ACCOMPLISHED: SECTOR SECURED"
			title_label.modulate = Color(0.0, 0.94, 1.0)
		else:
			title_label.text = "CRITICAL SYSTEM FAILURE: OPERATIVE DOWN"
			title_label.modulate = Color(1.0, 0.1, 0.3)
	if stats_label:
		stats_label.text = "Total Kills: %d\nNano-Chips Recovered: %d" % [kills, chips]
	if restart_btn:
		restart_btn.grab_focus()

func _on_restart_pressed() -> void:
	restarted.emit()
	var gd = get_node_or_null("/root/GameData")
	if gd:
		gd.reset_run()
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_restart_pressed()
