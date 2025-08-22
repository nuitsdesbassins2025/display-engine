extends Node2D

# Référence au prototype de joueur
@export var player_scene: PackedScene

# Dictionnaire pour stocker les joueurs par leur ID
var players: Dictionary = {}

@export var cell_size: int = 50:
	set(value):
		cell_size = max(1, value)
		queue_redraw()

@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)
@export var background_color: Color = Color(0.1, 0.1, 0.1, 1.0)
@export var line_thickness: float = 4

# Précharge la scène de la balle
const BALL_SCENE = preload("res://entities/balle/balle.tscn")
const PLAYER_SCENE = preload("res://entities/player/player.tscn")

func _ready():
	if NetworkManager.has_signal("move_player"):
		NetworkManager.move_player.connect(_on_move_player)


	spawn_ball()
	queue_redraw()

func _draw():
	draw_grid()

func _on_move_player(id: int, target_position: Vector2):
	print("ID : ", id, " spawned at : ", target_position)
	# Vérifie si le joueur existe déjà
	if players.has(id):
		# Le joueur existe, on le déplace
		players[id].move_to_position(target_position)
	else:
		# Le joueur n'existe pas, on l'instancie
		
		_spawn_player(id, target_position)


func _spawn_player(id: int, spawn_position: Vector2):
	if player_scene:
		var new_player = player_scene.instantiate()
		new_player.player_id = id
		new_player.global_position = spawn_position
		add_child(new_player)
		players[id] = new_player
		
		
		print("Player ", id, " spawned at: ", spawn_position)
	else:
		push_error("Player scene not assigned!")

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
		
func draw_grid():
	var viewport_size = get_viewport_rect().size
	
		# Dessine le fond
	# draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y), background_color)
	
	# Dessine les lignes verticales
	for x in range(0, int(viewport_size.x) + 1, cell_size):
		draw_line(Vector2(x, 0), Vector2(x, viewport_size.y), grid_color, line_thickness)
	
	# Dessine les lignes horizontales
	for y in range(0, int(viewport_size.y) + 1, cell_size):
		draw_line(Vector2(0, y), Vector2(viewport_size.x, y), grid_color, line_thickness)
