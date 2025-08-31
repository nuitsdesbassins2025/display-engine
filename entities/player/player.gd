extends CharacterBody2D
class_name Player

## SIGNALS
signal player_touche_objet(objet_nom)
signal player_dans_zone(zone_nom)
signal snake_mode_changed(active: bool)
signal snake_size_changed(new_size: int)

## EXPORTS
@export_category("Player Identity")
@export var player_id: int = -1:
	set(value):
		player_id = value
		_update_player_identity()

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
@export var snake_size: float = 0.1:  # Taille en pourcentage de l'écran (0.0 - 1.0)
	set(value):
		snake_size = clamp(value, 0.0, 1.0)
		_update_snake_trail()
@export var segment_spacing: float = 25.0  # Distance entre les segments en pixels
@export var max_snake_size: int = 20
@export var snake_segment_scene: PackedScene

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
var previous_positions: Array[Vector2] = []
var snake_segments: Array[Node2D] = []

var actions_map: Dictionary = {}

var path_points: Array[Vector2] = []  # Points du tracé
var segment_orientations: Array[float] = []  # Orientations des segments
var viewport_size: Vector2
var max_trail_length: float  # Longueur max en pixels



## REFERENCES
@onready var collision_shape: CollisionShape2D = $player_collision_shape
@onready var sprite: Polygon2D = $player_skin
@onready var shield: Polygon2D = $Shield/shield
@onready var line_renderer: Line2D = $Line2D  # Optionnel pour visualiser le tracé

#region INITIALIZATION
func _ready():
	viewport_size = get_viewport().get_visible_rect().size
	max_trail_length = viewport_size.x * snake_size  # Longueur max en pixels

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

#region SNAKE MODE SYSTEM COMPLÈTEMENT REFONDU
func _initialize_snake_mode():
	if snake_mode:
		_clear_snake_trail()
		path_points.clear()
		segment_orientations.clear()

func _update_snake_mode():
	snake_mode_changed.emit(snake_mode)
	
	if snake_mode:
		_clear_snake_trail()
		path_points.clear()
		segment_orientations.clear()
	else:
		_clear_snake_trail()

func _update_snake_trail():
	snake_size_changed.emit(snake_size)
	max_trail_length = viewport_size.x * snake_size
	_recalculate_snake_segments()

func _update_player_orientation(direction: Vector2):
	if direction.length() > 0.1:
		rotation = direction.angle()
		sprite.rotation = rotation

func _add_path_point(position: Vector2):
	# Ajouter le point au tracé
	path_points.append(position)
	
	# Calculer l'orientation si on a au moins 2 points
	if path_points.size() >= 2:
		var direction = (path_points[-1] - path_points[-2]).normalized()
		segment_orientations.append(direction.angle())
	
	# Maintenir la longueur totale du tracé
	_maintain_trail_length()

func _maintain_trail_length():
	if path_points.size() < 2:
		return
	
	# Calculer la longueur totale actuelle
	var total_length: float = 0.0
	for i in range(path_points.size() - 1):
		total_length += path_points[i].distance_to(path_points[i + 1])
	
	# Supprimer les points les plus anciens si trop long
	while total_length > max_trail_length and path_points.size() > 2:
		var removed_length = path_points[0].distance_to(path_points[1])
		path_points.remove_at(0)
		if segment_orientations.size() > 0:
			segment_orientations.remove_at(0)
		total_length -= removed_length
	
	_recalculate_snake_segments()

func _recalculate_snake_segments():
	if not snake_mode or path_points.size() < 2:
		return
	
	# Supprimer les anciens segments
	_clear_snake_trail()
	
	# Calculer les positions et orientations des nouveaux segments
	var accumulated_length: float = 0.0
	var segment_index: int = 0
	
	for i in range(path_points.size() - 1):
		var segment_start = path_points[i]
		var segment_end = path_points[i + 1]
		var segment_length = segment_start.distance_to(segment_end)
		var segment_direction = (segment_end - segment_start).normalized()
		
		# Placer des segments le long de ce segment du tracé
		while accumulated_length < segment_length and segment_index * segment_spacing < max_trail_length:
			var t = accumulated_length / segment_length
			var segment_pos = segment_start.lerp(segment_end, t)
			var segment_rot = segment_direction.angle()
			
			_create_snake_segment(segment_pos, segment_rot, segment_index)
			
			accumulated_length += segment_spacing
			segment_index += 1
		
		accumulated_length -= segment_length

