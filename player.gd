extends Node2D

func update_position(x, y):
	position = Vector2(x, y)

func update_rotation(degrees):
	rotation_degrees = degrees

func update_color(color):
	# Supposons que le sprite est le premier enfant
	var sprite = get_child(0)
	sprite.modulate = color
