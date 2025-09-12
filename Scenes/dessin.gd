# dessin.gd
extends Node2D

var last_trace_position: Vector2
var last_trace_timestamp: int = 0

var client_trace_data: Dictionary = {}  # {client_id: {position: Vector2, timestamp: int}}


const TRACE_TIMEOUT_MS: int = 700  # .7 seconde


var is_first_trace: bool = true
var trace_lines: Array = []

func _ready():
	
	# Fond noir
	#generate_background()
	# Attendre que le NetworkManager soit prêt
	call_deferred("connect_signal")
	
	
func generate_background():
	var container = Control.new()
	container.size = get_viewport().get_visible_rect().size
	add_child(container)

	# Ajouter le ColorRect comme enfant du container
	var color_rect = ColorRect.new()
	color_rect.color = "000"
	color_rect.anchor_left = 0
	color_rect.anchor_top = 0
	color_rect.anchor_right = 1
	color_rect.anchor_bottom = 1
	container.add_child(color_rect)

func connect_signal():
	if NetworkManager.has_signal("client_action_trigger"):
		NetworkManager.client_action_trigger.connect(_on_client_action_trigger)
		print("Signal connecté avec succès")

func _on_client_action_trigger(client_id:String, client_datas:Dictionary, action: String, datas: Dictionary):
	
	print("client action in dessin scene")
	
	#Debug temporaire en attendant de transmettre la valeur
	datas.color = "4E0A3A"
	
	match action:

		"pailettes":
			handle_pailettes(client_id, datas)
		"dessin_touch":
			handle_dessin(client_id, datas)
			#handle_pailettes(client_id, datas)
			#handle_trace(client_id, datas)
		"clear":
			clear_traces()

func handle_dessin(client_id: String, datas: Dictionary):
	var tool = datas.settings.tool
	
	match tool:
		"glitter":
			handle_pailettes(client_id, datas)
		"brush":
			handle_trace(client_id, datas)
			

func handle_pailettes(client_id: String, datas: Dictionary):
	var position = convert_percentage_to_screen(datas.x, datas.y)
	
	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.lifetime = 0.5
	particles.amount = 70
	
	var process_material = ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.spread = 60
	process_material.initial_velocity_min = 20
	process_material.initial_velocity_max = 50
	process_material.gravity = Vector3(0, 98, 0)
	
	# Convertir le code hexadécimal en couleur Godot
	var base_color = Color(datas.settings.color)
	var color_ramp = Gradient.new()
	color_ramp.add_point(0.0, base_color)
	color_ramp.add_point(1.0, base_color.darkened(0.4))
	process_material.color_ramp = color_ramp
	
	process_material.scale_min = 0.5  # Taille minimale
	process_material.scale_max = 0.8  # Taille maximale
	
	particles.process_material = process_material
	
	add_child(particles)
	
	particles.finished.connect(particles.queue_free)
	
func handle_trace(client_id: String, datas: Dictionary):
	print("handle_trace - client_id: ", client_id)
	var current_position = convert_percentage_to_screen(datas.x, datas.y)
	var current_time = Time.get_ticks_msec()
	
	# Initialiser ou récupérer les données du client
	if not client_trace_data.has(client_id) or datas.first:
		client_trace_data[client_id] = {
			"position": current_position,
			"timestamp": current_time
		}
		print("Premier trait pour le client: ", client_id)
		return
	
	var client_data = client_trace_data[client_id]
	var time_since_last = current_time - client_data.timestamp
	
	# Vérifier le délai (1 seconde)
	if time_since_last > 1000:
		print("Délai dépassé - nouveau trait pour: ", client_id)
		client_data.position = current_position
		client_data.timestamp = current_time
		return
	
	# Dessiner la ligne entre l'ancienne et la nouvelle position
	create_line(client_data.position, current_position, datas.settings.color, datas.settings.brushSize)
	
	# Mettre à jour les données
	client_data.position = current_position
	client_data.timestamp = current_time

func is_trace_timed_out(current_time: int) -> bool:
	return (current_time - last_trace_timestamp) > TRACE_TIMEOUT_MS

	

func create_line(from: Vector2, to: Vector2, color_hex: String, line_thickness:int = 2):
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = line_thickness
	line.default_color = Color(color_hex)
	line.antialiased = true
	
	add_child(line)
	trace_lines.append(line)
	
	# Animation de fondu
	var tween = create_tween()
	tween.tween_interval(2.0)  # Attendre 2 secondes
	tween.tween_property(line, "modulate:a", 0.0, 1.0)  # Fondu de 1 seconde
	tween.tween_callback(_remove_line.bind(line))

func _remove_line(line: Line2D):
	if is_instance_valid(line):
		line.queue_free()
	trace_lines.erase(line)
	
	


func convert_percentage_to_screen(x_percent: float, y_percent: float) -> Vector2:
	var viewport_size = get_viewport_rect().size
	return Vector2(
		(x_percent / 100.0) * viewport_size.x,
		(y_percent / 100.0) * viewport_size.y
	)

func clear_traces():
	for line in trace_lines:
		line.queue_free()
	trace_lines.clear()
	is_first_trace = true
