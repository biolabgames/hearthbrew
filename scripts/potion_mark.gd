extends Node2D
## Ink marks stay distinct even when two ingredients have similar liquid colours.
var ingredient = 0
const INK = Color('#756447')

func _draw():
	match ingredient % 6:
		0:
			draw_circle(Vector2.ZERO,7,INK)
			draw_circle(Vector2(3,-3),6,Color('#fff0ca'))
		1:
			draw_colored_polygon(PackedVector2Array([Vector2(0,-9),Vector2(6,0),Vector2(5,6),Vector2(0,8),Vector2(-6,4),Vector2(-5,-2),Vector2(-2,2)]),INK)
		2:
			draw_colored_polygon(PackedVector2Array([Vector2(0,-9),Vector2(6,2),Vector2(5,6),Vector2(0,8),Vector2(-5,6),Vector2(-6,2)]),INK)
		3:
			draw_line(Vector2(0,-8),Vector2(0,9),INK,2,true)
			for y in [-5,0,5]:
				draw_circle(Vector2(-3,y),2.5,INK)
				draw_circle(Vector2(3,y-2),2.5,INK)
		4:
			draw_colored_polygon(PackedVector2Array([Vector2(-7,7),Vector2(-6,-2),Vector2(0,-7),Vector2(8,-8),Vector2(6,2),Vector2(0,7)]),INK)
			draw_line(Vector2(-6,6),Vector2(5,-5),Color('#fff0ca'),1.3,true)
		5:
			draw_circle(Vector2.ZERO,4,INK)
			for i in range(8):
				var direction = Vector2.from_angle(i*TAU/8)
				draw_line(direction*6,direction*9,INK,1.5,true)
