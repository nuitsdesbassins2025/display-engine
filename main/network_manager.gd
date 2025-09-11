extends Node

# A mettre en true si on veuc afficher le débug de TOUTES les actions
var debbug_datas = true

## Gestion principale du réseau et de la compensation de latence
## - Communication WebSocket
## - Interpolation des positions
## - Buffer des actions
## - Calcul des états historiques

signal player_connected(player_id)
signal player_disconnected(player_id)
signal position_received(player_id, position)
signal action_received(player_id, action, timestamp)
signal client_action_trigger(client_id: String, client_datas:Dictionary, action: String, datas: Dictionary)

signal move_player(player_id, target_position)

# Configuration
var websocket_url = "http://localhost:5000"
var update_interval = 200 # ms entre chaque mise à jour
var average_latency = 300 # ms de latence estimée

# Données des joueurs
var players = {} # {player_id: {node: Node2D, data: {}}}
var interpolation_buffers = {} # {player_id: [{position: Vector2, timestamp: int}]}
var action_buffers = {} # {player_id: [{action: String, params: {}, timestamp: int}]}
var websocket = WebSocketPeer.new()


var is_networked_game = true
var client: SocketIO


## Variables pour le debug
#var debug_timer: Timer
#var is_debug_active: bool = true


func _ready():
	client = SocketIO.new()
	add_child(client)
	client.base_url = websocket_url
	client.socket_connected.connect(_on_socket_connected)
	client.event_received.connect(_on_event_received)
	client.connect_socket()
	#
	#setup_debug_timer()
#
#
#
#func setup_debug_timer():
		## Crée le timer pour le debug
	#debug_timer = Timer.new()
	#debug_timer.wait_time = 1.0  # 1 seconde
	#debug_timer.one_shot = false
	#debug_timer.timeout.connect(_on_debug_timer_timeout)
	#add_child(debug_timer)
#
	## Démarre automatiquement le debug (optionnel)
	#start_debug_mode()
	#
	## Fonction pour démarrer le mode debug
	#
#func start_debug_mode():
	#if not is_debug_active:
		#is_debug_active = true
		#debug_timer.start()
		#print("Debug mode STARTED - Sending random signals every second")
#
## Fonction pour arrêter le mode debug
#func stop_debug_mode():
	#if is_debug_active:
		#is_debug_active = false
		#debug_timer.stop()
		#print("Debug mode STOPPED")
#
## Fonction appelée à chaque tick du timer
#func _on_debug_timer_timeout():
	#if is_debug_active:
		#_send_random_move_signal()
		#
## Fonction pour envoyer un signal aléatoire
#func _send_random_move_signal():
	#var random_id = randi() % 5 + 1  # IDs de 1 à 5
	#var random_x = randf() * 1000.0  # X entre 0 et 1000
	#var random_y = randf() * 600.0   # Y entre 0 et 600
	#
	#var random_position = Vector2(random_x, random_y)
#
	#emit_move_player_signal(random_id, random_position)

# Fonction pour émettre le signal (publique)
func emit_move_player_signal(id: int, target_position: Vector2):
	move_player.emit(id, target_position)
	print("DEBUG - Signal emitted: move_player(", id, ", ", target_position,")")

# Fonction pour tester manuellement (utile pour le debug)
func test_specific_move(id: int, target_position: Vector2):
	emit_move_player_signal(id, target_position)


	
		
func _on_socket_connected(_namespace) -> void:
	client.emit("get_user_data", { "id": "id-godot" })
	print("Connecté, envoi get_user_data")

