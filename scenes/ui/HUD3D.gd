extends CanvasLayer
class_name HUD3D

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopRow/HealthBar
@onready var wave_label: Label = $MarginContainer/VBoxContainer/TopRow/WaveLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TopRow/TimerLabel
@onready var chips_label: Label = $MarginContainer/VBoxContainer/TopRow/ChipsLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/BottomRow/AmmoContainer/AmmoLabel
@onready var hit_indicator: ColorRect = $CenterContainer/HitCrosshair
@onready var crosshair: Control = $CenterContainer/Crosshair

func _ready() -> void:
	update_health(100, 100)
	update_wave(1)
	update_timer(45.0)
	update_chips(0)
	update_ammo(12, 12, 72)
	if hit_indicator:
		hit_indicator.modulate = Color(1, 1, 1, 0)

func update_health(current: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current

func update_wave(wave: int) -> void:
	if wave_label:
		if wave >= 5:
			wave_label.text = "WAVE 5 (FINAL ASSAULT)"
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

func update_ammo(current: int, _max_mag: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "%02d / %02d" % [current, reserve]
		ammo_label.modulate = Color(1, 0.2, 0.3) if current <= 3 else Color(0.0, 0.95, 1.0)

func flash_hit(is_headshot: bool) -> void:
	if not hit_indicator:
		return
	hit_indicator.modulate = Color(1.0, 0.1, 0.3, 0.9) if is_headshot else Color(1.0, 1.0, 1.0, 0.8)
	var tw := create_tween()
	tw.tween_property(hit_indicator, "modulate:a", 0.0, 0.12)
