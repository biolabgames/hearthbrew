extends Control
## Match the bowl's opening and body without capturing the surrounding counter.
func _has_point(point: Vector2) -> bool:
	return ((point-Vector2(150,75))/Vector2(150,75)).length_squared() <= 1.0
