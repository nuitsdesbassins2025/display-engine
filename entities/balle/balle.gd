extends RigidBody2D

# Les données de la balle
signal ball_datas(ball_id, datas)

# Les rebonds, les collisions
signal ball_events(ball_id, events)

var ball_datas_2 : Dictionary = {
	#posX posY speed size 
 }
	

# Configuration
@export var min_speed: float = 100.0
@export var max_speed: float = 300.0
@export var bounce_factor: float = 1.0
@export var ball_radius: float = 40.0
@export var wrap_around_edges: bool = true  # true = téléportation, false = rebond
@export var wall_repulsion_strength: float = 0.5  # Force de répulsion des murs

var original_collision_mask: int
var original_collision_layer: int

@export var ball_color: Color = Color(1, 0, 0)
@export var ball_size: float = 50.0
@export_range(1, 10) var ball_intensity: int = 5

var circle_texture: ImageTexture
var halo_texture: ImageTexture

	
	
func _ready():
	add_to_group("attractable")
	gravity_scale = 0
	if linear_velocity == Vector2.ZERO:
		_set_random_velocity()
	original_collision_mask = collision_mask
	original_collision_layer = collision_layer
	
	z_index = 100
	generate_textures()
	queue_redraw()

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
	
	## Bord gauche
	#if position.x - ball_radius < 0:
		#linear_velocity.x = abs(linear_velocity.x) * bounce_factor
		#position.x = ball_radius
		#_apply_proximity_repulsion(Vector2.RIGHT, viewport_size)
		#_on_ball_bounce("wall")
	#
	## Bord droit
	#elif position.x + ball_radius > viewport_size.x:
		#linear_velocity.x = -abs(linear_velocity.x) * bounce_factor
		#position.x = viewport_size.x - ball_radius
		#_apply_proximity_repulsion(Vector2.LEFT, viewport_size)
		#_on_ball_bounce("wall")
	#
	# Bord haut
	if position.y - ball_radius < 0:
		linear_velocity.y = abs(linear_velocity.y) * bounce_factor
		position.y = ball_radius
		_apply_proximity_repulsion(Vector2.DOWN, viewport_size)
		_on_ball_bounce("wall")
	
	# Bord bas
	elif position.y + ball_radius > viewport_size.y:
		linear_velocity.y = -abs(linear_velocity.y) * bounce_factor
		position.y = viewport_size.y - ball_radius
		_apply_proximity_repulsion(Vector2.UP, viewport_size)
		_on_ball_bounce("wall")
	

	
func move_to_center():
	var viewport_size = get_viewport_rect().size
	
	# Utiliser call_deferred pour éviter les conflits avec le moteur physique
	call_deferred("_deferred_move_to_center", viewport_size)

func _deferred_move_to_center(viewport_size: Vector2):
	# Réinitialiser toutes les propriétés physiques
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	constant_force = Vector2.ZERO
	constant_torque = 0
	
	# Téléporter au centre
	position = Vector2(viewport_size.x/2, viewport_size.y/2)
	
	# Réappliquer la physique au prochain frame
	await get_tree().physics_frame
	_set_random_velocity()
	
	print("déplace la balle au centre")


func _apply_proximity_repulsion(direction: Vector2, viewport_size: Vector2):
	# Calcule la distance au mur le plus proche
	var distance_to_wall = _get_distance_to_nearest_wall(viewport_size)
	
	# Applique une répulsion plus forte quand on est proche du mur
	if distance_to_wall < 50.0:  # Seuil de proximité
		var proximity_factor = 1.0 - (distance_to_wall / 50.0)  # 1.0 quand très proche, 0.0 quand loin
		var repulsion_strength = wall_repulsion_strength * proximity_factor
		
		linear_velocity += direction * repulsion_strength
		#print("Répulsion proximité: force ", repulsion_strength)

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

func emit_ball_datas():
	var ball_datas = {}
	ball_datas.emit(ball_datas)

func _on_body_entered(body: Node) -> void:
	print("collision detected")
	print(body)
	pass # Replace with function body.

func _on_ball_bounce(with):
	print(position)
	var percent_pos = T.global_position_to_percentage(position)
	var my_data = {
		"event_type": "ball_bounce",
		"event_datas":{
			"position": percent_pos,
			"pixel_position": position,
			"with":with,
			"velocity":linear_velocity.length()
			}
		}
		
	NetworkManager.transfer_datas("evenement", my_data)
	


