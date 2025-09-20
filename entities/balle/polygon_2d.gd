extends Polygon2D

var colors = [
	Color("#FFFFFF"), Color("#FF0000"), Color("#00FF00"), Color("#0000FF"),
	Color("#FFFF00"), Color("#FF00FF"), Color("#00FFFF"), Color("#FF8000"),
	Color("#8000FF"), Color("#0080FF"), Color("#FF0080"), Color("#008080")
]

var speed = 0.5  # vitesse de transition entre les couleurs
var pulse_speed = 0.50  # vitesse du "clignotement"
var intensity = 0.1    # intensité de la pulsation

func _process(delta):
	var t = Time.get_ticks_msec() / 1000.0
	
	# Calcul de l'index de couleur actuel
	var color_index = int(t * speed) % colors.size()
	var next_color_index = (color_index + 1) % colors.size()
	
	# Interpolation entre la couleur actuelle et la suivante
	var progress = fmod(t * speed, 1.0)
	var base_color = colors[color_index].lerp(colors[next_color_index], progress)
	
	# Ajout d'un effet de pulsation sur la luminosité
	var pulse = (sin(t * pulse_speed) * 0.5 + 0.5) * intensity
	color = base_color.lightened(pulse)
