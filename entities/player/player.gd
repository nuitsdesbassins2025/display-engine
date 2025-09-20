extends CharacterBody2D
class_name Player

## SIGNALS
signal player_touche_objet(objet_nom)
signal player_dans_zone(zone_nom)





# Signal émis lorsque le player est sur le point d'être supprimé
signal player_about_to_delete(player_instance, player_key)

## EXPORTS
@export_category("Player Identity")
@export var player_id: String = "" :
	set(value):
		player_id = value
		_update_player_identity()

@export var player_key: String = "0000":
	set(value):
		player_key = value
		_update_player_key()
		
@export var client_id: String = "":
	set(value):
		client_id = value
		_register_client_id()
		
@export var pseudo: String = "":
	set(value):
		pseudo = value
		_register_pseudo()


@export_category("Appearance")
@export var player_color: Color = Color.WHITE:
	set(value):
		player_color = value
		_register_color()
@export var player_size: int = 100:
	set(value):
		player_size = value
		_update_appearance()
@export var player_scale: float = 1.0:
	set(value):
		player_scale = value
		_update_appearance()
@export var circle_thickness: int = 10
	


@export var shield_cooldown: float = 1.5

@export_category("Movement")
@export var move_speed: float = 400.0

@export var debug_position = false

var base_color: Color = Color(0.2, 0.2, 0.2)

## VARIABLES
var gd_id: String = ""

var tracking_id: String = ""

var is_tracked_player: bool = false
var is_active: bool = true

var is_shield_active: bool = false
var can_use_shield: bool = true
var inactivity_timer: Timer
var last_player_action: float = 0.0
var current_move_tween: Tween = null
var actions_map: Dictionary = {}
var viewport_size: Vector2

var consecutive_lost:int = 0


var target_rotation: float = 0.0
var rotation_speed: float = 1.0  # Ajustez cette valeur pour contrôler la vitesse

## REFERENCES
@onready var collision_shape: CollisionShape2D = $player_collision_shape
@onready var sprite: Polygon2D = $player_skin
@onready var shield: Polygon2D = $Shield/shield
@onready var snake_trail: SnakeTrail = $SnakeTrail

# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready():
	viewport_size = get_viewport().get_visible_rect().size
	_setup_player()
	_setup_inactivity_timer()
	z_index = 40

func _setup_player():
	player_color = base_color
	_update_appearance()


func _setup_inactivity_timer():
	inactivity_timer = Timer.new()
	add_child(inactivity_timer)
	inactivity_timer.wait_time = 3.0
	inactivity_timer.one_shot = false
	inactivity_timer.timeout.connect(_on_inactivity_timeout)
	inactivity_timer.start()


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func object_infos() -> Dictionary:
	"""Renvoie les informations du joueur sous forme de dictionnaire"""
	var position = T.global_position_to_percentage(global_position)
	var infos = {
		"name": "player",
		"body_name": name,
		"player_id": player_id,
		"player_key": player_key,
		"global_position":  global_position,
		"position":position,
		"rotation": rotation,
		"speed": velocity.length(),

		"color": {
			"r": player_color.r,
			"g": player_color.g,
			"b": player_color.b,
			"a": player_color.a
		},
		"is_active": is_active,
		"is_shield_active": is_shield_active,
		"is_tracked": is_tracked_player
	}
	return infos
	
func set_display_text(text:String):
	$TruckatedCircle.display_text = text
	_update_appearance()



func move_to_position(target_position: Vector2):
	
	print("move_to : ", target_position)
	
	if debug_position:
		var position_txt = str(int(target_position.x)) + ":"+str(int(target_position.y))
		set_display_text(position_txt)
	else :
		if pseudo :
			set_display_text(pseudo)
		else :
			set_display_text(player_key)

	"""Déplace le joueur vers une position cible"""
	var actual_position = Vector2(
		target_position.x / 100.0 * viewport_size.x,
		target_position.y / 100.0 * viewport_size.y
	)

	last_player_action = Time.get_unix_time_from_system()

	if not is_active:
		set_active(true)

	var direction = (actual_position - global_position).normalized()
	_update_player_orientation(direction)

	if current_move_tween:
		current_move_tween.kill()

	current_move_tween = create_tween()
	var distance = global_position.distance_to(actual_position)
	
	var duration = clamp(distance / move_speed, 0.05, 0.3)
	
	current_move_tween.tween_property(self, "global_position", actual_position, duration)
	
	current_move_tween.finished.connect(_on_move_finished)
	


func set_active(active: bool):
	"""Active ou désactive le joueur"""
	is_active = active
	visible = active
	set_physics_process(active)
	if client_id != "":
		$BallSpawner.activated = active
	# Désactiver toutes les formes de collision
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = not active
		elif child is Node2D and child.has_method("set_collision_layer"):
			child.set_collision_layer(0 if not active else 1)


func trigger_shield():
	last_player_action = Time.get_unix_time_from_system()
	if not is_active:
		set_active(true)
	"""Active le bouclier du joueur"""
	if not can_use_shield:
		return
	is_shield_active = true
	can_use_shield = false
	
	var shield_collision_shape = $Shield/Area2D
	var shield_visual = $Shield/shield
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(shield_collision_shape, "scale", Vector2(3.0, 3.0), 0.3)
	tween.tween_property(shield_visual, "scale", Vector2(3.0, 3.0), 0.3)
	tween.tween_property(shield_collision_shape, "scale", Vector2(1.0, 1.0), 0.7).set_delay(0.3)
	tween.tween_property(shield_visual, "scale", Vector2(1.0, 1.0), 0.7).set_delay(0.3)
	tween.tween_callback(_on_shield_animation_finished).set_delay(1.0)
	
	push_objects()


