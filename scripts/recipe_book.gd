extends Control
## A leather cover, stacked paper edges, stitched gutter and ruled recipe page.

func _draw():
	draw_style_box(paper_style(Color('#382b23'),18),Rect2(-12,-12,1204,602))
	draw_style_box(paper_style(Color('#795039'),14),Rect2(-8,-8,1192,586))
	for i in range(4):
		draw_style_box(paper_style(Color('#cbb997').lightened(i*0.035),5),Rect2(4+i*2,4-i*2,1168,562))
	draw_style_box(paper_style(Color('#f0dfbb'),5),Rect2(8,0,320,552))
	draw_style_box(paper_style(Color('#fff0d1'),5),Rect2(336,0,826,552))
	for i in range(16):
		draw_rect(Rect2(321+i,2,1,548),Color(0.27,0.17,0.10,0.22*(1.0-absf(i-8)/8.0)))
	for y in range(28,535,42):
		draw_line(Vector2(324,y),Vector2(334,y+4),Color('#9e8058'),1.5,true)
	draw_line(Vector2(365,108),Vector2(1130,108),Color('#c4aa7a'),1.0,true)
	draw_rect(Rect2(1090,-8,20,49),Color('#9b5145'))
	draw_colored_polygon(PackedVector2Array([Vector2(1090,41),Vector2(1100,31),Vector2(1110,41)]),Color('#fff0d1'))

func paper_style(color, radius):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
