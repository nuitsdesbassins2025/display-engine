extends Node2D

signal ball_bounce()

var players_visible = true


# Référence au prototype de joueur
@export var player_scene: PackedScene

# Dictionnaire pour stocker les joueurs par leur ID
# Player = objet joueur in game, tracking
var players: Dictionary = {}

# Dictionnaire pour stocker les clients par leurs ID
# Clients = informations web, pseudo, couleur etc...
var clients: Dictionary = {}

@export var cell_size: int = 50:
	set(value):
		cell_size = max(1, value)
		queue_redraw()

@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)
@export var background_color: Color = Color(0.01, 0.01, 0.01, 1.0)
@export var line_thickness: float = 4
@export var grid_display: bool = true



# Précharge la scène de la balle
const BALL_SCENE = preload("res://entities/balle/balle.tscn")
const PLAYER_SCENE = preload("res://entities/player/player.tscn")

@export var player_scale: float = 50

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
		
	if !players_visible :
		hide_players()

func _on_set_game_settings(settings):
	print("get the settings in game : ",settings)
	match settings.action:
		"grid_toogle":
			toogle_grid()
		"set_player_scale":
			set_player_scale(settings.datas)
		"clear_balls":
			clear_all_balls()
		"clear_drawings":
			clear_all_drawings()
		"toogle_player_text":
			toogle_player_text()
		"remove_big_balls":
			remove_big_balls()
		"spawn_ball":
			spawn_ball()
		"reset_game":
			reset_scene()
		"hide_players":
			toggle_players_visibility()
		"remove_all_blackholes":
			remove_all_blackholes()
		"add_blackhole":
			add_blackhole()
		"declencher_buts":
			declencher_buts()
		"clear_neons":
			clear_neons()


func reset_scene():
	$Node/DodgeBut2.set_score(0)
	$Node/DodgeBut.set_score(0)
	clear_all_balls()
	clear_all_drawings()
	remove_all_blackholes()
	add_blackhole()


func declencher_buts():
	$Node/DodgeBut.ball_explosion()
	$Node/DodgeBut2.ball_explosion()


func toggle_players_visibility():
	players_visible = !players_visible
	print("players_viible = ",players_visible)
	if players_visible:
		for player_id in players:
			players[player_id].show()
	else : 
		for player_id in players:
			players[player_id].hide()

func hide_players():
	print("on cache les joueurs ?")
	for player_id in players:
		players[player_id].hide()
	

# clear all balls
func remove_big_balls():
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		ball.queue_free()

# Passe le texte des joueurs en position
func toogle_player_text():
	for player_key in players:
		var player = players[player_key]
		player.debug_position = !player.debug_position
		player._update_appearance()

# FAIRE UN TRUC QUI CHANGE LA TAILLE SELON LE NOMBRE DE JOUEURS
var force_scale = false
func set_player_scale(settings):
	var target_scale = settings.get("scale")
	player_scale = settings.get("scale")
	
	if player_scale < 20:
		force_scale = false
	else :
		force_scale = true
		for player_key in players:
			var player = players[player_key]
			player.set_player_size(player_scale)




func get_player_by_key(client_player_key):
	print(client_player_key)
	for player_key in players:
		var player = players[player_key]
		if str(player.player_key) == str(int(client_player_key)):
			print("On a une clée correspondante !")
			return player
	print("pas de clée trouvée", str(int(client_player_key)))
	return null


func get_player_by_client_id(client_id):
	print("look for client_id : ",client_id)
	for player_key in players:
		var player = players[player_key]
		if str(player.client_id) == client_id:
			print("On a une clée correspondante !")
			return player
	print("pas de client_id trouvé", str(int(client_id)))
	return null




func _on_player_action(client_id: String, client_datas:Dictionary, action: String, datas: Dictionary):
	
	if action == "trigger_shield":
		
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
	
	target_position = target_position/10
	
	if players.has(id):
		#print("on déplace l'id : ",id)
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
		
		new_player.set_player_size(player_scale)
		
		print("Player ", id, " spawned at: ", spawn_position)
		
		
				# Connecter le signal
		if new_player.player_about_to_delete.connect(_on_player_about_to_delete) != OK:
			push_error("Failed to connect player_about_to_delete signal")
	else:
		push_error("Player scene not assigned!")


