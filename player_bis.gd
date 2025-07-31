extends Area2D

@export var push_force := 500.0
@export var push_radius := 150.0
@export var cooldown_time := 0.5

var can_push := true

func _ready():
	$CooldownTimer.wait_time = cooldown_time

func _process(_delta):
	# Suit la position de la souris
	global_position = get_global_mouse_position()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and can_push:
		print("pousse")
		push_nearby_balls()
		can_push = false
		$CooldownTimer.start()

func push_nearby_balls():
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		print("une balle !")
		var distance = global_position.distance_to(ball.global_position)
		if distance < push_radius:
			print("assez proche")
			var direction = (ball.global_position - global_position).normalized()
			ball.apply_impulse(direction * push_force * (1 - distance/push_radius))
		else :
			print("balle trop loin")

func _on_cooldown_timer_timeout():
	can_push = true
