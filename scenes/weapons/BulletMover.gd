extends Node

var velocity: Vector2 = Vector2.ZERO
var damage: int = 25
var lifetime: float = 2.0

func _ready() -> void:
	var bullet = get_parent() as Area2D
	if bullet:
		bullet.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var bullet = get_parent() as Area2D
	if bullet:
		bullet.global_position += velocity * delta
		lifetime -= delta
		if lifetime <= 0.0:
			bullet.queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		var bullet = get_parent()
		if bullet:
			bullet.queue_free()
