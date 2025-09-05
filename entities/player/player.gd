extends CharacterBody2D
class_name Player

## SIGNALS (simplifiés)
signal player_touche_objet(objet_nom)
signal player_dans_zone(zone_nom)
signal snake_mode_changed(active: bool)

## EXPORTS (simplifiés)
@export_category("Player Identity")
@export var player_id: int = -1:
	set(value):
		player_id = value
		_update_player_identity()

@export var player_key: String = "0000"

@export_category("Appearance")
@export var player_color: Color = Color.WHITE:
	set(value):
		player_color = value
		_update_appearance()

@export_category("Snake Mode")
@export var snake_mode: bool = true:
	set(value):
		snake_mode = value
		_update_snake_mode()

@export_category("Combat")
@export var max_health: int = 10
@export var max_ammo: int = 5
@export var shield_cooldown: float = 2.0

@export_category("Movement")
@export var move_speed: float = 400.0

## VARIABLES
var gd_id: String = ""
var client_id: String = ""
var tracking_id: String = ""

var is_tracked_player: bool = false
var is_active: bool = true
var health: int = max_health
var ammo: int = max_ammo

var is_shield_active: bool = false
var can_use_shield: bool = true

var inactivity_timer: Timer
var last_position_update: float = 0.0
var current_move_tween: Tween = null

var actions_map: Dictionary = {}
var viewport_size: Vector2

## REFERENCES
@onready var collision_shape: CollisionShape2D = $player_collision_shape
@onready var sprite: Polygon2D = $player_skin
@onready var shield: Polygon2D = $Shield/shield
@onready var snake_trail: SnakeTrail = $SnakeTrail

#region INITIALIZATION
func _ready():
	viewport_size = get_viewport().get_visible_rect().size
	
	_setup_player()
	_setup_inactivity_timer()
	_setup_actions_map()
	_initialize_snake_mode()

func _setup_player():
	health = max_health
	ammo = max_ammo
	_update_appearance()

func _setup_inactivity_timer():
	inactivity_timer = Timer.new()
	add_child(inactivity_timer)
	inactivity_timer.wait_time = 10.0
	inactivity_timer.one_shot = false
	inactivity_timer.timeout.connect(_on_inactivity_timeout)
	inactivity_timer.start()

func _setup_actions_map():
	actions_map = {
		"shoot": _do_shoot,
		"reload": _do_reload,
		"heal": _do_heal,
		"move": _do_move
	}
#endregion

#region SNAKE MODE (délégué à SnakeTrail)
func _initialize_snake_mode():
	if snake_trail:
		snake_trail.trail_color = player_color
		snake_trail.snake_size = 0.1

func _update_snake_mode():
	snake_mode_changed.emit(snake_mode)
	
	if snake_trail:
		if snake_mode:
			snake_trail.enable()
		else:
			snake_trail.disable()

func agrandir_queue(value):
	if snake_trail:
		snake_trail.snake_size = min(snake_trail.snake_size + value, 1.0)
#endregion

#region PLAYER IDENTITY & APPEARANCE
func _update_player_identity():
	print("Player ID set to: ", player_id)

func _update_appearance():
	if sprite:
		sprite.modulate = player_color
	
	if snake_trail:
		snake_trail.trail_color = player_color
#endregion

#region MOVEMENT SYSTEM
func move_to_position(target_position: Vector2):
	var actual_position = Vector2(
		target_position.x / 100.0 * viewport_size.x,
		target_position.y / 100.0 * viewport_size.y
	)

	last_position_update = Time.get_unix_time_from_system()
	
	if not is_active:
		set_active(true)
	
	var direction = (actual_position - global_position).normalized()
	_update_player_orientation(direction)

	#if global_position.distance_to(actual_position) < 10.0:
		#global_position = actual_position
		#if snake_mode and snake_trail:
			#snake_trail.update_trail(global_position)
		#return

	if current_move_tween:
		current_move_tween.kill()

	current_move_tween = create_tween()
	var distance = global_position.distance_to(actual_position)
	var duration = clamp(distance / move_speed, 0.05, 0.3)
	
	if snake_mode and snake_trail:
		current_move_tween.tween_method(_update_position_with_trail, global_position, actual_position, duration)
	else:
		current_move_tween.tween_property(self, "global_position", actual_position, duration)
	
	current_move_tween.finished.connect(_on_move_finished)

