extends Area2D
class_name NetworkBullet

## Projectile avec compensation de latence
## - Mouvement linéaire
## - Détection de collision
## - Gestion des impacts
#
#@export var speed := 800.0
#@export var damage := 25
#@export var max_distance := 2000.0
#
#var direction := Vector2.RIGHT
#var distance_traveled := 0.0
#var shooter: Node2D = null
#var initial_position := Vector2.ZERO
#
### Initialisation de la balle
#func initialize(spawn_pos: Vector2, dir: Vector2, owner: Node2D):
	#position = spawn_pos
	#initial_position = spawn_pos
	#direction = dir.normalized()
	#shooter = owner
	#rotation = direction.angle()
	#
	## Configuration de la hitbox
	#$CollisionShape2D.disabled = false
#
#func _physics_process(delta):
	## Mouvement
	#var movement = direction * speed * delta
	#position += movement
	#distance_traveled += movement.length()
	#
	## Vérification de la distance maximale
	#if distance_traveled >= max_distance:
		#queue_free()
		#return
	#
	## Détection de collision avec compensation
	#if NetworkManager.is_networked_game:
		#check_historical_collision()
#
### Vérification des collisions avec compensation de latence
#func check_historical_collision():
	#var query = PhysicsShapeQueryParameters2D.new()
	#query.shape = $CollisionShape2D.shape
	#query.transform = global_transform
	#query.collision_mask = 0b1 # Ajuster selon vos layers
	#
	## Compensation de latence pour le tireur
	#var shooter_lag = NetworkManager.average_latency if shooter != NetworkManager.local_player else 0
	#
	## Exécution de la requête
	#var space = get_world_2d().direct_space_state
	#var collisions = space.intersect_shape(query)
	#
	#for collision in collisions:
		#var collider = collision.collider
		#
		## Ignorer le tireur
		#if collider == shooter:
			#continue
		#
		## Gestion des collisions avec les joueurs
		#if collider is NetworkPlayer:
			#handle_player_hit(collider)
		#
		## Gestion des collisions avec l'environnement
		#elif collider is TileMap:
			#handle_wall_hit()
		#
		#break
#
### Impact sur un joueur
#func handle_player_hit(player: NetworkPlayer):
	## Envoyer l'action de dégâts au serveur avec timestamp
	#NetworkManager.send_data({
		#"type": "player_action",
		#"action": "damage",
		#"target": player.name,
		#"params": {
			#"amount": damage,
			#"timestamp": Time.get_ticks_msec() - NetworkManager.average_latency
		#}
	#})
	#
	## Effets locaux
	#player.take_damage(damage)
	#queue_free()
#
### Impact sur un mur
#func handle_wall_hit():
	## Effets de particules ou son
	#$ImpactParticles.emitting = true
	#$AudioStreamPlayer.play()
	#
	## Désactivation
	#$CollisionShape2D.disabled = true
	#$Sprite2D.hide()
	#
	## Suppression après les effets
	#await $AudioStreamPlayer.finished
	#queue_free()
#
#func _on_body_entered(body):
	## Détection de collision standard (pour le mode hors-ligne)
	#if not NetworkManager.is_networked_game:
		#if body is NetworkPlayer and body != shooter:
			#handle_player_hit(body)
		#elif body is TileMap:
			#handle_wall_hit()