func _create_snake_segment(position: Vector2, rotation: float, index: int):
	if snake_segment_scene == null:
		return
	
	var segment = snake_segment_scene.instantiate()
	get_parent().add_child(segment)  # Ajouter au parent pour éviter les problèmes de transformation
	
	segment.global_position = position
	segment.rotation = rotation
	
	# Couleur en dégradé
	var color_factor = float(index) / float(max_trail_length / segment_spacing)
	segment.modulate = player_color.darkened(color_factor * 0.5)
	
	snake_segments.append(segment)

func _clear_snake_trail():
	for segment in snake_segments:
		segment.queue_free()
	snake_segments.clear()
#endregion


#region PLAYER IDENTITY & APPEARANCE
func _update_player_identity():
	print("Player ID set to: ", player_id)

func _update_appearance():

	# Mettre à jour aussi la couleur des segments de serpent
	for segment in snake_segments:
		var index = snake_segments.find(segment)
		segment.modulate = player_color.darkened(0.2 * (index + 1))
		
	if sprite:
		sprite.modulate = player_color
	
#endregion

#region MOVEMENT SYSTEM MODIFIÉ
func move_to_position(target_position: Vector2):
	var actual_position = Vector2(
		target_position.x / 100.0 * viewport_size.x,
		target_position.y / 100.0 * viewport_size.y
	)

	last_position_update = Time.get_unix_time_from_system()
	
	if not is_active:
		set_active(true)
	
	# Calculer la direction du mouvement
	var direction = (actual_position - global_position).normalized()
	_update_player_orientation(direction)

	# Téléportation si très proche
	if global_position.distance_to(actual_position) < 10.0:
		global_position = actual_position
		if snake_mode:
			_add_path_point(global_position)
		return

	# Arrêter l'animation précédente
	if current_move_tween:
		current_move_tween.kill()

	# Créer une nouvelle animation
	current_move_tween = create_tween()
	var distance = global_position.distance_to(actual_position)
	var duration = clamp(distance / move_speed, 0.05, 0.3)
	
	# Ajouter des points intermédiaires pour le tracé serpent
	if snake_mode:
		current_move_tween.tween_method(_update_position_with_trail, global_position, actual_position, duration)
	else:
		current_move_tween.tween_property(self, "global_position", actual_position, duration)
	
	current_move_tween.finished.connect(_on_move_finished)

func _update_position_with_trail(new_position: Vector2):
	global_position = new_position
	_add_path_point(new_position)

func _on_move_finished():
	current_move_tween = null
	if snake_mode:
		_add_path_point(global_position)
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

#region SHIELD SYSTEM
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

#region TRACKING SYSTEM
func sync_tracking_client(track_id: String, cl_id: String, pos: Vector2):
	tracking_id = track_id
	client_id = cl_id
	is_tracked_player = tracking_id != "" and client_id != ""
	
	if pos != Vector2.ZERO:
		move_to_position(pos)
#endregion

#region ACTIONS SYSTEM
func _do_shoot(data: Dictionary):
	if ammo > 0:
		ammo -= 1

func _do_reload(data: Dictionary):
	ammo = max_ammo

func _do_heal(data: Dictionary):
	health = min(health + data.get("amount", 1), max_health)

func agrandir_queue(value):
	snake_size = min(snake_size + 0.1, 1.0)
	pass

func _do_move(data: Dictionary):
	pass
#endregion

#region PROCESS FUNCTIONS
func _process(delta):
	pass

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
			# Augmenter taille serpent (10% par pression)
			snake_size = min(snake_size + 0.1, 1.0)
		KEY_F:
			# Réduire taille serpent (10% par pression)
			snake_size = max(snake_size - 0.1, 0.0)
		KEY_G:
			# Ajuster l'espacement des segments
			segment_spacing = clamp(segment_spacing + 1, 2, 20)
			_recalculate_snake_segments()
		KEY_H:
			segment_spacing = clamp(segment_spacing - 1, 2, 20)
			_recalculate_snake_segments()

#endregion
