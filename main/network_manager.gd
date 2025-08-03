extends Node

## Gestion principale du réseau et de la compensation de latence
## - Communication WebSocket
## - Interpolation des positions
## - Buffer des actions
## - Calcul des états historiques

signal player_connected(player_id)
signal player_disconnected(player_id)
signal position_received(player_id, position)
signal action_received(player_id, action, timestamp)

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


func _ready():
	client = SocketIO.new()
	add_child(client)
	client.base_url = "http://localhost:5000"
	client.socket_connected.connect(_on_socket_connected)
	client.event_received.connect(_on_event_received)
	client.connect_socket()



	#setup_websocket()
	
func _on_socket_connected(_namespace) -> void:
	client.emit("get_user_data", { "id": "id-godot" })
	print("Connecté, envoi get_user_data")

func _on_event_received(event: String, data: Variant, ns: String) -> void:
	print("Event", event, "avec", data)
	if event == "user_data":
		# OK, tu es identifié
		pass
	if event == "action_triggered_by":
		print("Action déclenchée par serveur local 👍 :", data)
		# fais ton traitement
	

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
	
	print(data)
	#match data.type:
		#"player_connect":
			#handle_player_connect(data)
		#"player_disconnect":
			#handle_player_disconnect(data)
		#"position_update":
			#handle_position_update(data)
		#"player_action":
			#handle_player_action(data)

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
