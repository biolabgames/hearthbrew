extends Control

const INK = Color('#604536')
const PAPER = Color('#fff1d5')
const DARK = Color('#355d4c')
const SAGE = Color('#70957b')
const ROSE = Color('#bf7969')
const GOLD = Color('#dca650')
var ui: Control
var serif: SystemFont
var body_font: SystemFont
var sound: AudioStreamPlayer
var muted = false
var rotoscope = preload('res://rotoscope_player.gd').new()

func initialise_art():
	if not rotoscope.load_manifest():
		push_error('Hand animation: '+str(rotoscope.errors))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(['Georgia','DejaVu Serif','serif'])
	body_font = SystemFont.new()
	body_font.font_names = PackedStringArray(['Trebuchet MS','DejaVu Sans','sans-serif'])
	ui = Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	sound = AudioStreamPlayer.new()
	sound.volume_db = -22
	add_child(sound)

func label_at(words, pos: Vector2, dimensions: Vector2, font_size = 18, color = INK, parent = null, fancy = false):
	var node = Label.new()
	node.position = pos
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_override('font',serif if fancy else body_font)
	node.add_theme_font_size_override('font_size',font_size)
	node.add_theme_color_override('font_color',color)
	node.size = dimensions
	node.text = str(words)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(ui if parent == null else parent).add_child(node)
	node.set_deferred('size',dimensions)
	return node

func button_at(words, pos: Vector2, dimensions: Vector2, action: Callable, color = DARK, parent = null, font_size = 17):
	var node = Button.new()
	node.focus_mode = Control.FOCUS_NONE
	node.position = pos
	node.size = dimensions
	node.text = str(words)
	node.add_theme_font_override('font',body_font)
	node.add_theme_font_size_override('font_size',font_size)
	node.add_theme_color_override('font_color',PAPER)
	node.add_theme_color_override('font_hover_color',PAPER)
	node.add_theme_color_override('font_disabled_color',Color('#62654f'))
	for state in ['normal','hover','pressed','disabled']:
		var style = StyleBoxFlat.new()
		style.bg_color = color
		if state == 'hover':
			style.bg_color = color.lightened(0.13)
		elif state == 'pressed':
			style.bg_color = color.darkened(0.08)
		elif state == 'disabled':
			style.bg_color = color.lerp(Color('#9eaa91'),0.45)
		style.set_corner_radius_all(11)
		style.border_color = INK.darkened(0.08)
		style.set_border_width_all(1)
		style.content_margin_left = 8
		style.content_margin_right = 8
		node.add_theme_stylebox_override(state,style)
	node.pressed.connect(action)
	(ui if parent == null else parent).add_child(node)
	return node

func new_layer():
	var layer = Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(layer)
	return layer

func clear_layer(layer):
	for child in layer.get_children():
		layer.remove_child(child)
		child.queue_free()

func box(rect: Rect2, color: Color, radius = 14, border = true):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	if border:
		style.border_color = Color('#936b48')
		style.set_border_width_all(2)
	draw_style_box(style,rect)

func paper_panel(rect: Rect2, tint = PAPER):
	box(Rect2(rect.position+Vector2(0,5),rect.size),Color(0.23,0.16,0.10,0.23),16,false)
	box(rect,tint)
	# Tiny irregular paper flecks keep the UI from feeling like a flat dashboard.
	for i in range(26):
		var p = rect.position+Vector2(10+fmod(i*71.31,rect.size.x-20),10+fmod(i*43.71,rect.size.y-20))
		draw_circle(p,0.8,Color(0.44,0.30,0.14,0.10))

func ellipse(center: Vector2, radii: Vector2, color: Color, outline = true, thickness = 2.5):
	var points = PackedVector2Array()
	for i in range(49):
		var angle = TAU*i/48.0
		points.append(center+Vector2(cos(angle)*radii.x,sin(angle)*radii.y))
	draw_colored_polygon(points,color)
	if outline:
		draw_polyline(points,INK,thickness,true)

func polygon(points, color, thickness = 3.0):
	var p = PackedVector2Array(points)
	draw_colored_polygon(p,color)
	p.append(p[0])
	draw_polyline(p,INK,thickness,true)

func capsule(start: Vector2, finish: Vector2, width: float, color: Color):
	draw_line(start,finish,INK,width+5,true)
	draw_circle(start,(width+5)/2.0,INK)
	draw_circle(finish,(width+5)/2.0,INK)
	draw_line(start,finish,color,width,true)
	draw_circle(start,width/2.0,color)
	draw_circle(finish,width/2.0,color)

