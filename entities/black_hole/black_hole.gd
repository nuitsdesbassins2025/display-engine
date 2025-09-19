extends Node2D

# Configuration
@export var initial_radius: float = 50.0
@export var growth_per_object: float = 5.0
@export var influence_radius: float = 300.0
@export var attraction_force: float = 200.0
@export var rotation_speed: float = 20.0

# Variables internes
var current_radius: float
var objects_absorbed: int = 0
var ring_data = []  # Stocke les données pour chaque anneau: [radius, color, offset]


@export var max_speed: float = 40.0
@export var min_speed: float = 10.0
@export var object_radius: float = 20.0
@export var direction_change_interval: float = 1.5
@export var speed_variation: float = 0.3

var current_velocity: Vector2
var target_velocity: Vector2
var viewport_rect: Rect2
var time_since_direction_change: float = 0.0


var lost_control = false


func _ready():

	reset_blackhole()

# L'effet coloré du trou noir, varie selon qui il absorbe
var color_circle : Color = Color(0.941, 0.925, 0.039, 0.7)

func reset_blackhole():
	color_circle = Color(0.941, 0.925, 0.039, 0.7)
	objects_absorbed = 0
	current_radius = initial_radius
	
	viewport_rect = get_viewport().get_visible_rect()
	global_position = get_random_position_within_bounds()	
	choose_new_movement_parameters()
	lost_control = false
	
	create_ring_data()
	grow_blackhole()


func _process(delta):
	# Mise à jour pour le dessin
	queue_redraw()
	# Attirer les objets dans la zone d'influence
	attract_objects()
	
	time_since_direction_change += delta
	
	# Changer progressivement de paramètres de mouvement
	if time_since_direction_change >= direction_change_interval:
		choose_new_movement_parameters()
		time_since_direction_change = 0.0
	
	# Interpolation fluide vers la vitesse cible
	update_movement_smoothly(delta)
	
	# Appliquer le mouvement
	global_position += current_velocity * delta

	# Gérer les bords
	handle_boundaries()
	
	if lost_control:
		if (current_radius < viewport_rect.size.x*3 ):
			grow_blackhole()
		global_position = get_viewport().get_visible_rect().size / 2
	
	if objects_absorbed > 400 :
		get_tree().create_timer(10.0).timeout.connect(
			func(): 
				if get_tree().current_scene.has_method("reset_scene"):
					get_tree().current_scene.reset_scene()
		)
		


func create_ring_data():
	# Créer les données pour les anneaux orbitaux
	ring_data.clear()
		# Anneau 1: noir
	ring_data.append([current_radius * 1.03, Color(0, 0, 00, 1), Vector2.ZERO])
	# Anneau 1: blanc
	ring_data.append([current_radius * 1.05, Color(1, 1, 1.0, 1), Vector2.ZERO])

	# Anneau Léger, bleuâtre
	ring_data.append([current_radius * 1.12, color_circle, Vector2.ZERO])
	
	ring_data.append([current_radius * 1.1, Color(0.941, 0.925, 0.739,0.6), Vector2.ZERO])
	# Anneau 2: Plus large, violet clair	
	ring_data.append([current_radius * 1.1, Color(0.9, 0.9, 0.9, 0.6), Vector2.ZERO])
	# Anneau 2: Plus large, violet clair
	
	ring_data.append([current_radius * 1.2, Color(0.9, 0.8, 1.0, 0.5), Vector2.ZERO])
	# Anneau 3: Extérieur, bleu très transparent
	ring_data.append([current_radius * 1.3, Color(0.8, 0.8, 0.5, 0.2), Vector2.ZERO])
			# Anneau 1: noir
	ring_data.append([current_radius * 1.03, Color(0, 0, 00, 1), Vector2.ZERO])
	
func _draw():
	# Dessiner le cercle noir central
	#draw_circle(Vector2.ZERO, current_radius, Color(0, 0, 0, 1))
	
	# Dessiner les anneaux orbitaux avec effets
	var time = Time.get_ticks_msec() / 1000.0
	
	for i in range(ring_data.size()):
		var radius = ring_data[i][0]
		var color = ring_data[i][1]
		var base_offset = ring_data[i][2]
		
		# Animation des anneaux (rotation + oscillation)
		var angle = time * rotation_speed * (0.8 + i * 0.2)
		var oscillation = sin(time * (3 + i)) * (2 + i)
		
		# Calculer le décalage animé
		var animated_offset = base_offset + Vector2(oscillation, 0).rotated(angle)
		
		draw_circle(animated_offset,radius,color)


	# Dessiner le cercle noir central
	draw_circle(Vector2.ZERO, current_radius, Color(0, 0, 0, 1))
	$center._draw_black_circle(current_radius*1.1)
	
	#draw_blurring_arc(Vector2.ZERO, current_radius)

