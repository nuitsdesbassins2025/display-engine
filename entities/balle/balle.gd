extends RigidBody2D

# Configuration
@export var min_speed: float = 100.0
@export var max_speed: float = 300.0
@export var bounce_factor: float = 1.0
@export var ball_radius: float = 40.0
@export var wrap_around_edges: bool = true  # true = téléportation, false = rebond
@export var wall_repulsion_strength: float = 0.5  # Force de répulsion des murs

func _ready():
	gravity_scale = 0
	if linear_velocity == Vector2.ZERO:
		_set_random_velocity()

func _set_random_velocity():
	var speed = randf_range(min_speed, max_speed)
	var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	linear_velocity = direction * speed

func _physics_process(delta):
	var viewport_size = get_viewport_rect().size
	

	_bounce_off_edges(viewport_size)
	
	_maintain_minimum_speed()

func _bounce_off_edges(viewport_size: Vector2):
	var wall_proximity_threshold = 20.0  # Distance pour appliquer la répulsion
	
	# Bord gauche
	if position.x - ball_radius < 0:
		linear_velocity.x = abs(linear_velocity.x) * bounce_factor
		position.x = ball_radius
		_apply_proximity_repulsion(Vector2.RIGHT, viewport_size)
	
	# Bord droit
	elif position.x + ball_radius > viewport_size.x:
		linear_velocity.x = -abs(linear_velocity.x) * bounce_factor
		position.x = viewport_size.x - ball_radius
		_apply_proximity_repulsion(Vector2.LEFT, viewport_size)
	
	# Bord haut
	if position.y - ball_radius < 0:
		linear_velocity.y = abs(linear_velocity.y) * bounce_factor
		position.y = ball_radius
		_apply_proximity_repulsion(Vector2.DOWN, viewport_size)
	
	# Bord bas
	elif position.y + ball_radius > viewport_size.y:
		linear_velocity.y = -abs(linear_velocity.y) * bounce_factor
		position.y = viewport_size.y - ball_radius
		_apply_proximity_repulsion(Vector2.UP, viewport_size)

func _apply_proximity_repulsion(direction: Vector2, viewport_size: Vector2):
	# Calcule la distance au mur le plus proche
	var distance_to_wall = _get_distance_to_nearest_wall(viewport_size)
	
	# Applique une répulsion plus forte quand on est proche du mur
	if distance_to_wall < 50.0:  # Seuil de proximité
		var proximity_factor = 1.0 - (distance_to_wall / 50.0)  # 1.0 quand très proche, 0.0 quand loin
		var repulsion_strength = wall_repulsion_strength * proximity_factor
		
		linear_velocity += direction * repulsion_strength
		print("Répulsion proximité: force ", repulsion_strength)

func _get_distance_to_nearest_wall(viewport_size: Vector2) -> float:
	var distances = [
		position.x - ball_radius,  # Distance au mur gauche
		viewport_size.x - (position.x + ball_radius),  # Distance au mur droit
		position.y - ball_radius,  # Distance au mur haut
		viewport_size.y - (position.y + ball_radius)   # Distance au mur bas
	]
	return abs(distances.min())  # Retourne la distance absolue la plus petite

func _maintain_minimum_speed():
	var current_speed = linear_velocity.length()
	if current_speed < min_speed and current_speed > 0:
		linear_velocity = linear_velocity.normalized() * min_speed

func reset_velocity():
	_set_random_velocity()
