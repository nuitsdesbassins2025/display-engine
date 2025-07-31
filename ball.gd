extends RigidBody2D

var bounce_factor = 0.9

func _ready():
	gravity_scale = 0
	if linear_velocity == Vector2.ZERO:
		var speed = randf_range(100, 300)
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		linear_velocity = direction * speed

func _physics_process(delta):
	position += linear_velocity * delta
	
	# Rebond sur les bords de l'écran
	var viewport_size = get_viewport_rect().size
	if position.x < 0 or position.x > viewport_size.x:
		linear_velocity.x *= -1 * bounce_factor
		position.x = clamp(position.x, 0, viewport_size.x)
	if position.y < 0 or position.y > viewport_size.y:
		linear_velocity.y *= -1 * bounce_factor
		position.y = clamp(position.y, 0, viewport_size.y)