var influence_radius = player_scale + 200;
var push_force = 500000

func push_objects():
	# Trouver tous les objets dans la zone d'influence
	var bodies = get_tree().get_nodes_in_group("attractable")
	for body in bodies:
		if body != self:
			
			var direction = body.global_position - global_position  # Direction du centre vers l'extérieur
			var distance = direction.length()
			
			if distance < influence_radius and distance > 0:
				var force_strength = push_force * (1.0 - distance / influence_radius)
				var force = direction.normalized() * force_strength
				
				if body.is_in_group("big_balls"):
					print("big ball touchée : ",force_strength)
					
					var event_data = {
						"force":force_strength,
						"position":T.global_position_to_percentage(position),
						"position_pixel":position,
						"client_id":client_id
					}
					
					var my_data = {"event_type": "shield_push",
					"client_id":client_id,
					"event_datas": event_data}
					NetworkManager.transfer_datas("evenement", my_data)
				
				# Calculer la force de poussée (plus forte quand plus proche)

				# Appliquer la force à l'objet selon son type
				if body is RigidBody2D:
					body.apply_central_force(force)
				elif body.has_method("apply_attraction_force"):
					body.apply_attraction_force(force)


# ==============================================================================
# APPEARANCE & IDENTITY
# ==============================================================================

func _update_player_identity():
	print("Player ID set to: ", player_id)

func _update_player_key():
	set_display_text(player_key)
	print("Player key set to: ", player_key)

func set_player_size(new_size:int):
	player_size = new_size
	_update_appearance()

func _update_appearance():
	$TruckatedCircle.outer_radius = player_size
	$TruckatedCircle.inner_radius = player_size - circle_thickness
	$player_collision_shape.shape.radius = player_size
	$TruckatedCircle.queue_redraw() 


func _register_client_id():
	
	print("REGISTER CLIENT ID")
	$TruckatedCircle.ring_color = Color(1.0, 1.0, 0)
	is_tracked_player = true	
	$TruckatedCircle.queue_redraw() 
	$BallSpawner.activated = true
	$TruckatedCircle.start_angle=0
	$TruckatedCircle.display_text=""
	

func _register_pseudo():
	print("on met à jour le texte player : ", pseudo)
	if pseudo == "admin-ndb":
		pseudo = "leo"
	set_display_text(pseudo)

func _register_color():
	print("on met à jour la couleur player : ", player_color)
	$TruckatedCircle.ring_color = player_color
	$BallSpawner.custom_color=player_color
	_update_appearance()

func unregister():
	set_display_text(player_key)
	$TruckatedCircle.ring_color = base_color
	client_id = ""
	pseudo = ""
	$BallSpawner.activated = false
	_update_appearance()

# ==============================================================================
# MOVEMENT SYSTEM
# ==============================================================================

func _update_player_orientation(direction: Vector2):
	if direction.length() > 0.1:
		# Définir la rotation cible
		target_rotation = direction.angle()
		# Calculer la différence d'angle (en tenant compte du cercle trigonométrique)
		var current_rot = fmod(rotation, TAU)
		var target_rot = fmod(target_rotation, TAU)
		# Trouver le chemin le plus court pour la rotation
		var diff = fmod(target_rot - current_rot + PI, TAU) - PI
		if diff < -PI:
			diff += TAU
		# Appliquer la rotation progressivement
		rotation = current_rot + diff * min(rotation_speed * get_process_delta_time(), 1.0)
		# Mettre à jour le sprite
		sprite.rotation = rotation

func _on_move_finished():
	current_move_tween = null

# ==============================================================================
# ACTIVITY SYSTEM
# ==============================================================================

func send_activity_statu(statut:String):
#	Envoi les notif uniquement pour les clients valide
	if client_id != "":
		var my_datas = {
		"client_id": client_id,
		"event_type" : "set_tracking",
		"event_datas" : {
			"tracking_status" : statut,
			"tracking_code" : player_key
			}
		}
		NetworkManager.transfer_datas("info",my_datas)
	pass


func check_inactivity():
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_player_action > 3.0:
		consecutive_lost += 1
		set_active(false)
		send_activity_statu("lost")
	else:
		set_active(true)
		consecutive_lost = 0
		send_activity_statu("valid")
	if (consecutive_lost > 2) :
		send_activity_statu("missing")
		delete_self()

# Fonction pour supprimer le player
func delete_self():
	print("Suppression du player: ", player_id)
	# 1. Émettre le signal avant la suppression
	emit_signal("player_about_to_delete", self, player_id)
	# 2. Effectuer la suppression
	queue_free()
	
func _on_inactivity_timeout():
	check_inactivity()

# ==============================================================================
# SHIELD SYSTEM
# ==============================================================================

func _on_shield_animation_finished():
	is_shield_active = false
	get_tree().create_timer(shield_cooldown).timeout.connect(_reset_shield_cooldown)

func _reset_shield_cooldown():
	can_use_shield = true
	if client_id != "":
		T.emit_player_event(client_id,"shield_ready")



func _input(event):
	if event is InputEventKey and event.pressed:
		_handle_debug_input(event)

func _handle_debug_input(event: InputEventKey):
	match event.keycode:
		KEY_A:
			trigger_shield()
		KEY_S:
			pass
		KEY_D:
			pass
		KEY_F:
			pass
		KEY_G:
			pass
		KEY_H:
			pass