func _on_area_2d_body_entered(body: Node2D) -> void:
	#print("Collision détectée par Area2D ici")
	print(body.name)
	if body.name =="poteaux":
		_on_ball_bounce("poteaux")
		
	if body.name =="back_wall":
		_on_ball_bounce("back_wall")
		
	if body.is_in_group("players"):
		var player_key = body.player_key
		_on_ball_bounce(player_key)

		if body.client_id != "":
			print("client_id")
			T.emit_player_event(body.client_id, "player_ball")
			
			var my_data2 = {
				"event_type": "player_ball",
				"client_id":body.client_id,
				"event_datas":{
					"pixel_position": position,
					"position":T.global_position_to_percentage(position),
					"velocity":linear_velocity.length()
					}
				}
				
			NetworkManager.transfer_datas("evenement", my_data2)
		
		
		
	if body.is_in_group("poteaux"):
		print("poteaux", body.name)



func _draw():
	# Dessiner le halo en premier (en dessous)
	if halo_texture:
		draw_texture(halo_texture, -halo_texture.get_size() / 2)
	
	# Dessiner le cercle principal
	if circle_texture:
		draw_texture(circle_texture, -circle_texture.get_size() / 2)

func generate_textures():
	circle_texture = generate_circle_texture(ball_size, ball_color)
	halo_texture = generate_halo_texture(ball_size * 1.5, ball_color, ball_intensity)

func generate_circle_texture(size: float, color: Color) -> ImageTexture:
	var image = Image.create(int(size * 2), int(size * 2), false, Image.FORMAT_RGBA8)
	var center = Vector2(size, size)
	
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			if distance <= size:
				var alpha = 1.0
				if distance > size - 2:
					alpha = (size - distance) / 2.0
				
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	return ImageTexture.create_from_image(image)

func generate_halo_texture(size: float, color: Color, intensity: int) -> ImageTexture:
	var halo_size = size * (1.0 + intensity * 0.1)
	var image = Image.create(int(halo_size * 2), int(halo_size * 2), false, Image.FORMAT_RGBA8)
	var center = Vector2(halo_size, halo_size)
	
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			var max_radius = halo_size
			
			if distance <= max_radius:
				var normalized_dist = distance / max_radius
				var alpha = (1.0 - normalized_dist) * (intensity * 0.1)
				alpha = clamp(alpha, 0, 0.8)
				
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	return ImageTexture.create_from_image(image)

# Fonction pour régler l'intensité du halo (permanent)
func set_ball_intensity(intensity: int):
	ball_intensity = clamp(intensity, 1, 10)
	generate_textures()
	queue_redraw()

# Fonction pour déclencher un effet visuel court
func ball_effect():
	# Animation d'échelle (pulse)
	var original_scale = scale
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Effet de pulse
	tween.tween_property(self, "scale", original_scale * 1.3, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.3).set_delay(0.1)
	
	# Effet de luminosité
	var original_modulate = modulate
	tween.tween_property(self, "modulate", original_modulate * 2.0, 0.1)
	tween.tween_property(self, "modulate", original_modulate, 0.3).set_delay(0.1)
	
	# Effet de halo temporaire (plus intense pendant l'effet)
	var original_intensity = ball_intensity
	set_ball_intensity(10)  # Intensité maximale pendant l'effet
	
	# Retour à l'intensité originale après l'effet
	await get_tree().create_timer(0.4).timeout
	set_ball_intensity(original_intensity)

# Fonction pour changer la couleur
func set_ball_color(new_color: Color):
	ball_color = new_color
	generate_textures()
	queue_redraw()

# Fonction pour changer la taille
func set_ball_size(new_size: float):
	ball_size = new_size
	generate_textures()
	queue_redraw()

# Optionnel: Effet spécial avec paramètres
func ball_effect_custom(duration: float = 0.4, pulse_scale: float = 1.3, brightness: float = 2.0):
	var original_scale = scale
	var original_modulate = modulate
	var original_intensity = ball_intensity
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Pulse
	tween.tween_property(self, "scale", original_scale * pulse_scale, duration * 0.25)
	tween.tween_property(self, "scale", original_scale, duration * 0.75).set_delay(duration * 0.25)
	
	# Luminosité
	tween.tween_property(self, "modulate", original_modulate * brightness, duration * 0.25)
	tween.tween_property(self, "modulate", original_modulate, duration * 0.75).set_delay(duration * 0.25)
	
	# Halo intensifié
	set_ball_intensity(10)
	await get_tree().create_timer(duration).timeout
	set_ball_intensity(original_intensity)
