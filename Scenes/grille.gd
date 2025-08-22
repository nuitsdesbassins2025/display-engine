extends Polygon2D

@export var cell_size: float = 50.0:
	set(value):
		cell_size = value
		update_grid()

@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)
@export var background_color: Color = Color(0.1, 0.1, 0.1, 1.0)

func _ready():
	update_grid()

func update_grid():
	var viewport_size = get_viewport_rect().size
	var points = PackedVector2Array()
	var colors = PackedColorArray()
	
	# Fond
	points.append_array([
		Vector2(0, 0),
		Vector2(viewport_size.x, 0),
		Vector2(viewport_size.x, viewport_size.y),
		Vector2(0, viewport_size.y)
	])
	colors.append_array([background_color, background_color, background_color, background_color])
	
	# Lignes verticales
	for x in range(0, int(viewport_size.x) + 1, cell_size):
		points.append_array([
			Vector2(x, 0),
			Vector2(x, viewport_size.y)
		])
		colors.append_array([grid_color, grid_color])
	
	# Lignes horizontales
	for y in range(0, int(viewport_size.y) + 1, cell_size):
		points.append_array([
			Vector2(0, y),
			Vector2(viewport_size.x, y)
		])
		colors.append_array([grid_color, grid_color])
	
	polygon = points
	vertex_colors = colors
