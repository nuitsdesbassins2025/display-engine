# dessin.gd
extends Node2D

var last_trace_position: Vector2
var is_first_trace: bool = true
var trace_lines: Array = []

func _ready():
	# Fond noir
	var color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.anchor_right = 1
	color_rect.anchor_bottom = 1
	add_child(color_rect)
		# Attendre que le NetworkManager soit prêt
	call_deferred("connect_signal")

func connect_signal():
	if NetworkManager.has_signal("client_action_trigger"):
		NetworkManager.client_action_trigger.connect(_on_client_action_trigger)
		print("Signal connecté avec succès")

func _on_client_action_trigger(client_id:String, action: String, datas: Dictionary):
	
	print("client action in dessin scene")
	
	#Debug temporaire en attendant de transmettre la valeur
	datas.color = "4E0A3A"
	
	match action:

		"pailettes":
			handle_pailettes(datas)
		"touch_screen":
			handle_pailettes(datas)
			#handle_trace(datas)
		"clear":
			clear_traces()


func handle_pailettes(datas: Dictionary):
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
	
	# Créer un dégradé de couleur
	var base_color = Color(datas.color)
	var color_ramp = Gradient.new()
	color_ramp.add_point(0.0, base_color)
	color_ramp.add_point(1.0, base_color.darkened(0.4))
	process_material.color_ramp = color_ramp
	
	process_material.scale_min = 0.5  # Taille minimale
	process_material.scale_max = 0.8  # Taille maximale

	
	particles.process_material = process_material
	
	add_child(particles)
	
	particles.finished.connect(particles.queue_free)

func handle_trace(datas: Dictionary):
	
	print("handle_trace")
	var current_position = convert_percentage_to_screen(datas.x, datas.y)
	
	if is_first_trace:
		last_trace_position = current_position
		is_first_trace = false
		return
	datas.color = "4E0A3A"

	create_line(last_trace_position, current_position, datas.color)
	last_trace_position = current_position

func create_line(from: Vector2, to: Vector2, color_hex: String):
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2
	line.default_color = Color(color_hex)
	line.antialiased = true
	
	add_child(line)
	trace_lines.append(line)

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
