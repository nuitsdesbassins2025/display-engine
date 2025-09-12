extends Node2D

@export_range(0.0, 1000.0) var inner_radius: float = 30.0:
	set(value):
		inner_radius = value
		update_ring()

@export_range(0.0, 1000.0) var outer_radius: float = 50.0:
	set(value):
		outer_radius = value
		update_ring()
		
@export_range(0.0, 1000.0) var text_margin: float = 10.0:
	set(value):
		text_margin = value
		update_ring()		



@export_range(0.0, 360.0) var start_angle: float = 0.0:
	set(value):
		start_angle = value
		update_ring()

@export_range(0.0, 360.0) var end_angle: float = 270.0:
	set(value):
		end_angle = value
		update_ring()

@export_range(3, 128) var segments: int = 32:
	set(value):
		segments = value
		update_ring()

@export var ring_color: Color = Color(0.2, 0.6, 1.0, 1.0):
	set(value):
		ring_color = value
		if ring:
			ring.color = value

@export var background_color: Color = Color(0.1, 0.1, 0.2, 1.0):
	set(value):
		background_color = value
		if background_circle:
			background_circle.color = value

@export var display_text: String = "Text"

@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value


@export var font_size: int = 16:
	set(value):
		font_size = value
		update_text()

@export var text_follow_curve: bool = true
@export var text_spacing: float = 1.0


var text_container: Node2D



var ring: Polygon2D
var background_circle: Polygon2D
#var label: Label

func _ready():
	draw_shape()


func draw_shape():
	create_background_circle()
	create_ring()
	create_text_container()
	update_ring()
	update_text()

func create_background_circle():
	background_circle = Polygon2D.new()
	background_circle.color = background_color
	add_child(background_circle)

func create_ring():
	ring = Polygon2D.new()
	ring.color = ring_color
	add_child(ring)

func update_ring():
	if inner_radius >= outer_radius:
		push_warning("Inner radius must be smaller than outer radius")
		return
	if not background_circle or not ring:
		return
	# Mettre à jour le cercle de fond
	var bg_points = PackedVector2Array()
	for i in range(segments):
		var angle = 2 * PI * i / segments
		bg_points.append(Vector2(cos(angle), sin(angle)) * (outer_radius + text_margin))
	background_circle.polygon = bg_points
	
	# Mettre à jour l'anneau
	var ring_points = PackedVector2Array()
	var angle_range = deg_to_rad(end_angle - start_angle)
	
	# Points extérieurs (sens horaire)
	for i in range(segments + 1):
		var angle = deg_to_rad(start_angle) + (angle_range * i / segments)
		ring_points.append(Vector2(cos(angle), sin(angle)) * outer_radius)
	
	# Points intérieurs (sens anti-horaire)
	for i in range(segments, -1, -1):
		var angle = deg_to_rad(start_angle) + (angle_range * i / segments)
		ring_points.append(Vector2(cos(angle), sin(angle)) * inner_radius)
	
	ring.polygon = ring_points
	update_text()


func create_text_container():
	text_container = Node2D.new()
	add_child(text_container)

func update_text():
	
	
	
	if not text_container:
		return
	# Nettoyer les anciens caractères
	for child in text_container.get_children():
		child.queue_free()

#	display_text = $"..".player_key
	if display_text.is_empty():
		return
		

	if text_follow_curve:
		create_curved_text()
	else:
		create_centered_text()

func create_curved_text():
	var total_angle = deg_to_rad(end_angle - start_angle - 20 )
	var missing_angle = deg_to_rad(360.0 - (end_angle - start_angle))
	var char_angle = missing_angle / (display_text.length() * text_spacing)

	# Commencer au début de la zone manquante (après end_angle)
	var current_angle = deg_to_rad(end_angle + 10 )
	var text_radius = (inner_radius + outer_radius) / 2.0 + 22
	
	for i in range(display_text.length()):
		var char_label = Label.new()
		char_label.text = display_text[i]
		char_label.add_theme_font_size_override("font_size", font_size)
		char_label.modulate = text_color

		# Positionner le caractère dans la zone tronquée
		var char_pos = Vector2(cos(current_angle), sin(current_angle)) * text_radius
		char_label.position = char_pos

		# Rotation pour que le texte soit lisible (tangent à l'arc)
		char_label.rotation = current_angle + PI/2

		# Centrer le caractère
		char_label.pivot_offset = Vector2(0, -font_size * 0.3)  # Ajustement vertical

		text_container.add_child(char_label)
		current_angle += char_angle * text_spacing

		# Si on dépasse le cercle complet, on arrête
		if current_angle >= deg_to_rad(end_angle) + missing_angle:
			break

func create_centered_text():
	var label = Label.new()
	label.text = display_text
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = text_color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Positionner au centre de l'anneau
	label.position = Vector2(-inner_radius * 0.7, -font_size * 0.5)
	label.size = Vector2(inner_radius * 1.4, font_size * 1.5)

	text_container.add_child(label)

# Fonction utilitaire pour régler tout d'un coup
func set_ring_properties(inner: float, outer: float, start: float, end: float, 
						ring_col: Color = Color(0.2, 0.6, 1.0), 
						bg_col: Color = Color(0.1, 0.1, 0.2),
						text: String = "", text_col: Color = Color.WHITE,
						text_size: int = 16, follow_curve: bool = true,
						spacing: float = 1.0):
	inner_radius = inner
	outer_radius = outer
	start_angle = start
	end_angle = end
	ring_color = ring_col
	background_color = bg_col
	display_text = text
	text_color = text_col
	font_size = text_size
	text_follow_curve = follow_curve
	text_spacing = spacing
