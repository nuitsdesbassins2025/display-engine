extends CharacterBody2D
class_name NetworkPlayer

## Joueur avec support réseau
## - Gère le mouvement local et distant
## - Traite les actions avec compensation de latence
## - Gère les collisions

signal fired_bullet(position, direction)

@export var is_local_player := false
@export var move_speed := 300.0
@export var interpolation_speed := 5.0

var target_position := Vector2.ZERO
var last_direction := Vector2.RIGHT
var health := 100

# Références
@onready var sprite := $Sprite2D
@onready var gun := $GunPosition
@onready var animation_player := $AnimationPlayer

func _ready():
	if is_local_player:
		target_position = position
	
	# Connexion au NetworkManager
	NetworkManager.position_received.connect(_on_position_received)
	NetworkManager.action_received.connect(_on_action_received)

func _physics_process(delta):
	if is_local_player:
		process_local_input()
	else:
		process_network_movement(delta)
	
	update_visuals()

## Traitement de l'entrée locale
func process_local_input():
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * move_speed
	move_and_slide()
	
	if input_dir != Vector2.ZERO:
		last_direction = input_dir
		target_position = position
	
	# Envoi périodique de la position
	if Engine.get_frames_drawn() % 10 == 0:
		send_position_update()
	
	# Tir
	if Input.is_action_just_pressed("shoot"):
		perform_shoot(Time.get_ticks_msec())

## Mouvement pour les joueurs réseau
func process_network_movement(delta):
	if position.distance_to(target_position) > 5.0:
		var direction = position.direction_to(target_position)
		velocity = direction * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

## Mise à jour visuelle
func update_visuals():
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
	
	if velocity != Vector2.ZERO:
		animation_player.play("walk")
	else:
		animation_player.play("idle")

## Réception de position du serveur
func _on_position_received(player_id, new_position):
	if name == str(player_id) and not is_local_player:
		target_position = new_position

## Réception d'action du serveur
func _on_action_received(player_id, action, timestamp):
	if name == str(player_id):
		execute_historical_action(action, {}, timestamp)

## Exécution d'action avec compensation de latence
func execute_historical_action(action, params, action_time):
	match action:
		"shoot":
			var historical_pos = NetworkManager.get_historical_position(name, action_time)
			var historical_dir = params.get("direction", last_direction)
			spawn_bullet(historical_pos, historical_dir)
		
		"damage":
			var amount = params.get("amount", 0)
			take_damage(amount)

## Envoi de la position au serveur
func send_position_update():
	if is_local_player:
		NetworkManager.send_data({
			"type": "position_update",
			"x": position.x,
			"y": position.y,
			"timestamp": Time.get_ticks_msec()
		})

## Action de tir
func perform_shoot(timestamp):
	# Tir local immédiat
	spawn_bullet(gun.global_position, last_direction)
	
	# Envoi au serveur
	NetworkManager.send_data({
		"type": "player_action",
		"action": "shoot",
		"params": {
			"direction": last_direction,
			"timestamp": timestamp
		}
	})

## Création d'une balle
func spawn_bullet(spawn_pos, direction):
	var bullet = preload("res://entities/balle/balle.tscn").instantiate()
	bullet.initialize(spawn_pos, direction, self)
	get_parent().add_child(bullet)
	emit_signal("fired_bullet", spawn_pos, direction)

## Prise de dégâts
func take_damage(amount):
	health -= amount
	animation_player.play("hurt")
	
	if health <= 0:
		die()

## Mort du joueur
func die():
	set_process(false)
	set_physics_process(false)
	animation_player.play("die")
