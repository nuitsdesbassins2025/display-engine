extends RigidBody2D

@export var min_size: float = 10.0
@export var max_size: float = 30.0
@export var collision_threashold: float = 2.0
@export var lifetime: float = 0.0  # 0 = illimité
@export var colors: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, 
	Color.PURPLE, Color.ORANGE, Color.PINK, Color.CYAN
]

var time_alive: float = 0.0
signal ball_collision(other_ball: Node, impact_force: float)
signal ball_expired  # Nouveau signal pour l'expiration

func _ready():
	randomize_ball()
	if lifetime > 0:
		start_lifetime_timer()

func start_lifetime_timer():
	# Démarrer un timer pour la durée de vie
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_expired)
	add_child(timer)
	timer.start()

func _on_lifetime_expired():
	# Émettre le signal et se supprimer
	ball_expired.emit()
	queue_free()

func _process(delta):
	if lifetime > 0:
		time_alive += delta
		check_screen_bounds()

func check_screen_bounds():
	var viewport_rect = get_viewport_rect()
	var screen_margin = 100  # Marge pour être sûr de sortir complètement
	
	# Vérifier si la balle est complètement sortie de l'écran
	if (global_position.x < -screen_margin || 
		global_position.x > viewport_rect.size.x + screen_margin ||
		global_position.y < -screen_margin || 
		global_position.y > viewport_rect.size.y + screen_margin):
		
		# Option 1: Supprimer la balle
		queue_free()
		
		# Option 2: La replacer (décommentez si préféré)
		# respawn_at_random_position()

func respawn_at_random_position():
	# Replacer la balle à une position aléatoire dans l'écran
	var viewport_rect = get_viewport_rect()
	global_position = Vector2(
		randf_range(50, viewport_rect.size.x - 50),
		randf_range(50, viewport_rect.size.y - 50)
	)
	linear_velocity = Vector2.ZERO


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
	
	# Sauvegarder l'état de physique
	var was_frozen = freeze
	freeze = true
	
	# Modifier les properties
	$CollisionShape2D.shape.radius = size
	$TruckatedCircle.outer_radius = size
	$TruckatedCircle.inner_radius = 0
	$Area2D/CollisionShape2D.shape.radius = size + collision_threashold
	
	# Recréer les shapes
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	$Area2D/CollisionShape2D.shape = $Area2D/CollisionShape2D.shape.duplicate()
	
	# Restaurer l'état de physique
	await get_tree().physics_frame
	freeze = was_frozen


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
