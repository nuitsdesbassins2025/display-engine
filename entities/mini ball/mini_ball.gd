extends RigidBody2D

@export var min_size: float = 10.0
@export var max_size: float = 30.0
@export var colors: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, 
	Color.PURPLE, Color.ORANGE, Color.PINK, Color.CYAN
]
signal ball_collision(other_ball: Node, impact_force: float)

func _ready():
	randomize_ball()

func randomize_ball():
	# Taille aléatoire
	var size = randf_range(min_size, max_size)
	#var scale_factor = size / 20.0  # 20px comme référence
	
	# Couleur aléatoire
	var random_color = colors[randi() % colors.size()]
	
	# Appliquer la taille
	$CollisionShape2D.shape.radius = size
	#print("collision size :")
	#print($CollisionShape2D.shape.radius)
	$TruckatedCircle.outer_radius = size
	$TruckatedCircle.inner_radius = 0
	#print("TruckatedCircle size :")
	#print($TruckatedCircle.outer_radius)
	# Appliquer la couleur
	$TruckatedCircle.ring_color = random_color
	
	# Propriétés physiques aléatoires
	mass = size / 10.0  # Masse proportionnelle à la taille
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = randf_range(0.6, 0.9)  # Rebond aléatoire



func _on_body_entered(body: Node):
	#if body.is_in_group("mini_balls"):
	var impact_force = calculate_impact_force(body)
	print("Collision entre balles: ", name, " et ", body.name)
	print("Force d'impact: ", impact_force)
	
	# Émettre le signal
	ball_collision.emit(body, impact_force)
	
	# Envoyer au NetworkManager
	NetworkManager.transfer_datas("ball_collision", {
		"ball1": name,
		"ball2": body.name,
		"impact_force": impact_force,
		"position1": {"x": global_position.x, "y": global_position.y},
		"position2": {"x": body.global_position.x, "y": body.global_position.y},
		"velocity1": linear_velocity.length(),
		"velocity2": body.linear_velocity.length()
	})

func calculate_impact_force(other_ball: Node) -> float:
	var relative_velocity = linear_velocity - other_ball.linear_velocity
	return relative_velocity.length() * mass

# Optionnel : Ajouter un effet visuel sur collision
func play_collision_effect():
	$Sprite2D.modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0.5), 0.1)
	tween.tween_property($Sprite2D, "modulate", $Sprite2D.modulate, 0.1)