# Fonction appelée quand un player veut se supprimer
func _on_player_about_to_delete(player_instance, player_id):
	print("Signal reçu - suppression du player: ", player_id)
	
	# Retirer le player du dictionnaire
	if players.has(player_id):
		players.erase(player_id)
		print("Player retiré du dictionnaire: ", player_id)
	
	# Optionnel: Vérifier que l'instance est toujours valide
	if is_instance_valid(player_instance):
		print("Instance toujours valide, suppression en cours...")
		





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
		
func spawn_ball(count:int=1):
	
	var ball = BALL_SCENE.instantiate()
	ball.add_to_group("balls")  # Important pour que le joueur puisse trouver les balles
	add_child(ball)
	
	ball.move_to_center()
	
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
	#for x in range(0, int(viewport_size.x) + 1, cell_size):
		#draw_line(Vector2(x, 0), Vector2(x, viewport_size.y), grid_color, line_thickness)
	## Dessine les lignes horizontales
	#for y in range(0, int(viewport_size.y) + 1, cell_size):
		#draw_line(Vector2(0, y), Vector2(viewport_size.x, y), grid_color, line_thickness)
	var divisitons = 4
	for x in range(0, divisitons):
		var steps = (viewport_size.x/4)*x
		draw_line(Vector2(steps, 0), Vector2(steps, viewport_size.y), grid_color, line_thickness)
	# Dessine les lignes horizontales
	for y in range(0,divisitons):
		var steps = (viewport_size.y/4)*y
		draw_line(Vector2(0, steps), Vector2(viewport_size.x, steps), grid_color, line_thickness)
		

func move_player_to_click():
	#print("move")
	var mouse_pos = get_global_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size

	# Mapper X entre 0 et 100
	var mapped_x = (mouse_pos.x / viewport_size.x) * 1000

	# Mapper Y entre 0 et 100
	var mapped_y = (mouse_pos.y / viewport_size.y) * 1000
	print(Vector2(mapped_x,mapped_y))
	_on_move_player("click_player",Vector2(mapped_x,mapped_y)) 



func register_key(client_id, datas):
	
	var key = datas.tracking_code
	
	var player_by_key = get_player_by_key(key)
	var my_datas = {
		"client_id": client_id,
		"event_type" : "set_tracking",
		"event_datas" : {
			"tracking_status" : "error",
			"tracking_code" : key
			}
		}
		
	if player_by_key :
		player_by_key.client_id = client_id
		print(datas)
		if(datas.color !=null):
			player_by_key.player_color = Color(datas.color)
		my_datas["event_datas"]["tracking_status"] = "valid"

	else :
		var player_by_id = get_player_by_client_id(client_id)
		if player_by_id :
			player_by_id.unregister()
		print("Clee non existante")
		#my_datas["event_datas"]["status"] = "missing"
		
	NetworkManager.transfer_datas("info",my_datas)
		
	pass

func set_player_pseudo(client_id, pseudo):
	
	var player = get_player_by_client_id(client_id)
	if player :
		player.pseudo = pseudo
	else :
		print("player non trouvé")
		
func set_player_color(client_id, color):
	
	var player = get_player_by_client_id(client_id)
	if player :
		player.player_color = color
	else :
		print("player non trouvé")
		
func clear_all_balls():
	# Récupérer toutes les balles du groupe "balls"
	var balls = get_tree().get_nodes_in_group("mini_balls")
	
	for ball in balls:
		ball.queue_free()
	
	print("Supprimé ", balls.size(), " balles")
	
func clear_all_drawings():
	var drawings = get_tree().get_nodes_in_group("drawings")
	
	for drawing in drawings:
		drawing.queue_free()

func clear_neons():
	var neons = get_tree().get_nodes_in_group("neons")
	for drawing in neons:
		drawing.queue_free()


func add_blackhole():
	var blackhole_scene = preload("res://entities/black_hole/black_hole.tscn")
	var blackhole = blackhole_scene.instantiate()
	get_tree().current_scene.add_child(blackhole)

	
func remove_all_blackholes():
	var blackholes = get_tree().get_nodes_in_group("blackholes")
	for blackhole in blackholes:
		if is_instance_valid(blackhole):
			blackhole.queue_free()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT :
		move_player_to_click()
		#move_to_position(get_global_mouse_position())


	# Menu de debug avec touches A Z E R T
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_A:
				#print("trigger_shield")
			#	trigger_shield()
				pass
			KEY_Z:
				
				_on_move_player("player150",Vector2(500,500))
				pass
			KEY_E:
				clear_all_balls()
				clear_all_drawings()
				pass
			KEY_R:
				pass
			KEY_T:
				pass