func _on_event_received(event: String, data: Variant, ns: String) -> void:
	
	if debbug_datas == true:
		print("Event DEBUG : ", event, " datas : ", data)
	
	if event == "user_data":
		# OK, tu es identifié
		pass
	#if event == "action_triggered_by":
		#pass
		#print("Action déclenchée par serveur local 👍 :", data)
		# fais ton traitement
		
	if event == "tracking_datas":
		print("tracking data recues")
		handle_tracking_datas(data[0][0])
		
			
	if event == "client_action_trigger":
		print("Action déclenchée par serveur local 👍 :", data)
		data = data[0]
		print(data)
		
		#A Remplacer par client_datas
		var client_id = data.client_id
		
		var client_datas = data.client_datas
		var action = data.action
		var action_datas = data.datas
		
		var player_key = client_datas.player_id
		
		if action == "client_move":
			print(data)
			var datas_tacking = {
				"tracking_fps": 9.84983032936065,
				"tracking_datas": [
					{
					"tracking_id": client_datas.player_id, 
					"related_client_id": client_id, 
					"posX": action_datas.x, 
					"posY": action_datas.y, 
					"state": "lost",
					 "lost_frame": 164.0, 
					"zone": "game" }
					]
				}
			handle_tracking_datas(datas_tacking)
		else :
			client_action_trigger.emit(client_id, client_datas, action, action_datas)
			#emit_signal("player_action", )
		
		
		
	if event == "request_new_player":
		print("new player requested :", data)
		pass
	
		
	if event == "admin_game_setting":
		
		if data[0].action == "set_scene":
			print("changmeent de scene demandé")
			
			if data[0].value =="dogeball":
				print("on change de scene en dogeball")
				get_tree().change_scene_to_file("res://Scenes/dogeball.tscn")
			else :
				print("scene non configurée")

		
		
		
	

func _process(delta):
	pass
#	process_websocket()
	#process_interpolation()
	#process_actions()

## Initialisation de la connexion WebSocket
func setup_websocket():
	websocket.connect_to_url(websocket_url)
	print("Tentative de connexion WebSocket...")

## Traitement des messages WebSocket
func process_websocket():
	websocket.poll()
	var state = websocket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		while websocket.get_available_packet_count() > 0:
			var packet = websocket.get_packet()
			
			handle_data(packet.get_string_from_utf8())
	
	elif state == WebSocketPeer.STATE_CLOSED:
		print("Connexion fermée. Code: ", websocket.get_close_code(), " Raison: ", websocket.get_close_reason())

## Traitement des données reçues
func handle_data(json_data):
	var data = JSON.parse_string(json_data)
	
	#print(data)
	#match data.type:
		#"tracking_datas":
		#	handle_tracking_datas(data)
			#handle_player_connect(data)
		#"player_disconnect":
			#handle_player_disconnect(data)
		#"position_update":
			#handle_position_update(data)
		#"player_action":
			#handle_player_action(data)

func handle_tracking_datas(data):
	var tracking_datas = data.get('tracking_datas', [])
	for track_data in tracking_datas:
		var tracking_position : Vector2 = Vector2(track_data['posX'], track_data['posY'])
		var tracking_id : String = str(track_data['tracking_id'])
		emit_signal("move_player", tracking_id, tracking_position)



## Gestion de la connexion d'un joueur
func handle_player_connect(data):
	var player_id = data.player_id
	players[player_id] = {node = null, data = {}}
	interpolation_buffers[player_id] = []
	action_buffers[player_id] = []
	emit_signal("player_connected", player_id)

## Gestion de la déconnexion d'un joueur
func handle_player_disconnect(data):
	var player_id = data.player_id
	players.erase(player_id)
	interpolation_buffers.erase(player_id)
	action_buffers.erase(player_id)
	emit_signal("player_disconnected", player_id)

## Traitement des mises à jour de position
func handle_position_update(data):
	var player_id = data.player_id
	var position = Vector2(data.x, data.y)
	
	var timestamp = Time.get_ticks_msec() - average_latency
	
	# Ajout au buffer d'interpolation
	if not interpolation_buffers.has(player_id):
		interpolation_buffers[player_id] = []
	
	interpolation_buffers[player_id].push_back({
		"position": position,
		"timestamp": timestamp
	})
	
	# Garder seulement les 3 dernières positions
	if interpolation_buffers[player_id].size() > 3:
		interpolation_buffers[player_id].pop_front()
	
	emit_signal("position_received", player_id, position)