func draw_blurring_arc(center: Vector2, radius: float):
	var points = 32  # Plus de points pour un effet plus lisse
	var blur_width = 10.0  # Largeur de l'effet de blur
	var steps = 10  # Nombre d'étapes pour le dégradé
	
	# Dessiner plusieurs arcs avec un dégradé d'alpha
	for i in range(steps):
		var alpha = 0.8 * (1.0 - float(i) / steps)
		var current_radius = radius + (i * blur_width / steps)
		var current_width = blur_width / steps
		
		draw_arc(center, current_radius, 0, TAU, points, Color(0, 0, 0, alpha), current_width)


func attract_objects():
	# Trouver tous les objets dans la zone d'influence
	var bodies = get_tree().get_nodes_in_group("attractable")
	for body in bodies:
		if body != self:
			var direction = global_position - body.global_position
			var distance = direction.length()
			
			if distance < influence_radius:
				# Calculer la force d'attraction (plus forte quand plus proche)
				var force_strength = attraction_force * (1.0 - distance / influence_radius)
				var force = direction.normalized() * force_strength
				
				# Appliquer la force à l'objet selon son type
				if body is RigidBody2D:
					body.apply_central_force(force)
				elif body.has_method("apply_attraction_force"):
					body.apply_attraction_force(force)
				
				# Si l'objet est très proche, l'absorber
				if distance < current_radius:
					absorb_object(body)

func absorb_object(object):
	if !object.is_in_group("absobable"):
		return
	# Supprimer l'objet absorbé
	if object.is_in_group("mini_balls"):
		color_circle = object.ball_color
		color_circle.a = 0.8
	object.queue_free()
	
	grow_blackhole()
	
	var my_data = {
		"event_type": "black_grow",
		"event_datas":{
			"objects_absorbed": objects_absorbed,
			"radius":current_radius,
			}
		}
		
	NetworkManager.transfer_datas("evenement", my_data)
	
	if (objects_absorbed > 100) :
		lost_control = true



func grow_blackhole():
		# Agrandir le trou noir
	objects_absorbed += 1
	var grow = objects_absorbed * growth_per_object
	
	if objects_absorbed > 100 :
		grow = 100 * growth_per_object + (objects_absorbed-100)*growth_per_object/8
	
	current_radius = initial_radius + grow
	
	# Mettre à jour les données des anneaux
	create_ring_data()


func choose_new_movement_parameters():
	# Nouvelle direction aléatoire
	var random_angle = randf_range(0, TAU)
	var new_direction = Vector2(cos(random_angle), sin(random_angle))
	
	# Nouvelle vitesse aléatoire dans une plage
	var new_speed = randf_range(min_speed, max_speed)
	
	# Vitesse cible
	target_velocity = new_direction * new_speed

func update_movement_smoothly(delta):
	# Interpolation douce avec acceleration/décélération
	var acceleration = max_speed * 0.8
	current_velocity = current_velocity.move_toward(
		target_velocity, 
		acceleration * delta
	)
	
	# Ajouter un peu de variation aléatoire pour un mouvement plus organique
	if randf() < 0.02:  # 2% de chance par frame
		current_velocity = current_velocity.rotated(randf_range(-0.1, 0.1))
		current_velocity = current_velocity.limit_length(max_speed)

func handle_boundaries():
	var current_pos = global_position
	var min_pos = viewport_rect.position + Vector2(current_radius, current_radius)
	var max_pos = viewport_rect.size - Vector2(current_radius, current_radius)
	
	var needs_bounce = false
	
	# Vérifier les bords et préparer le rebond
	if current_pos.x <= min_pos.x or current_pos.x >= max_pos.x:
		target_velocity.x = -target_velocity.x * 0.8  # Rebond avec perte d'énergie
		needs_bounce = true
	
	if current_pos.y <= min_pos.y or current_pos.y >= max_pos.y:
		target_velocity.y = -target_velocity.y * 0.8  # Rebond avec perte d'énergie
		needs_bounce = true
	
	if needs_bounce:
		# Réinitialiser le timer de changement de direction
		time_since_direction_change = direction_change_interval * 0.8
	
	# Maintenir dans les limites
	global_position = Vector2(
		clamp(current_pos.x, min_pos.x, max_pos.x),
		clamp(current_pos.y, min_pos.y, max_pos.y)
	)
	
func get_random_position_within_bounds() -> Vector2:
	var min_pos = viewport_rect.position + Vector2(object_radius, object_radius)
	var max_pos = viewport_rect.size - Vector2(object_radius, object_radius)
	return Vector2(
		randf_range(min_pos.x, max_pos.x),
		randf_range(min_pos.y, max_pos.y)
	)
# Optionnel: Pour faire tourner l'objet selon sa direction
func _physics_process(delta):
	if current_velocity.length() > 0.1:
		rotation = current_velocity.angle() + PI/2  # Ajustez selon l'orientation de votre sprite
