extends "res://scenes/weapons/WeaponBase.gd"
class_name BlasterWeapon

@export var projectile_speed: float = 650.0

func _init() -> void:
	weapon_name = "Pulse Blaster"
	base_damage = 25
	cooldown = 0.4

func fire(target: Node2D) -> void:
	if not target or not is_instance_valid(target):
		return
	var bullet := Area2D.new()
	bullet.collision_layer = 0
	bullet.collision_mask = 4 # Enemies
	
	# Direction towards target
	var dir := (target.global_position - global_position).normalized()
	bullet.global_position = global_position
	bullet.rotation = dir.angle()
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	bullet.add_child(col)
	
	# Procedural neon bolt drawing
	var drawer := Node2D.new()
	drawer.set_script(load("res://scenes/weapons/BoltVisual.gd"))
	bullet.add_child(drawer)
	
	# Movement script
	var mover := Node.new()
	mover.set_script(load("res://scenes/weapons/BulletMover.gd"))
	mover.set("velocity", dir * projectile_speed)
	mover.set("damage", base_damage)
	bullet.add_child(mover)
	
	# Add to scene tree
	var tree_root := get_tree().current_scene
	if not tree_root:
		tree_root = get_tree().root
	tree_root.add_child(bullet)
