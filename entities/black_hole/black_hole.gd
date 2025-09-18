extends Node2D

# Configuration
@export var initial_radius: float = 350.0
@export var growth_per_object: float = 5.0
@export var influence_radius: float = 300.0
@export var attraction_force: float = 200.0
@export var rotation_speed: float = 20.0

# Variables internes
var current_radius: float
var objects_absorbed: int = 0
var ring_data = []  # Stocke les données pour chaque anneau: [radius, color, offset]

func _ready():
	current_radius = initial_radius
	create_ring_data()
	
var color_circle : Color = Color(0.941, 0.925, 0.039, 0.7)

	
func _process(delta):
	# Mise à jour pour le dessin
	queue_redraw()
	
	# Attirer les objets dans la zone d'influence
	attract_objects()

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
		
		
		# Dessiner l'anneau avec un contour
		#draw_arc(animated_offset, radius, 0, TAU, 64, color, 4.0 + i * 2)
		
		# Ajouter quelques cercles supplémentaires pour l'effet vibrant
		#for j in range(3):
			#var segment_angle = angle + j * TAU/3
			#var point_pos = Vector2(radius, 0).rotated(segment_angle) + animated_offset
			#draw_circle(point_pos, 3 + j, color.lightened(0.3))
		
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
	
	# Agrandir le trou noir
	objects_absorbed += 1
	current_radius = initial_radius + objects_absorbed * growth_per_object
	
	# Mettre à jour les données des anneaux
	create_ring_data()
	
	var my_data = {
		"event_type": "black_grow",
		"event_datas":{
			"objects_absorbed": objects_absorbed,
			"radius":current_radius,
			}
		}
		
	NetworkManager.transfer_datas("evenement", my_data)
	
