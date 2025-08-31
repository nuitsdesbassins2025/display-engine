extends Area2D

signal bonus_ramasse(joueur_nom, bonus_type)

@export var bonus_type: String = "nouriture"  # "vitesse", "score", etc.
@export var valeur: int = 10

func _ready():
	# Détection quand un corps entre dans la zone
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("bonus body entered")
	if body.is_in_group("players"):
		# Émettre le signal avant de disparaître
		emit_signal("bonus_ramasse", body.name, bonus_type)
		
		# Appliquer l'effet au joueur
		_appliquer_effet(body)
		
		# Animation de disparition
		_disparaitre()

func _appliquer_effet(joueur):
	match bonus_type:
		"nouriture":
			if joueur.has_method("agrandir_queue"):
				joueur.agrandir_queue(valeur)
		"vie":
			if joueur.has_method("ajouter_vie"):
				joueur.ajouter_vie(valeur)
		"vitesse":
			if joueur.has_method("ajouter_vitesse"):
				joueur.ajouter_vitesse(valeur, 5.0)  # 5 secondes
		"score":
			if joueur.has_method("ajouter_score"):
				joueur.ajouter_score(valeur)

func _disparaitre():
	# Désactiver la collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Animation de disparition
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
