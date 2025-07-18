extends Node2D

# Charge la scène "player"
var player_scene := preload("res://player.tscn")

var ws := WebSocketPeer.new()
var clients := {}

func _ready():
	ws.connect_to_url("ws://localhost:3000")
	print("Tentative de connexion WebSocket...")

func _process(_delta):
	ws.poll()
	while ws.get_available_packet_count() > 0:
		var packet = ws.get_packet().get_string_from_utf8()
		# print("Reçu :", packet)
		var json = JSON.new()
		var result = json.parse(packet)
		if result == OK:
			var message = json.data
			if message.has("id") and message.has("data"):
				print(message.id)
				_update_client(message.id, message.data)
		else:
			print("fail json parse")

func _update_client(id, data):
	print("Reçu :", data)
	if not clients.has(id):
		var player_instance = player_scene.instantiate()
		add_child(player_instance)
		clients[id] = player_instance
		print("Ajout d'une instance de joueur pour", id)

	var player_instance = clients[id]
	if data.has("x") and data.has("y"):
		var x = clamp(data.x, 0, 100) / 100.0 * get_viewport().size.x
		var y = clamp(data.y, 0, 100) / 100.0 * get_viewport().size.y
		player_instance.update_position(x, y)
	if data.has("orientation"):
		player_instance.update_rotation(data.orientation)
	if data.has("rgb"):
		var c = data.rgb
		player_instance.update_color(Color(c.r / 255.0, c.g / 255.0, c.b / 255.0))
	if data.has("action"):
		print(data)
		if data.action == "action1":
			player_instance.do_action01()
		if data.action == "action2":
			player_instance.do_action_nuits_des_bassins()
