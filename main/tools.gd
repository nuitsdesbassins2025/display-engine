extends Node

func global_position_to_percentage(global_pos: Vector2) -> Vector2:
	"""Convertit une position globale en pourcentage (0-100)"""
	var viewport_size = get_viewport().get_visible_rect().size
	var percentage = Vector2(
		(global_pos.x / viewport_size.x) * 100.0,
		(global_pos.y / viewport_size.y) * 100.0
	)
	return percentage

func percentage_to_global_position(percentage: Vector2) -> Vector2:
	"""Convertit un pourcentage (0-100) en position globale"""
	var viewport_size = get_viewport().get_visible_rect().size
	var global_pos = Vector2(
		(percentage.x / 100.0) * viewport_size.x,
		(percentage.y / 100.0) * viewport_size.y
	)
	return global_pos
