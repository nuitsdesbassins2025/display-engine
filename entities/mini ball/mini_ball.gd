extends RigidBody2D

@export var min_size: float = 10.0
@export var max_size: float = 30.0
@export var collision_threashold: float = 2.0
@export var colors: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, 
	Color.PURPLE, Color.ORANGE, Color.PINK, Color.CYAN
]

signal ball_collision(other_ball: Node, impact_force: float)

func _ready():
	randomize_ball()

# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func randomize_ball():
	"""Initialise la balle avec des propriétés aléatoires"""
	var size = randf_range(min_size, max_size)
	var random_color = colors[randi() % colors.size()]
	
	set_size(size)
	set_color(random_color)
	set_physics_properties(size)

func set_size(size: float):
	"""Définit la taille de la balle"""
	$CollisionShape2D.shape.radius = size
	$TruckatedCircle.outer_radius = size
	$TruckatedCircle.inner_radius = 0
	$Area2D/CollisionShape2D.shape.radius = size + collision_threashold

func set_color(color: Color):
	"""Définit la couleur de la balle"""
	$TruckatedCircle.ring_color = color

func set_physics_properties(size: float):
	"""Définit les propriétés physiques de la balle"""
	mass = size / 10.0
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = randf_range(0.6, 0.9)

func object_infos() -> Dictionary:
	"""Renvoie les informations de l'objet sous forme de dictionnaire"""
	return {
		"name": "mini_ball",
		"body_name": name,
		"size": $CollisionShape2D.shape.radius,
		"position": {"x": global_position.x, "y": global_position.y},
		"speed": linear_velocity.length(),
		"mass": mass,
		"color": {
			"r": $TruckatedCircle.ring_color.r,
			"g": $TruckatedCircle.ring_color.g,
			"b": $TruckatedCircle.ring_color.b,
			"a": $TruckatedCircle.ring_color.a
		}
	}

func calculate_impact_force(other_ball: Node) -> float:
	"""Calcule la force d'impact lors d'une collision"""
	var relative_velocity = linear_velocity - other_ball.linear_velocity
	return relative_velocity.length() * mass

func play_collision_effect():
	"""Joue un effet visuel lors de la collision"""
	var tween = create_tween()
	tween.tween_property($TruckatedCircle, "modulate", Color(1, 1, 1, 0.5), 0.1)
	tween.tween_property($TruckatedCircle, "modulate", $TruckatedCircle.modulate, 0.1)

# ==============================================================================
# SIGNAL HANDLERS
# ==============================================================================

func _on_area_2d_body_entered(body: Node2D) -> void:
	"""Gère l'entrée d'un corps dans la zone de collision"""
	var impact_force: float = 0.0
	
	if body.has_method("calculate_impact_force"):
		impact_force = calculate_impact_force(body)
	
	# Émettre le signal
	ball_collision.emit(body, impact_force)
	
	# Préparer les données d'événement
	var event_datas = {
		"ball1": object_infos(),
		"collide_with": body.name,
		"impact_force": impact_force,
		"position1": {"x": global_position.x, "y": global_position.y},
		"position2": {"x": body.global_position.x, "y": body.global_position.y},
		"velocity1": linear_velocity.length(),
	}
	
	# Ajouter les informations de l'autre balle si disponible
	if body.has_method("object_infos"):
		event_datas["ball2"] = body.object_infos()
#		event_datas["velocity2"] = body.linear_velocity.length()
	
	# Envoyer les données au NetworkManager
	var my_data = {"event_type": "ball_collide", "event_datas": event_datas}
	NetworkManager.transfer_datas("evenement", my_data)
	
	# Jouer l'effet de collision (décommenter si besoin)
	# play_collision_effect()