func _update_position_with_trail(new_position: Vector2):
	global_position = new_position
	if snake_trail:
		snake_trail.update_trail(new_position, rotation)



func _update_player_orientation(direction: Vector2):
	if direction.length() > 0.1:
		rotation = direction.angle()
		sprite.rotation = rotation
		# Mettre à jour la traînée avec la nouvelle rotation
		if snake_mode and snake_trail:
			snake_trail.update_trail(global_position, rotation)

func _on_move_finished():
	current_move_tween = null
	if snake_mode and snake_trail:
		snake_trail.update_trail(global_position, rotation)

#endregion

#region ACTIVITY SYSTEM
func set_active(active: bool):
	is_active = active
	visible = active
	set_physics_process(active)

func check_inactivity():
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_position_update > 10.0:
		is_active = false
		visible = false
	else:
		is_active = true
		visible = true

func _on_inactivity_timeout():
	check_inactivity()
#endregion

#region SHIELD SYSTEM (inchangé)
func trigger_shield():
	if not can_use_shield:
		return
	
	is_shield_active = true
	can_use_shield = false
	
	var collision_shape = $Shield/shield_collision
	var shield_visual = $Shield/shield
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(collision_shape, "scale", Vector2(3.0, 3.0), 0.3)
	tween.tween_property(shield_visual, "scale", Vector2(3.0, 3.0), 0.3)
	tween.tween_property(collision_shape, "scale", Vector2(1.0, 1.0), 0.7).set_delay(0.3)
	tween.tween_property(shield_visual, "scale", Vector2(1.0, 1.0), 0.7).set_delay(0.3)
	
	tween.tween_callback(_on_shield_animation_finished).set_delay(1.0)

func _on_shield_animation_finished():
	is_shield_active = false
	get_tree().create_timer(shield_cooldown).timeout.connect(_reset_shield_cooldown)

func _reset_shield_cooldown():
	can_use_shield = true
#endregion

#region TRACKING SYSTEM (inchangé)
func sync_tracking_client(track_id: String, cl_id: String, pos: Vector2):
	tracking_id = track_id
	client_id = cl_id
	is_tracked_player = tracking_id != "" and client_id != ""
	
	if pos != Vector2.ZERO:
		move_to_position(pos)
#endregion

#region ACTIONS SYSTEM (inchangé)
func _do_shoot(data: Dictionary):
	if ammo > 0:
		ammo -= 1

func _do_reload(data: Dictionary):
	ammo = max_ammo

func _do_heal(data: Dictionary):
	health = min(health + data.get("amount", 1), max_health)

func _do_move(data: Dictionary):
	pass
#endregion

#region PROCESS FUNCTIONS
func _input(event):
	if event is InputEventKey and event.pressed:
		_handle_debug_input(event)

func _handle_debug_input(event: InputEventKey):
	match event.keycode:
		KEY_A:
			trigger_shield()
		KEY_S:
			snake_mode = not snake_mode
		KEY_D:
			agrandir_queue(0.1)
		KEY_F:
			if snake_trail:
				snake_trail.snake_size = max(snake_trail.snake_size - 0.1, 0.0)
		KEY_G:
			if snake_trail:
				snake_trail.segment_spacing = clamp(snake_trail.segment_spacing + 1, 2, 20)
		KEY_H:
			if snake_trail:
				snake_trail.segment_spacing = clamp(snake_trail.segment_spacing - 1, 2, 20)
#endregion
