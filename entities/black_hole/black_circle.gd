extends Node2D

var current_radius

func _ready():
	current_radius = $"..".current_radius
	_draw_black_circle(current_radius)

func _draw_black_circle(current_radius):
	current_radius = current_radius
	
	
func _draw():
	draw_circle(Vector2.ZERO, current_radius, Color(0, 0, 0, 1))

func _process(delta):
	# Mise à jour pour le dessin
	queue_redraw()
