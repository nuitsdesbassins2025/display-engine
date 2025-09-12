extends Node2D

signal ball_bounce()


# Référence au prototype de joueur
@export var player_scene: PackedScene

# Dictionnaire pour stocker les joueurs par leur ID
var players: Dictionary = {}

@export var cell_size: int = 50:
	set(value):
		cell_size = max(1, value)
		queue_redraw()

@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)
@export var background_color: Color = Color(0.01, 0.01, 0.01, 1.0)
@export var line_thickness: float = 4
@export var grid_display: bool = false



# Précharge la scène de la balle
const BALL_SCENE = preload("res://entities/balle/balle.tscn")
const PLAYER_SCENE = preload("res://entities/player/player.tscn")

@export var player_scale: float = 1.0

func _ready():
	if NetworkManager.has_signal("move_player"):
		NetworkManager.move_player.connect(_on_move_player)
		
	if NetworkManager.has_signal("client_action_trigger"):
		NetworkManager.client_action_trigger.connect(_on_player_action)
		
	if NetworkManager.has_signal("set_game_settings"):
		NetworkManager.set_game_settings.connect(_on_set_game_settings)

	spawn_ball()
	queue_redraw()


func _draw():
	draw_background()
	
func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		move_player_to_click()

func _on_set_game_settings(settings):
	print("get the settings in game : ",settings)
	
	match settings.action:
		"grid_toogle":
			print("on déclenche le grid toogle")
			toogle_grid()
		"set_player_scale":
			set_player_scale(settings.datas)
	
	

func set_player_scale(settings):
	print("set player scale déclenchée !!")
	print(settings)
	for player_key in players:
		
		var player = players[player_key]
		var new_size:int = settings.scale
		print(new_size)
		player.set_player_size(new_size)
	#pass


func get_player_by_key(client_player_key):
	print(client_player_key)
	for player_key in players:
		var player = players[player_key]
		
		if str(player.player_key) == str(int(client_player_key)):

			print("On a une clée correspondante !")
			return player

	print("pas de clée trouvée", str(int(client_player_key)))
	return null




func _on_player_action(client_id: String, client_datas:Dictionary, action: String, datas: Dictionary):
	
	if action == "touch_screen":
		
		var player = null
		var player_key = client_datas.get("player_id")
		if player_key != "":
			player = get_player_by_key(player_key)
	
		if player != null :
			player.trigger_shield()
	

func toogle_grid():
	grid_display = !grid_display
	queue_redraw()  


func _on_move_player(id: String, target_position: Vector2):
	# print("ID : ", id, " spawned at : ", target_position)
	# Vérifie si le joueur existe déjà
	

	
	if players.has(id):
		# Le joueur existe, on le déplace
		players[id].move_to_position(target_position)
	else:
		# Le joueur n'existe pas, on l'instancie
		
		_spawn_player(id, target_position)



func _spawn_player(id: String, spawn_position: Vector2):
	if player_scene:
		var new_player = player_scene.instantiate()
		new_player.player_id = id
		new_player.global_position = spawn_position
		new_player.player_key = get_random_key()
		add_child(new_player)
		players[id] = new_player
		
		
		print("Player ", id, " spawned at: ", spawn_position)
	else:
		push_error("Player scene not assigned!")

func get_random_key() -> String:
	var random = RandomNumberGenerator.new()
	random.randomize()
	
	var attempts = 0
	var max_attempts = 1000  # Sécurité pour éviter une boucle infinie
	
	while attempts < max_attempts:
		# Générer 4 chiffres aléatoires
		var key = ""
		key += str(random.randi_range(1, 9))
		
		for i in range(3):
			key += str(random.randi_range(0, 9))
		
		# Vérifier si la clé existe déjà
		var key_exists = false
		for player_id in players:
			if players[player_id] is Dictionary and players[player_id].has("key"):
				if players[player_id]["key"] == key:
					key_exists = true
					break
		
		# Si la clé n'existe pas, la retourner
		if not key_exists:
			return key
		
		attempts += 1
	
	# Fallback si trop de tentatives (très improbable)
	push_error("Impossible de générer une clé unique après " + str(max_attempts) + " tentatives")
	return str(random.randi_range(1000, 9999))  # Retourne un nombre aléatoire de 4 chiffres


# Fonction pour nettoyer si besoin
func remove_player(id: int):
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
		
func spawn_ball():
	var ball = BALL_SCENE.instantiate()
	ball.add_to_group("balls")  # Important pour que le joueur puisse trouver les balles
	add_child(ball)
	
	ball.position = Vector2(
		randf_range(50, get_viewport_rect().size.x - 50),
		randf_range(50, get_viewport_rect().size.y - 50)
	)
	
	var speed = randf_range(100, 300)
	var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	ball.linear_velocity = direction * speed


func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		# Redessine quand la fenêtre change de taille
		queue_redraw()
		
func draw_background():
	var viewport_size = get_viewport_rect().size
	# Dessine le fond
	draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y), background_color)
	
	if grid_display:
		draw_grid()


func draw_grid():
	var viewport_size = get_viewport_rect().size
	# Dessine les lignes verticales
	for x in range(0, int(viewport_size.x) + 1, cell_size):
		draw_line(Vector2(x, 0), Vector2(x, viewport_size.y), grid_color, line_thickness)
	# Dessine les lignes horizontales
	for y in range(0, int(viewport_size.y) + 1, cell_size):
		draw_line(Vector2(0, y), Vector2(viewport_size.x, y), grid_color, line_thickness)

func move_player_to_click():
	#print("move")
	var mouse_pos = get_global_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size

	# Mapper X entre 0 et 100
	var mapped_x = (mouse_pos.x / viewport_size.x) * 100

	# Mapper Y entre 0 et 100
	var mapped_y = (mouse_pos.y / viewport_size.y) * 100
	_on_move_player("click_player",Vector2(mapped_x,mapped_y)) 
	

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT :
		move_player_to_click()
		#move_to_position(get_global_mouse_position())


	# Menu de debug avec touches A Z E R T
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_A:
				print("trigger_shield")
			#	trigger_shield()
				pass
			KEY_Z:
				
				_on_move_player("player150",Vector2(10,10))
				pass
			KEY_E:
				pass
			KEY_R:
				pass
			KEY_T:
				pass
