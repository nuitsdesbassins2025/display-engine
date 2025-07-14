extends Node2D

var ws := WebSocketPeer.new()
var clients := {}

func _ready():
	ws.connect_to_url("ws://localhost:3000")
	print("Tentative de connexion WebSocket...")


func _process(_delta):
	ws.poll()

	#match ws.get_ready_state():
		#WebSocketPeer.STATE_OPEN:
			#print("✅ WebSocket connecté")
		#WebSocketPeer.STATE_CLOSING, WebSocketPeer.STATE_CLOSED:
			#print("❌ WebSocket déconnecté")
#	
	while ws.get_available_packet_count() > 0:
		#var msg = ws.get_packet().get_string_from_utf8()
		

		#print("on a quelque chose")
		var packet = ws.get_packet().get_string_from_utf8()
		print("Reçu :", packet)
		var json = JSON.new()
		var result = json.parse(packet)
		if result == OK:
			var message = json.data
			if message.has("id") and message.has("data"):
				print(message.id)
				_update_client(message.id, message.data)
		else :
			print("fail json parse")

func _update_client(id, data):
	print("Reçu :", data)

	if not clients.has(id):
		var sprite := Sprite2D.new()
		sprite.texture = preload("res://default_square.png")  # un carré blanc
		sprite.scale = Vector2(0.3, 0.3)
		add_child(sprite)
		clients[id] = sprite
		print("Ajout d’un Sprite2D pour", id)

	var sprite = clients[id]

	if data.has("x") and data.has("y"):
		var x = clamp(data.x, 0, 100) / 100.0 * get_viewport().size.x
		var y = clamp(data.y, 0, 100) / 100.0 * get_viewport().size.y
		sprite.position = Vector2(x, y)

	if data.has("orientation"):
		sprite.rotation_degrees = data.orientation

	if data.has("rgb"):
		var c = data.rgb
		sprite.modulate = Color(c.r / 255.0, c.g / 255.0, c.b / 255.0)
