extends Polygon2D



var speed = 0.5  # vitesse de rotation des couleurs
var pulse_speed = 2.0  # vitesse du "clignotement"
var intensity = 0.5    # intensité de la pulsation

func _process(delta):
	var t = Time.get_ticks_msec() / 500.0
	
	# Teinte qui tourne en boucle [0..1]
	var hue = fmod(t * speed, 1.0)
	
	# Saturation et valeur restent à 1 pour des couleurs vives
	var base_color = Color.from_hsv(hue, 1.0, 1.0)
	
	# Ajout d’un effet de pulsation sur la luminosité
	var pulse = (sin(t * pulse_speed) * 0.5 + 0.5) * intensity
	color = base_color.lightened(pulse)
