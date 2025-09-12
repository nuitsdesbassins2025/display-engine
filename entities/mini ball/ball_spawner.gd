extends Node2D

@export var ball_scene: PackedScene
@export var spawn_interval: float = 1.0  # Secondes entre chaque spawn
@export var max_balls: int = 20
@export var spawn_radius: float = 50.0

var current_balls: int = 0

func _ready():
	# Charger la scène de balle si non assignée
	if ball_scene == null:
		ball_scene = preload("res://entities/mini ball/miniBall.tscn")
	
	# Démarrer le spawn automatique
	start_spawning()

func start_spawning():
	while true:
		if current_balls < max_balls:
			spawn_ball()
		await get_tree().create_timer(spawn_interval).timeout

func spawn_ball():
	var ball_instance = ball_scene.instantiate()
	add_child(ball_instance)
	
	# Position aléatoire autour du spawner
	var random_angle = randf() * TAU
	var random_distance = randf() * spawn_radius
	var spawn_position = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	ball_instance.global_position = global_position + spawn_position
	
	# Vitesse initiale aléatoire
	var random_velocity = Vector2(
		randf_range(-100, 100),
		randf_range(-100, 100)
	)
	ball_instance.linear_velocity = random_velocity
	
	current_balls += 1
	
	# Se connecter à la suppression de la balle
	ball_instance.tree_exiting.connect(_on_ball_removed.bind())

func _on_ball_removed():
	current_balls -= 1

# Fonction pour spawner une balle manuellement
func spawn_specific_ball(position: Vector2, size: float, color: Color):
	var ball_instance = ball_scene.instantiate()
	add_child(ball_instance)
	ball_instance.global_position = position
	
	# Forcer les propriétés
	ball_instance.get_node("CollisionShape2D").shape.radius = size
	ball_instance.get_node("TruckatedCircle").outer_radius = Vector2(size / 20.0, size / 20.0)
	ball_instance.get_node("TruckatedCircle").background_color = color
	ball_instance.get_node("TruckatedCircle").ring_color = color
	
	current_balls += 1
	ball_instance.tree_exiting.connect(_on_ball_removed.bind())

func ball_explosion(ball_count: int = 10, explosion_force: float = 500.0):
	"""Crée une explosion de balles depuis la position et rotation du spawner"""
	var total_duration = 0.5  # 1/2 seconde totale
	var spawn_delay = total_duration / ball_count
	
	# Utiliser la position et rotation du spawner
	var spawn_position = global_position
	var spawn_angle = $"..".rotation_degrees  # Angle en degrés du spawner
	
	for i in range(ball_count):
		# Calculer l'angle avec variation (+/- 20°) par rapport à l'angle du spawner
		var angle_variation = randf_range(-25.0, 25.0)
		var final_angle = deg_to_rad(spawn_angle + angle_variation)
		
		# Créer la balle
		var ball_instance = ball_scene.instantiate()
		add_child(ball_instance)
		
		# Position au centre du spawner
		ball_instance.global_position = spawn_position
		
		# Vitesse directionnelle avec force d'explosion
		var direction = Vector2(cos(final_angle), sin(final_angle))
		var force_variation = randf_range(0.7, 1.3)
		
		ball_instance.linear_velocity = direction * explosion_force * force_variation
		
		# Réduire la durée de vie pour les balles d'explosion
		if ball_instance.has_method("set_lifetime"):
			ball_instance.lifetime = randf_range(2.0, 5.0)
		
		current_balls += 1
		ball_instance.tree_exiting.connect(_on_ball_removed.bind())
		
		# Attendre avant de spawner la prochaine balle
		await get_tree().create_timer(spawn_delay).timeout


# Optionnel : spawner avec un clic
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			pass
			#spawn_ball_at_position(event.position)
