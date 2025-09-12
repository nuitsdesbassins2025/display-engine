extends Area2D




@export_enum("Gauche", "Droite", "Haut", "Bas") var position_cote: int = 0
@export var marge: int = 50  # Marge depuis le bord

func _ready():
	positionner_selon_cote()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("big_balls"):
		body.move_to_center()
		pass # Replace with function body.


func positionner_selon_cote():
	var viewport_size = get_viewport_rect().size
	var object_size = calculer_taille_objet()
	
	match position_cote:
		0:  # Gauche
			position = Vector2(marge + object_size.x / 2, viewport_size.y / 2)
			rotation_degrees = 0
		1:  # Droite
			position = Vector2(viewport_size.x - marge - object_size.x / 2, viewport_size.y / 2)
			rotation_degrees = 180
		2:  # Haut
			position = Vector2(viewport_size.x / 2, marge + object_size.y / 2)
			rotation_degrees = 270
		3:  # Bas
			position = Vector2(viewport_size.x / 2, viewport_size.y - marge - object_size.y / 2)
			rotation_degrees = 90

func calculer_taille_objet() -> Vector2:
	# Essaye de trouver la taille via différents composants
	var size = Vector2(50, 50)  # Taille par défaut
	
	# Si on a un CollisionShape2D
	if has_node("CollisionShape2D"):
		var collision = $CollisionShape2D
		if collision.shape:
			var rect = collision.shape.get_rect()
			size = rect.size * collision.scale
	
	# Si on a un Sprite2D
	elif has_node("Sprite2D"):
		var sprite = $Sprite2D
		if sprite.texture:
			size = sprite.texture.get_size() * sprite.scale
	
	return size

# Optionnel : pour mettre à jour en temps réel dans l'éditeur
func _process(_delta):
	if Engine.is_editor_hint():
		positionner_selon_cote()

# Optionnel : pour s'adapter au redimensionnement
func _on_viewport_size_changed():
	positionner_selon_cote()

func _enter_tree():
	# Se connecter au redimensionnement
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

func _exit_tree():
	# Se déconnecter
	if get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().disconnect("size_changed", Callable(self, "_on_viewport_size_changed"))
