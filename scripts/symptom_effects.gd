extends Node2D
const Brewing = preload("res://brewing.gd")
var effect_mask = 0
var effect_time = 0.0
var effect_origin = Vector2.ZERO
var face_center = Vector2(264,169)

func cheek_wash(center, shade):
	# Layered, translucent ellipses keep the colour soft on the painted faces.
	draw_set_transform(effect_origin+center,0,Vector2(1.0,0.58))
	for radius in range(18,0,-2):
		var wash = shade
		wash.a *= 0.07
		draw_circle(Vector2.ZERO,radius,wash)
	draw_set_transform(Vector2.ZERO)

func _draw():
	var t = effect_time
	if (effect_mask & Brewing.FEVER) != 0:
		cheek_wash(face_center+Vector2(-25,0),Color('#e66c68'))
		cheek_wash(face_center+Vector2(25,0),Color('#e66c68'))
	if (effect_mask & Brewing.CHILLS) != 0:
		cheek_wash(face_center+Vector2(-25,7),Color('#88bde4'))
		cheek_wash(face_center+Vector2(25,7),Color('#88bde4'))
	if (effect_mask & Brewing.DROWSINESS) != 0:
		for i in range(3):
			var rise = fposmod(t*16+i*25,80)
			draw_string(ThemeDB.fallback_font,effect_origin+Vector2(326+i*9,100-rise),'z',HORIZONTAL_ALIGNMENT_LEFT,-1,18+i*3,Color(0.72,0.65,0.85,1-rise/100))
	if (effect_mask & Brewing.DIZZINESS) != 0:
		for i in range(5):
			var a = t*1.5+i*TAU/5
			var p = effect_origin+Vector2(260+cos(a)*67,42+sin(a)*13)
			draw_line(p-Vector2(4,0),p+Vector2(4,0),Color('#e6ca7d'),2)
			draw_line(p-Vector2(0,4),p+Vector2(0,4),Color('#e6ca7d'),2)
	if (effect_mask & Brewing.SPARKS) != 0:
		for i in range(7):
			var phase = fposmod(t*0.8+i/7.0,1.0)
			var p = effect_origin+Vector2(274,168)+Vector2(62*phase,(-35+i*10)*phase)
			draw_circle(p,2+phase*2,Color(1,0.75,0.35,1-phase))
	if (effect_mask & Brewing.ECHO) != 0:
		for i in range(3):
			var phase = fposmod(t*0.7+i/3.0,1.0)
			draw_arc(effect_origin+Vector2(292,177),12+phase*48,-0.8,0.8,20,Color(0.65,0.8,1,1-phase),2,true)
	if (effect_mask & Brewing.GLOW) != 0:
		for x in [156,356]:
			for r in range(4):
				draw_circle(effect_origin+Vector2(x,350),12+r*7+sin(t*2)*3,Color(1,0.87,0.47,0.10))
