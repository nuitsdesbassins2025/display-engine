extends ColorRect

@export var cell_size: float = 10.0:
	set(value):
		cell_size = max(1.0, value)
		if material:
			material.set_shader_parameter("cell_size", cell_size)

@export var line_width: float = 1.0:
	set(value):
		line_width = max(0.1, value)
		if material:
			material.set_shader_parameter("line_width", line_width)

@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5):
	set(value):
		grid_color = value
		if material:
			material.set_shader_parameter("grid_color", value)

@export var background_color: Color = Color(0.1, 0.1, 0.1, 1.0):
	set(value):
		background_color = value
		if material:
			material.set_shader_parameter("background_color", value)

func _ready():
	# Crée le matériau shader
	material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	
	uniform vec4 grid_color : source_color = vec4(0.3, 0.3, 0.3, 0.5);
	uniform vec4 background_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
	uniform float cell_size : hint_range(1, 1000) = 50.0;
	uniform float line_width : hint_range(0.1, 10.0) = 1.0;
	
	void fragment() {
		vec2 uv = UV * TEXTURE_PIXEL_SIZE;
		
		// Calcul des positions de grille
		vec2 grid_pos = floor(uv / cell_size);
		vec2 grid_uv = fract(uv / cell_size);
		
		// Dessin des lignes
		vec2 line = smoothstep(vec2(line_width / cell_size), vec2(0.0), grid_uv);
		line += smoothstep(vec2(1.0 - line_width / cell_size), vec2(1.0), grid_uv);
		
		float grid = max(line.x, line.y);
		
		// Mélange entre couleur de grille et fond
		COLOR = mix(background_color, grid_color, grid);
	}
	"""
	material.shader = shader
	
	# Initialise les paramètres
	material.set_shader_parameter("cell_size", cell_size)
	material.set_shader_parameter("line_width", line_width)
	material.set_shader_parameter("grid_color", grid_color)
	material.set_shader_parameter("background_color", background_color)
	
	# S'étend sur tout l'écran
	size = get_viewport_rect().size
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1

func _process(_delta):
	# Met à jour la taille si la fenêtre change
	size = get_viewport_rect().size
