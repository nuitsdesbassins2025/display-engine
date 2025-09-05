extends Node2D
class_name SnakeTrail

## SIGNALS
signal snake_size_changed(new_size: int)

## EXPORTS
@export_category("Snake Trail")
@export var snake_size: float = 0.1:
	set(value):
		snake_size = clamp(value, 0.0, 1.0)
		_update_snake_trail()

@export var segment_spacing: float = 25.0
@export var max_snake_size: int = 20
@export var snake_segment_scene: PackedScene
@export var trail_color: Color = Color.WHITE:
	set(value):
		trail_color = value
		_update_trail_color()

## VARIABLES
var viewport_size: Vector2
var max_trail_length: float
var snake_segments: Array[Node2D] = []
var segment_positions: Array[Vector2] = []
var segment_rotations: Array[float] = []

func _ready():
	viewport_size = get_viewport().get_visible_rect().size
	max_trail_length = viewport_size.x * snake_size
	_clear_snake_trail()

func enable():
	visible = true
	process_mode = PROCESS_MODE_INHERIT

func disable():
	visible = false
	process_mode = PROCESS_MODE_DISABLED
	_clear_snake_trail()

func update_trail(player_position: Vector2, player_rotation: float):
	# Ajouter la position et rotation actuelles du joueur
	segment_positions.append(player_position)
	segment_rotations.append(player_rotation)
	
	# Maintenir la longueur de la traînée
	_maintain_trail_length()
	
	# Mettre à jour les segments visuels
	_update_snake_segments()

func _maintain_trail_length():
	if segment_positions.size() < 2:
		return
	
	# Calculer la longueur totale actuelle
	var total_length: float = 0.0
	for i in range(segment_positions.size() - 1):
		total_length += segment_positions[i].distance_to(segment_positions[i + 1])
	
	# Supprimer les segments les plus anciens si trop long
	while total_length > max_trail_length and segment_positions.size() > 2:
		var removed_length = segment_positions[0].distance_to(segment_positions[1])
		segment_positions.remove_at(0)
		segment_rotations.remove_at(0)
		total_length -= removed_length
	
	# Ajuster le nombre de segments visuels
	_adjust_segment_count()

func _adjust_segment_count():
	if segment_positions.size() < 2:
		_clear_snake_trail()
		return
	
	# Calculer le nombre de segments nécessaires basé sur la longueur totale
	var total_length: float = 0.0
	for i in range(segment_positions.size() - 1):
		total_length += segment_positions[i].distance_to(segment_positions[i + 1])
	
	var required_segments = ceil(total_length / segment_spacing)
	
	# Ajouter ou supprimer des segments
	if snake_segments.size() < required_segments:
		_add_missing_segments(required_segments - snake_segments.size())
	elif snake_segments.size() > required_segments:
		_remove_excess_segments(snake_segments.size() - required_segments)
	
	# Mettre à jour les positions des segments existants
	_update_snake_segments()

func _add_missing_segments(count: int):
	for i in range(count):
		var segment_index = snake_segments.size()
		var segment_pos = _calculate_segment_position(segment_index)
		var segment_rot = _calculate_segment_rotation(segment_index)
		
		_create_snake_segment(segment_pos, segment_rot, segment_index)

func _remove_excess_segments(count: int):
	for i in range(count):
		if snake_segments.size() > 0:
			# Enlever le segment le plus ancien (premier de la liste)
			var segment = snake_segments.pop_front()
			segment.queue_free()
			
			# Aussi enlever les données de position/rotation correspondantes
			if segment_positions.size() > 0:
				segment_positions.remove_at(0)
			if segment_rotations.size() > 0:
				segment_rotations.remove_at(0)

func _calculate_segment_position(segment_index: int):
	if segment_positions.size() < 2:
		return Vector2.ZERO
	
	var target_length = segment_index * segment_spacing
	var accumulated_length: float = 0.0
	
	for i in range(segment_positions.size() - 1):
		var segment_start = segment_positions[i]
		var segment_end = segment_positions[i + 1]
		var segment_length = segment_start.distance_to(segment_end)
		
		if accumulated_length + segment_length >= target_length:
			var t = (target_length - accumulated_length) / segment_length
			return segment_start.lerp(segment_end, t)
		
		accumulated_length += segment_length
	
	# Si on dépasse, retourner le dernier point
	return segment_positions[-1]

func _calculate_segment_rotation(segment_index: int):
	if segment_rotations.size() == 0:
		return 0.0
	
	# Pour un effet plus smooth, on pourrait interpoler entre les rotations
	# mais pour l'instant on prend la rotation du point correspondant
	var point_index = min(segment_index, segment_rotations.size() - 1)
	return segment_rotations[point_index]

func _update_snake_segments():
	for i in range(snake_segments.size()):
		var segment_pos = _calculate_segment_position(i)
		var segment_rot = _calculate_segment_rotation(i)
		
		snake_segments[i].global_position = segment_pos
		snake_segments[i].rotation = segment_rot
		
		# Mettre à jour la couleur
		var color_factor = float(i) / float(snake_segments.size())
		snake_segments[i].modulate = trail_color.darkened(color_factor * 0.5)

func _create_snake_segment(position: Vector2, rotation: float, index: int):
	if snake_segment_scene == null:
		return
	
	var segment = snake_segment_scene.instantiate()
	$".".add_child(segment)
	
	# CRITIQUE : Rendre le segment indépendant du parent
	segment.top_level = true
	segment.global_position = position
	segment.rotation = rotation
	
	var color_factor = float(index) / float(max_trail_length / segment_spacing)
	segment.modulate = trail_color.darkened(color_factor * 0.5)
	
	snake_segments.append(segment)

func _clear_snake_trail():
	for segment in snake_segments:
		segment.queue_free()
	snake_segments.clear()
	segment_positions.clear()
	segment_rotations.clear()

func _update_snake_trail():
	snake_size_changed.emit(snake_size)
	max_trail_length = viewport_size.x * snake_size
	_adjust_segment_count()

func _update_trail_color():
	for i in range(snake_segments.size()):
		var color_factor = float(i) / float(snake_segments.size())
		snake_segments[i].modulate = trail_color.darkened(color_factor * 0.5)

func clear():
	_clear_snake_trail()