## Traitement des actions des joueurs
func handle_player_action(data):
	var player_id = data.player_id
	var action = data.action
	var params = data.params
	var timestamp = Time.get_ticks_msec() - (data.latency || average_latency/2)
	
	if not action_buffers.has(player_id):
		action_buffers[player_id] = []
	
	action_buffers[player_id].push_back({
		"action": action,
		"params": params,
		"timestamp": timestamp
	})
	
	emit_signal("action_received", player_id, action, timestamp)

## Interpolation des positions
func process_interpolation():
	var current_time = Time.get_ticks_msec()
	
	for player_id in interpolation_buffers:
		var buffer = interpolation_buffers[player_id]
		if buffer.size() < 2:
			continue
		
		# Points d'interpolation
		var from_point = buffer[-2]
		var to_point = buffer[-1]
		
		# Calcul du ratio
		var total_time = float(to_point.timestamp - from_point.timestamp)
		var elapsed_time = current_time - from_point.timestamp
		
		var ratio = clamp(elapsed_time / total_time, 0.0, 1.0)
		
		# Interpolation
		var interpolated_pos = from_point.position.lerp(to_point.position, ratio)
		
		# Mise à jour du joueur
		if players.has(player_id) and is_instance_valid(players[player_id].node):
			players[player_id].node.target_position = interpolated_pos

## Traitement des actions en buffer
func process_actions():
	var current_time = Time.get_ticks_msec()
	
	for player_id in action_buffers:
		if not action_buffers.has(player_id):
			continue
			
		var buffer = action_buffers[player_id]
		var to_remove = []
		
		# Première passe: marquer les actions à traiter
		for i in range(buffer.size()):
			var action_data = buffer[i]
			if action_data.timestamp <= current_time:
				# Exécuter l'action
				if players.has(player_id) and is_instance_valid(players[player_id].node):
					players[player_id].node.execute_historical_action(
						action_data.action,
						action_data.params,
						action_data.timestamp
					)
				to_remove.append(i)
		
		# Deuxième passe: suppression en partant de la fin
		if to_remove.size() > 0:
			to_remove.reverse()
			for i in to_remove:
				if i < buffer.size():
					buffer.remove_at(i)

## Récupération de la position historique
func get_historical_position(player_id, target_time):
	if not interpolation_buffers.has(player_id) or interpolation_buffers[player_id].size() < 2:
		return Vector2.ZERO
	
	var buffer = interpolation_buffers[player_id]
	
	# Trouver les points encadrants
	var prev_point = null
	var next_point = null
	
	for i in range(buffer.size() - 1):
		if buffer[i].timestamp <= target_time and buffer[i+1].timestamp >= target_time:
			prev_point = buffer[i]
			next_point = buffer[i+1]
			break
	
	if prev_point and next_point:
		# Interpolation
		var ratio = float(target_time - prev_point.timestamp) / float(next_point.timestamp - prev_point.timestamp)
		return prev_point.position.lerp(next_point.position, ratio)
	else:
		# Retourner la position la plus récente
		return buffer[-1].position

## Envoi de données au serveur
func send_data(data):
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		websocket.send_text(JSON.stringify(data))


func transfer_datas(data_type: String, data: Dictionary) -> void:
	print("Données reçues - Type: ", data_type, " Data: ", data)
	# Traitez vos données ici
	match data_type:
		"evenement":
			handle_event(data)
		"message":
				handle_message(data)
		_:
			print("Type de données inconnu: ", data_type)

func handle_event(data: Dictionary) -> void:
	print("event vers socket")
	client.emit("godot_event", data)
	pass

func handle_message(data: Dictionary) -> void:
	# Traitement des messages
	pass
