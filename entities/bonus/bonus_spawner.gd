extends Node2D

@export var scene_bonus: PackedScene = preload("res://entities/bonus/bonus.tscn")
@export var nombre_bonus_max: int = 5
@export var temps_respawn: float = 10.0

var bonus_actuels: int = 0
var timer_respawn: Timer

func _ready():
	print("bonus importé")
	timer_respawn = Timer.new()
	add_child(timer_respawn)
	timer_respawn.wait_time = temps_respawn
	timer_respawn.timeout.connect(_spawn_bonus)
	
	# Générer les premiers bonus
	for i in range(nombre_bonus_max):
		_spawn_bonus()

func _spawn_bonus():
	if bonus_actuels >= nombre_bonus_max:
		return
	print("on genere un bonus")
	var bonus = scene_bonus.instantiate()
	add_child(bonus)
	bonus_actuels += 1
	
	# Position aléatoire
	var viewport_size = get_viewport().get_visible_rect().size
	bonus.position = Vector2(
		randf_range(50, viewport_size.x - 50),
		randf_range(50, viewport_size.y - 50)
	)
	
	# Connecter le signal de disparition
	bonus.bonus_ramasse.connect(_on_bonus_ramasse)
	bonus.tree_exited.connect(_on_bonus_disparu)

func _on_bonus_ramasse(joueur_nom, bonus_type):
	print("Bonus ", bonus_type, " ramassé par ", joueur_nom)
	# Démarrer le timer pour respawn
	timer_respawn.start()

func _on_bonus_disparu():
	bonus_actuels -= 1
