# dessin.gd
extends Node2D

# Configuration
const TRACE_TIMEOUT_MS: int = 700  # .7 seconde
const SEGMENT_FADE_DELAY: float = 2.0  # Attente avant le fondu d'un segment
const SEGMENT_FADE_DURATION: float = 1.0  # Durée du fondu d'un segment
const GLOW_LAYERS: int = 4  # Nombre de couches de glow
const FADE_CHECK_INTERVAL: float = 0.1  # Vérifier toutes les 100ms

# Données des clients
var client_trace_data: Dictionary = {}  # {client_id: {main_line: Line2D, glow_lines: Array, segment_timestamps: Array}}
var fade_check_timer: Timer

func _ready():
	# Créer le timer pour vérifier les segments à effacer
	fade_check_timer = Timer.new()
	fade_check_timer.wait_time = FADE_CHECK_INTERVAL
	fade_check_timer.timeout.connect(_on_fade_check_timeout)
	add_child(fade_check_timer)
	fade_check_timer.start()
	
	# Attendre que le NetworkManager soit prêt
	call_deferred("connect_signal")

func _on_fade_check_timeout():
	# Vérifier tous les segments de toutes les lignes en continu
	var current_time = Time.get_ticks_msec()
	
	for client_id in client_trace_data.keys():
		check_fading_segments(client_id, current_time)

func connect_signal():
	if NetworkManager.has_signal("client_action_trigger"):
		NetworkManager.client_action_trigger.connect(_on_client_action_trigger)
		print("Signal connecté avec succès")

func _on_client_action_trigger(client_id: String, client_datas: Dictionary, action: String, datas: Dictionary):
	# Debug temporaire en attendant de transmettre la valeur
	datas.color = "4E0A3A"
	
	match action:
		"pailettes":
			handle_pailettes(client_id, datas)
		"dessin_touch":
			handle_dessin(client_id, datas)
		"clear":
			clear_traces()
		"touch_end":  # Nouvel action pour détecter la fin du toucher
			handle_touch_end(client_id)

func handle_dessin(client_id: String, datas: Dictionary):
	var tool = datas.settings.tool
	
	match tool:
		"ball":
			handle_pailettes(client_id, datas)
		"pencil":
			handle_trace(client_id, datas)
		"neon":
			handle_trace(client_id, datas, true)
			
func handle_touch_end(client_id: String):
	# Terminer la ligne quand l'utilisateur relève le doigt
	if client_trace_data.has(client_id):
		complete_line(client_id)

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
	
	process_material.scale_min = 0.5
	process_material.scale_max = 0.8
	
	particles.process_material = process_material
	add_child(particles)
	
	particles.finished.connect(particles.queue_free)

func handle_trace(client_id: String, datas: Dictionary, neon: bool = false):
	var current_position = convert_percentage_to_screen(datas.x, datas.y)
	var current_time = Time.get_ticks_msec()
	
	# Initialiser ou récupérer les données du client
	if not client_trace_data.has(client_id) or datas.get("first", false):
		start_new_line(client_id, current_position, current_time, datas.settings.color, neon)
		return
	
	var client_data = client_trace_data[client_id]
	var time_since_last = current_time - client_data.segment_timestamps[-1] if client_data.segment_timestamps.size() > 0 else 1000
	
	# Vérifier le délai (1 seconde)
	if time_since_last > 1000:
		complete_line(client_id)  # Terminer l'ancienne ligne
		start_new_line(client_id, current_position, current_time, datas.settings.color, neon)  # Commencer une nouvelle
		return
	
	# Ajouter le point à la ligne existante
	if client_data.main_line :
		add_point_to_line(client_id, current_position, current_time)

func start_new_line(client_id: String, position: Vector2, timestamp: int, color_hex: String, neon: bool):
	# Créer une nouvelle ligne continue avec effet néon
	var main_line = Line2D.new()
	main_line.width = 5
	main_line.default_color = Color(color_hex)
	main_line.antialiased = true
	main_line.z_index = 11
	main_line.add_point(position)
	main_line.add_to_group("drawings")
	
	var glow_lines = []
	if neon :
		# Créer les couches de glow
		for i in range(GLOW_LAYERS):
			var glow_line = Line2D.new()
			glow_line.width = 5 + 30 * (1.0 - float(i) / GLOW_LAYERS)
			glow_line.default_color = Color(color_hex)
			glow_line.default_color.a = 0.15 * (1.0 - float(i) / GLOW_LAYERS)
			glow_line.antialiased = true
			glow_line.z_index = 10 - i
			glow_line.add_point(position)
			
			add_child(glow_line)
			glow_lines.append(glow_line)
	
	add_child(main_line)
	
	# Stocker les données
	client_trace_data[client_id] = {
		"main_line": main_line,
		"glow_lines": glow_lines,
		"color": color_hex,
		"segment_timestamps": [timestamp]  # Stocker les timestamps de chaque point
	}

func add_point_to_line(client_id: String, position: Vector2, timestamp: int):
	var client_data = client_trace_data[client_id]
	
	# Ajouter le point à la ligne principale
	client_data.main_line.add_point(position)
	
	# Ajouter le point à toutes les lignes de glow
	for glow_line in client_data.glow_lines:
		glow_line.add_point(position)
	
	# Ajouter le timestamp du nouveau point
	client_data.segment_timestamps.append(timestamp)

