extends CanvasLayer
class_name GameHUD

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopRow/HealthBar
@onready var wave_label: Label = $MarginContainer/VBoxContainer/TopRow/WaveLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TopRow/TimerLabel
@onready var chips_label: Label = $MarginContainer/VBoxContainer/TopRow/ChipsLabel

func _ready() -> void:
	update_health(100, 100)
	update_wave(1)
	update_timer(45.0)
	update_chips(0)

func update_health(current: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current

func update_wave(wave: int) -> void:
	if wave_label:
		if wave >= 5:
			wave_label.text = "WAVE 5 (FINAL BOSS)"
			wave_label.modulate = Color(1.0, 0.2, 0.4)
		else:
			wave_label.text = "WAVE %d/5" % wave
			wave_label.modulate = Color.WHITE

func update_timer(seconds: float) -> void:
	if timer_label:
		var s := int(ceil(max(0.0, seconds)))
		timer_label.text = "%02d:%02d" % [s / 60, s % 60]

func update_chips(amount: int) -> void:
	if chips_label:
		chips_label.text = "CHIPS: %d" % amount
