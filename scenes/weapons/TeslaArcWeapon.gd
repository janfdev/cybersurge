extends "res://scenes/weapons/WeaponBase.gd"
class_name TeslaArcWeapon

@export var max_chains: int = 2
@export var chain_radius: float = 150.0

var _arc_lines: Array[PackedVector2Array] = []
var _fade_timer: float = 0.0

func _init() -> void:
	weapon_name = "Tesla Arc"
	base_damage = 45
	cooldown = 1.2

func fire(target: Node2D) -> void:
	if not target or not is_instance_valid(target):
		return
		
	_arc_lines.clear()
	# Hit primary target
	if target.has_method("take_damage"):
		target.take_damage(base_damage)
	_arc_lines.append(PackedVector2Array([global_position, target.global_position]))
	
	# Chain to adjacent enemies in group "enemies"
	var hit_list: Array[Node2D] = [target]
	var current_source := target
	var current_dmg := int(base_damage * 0.7)
	
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for _i in range(max_chains):
		var next_target: Node2D = null
		var min_dist := chain_radius
		for enemy in all_enemies:
			if is_instance_valid(enemy) and not hit_list.has(enemy):
				var dist = current_source.global_position.distance_to(enemy.global_position)
				if dist < min_dist:
					min_dist = dist
					next_target = enemy
		if next_target:
			hit_list.append(next_target)
			if next_target.has_method("take_damage"):
				next_target.take_damage(current_dmg)
			_arc_lines.append(PackedVector2Array([current_source.global_position, next_target.global_position]))
			current_source = next_target
			current_dmg = int(current_dmg * 0.7)
		else:
			break
			
	_fade_timer = 0.15
	queue_redraw()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _fade_timer > 0.0:
		_fade_timer -= delta
		if _fade_timer <= 0.0:
			_arc_lines.clear()
			queue_redraw()

func _draw() -> void:
	# Draw electric arc lines in global-to-local space
	var electric := Color(0.2, 0.9, 1.0, 0.9)
	for line in _arc_lines:
		var p1 = to_local(line[0])
		var p2 = to_local(line[1])
		draw_line(p1, p2, electric, 3.0)
		draw_line(p1, p2, Color.WHITE, 1.0)
