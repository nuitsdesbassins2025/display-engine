extends StaticBody2D

@export var decalage_exterieur: int = 10
@export var epaisseur_mur: int = 50

func _ready():
	creer_murs_bords()

func creer_murs_bords():
	var viewport_size = get_viewport_rect().size
	
	# Supprimer les anciennes collisions
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	
	# Positions et tailles des 4 murs
	var murs = [
		{ # Gauche
			"size": Vector2(epaisseur_mur, viewport_size.y + epaisseur_mur * 2),
			"position": Vector2(-epaisseur_mur/2 - decalage_exterieur, viewport_size.y/2)
		},
		{ # Droit
			"size": Vector2(epaisseur_mur, viewport_size.y + epaisseur_mur * 2),
			"position": Vector2(viewport_size.x + epaisseur_mur/2 + decalage_exterieur, viewport_size.y/2)
		},
		{ # Haut
			"size": Vector2(viewport_size.x + epaisseur_mur * 2, epaisseur_mur),
			"position": Vector2(viewport_size.x/2, -epaisseur_mur/2 - decalage_exterieur)
		},
		{ # Bas
			"size": Vector2(viewport_size.x + epaisseur_mur * 2, epaisseur_mur),
			"position": Vector2(viewport_size.x/2, viewport_size.y + epaisseur_mur/2 + decalage_exterieur)
		}
	]
	
	for mur in murs:
		var collision_shape = CollisionShape2D.new()
		var rectangle = RectangleShape2D.new()
		rectangle.size = mur["size"]
		collision_shape.shape = rectangle
		collision_shape.position = mur["position"]
		add_child(collision_shape)

# Gestion du redimensionnement
func _on_viewport_size_changed():
	creer_murs_bords()

func _enter_tree():
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

func _exit_tree():
	if get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().disconnect("size_changed", Callable(self, "_on_viewport_size_changed"))
