extends Node2D

# Variables publiques
var actif: bool = true
var posX: float
var posY: float
var angle: float
var size: float = 1.0  # Taille initiale
var animation_player: AnimationPlayer

func _ready():
	# Initialisez ici les références qui nécessitent que le nœud soit prêt
	animation_player = $AnimationPlayer

	# Position initiale
	posX = position.x
	posY = position.y
	angle = rotation_degrees

func move_to(new_x: float, new_y: float):
	# Crée une animation pour déplacer le joueur à la nouvelle position
	var anim_length = 0.2  # Durée de l'animation en secondes
	var animation = Animation.new()
	animation.length = anim_length

	animation.track_insert_key(0, 0, position)
	animation.track_insert_key(0, anim_length, Vector2(new_x, new_y))

	animation_player.add_animation("move_animation", animation)
	animation_player.play("move_animation")

	# Met à jour les variables publiques
	posX = new_x
	posY = new_y

func turn_to(new_angle: float):
	# Crée une animation pour tourner le joueur vers le nouvel angle
	var anim_length = 0.3  # Durée de l'animation en secondes
	var animation = Animation.new()
	animation.length = anim_length

	animation.track_insert_key(0, 0, rotation_degrees)
	animation.track_insert_key(0, anim_length, new_angle)

	animation_player.add_animation("turn_animation", animation)
	animation_player.play("turn_animation")

	# Met à jour la variable publique
	angle = new_angle

func do_action01():
	# Animation pour faire grandir le joueur puis revenir à la taille normale
	var anim_length = 1.0  # Durée totale de l'animation
	var animation = Animation.new()
	animation.length = anim_length

	animation.track_insert_key(0, 0, Vector2(size, size))
	animation.track_insert_key(0, anim_length * 0.5, Vector2(size * 1.3, size * 1.3))
	animation.track_insert_key(0, anim_length, Vector2(size, size))

	animation_player.add_animation("grow_shrink", animation)
	animation_player.play("grow_shrink")

# Mettre à jour la position directement (sans animation)
func update_position(x, y):
	position.x = x
	position.y = y
	posX = x
	posY = y

# Mettre à jour la rotation directement (sans animation)
func update_rotation(degrees):
	rotation_degrees = degrees
	angle = degrees

# Mettre à jour la couleur directement
func update_color(color):
	# Supposons que le sprite est le premier enfant
	var sprite = get_child(0)
	sprite.modulate = color
