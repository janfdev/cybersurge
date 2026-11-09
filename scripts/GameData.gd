extends Node

signal chips_updated(new_amount: int)
signal wave_changed(new_wave: int)
signal stats_updated()

var nano_chips: int = 0
var current_wave: int = 1
var total_kills: int = 0

# Player Upgradable Attributes
var player_max_hp: int = 100
var player_speed: float = 240.0
var player_magnet_radius: float = 120.0
var damage_multiplier: float = 1.0

# Active weapons list
var active_weapons: Array[String] = ["blaster"]

func reset_run() -> void:
	nano_chips = 0
	current_wave = 1
	total_kills = 0
	player_max_hp = 100
	player_speed = 240.0
	player_magnet_radius = 120.0
	damage_multiplier = 1.0
	active_weapons = ["blaster"]
	chips_updated.emit(nano_chips)
	wave_changed.emit(current_wave)
	stats_updated.emit()

func add_chips(amount: int) -> void:
	if amount <= 0:
		return
	nano_chips += amount
	chips_updated.emit(nano_chips)

func spend_chips(amount: int) -> bool:
	if amount <= 0:
		return false
	if nano_chips >= amount:
		nano_chips -= amount
		chips_updated.emit(nano_chips)
		return true
	return false

func register_kill() -> void:
	total_kills += 1

func set_wave(wave: int) -> void:
	current_wave = wave
	wave_changed.emit(current_wave)
