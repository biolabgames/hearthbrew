extends Control
## Lightweight botanical drawings shared by the garden and preparation bench.
var herb = 0
var growth = 2
var planter = true
var grinding = false
var progress = -1

func _draw():
	var ink = Color('#355d4c')
	var tint = Color(preload('res://scripts/herbalism.gd').HERBS[herb].color)
	var center = size*Vector2(0.5,0.77)
	if planter:
		draw_style_box(box(Color('#c09a70'),12),Rect2(8,size.y-24,size.x-16,22))
		paint_oval(center,Vector2(size.x*0.40,13),Color('#715b43'))
	var height = 22.0+growth*20.0
	for stem in range(3):
		var base = center+Vector2((stem-1)*17,0)
		var top = base+Vector2((stem-1)*9,-height+abs(stem-1)*9)
		draw_line(base,top,ink,2,true)
		for leaf in range(2+growth):
			var joint = base.lerp(top,(leaf+1.0)/(3+growth))
			var side = -1 if leaf%2 == 0 else 1
			var tip = joint+Vector2(side*(14+growth*3),-12)
			draw_colored_polygon(PackedVector2Array([joint,joint+Vector2(side*9,-15),tip,joint+Vector2(side*13,-1)]),tint)
			draw_line(joint,tip,ink,1,true)
		if herb == 3 and growth == 2:
			for petal in range(5):
				var offset = Vector2.from_angle(petal*TAU/5)*7
				draw_circle(top+offset,6,tint,true,-1,true)
			draw_circle(top,3,Color('#e2bb64'),true,-1,true)
		if herb == 1 and not planter:
			draw_line(base,base+Vector2((stem-1)*8,18),tint,8,true)
	if progress >= 0:
		var bowl = Vector2(size.x*0.75,size.y*0.80)
		paint_oval(bowl,Vector2(47,15),ink)
		paint_oval(bowl-Vector2(0,3),Vector2(40,11),tint)
		if grinding:
			draw_line(bowl+Vector2(0,-3),bowl+Vector2(22-progress*5,-50),Color('#907452'),13,true)
		else:
			for i in range(progress+1):
				draw_arc(bowl+Vector2(-15+i*14,-27),9,-PI/2,PI/2,12,Color('#b3b4a2'),2,true)

func paint_oval(center, radius, tint):
	var points = PackedVector2Array()
	for i in range(48): points.append(center+Vector2(cos(i*TAU/48),sin(i*TAU/48))*radius)
	draw_colored_polygon(points,tint)

func box(tint, radius):
	var style = StyleBoxFlat.new()
	style.bg_color = tint
	style.set_corner_radius_all(radius)
	return style