func check_fading_segments(client_id: String, current_time: int):
	var client_data = client_trace_data[client_id]
	if client_data.segment_timestamps.is_empty():
		return
	
	var points_to_remove = 0
	
	if not client_data.main_line :
		return
	
	# Compter combien de points doivent disparaître (âgés de plus de 2 secondes)
	for i in range(client_data.segment_timestamps.size()):
		if current_time - client_data.segment_timestamps[i] > SEGMENT_FADE_DELAY * 1000:
			points_to_remove = i + 1
		else:
			break
	
	if points_to_remove > 0 and client_data.main_line.get_point_count() > points_to_remove:
		# Créer une copie des segments à faire disparaître
		fade_segments(client_data.main_line, client_data.glow_lines, points_to_remove)
		
		# Supprimer les points des lignes principales
		for i in range(points_to_remove):
			if client_data.main_line.get_point_count() > 1:
				client_data.main_line.remove_point(0)
			for glow_line in client_data.glow_lines:
				if glow_line.get_point_count() > 1:
					glow_line.remove_point(0)
		
		# Supprimer les timestamps correspondants
		client_data.segment_timestamps = client_data.segment_timestamps.slice(points_to_remove)
		
		# Si la ligne n'a plus de points, la supprimer complètement
		if client_data.main_line.get_point_count() == 0:
			complete_line(client_id)

func fade_segments(main_line: Line2D, glow_lines: Array, points_to_keep: int):
	# Créer des copies des segments à faire disparaître
	if main_line.get_point_count() <= points_to_keep:
		return
	
	# Créer une copie de la ligne principale pour les segments à faire disparaître
	var fade_main_line = Line2D.new()
	fade_main_line.width = main_line.width
	fade_main_line.default_color = main_line.default_color
	fade_main_line.antialiased = true
	fade_main_line.z_index = main_line.z_index - 1
	
	# Ajouter les points à faire disparaître
	for i in range(main_line.get_point_count() - points_to_keep):
		fade_main_line.add_point(main_line.get_point_position(i))
	
	add_child(fade_main_line)
	
	# Créer des copies des lignes de glow
	var fade_glow_lines = []
	for original_glow in glow_lines:
		var fade_glow_line = Line2D.new()
		fade_glow_line.width = original_glow.width
		fade_glow_line.default_color = original_glow.default_color
		fade_glow_line.antialiased = true
		fade_glow_line.z_index = original_glow.z_index - 1
		
		# Ajouter les points à faire disparaître
		for i in range(original_glow.get_point_count() - points_to_keep):
			fade_glow_line.add_point(original_glow.get_point_position(i))
		
		add_child(fade_glow_line)
		fade_glow_lines.append(fade_glow_line)
	
	# Animer la disparition des copies
	var tween_main = create_tween()
	tween_main.tween_property(fade_main_line, "modulate:a", 0.0, SEGMENT_FADE_DURATION)
	tween_main.tween_callback(fade_main_line.queue_free)
	
	for fade_glow_line in fade_glow_lines:
		var tween_glow = create_tween()
		tween_glow.tween_property(fade_glow_line, "modulate:a", 0.0, SEGMENT_FADE_DURATION)
		tween_glow.tween_callback(fade_glow_line.queue_free)

func complete_line(client_id: String):
	if not client_trace_data.has(client_id):
		return
	
	var client_data = client_trace_data[client_id]
	
	if not client_data.main_line :
		return
	
	# Faire disparaître tous les segments restants
	if client_data.main_line.get_point_count() > 0:
		# Créer des copies pour l'animation de fondu final
		var fade_main_line = Line2D.new()
		fade_main_line.width = client_data.main_line.width
		fade_main_line.default_color = client_data.main_line.default_color
		fade_main_line.antialiased = true
		fade_main_line.z_index = client_data.main_line.z_index - 1
		
		for i in range(client_data.main_line.get_point_count()):
			fade_main_line.add_point(client_data.main_line.get_point_position(i))
		
		add_child(fade_main_line)
		
		var fade_glow_lines = []
		for original_glow in client_data.glow_lines:
			var fade_glow_line = Line2D.new()
			fade_glow_line.width = original_glow.width
			fade_glow_line.default_color = original_glow.default_color
			fade_glow_line.antialiased = true
			fade_glow_line.z_index = original_glow.z_index - 1
			
			for i in range(original_glow.get_point_count()):
				fade_glow_line.add_point(original_glow.get_point_position(i))
			
			add_child(fade_glow_line)
			fade_glow_lines.append(fade_glow_line)
		
		# Animer la disparition
		var tween_main = create_tween()
		tween_main.tween_property(fade_main_line, "modulate:a", 0.0, SEGMENT_FADE_DURATION)
		tween_main.tween_callback(fade_main_line.queue_free)
		
		for fade_glow_line in fade_glow_lines:
			var tween_glow = create_tween()
			tween_glow.tween_property(fade_glow_line, "modulate:a", 0.0, SEGMENT_FADE_DURATION)
			tween_glow.tween_callback(fade_glow_line.queue_free)
	
	# Supprimer les lignes principales
	client_data.main_line.queue_free()
	for glow_line in client_data.glow_lines:
		glow_line.queue_free()
	
	# Retirer des données actives
	client_trace_data.erase(client_id)

func convert_percentage_to_screen(x_percent: float, y_percent: float) -> Vector2:
	var viewport_size = get_viewport_rect().size
	return Vector2(
		(x_percent / 100.0) * viewport_size.x,
		(y_percent / 100.0) * viewport_size.y
	)

func clear_traces():
	# Supprimer toutes les lignes actives
	for client_id in client_trace_data.keys():
		complete_line(client_id)
	
	# Nettoyer les segments en cours de fade
	for child in get_children():
		if child is Line2D:
			child.queue_free()
