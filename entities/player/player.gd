extends CharacterBody2D
class_name Player


@export var player_id: int = -1:
	set(value):
		player_id = value
		# Mettez à jour ici ce qui dépend de l'ID
		_update_player_identity()
		
		
# Propriétés du joueur
var gd_id: String = ""
var client_id: String = ""
var tracking_id: String = ""

var is_tracked_player: bool = false
var is_active: bool = true

var player_color: Color = Color.WHITE
var health: int = 10
var ammo: int = 5

# Timer pour l'inactivité
var inactivity_timer: Timer
var last_position_update: float = 0.0

# Références aux nodes
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

# Dictionnaire des actions disponibles
var actions_map: Dictionary = {}

func _ready():
	# Configuration initiale
	setup_player()
	#setup_signals()
	setup_inactivity_timer()
	setup_actions_map()

func setup_player():
	
	pass
	# Configuration du sprite en cercle
	#var circle_texture = create_circle_texture()
	#sprite.texture = circle_texture
	#sprite.modulate = player_color
	#
	## Configuration de la collision
	#var circle_shape = CircleShape2D.new()
	#circle_shape.radius = 10
	#collision_shape.shape = circle_shape
	#
	
func _update_player_identity():
	print("Player ID set to: ", player_id)
	# Ajoutez ici la logique spécifique à l'ID
	# Par exemple : changer la couleur, le nom, etc.
	
	
func setup_signals():
	
	pass
	# Connexion aux signaux externes
	#if NetworkManager.has_signal("player_change_position"):
		#NetworkManager.player_change_position.connect(_on_player_change_position)
	#
	#if NetworkManager.has_signal("player_do_action"):
		#NetworkManager.player_do_action.connect(_on_player_do_action)
	#
	#if NetworkManager.has_signal("player_set_color"):
		#NetworkManager.player_set_color.connect(_on_player_set_color)
	#
	#if NetworkManager.has_signal("player_sync_tracking_client"):
		#NetworkManager.player_sync_tracking_client.connect(_on_player_sync_tracking_client)
#


func setup_inactivity_timer():
	inactivity_timer = Timer.new()
	add_child(inactivity_timer)
	inactivity_timer.wait_time = 10.0
	inactivity_timer.one_shot = false
	inactivity_timer.timeout.connect(_on_inactivity_timeout)
	inactivity_timer.start()

func setup_actions_map():
	# Mapping des actions disponibles
	actions_map = {
		"shoot": _do_shoot,
		"reload": _do_reload,
		"heal": _do_heal,
		"move": _do_move
	}

#func create_circle_texture() -> Texture2D:
	## Création d'une texture de cercle programmatiquement
	#var image = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	#image.fill(Color.TRANSPARENT)
	#
	## Dessiner un cercle (simplifié)
	#var center = Vector2(10, 10)
	#for x in range(20):
		#for y in range(20):
			#if Vector2(x, y).distance_to(center) <= 8:
				#image.set_pixel(x, y, Color.WHITE)
	#
	#return ImageTexture.create_from_image(image)

## SIGNAL HANDLERS
#func _on_player_change_position( new_position: Vector2):
	##if player_id == gd_id:
	#move_to_position(new_position)
#
#func _on_player_do_action(player_id: String, action: String, action_datas: Dictionary):
	#if player_id == gd_id and actions_map.has(action):
		#actions_map[action].call(action_datas)
#
#func _on_player_set_color(player_id: String, color: Color):
	#if player_id == gd_id:
		#set_player_color(color)
#
#func _on_player_sync_tracking_client(player_id: String, track_id: String, cl_id: String, pos: Vector2):
	#if player_id == gd_id:
		#sync_tracking_client(track_id, cl_id, pos)

func _on_inactivity_timeout():
	check_inactivity()

# FONCTIONS PRINCIPALES

var current_move_tween: Tween = null


func move_to_position(target_position: Vector2):
	#On met à jours pour l'inactivité
	last_position_update = Time.get_unix_time_from_system()
	
	if not is_active:
		set_active(true)

	# Si très proche, téléportation immédiate
	if global_position.distance_to(target_position) < 10.0:
		print("tp")
		global_position = target_position
		return

	# Arrêter l'animation précédente
	if current_move_tween:
		current_move_tween.kill()

	# Créer une nouvelle animation
	current_move_tween = create_tween()

	# Durée dynamique basée sur la distance
	var distance = global_position.distance_to(target_position)
	var duration = clamp(distance / 400.0, 0.05, 0.3)

	current_move_tween.tween_property(self, "global_position", target_position, duration)
	current_move_tween.finished.connect(_cleanup_tween)

func _cleanup_tween():
	current_move_tween = null

func set_active(active: bool):
	is_active = active
	visible = active
	set_physics_process(active)  # Désactiver le processing si inactif


func set_player_color(color: Color):
	player_color = color
	sprite.modulate = player_color

func sync_tracking_client(track_id: String, cl_id: String, pos: Vector2):
	tracking_id = track_id
	client_id = cl_id
	is_tracked_player = tracking_id != "" and client_id != ""
	
	if pos != Vector2.ZERO:
		move_to_position(pos)

func check_inactivity():
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_position_update > 10.0:
		print("inactif")
		is_active = false
		visible = false
	else:
		print("actif")
		is_active = true
		visible = true

# ACTIONS DISPONIBLES
func _do_shoot(data: Dictionary):
	if ammo > 0:
		ammo -= 1
		# Logique de tir
		pass

func _do_reload(data: Dictionary):
	ammo = 5
	# Logique de rechargement
	pass

func _do_heal(data: Dictionary):
	health = min(health + data.get("amount", 1), 10)
	# Logique de soin
	pass

func _do_move(data: Dictionary):
	# Logique de mouvement supplémentaire
	pass

func _process(delta):
	#global_position = get_global_mouse_position()
	# Mise à jour de la dernière activité
	pass 
	#if position != Vector2.ZERO:
		#last_position_update = Time.get_unix_time_from_system()
		
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT :
		print("move")
		move_to_position(get_global_mouse_position())
		
		#_on_player_change_position(gd_id,get_global_mouse_position() )
		#global_position = get_global_mouse_position()
		#push_nearby_balls()
		#can_push = false
		#$CooldownTimer.start()
