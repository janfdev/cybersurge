extends Node2D
class_name WeaponBase

@export var weapon_name: String = "Weapon"
@export var base_damage: int = 25
@export var cooldown: float = 0.4
@export var current_level: int = 1

var _timer: float = 0.0
var _player: Node2D = null

func _ready() -> void:
	_player = _find_player_parent()

func _find_player_parent() -> Node2D:
	var p = get_parent()
	while p:
		if p.is_in_group("player") or p.has_method("get_closest_enemy"):
			return p
		p = p.get_parent()
	return null

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		if not _player:
			_player = _find_player_parent()
		if _player and _player.has_method("get_closest_enemy"):
			var target = _player.get_closest_enemy()
			if target and is_instance_valid(target):
				fire(target)
				_timer = cooldown

func fire(_target: Node2D) -> void:
	pass

func upgrade_level() -> void:
	current_level += 1
	base_damage = int(base_damage * 1.25)
	cooldown = max(0.15, cooldown * 0.9)
