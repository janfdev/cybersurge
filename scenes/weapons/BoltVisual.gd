extends Node2D

func _draw() -> void:
	var cyan := Color(0.0, 0.94, 1.0, 1.0)
	var glow := Color(0.0, 0.94, 1.0, 0.4)
	# Draw capsule-like bolt
	draw_line(Vector2(-8, 0), Vector2(8, 0), glow, 6.0)
	draw_line(Vector2(-8, 0), Vector2(8, 0), Color.WHITE, 2.5)
