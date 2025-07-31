extends Node2D

# Précharge la scène de la balle
const BALL_SCENE = preload("res://ball.tscn")
const PLAYER_SCENE = preload("res://playerBis.tscn")

func _ready():
	spawn_ball()
	spawn_player()

func spawn_ball():
	var ball = BALL_SCENE.instantiate()
	ball.add_to_group("balls")  # Important pour que le joueur puisse trouver les balles
	add_child(ball)
	
	ball.position = Vector2(
		randf_range(50, get_viewport_rect().size.x - 50),
		randf_range(50, get_viewport_rect().size.y - 50)
	)
	
	var speed = randf_range(100, 300)
	var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	ball.linear_velocity = direction * speed

func spawn_player():
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