func ink_text(words, pos: Vector2, font_size = 18, color = INK, fancy = false):
	draw_string(serif if fancy else body_font,pos,str(words),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func bottle(center: Vector2, color: Color, angle = 0.0, scale_factor = 1.0, corked = true, symbol = ''):
	draw_set_transform(center,angle,Vector2.ONE*scale_factor)
	polygon([Vector2(-13,-52),Vector2(13,-52),Vector2(13,-27),Vector2(32,-10),Vector2(37,14),Vector2(27,34),Vector2(-27,34),Vector2(-37,14),Vector2(-32,-10),Vector2(-13,-27)],Color('#e8ecd8'))
	ellipse(Vector2(0,9),Vector2(29,21),color,false)
	polygon([Vector2(-27,0),Vector2(27,0),Vector2(30,14),Vector2(22,29),Vector2(-22,29),Vector2(-30,14)],color,0.8)
	draw_line(Vector2(-23,-13),Vector2(-27,10),Color(1,1,0.91,0.75),5,true)
	draw_line(Vector2(19,15),Vector2(14,24),color.lightened(0.3),3,true)
	box(Rect2(-16,-29,32,14),Color('#b7c5b1'),3)
	if corked:
		box(Rect2(-15,-60,30,12),Color('#b89463'),4)
	if symbol != '':
		box(Rect2(-17,-2,34,24),Color('#fff0ca'),5)
		draw_symbol(Vector2(0,10),symbol,color.darkened(0.3),9)
	draw_set_transform(Vector2.ZERO)

func draw_symbol(center, kind, color, radius = 9.0):
	match kind:
		'moon':
			draw_circle(center,radius,color)
			draw_circle(center+Vector2(4,-3),radius*0.8,Color('#fff0ca'))
		'drop':
			polygon([center+Vector2(0,-radius),center+Vector2(radius*0.7,3),center+Vector2(0,radius),center+Vector2(-radius*0.7,3)],color,1)
		'leaf':
			ellipse(center,Vector2(radius,radius*0.6),color,false)
			draw_line(center-Vector2(radius,0),center+Vector2(radius,0),INK,1)
		'sun','flower':
			for i in range(6):
				var v = Vector2.from_angle(i*TAU/6)
				draw_circle(center+v*radius*0.65,radius*0.4,color)
			draw_circle(center,radius*0.4,GOLD)
		'flame':
			polygon([center+Vector2(0,-radius),center+Vector2(radius,4),center+Vector2(3,radius),center+Vector2(-radius,6)],color,1)

func cauldron(center: Vector2, color: Color, clock: float, filled: bool):
	ellipse(center+Vector2(0,102),Vector2(151,24),Color(0.24,0.16,0.10,0.2),false)
	capsule(center+Vector2(-72,75),center+Vector2(-86,103),15,Color('#486154'))
	capsule(center+Vector2(72,75),center+Vector2(86,103),15,Color('#486154'))
	ellipse(center+Vector2(-121,13),Vector2(24,29),Color('#69887c'))
	ellipse(center+Vector2(121,13),Vector2(24,29),Color('#69887c'))
	ellipse(center+Vector2(0,27),Vector2(126,78),Color('#547d70'))
	ellipse(center+Vector2(0,35),Vector2(109,58),Color('#618c79'),false)
	ellipse(center+Vector2(-66,33),Vector2(12,30),Color('#91ad88'),false)
	ellipse(center,Vector2(128,47),Color('#395a4e'))
	ellipse(center,Vector2(117,38),color if filled else Color('#9a9d83'))
	if filled:
		for i in range(4):
			var p = center+Vector2(sin(clock*1.3+i*1.9)*76,cos(clock+i)*20)
			var radius = 3+fmod(clock*8+i*3,9)
			draw_arc(p,radius,0,TAU,24,color.lightened(0.32),1.5,true)
		for i in range(3):
			var height = fmod(clock*26+i*43,103)
			var p = center+Vector2(-44+i*44+sin(clock*2+i)*7,-height-35)
			var steam = Color('#f9efd9')
			steam.a = (1-height/103.0)*0.55
			ellipse(p,Vector2(8+height*0.08,12+height*0.1),steam,false)
	draw_arc(center,127,0,PI,48,Color('#9cbc9e'),4,true)
	draw_symbol(center+Vector2(0,55),'moon',Color('#f0d58d'),15)

func patient_portrait(center: Vector2, kind, coat: Color, mask: int, clock: float, happy: bool):
	var lift = sin(clock*2)*8 if (mask & 4) != 0 else 0.0
	center.y -= lift
	ellipse(center+Vector2(0,86+lift),Vector2(66,10),Color(0.2,0.3,0.15,0.14),false)
	var body = coat
	if (mask & 8) != 0:
		body = Color('#a0aaa0')
	if (mask & 16) != 0:
		body.a = 0.24
	ellipse(center+Vector2(0,45),Vector2(54,47),body)
	if kind == 'rabbit':
		ellipse(center+Vector2(-25,-57),Vector2(16,49),body)
		ellipse(center+Vector2(25,-57),Vector2(16,49),body)
		ellipse(center+Vector2(-25,-59),Vector2(7,32),Color('#d89287'),false)
		ellipse(center+Vector2(25,-59),Vector2(7,32),Color('#d89287'),false)
	elif kind == 'hedgehog':
		for i in range(11):
			var a = PI+i*PI/10
			var p = center+Vector2(cos(a)*55,sin(a)*55)
			polygon([p+Vector2(-15,4),p+Vector2(0,-23),p+Vector2(15,4)],Color('#8b7155'),2)
	elif kind == 'moth':
		ellipse(center+Vector2(-54,28),Vector2(29,51),Color('#d4c4a8'))
		ellipse(center+Vector2(54,28),Vector2(29,51),Color('#d4c4a8'))
		capsule(center+Vector2(-14,-36),center+Vector2(-29,-72),4,INK)
		capsule(center+Vector2(14,-36),center+Vector2(29,-72),4,INK)
	elif kind == 'fox':
		polygon([center+Vector2(-53,-14),center+Vector2(-45,-75),center+Vector2(-10,-40)],body)
		polygon([center+Vector2(53,-14),center+Vector2(45,-75),center+Vector2(10,-40)],body)
	ellipse(center,Vector2(55,50),body)
	if kind == 'witch':
		polygon([center+Vector2(-49,-30),center+Vector2(-16,-104),center+Vector2(25,-58),center+Vector2(50,-30)],Color('#78927d'))
		ellipse(center+Vector2(0,-30),Vector2(72,13),Color('#78927d'))
	if kind == 'frog':
		ellipse(center+Vector2(-31,-30),Vector2(21,23),body)
		ellipse(center+Vector2(31,-30),Vector2(21,23),body)
	if (mask & 16) == 0 or happy:
		var eyey = -24 if kind == 'frog' else -5
		if happy:
			for x in [-22,22]:
				draw_arc(center+Vector2(x,eyey),7,PI,TAU,12,INK,3,true)
		else:
			for x in [-22,22]:
				ellipse(center+Vector2(x,eyey),Vector2(4,6),INK,false)
		ellipse(center+Vector2(-33,14),Vector2(9,5),Color('#d99080'),false)
		ellipse(center+Vector2(33,14),Vector2(9,5),Color('#d99080'),false)
		if happy:
			draw_arc(center+Vector2(0,15),13,0,PI,20,INK,2.5,true)
		else:
			draw_line(center+Vector2(-9,24),center+Vector2(9,24),INK,2,true)
	if (mask & 1) != 0:
		capsule(center+Vector2(-29,-25),center+Vector2(29,-25),8,Color('#e8937c'))
	if (mask & 2) != 0:
		for x in [-74,74]:
			var y = sin(clock*9)*5
			draw_polyline(PackedVector2Array([center+Vector2(x-3,y),center+Vector2(x+3,y+8),center+Vector2(x-3,y+16)]),Color('#6b9eaf'),2,true)
	if (mask & 32) != 0:
		for i in range(3):
			var y = fmod(clock*34+i*23,80)
			ellipse(center+Vector2(39+i*8,-y+12),Vector2(5,5),Color(0.85,0.79,0.86,0.7))
	if (mask & 64) != 0:
		for i in range(3):
			draw_symbol(center+Vector2(-40+i*39,-40-abs(i-1)*10),'flower',Color('#f0e8d3'),13)

func tone(hz = 440.0, duration = 0.12):
	if muted:
		return
	var samples = PackedByteArray()
	var count = int(22050*duration)
	samples.resize(count*2)
	for i in range(count):
		var envelope = minf(float(i)/160.0,1.0)*minf(float(count-i)/500.0,1.0)
		var wave = sin(TAU*hz*i/22050.0)+0.2*sin(TAU*hz*2*i/22050.0)
		samples.encode_s16(i*2,int(wave*10000*envelope))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = samples
	sound.stream = stream
	sound.play()

func _exit_tree():
	if sound:
		sound.stop()
		sound.stream = null
