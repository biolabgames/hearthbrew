extends "res://art.gd"

const Brewing = preload('res://brewing.gd')
const POT = Vector2(720,700)
const POUR_SECONDS = 6.0
const STIR_SECONDS = 7.0
const PATIENT_ORIGIN = Vector2(464,166)
var patient_sprites = preload('res://patient_sprites.gd').new()
var patient_reaction = 'neutral'
var patient_reaction_until = 0.0
var background: ImageTexture
var layer: Control
var status_label: Label
var phase_label: Label
var patient_index = 0
var symptoms = 0
var queue = []
var pinned = 0
var mixing = false
var animation_time = 0.0
var has_result = false
var result_recipe = -1
var result_color = Color('#efdeb3')
var batches = 0
var served = 0
var clinic_stars = 0
var awarded = false
var patient_stars = 0
var shift_complete = false
var speed = 1.0
var paused = false
var focused = true
var clock = 0.0
var last_sound_stage = -1
var message = 'Welcome in. Read Poppy\'s chart, then choose your ingredients from left to right.'
var message_good = true
var celebration = 0.0

func _ready():
	initialise_art()
	if not patient_sprites.load_people():
		push_error('Patient sprites: '+str(patient_sprites.errors))
	var image = Image.load_from_file(ProjectSettings.globalize_path('res://assets/apothecary.png'))
	if image and not image.is_empty():
		background = ImageTexture.create_from_image(image)
	layer = new_layer()
	load_patient(0)

func patient():
	return Brewing.PATIENTS[patient_index]

func can_edit():
	return not mixing and not has_result and symptoms != 0 and not shift_complete

func load_patient(index):
	patient_index = index
	symptoms = patient().mask
	queue.clear()
	mixing = false
	has_result = false
	result_recipe = -1
	result_color = Color('#efdeb3')
	batches = 0
	served = 0
	awarded = false
	patient_stars = 0
	shift_complete = false
	paused = false
	animation_time = 0
	patient_reaction = 'frown'
	patient_reaction_until = clock+2.4
	pinned = [0,1,2,3,4,7][patient_index]
	message = patient().hint if index < 2 else 'Read the chart. The journal contains a remedy for each symptom.'
	message_good = true
	refresh()

func add_ingredient(index):
	if not can_edit():
		return
	if queue.size() >= 4:
		say('The mixing flask holds at most four ingredients. Remove one before adding another.',false)
		return
	queue.append(index)
	tone(350+index*48,0.07)
	message = 'Added '+Brewing.INGREDIENTS[index].name+'. The order of the bottles matters.'
	message_good = true
	refresh()

func remove_ingredient(index):
	if not can_edit() or index < 0 or index >= queue.size():
		return
	queue.remove_at(index)
	refresh()
	tone(290,0.07)

func clear_queue():
	if not can_edit():
		return
	queue.clear()
	refresh()
	say('Mixing order cleared. A fresh start costs nothing.')

func pin_recipe(index):
	pinned = index
	refresh()
	if not mixing:
		tone(620,0.06)

func start_mix():
	if not can_edit() or queue.size() < 2:
		return
	mixing = true
	animation_time = 0.0
	last_sound_stage = -1
	batches += 1
	result_recipe = -1
	paused = false
	message = 'Pour each ingredient, then stir the mixture. Watch the colours change.'
	message_good = true
	refresh()

func pour_duration():
	return queue.size()*POUR_SECONDS

func mix_duration():
	return pour_duration()+STIR_SECONDS

func is_stirring():
	return mixing and animation_time >= pour_duration()

func finish_mix():
	if not mixing:
		return
	mixing = false
	has_result = true
	paused = false
	result_recipe = Brewing.resolve(queue)
	result_color = Color(Brewing.RECIPES[result_recipe].color) if result_recipe >= 0 else Color('#a89272')
	message = (Brewing.RECIPES[result_recipe].name+' is ready. Serve it, or set it aside.') if result_recipe >= 0 else 'A muddled brew. No recipe matches this exact order. Discard it, or risk a taste.'
	message_good = result_recipe >= 0
	tone(780 if result_recipe >= 0 else 240,0.18)
	refresh()

func discard():
	if not has_result or mixing:
		return
	has_result = false
	queue.clear()
	result_recipe = -1
	result_color = Color('#efdeb3')
	refresh()
	say('The flask is rinsed. Check the order in the journal before the next batch.')

func serve():
	if not has_result or mixing or symptoms == 0:
		return
	var outcome = Brewing.treat(symptoms,result_recipe,queue,patient().allergy)
	patient_reaction = 'smile' if outcome.good else 'frown'
	patient_reaction_until = clock+4.0
	symptoms = outcome.mask
	served += 1
	has_result = false
	queue.clear()
	result_recipe = -1
	if symptoms == 0:
		celebration = 3.0
		if not awarded:
			patient_stars = 3 if batches <= patient().minimum else (2 if batches == patient().minimum+1 else 1)
			clinic_stars += patient_stars
			awarded = true
		message = '%s feels better! %d stars, %d %s brewed. Another happy face at the door.' % [patient().name,patient_stars,batches,'batch' if batches == 1 else 'batches']
		message_good = true
		tone(880,0.24)
	else:
		message = outcome.message
		message_good = outcome.good
		tone(640 if outcome.good else 210,0.15)
	refresh()

func next_patient():
	if symptoms != 0:
		return
	if patient_index == Brewing.PATIENTS.size()-1:
		shift_complete = true
		message = 'A good day at the apothecary. Six neighbours helped. %d / 18 stars.' % clinic_stars
		message_good = true
		refresh()
	else:
		load_patient(patient_index+1)

func new_shift():
	clinic_stars = 0
	load_patient(0)

func restart_patient():
	if awarded:
		clinic_stars -= patient_stars
	load_patient(patient_index)

func hint():
	say(patient().hint)

func toggle_speed():
	speed = 2.0 if speed == 1.0 else 1.0
	refresh()

func toggle_mute():
	muted = not muted
	if muted:
		sound.stop()
	refresh()

func toggle_pause():
	if mixing:
		paused = not paused
		refresh()

func say(words, good = true):
	message = words
	message_good = good
	if status_label:
		status_label.text = message
		status_label.add_theme_color_override('font_color',DARK if good else Color('#a35843'))

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true

func _process(delta):
	clock += delta
	celebration = maxf(0,celebration-delta)
	if mixing and not paused and focused:
		animation_time += delta*speed
		var stage = int(animation_time/POUR_SECONDS)
		if stage != last_sound_stage and stage < queue.size():
			last_sound_stage = stage
			tone(300+queue[stage]*45,0.14)
		if animation_time >= mix_duration():
			finish_mix()
	if mixing and phase_label:
		var index = mini(int(animation_time/POUR_SECONDS),queue.size()-1)
		if paused or not focused:
			phase_label.text = 'PAUSED - P to resume'
		elif is_stirring():
			phase_label.text = 'Stirring the mixture'
		else:
			phase_label.text = 'Pour %d of %d  -  %s' % [index+1,queue.size(),Brewing.INGREDIENTS[queue[index]].name]
	queue_redraw()

func refresh():
	queue_redraw()
	clear_layer(layer)
	label_at('Hearthbrew',Vector2(46,23),Vector2(570,57),43,DARK,layer,true)
	status_label = label_at(message,Vector2(49,80),Vector2(880,37),14,DARK if message_good else Color('#a35843'),layer)
	label_at('Neighbour %d / 6\nClinic stars: %d / 18' % [patient_index+1,clinic_stars],Vector2(950,40),Vector2(225,58),18,DARK,layer)
	button_at('%dx speed' % int(speed),Vector2(1181,46),Vector2(108,39),toggle_speed,DARK,layer,15)
	button_at('Sound off' if muted else 'Sound on',Vector2(1301,46),Vector2(94,39),toggle_mute,SAGE,layer,14)
	# Journal and ingredient shelf remain within easy reach on the left.
	label_at('The remedy journal',Vector2(43,153),Vector2(272,36),24,DARK,layer,true)
	label_at('Pin a recipe to read its order and notes.',Vector2(44,191),Vector2(273,25),13,INK,layer)
	for i in range(Brewing.RECIPES.size()):
		var r = Brewing.RECIPES[i]
		var b = button_at(r.name,Vector2(42,220+i*28),Vector2(274,25),func(): pin_recipe(i),DARK if pinned == i else Color('#8d9f7c'),layer,15)
		b.tooltip_text = r.effect
	label_at('The bottle shelf',Vector2(44,491),Vector2(270,33),24,DARK,layer,true)
	label_at('Click to add. Keys 1-6 also work.',Vector2(44,525),Vector2(270,24),14,INK,layer)
	for i in range(Brewing.INGREDIENTS.size()):
		var pos = Vector2(42+(i%2)*142,557+int(i/2)*102)
		var b = button_at('',pos,Vector2(132,94),func(): add_ingredient(i),Color(0.48,0.56,0.39,0.03),layer)
		b.disabled = not can_edit()
		var disabled_style = b.get_theme_stylebox('disabled').duplicate()
		disabled_style.bg_color = Color(0.5,0.45,0.3,0.08)
		b.add_theme_stylebox_override('disabled',disabled_style)
		b.tooltip_text = Brewing.INGREDIENTS[i].description
		label_at('%d. %s' % [i+1,Brewing.INGREDIENTS[i].short],pos+Vector2(7,68),Vector2(120,23),14,INK,layer)
	# A single clipboard contains the chart, pinned recipe and mixing order.
	label_at('PATIENT %02d / CLINIC CHART' % (patient_index+1),Vector2(1127,155),Vector2(267,21),12,DARK,layer)
	label_at(patient().name,Vector2(1127,178),Vector2(267,36),28,DARK,layer,true)
	label_at(patient().job,Vector2(1127,217),Vector2(267,28),14,INK,layer)
	label_at('Symptoms',Vector2(1127,251),Vector2(267,27),18,DARK,layer,true)
	var symptom_text = ', '.join(Brewing.symptom_names(symptoms)) if symptoms != 0 else 'Feeling wonderful!  %d / 3 stars' % patient_stars
	label_at(symptom_text,Vector2(1127,281),Vector2(267,55),16,Color('#a35843') if symptoms != 0 else DARK,layer)
	label_at('Allergy: '+Brewing.INGREDIENTS[patient().allergy].name if patient().allergy >= 0 else 'No known ingredient allergies.',Vector2(1127,340),Vector2(267,32),13,Color('#a35843') if patient().allergy >= 0 else DARK,layer)
	label_at('"'+patient().story+'"',Vector2(1127,377),Vector2(267,67),14,INK,layer)
	label_at('Batches: %d   Treatments: %d' % [batches,served],Vector2(1127,450),Vector2(267,22),13,INK,layer)
	button_at('A little guidance',Vector2(1127,479),Vector2(267,32),hint,SAGE,layer,15)
	var reset = button_at('Restart this patient',Vector2(1127,520),Vector2(267,29),restart_patient,Color('#a58c6c'),layer,14)
	reset.disabled = mixing
	var recipe = Brewing.RECIPES[pinned]
	label_at(recipe.effect.to_upper(),Vector2(1127,578),Vector2(267,21),11,DARK,layer)
	label_at(recipe.name,Vector2(1127,601),Vector2(267,31),22,DARK,layer,true)
	label_at(recipe.note,Vector2(1127,636),Vector2(267,70),14,INK,layer)
	label_at('Mixing order',Vector2(1127,715),Vector2(158,28),19,DARK,layer,true)
	label_at('2-4 pours',Vector2(1297,720),Vector2(97,21),12,INK,layer)
	for i in range(4):
		var pos = Vector2(1127+(i%2)*139,747+int(i/2)*40)
		var words = '%d. %s' % [i+1,Brewing.INGREDIENTS[queue[i]].short] if i < queue.size() else '%d. empty' % (i+1)
		var b = button_at(words,pos,Vector2(128,34),func(): remove_ingredient(i),Color('#758f76') if i < queue.size() else Color('#b5b69a'),layer,14)
		b.disabled = not can_edit() or i >= queue.size()
	if mixing:
		button_at('Resume' if paused else 'Pause',Vector2(1127,842),Vector2(98,32),toggle_pause,DARK,layer,14)
		button_at('Finish animation',Vector2(1233,842),Vector2(161,32),finish_mix,SAGE,layer,14)
	elif has_result:
		button_at('Serve '+patient().name,Vector2(1127,842),Vector2(166,32),serve,DARK,layer,15)
		button_at('Discard brew',Vector2(1301,842),Vector2(93,32),discard,ROSE,layer,12)
	elif symptoms == 0:
		button_at('Start a new shift' if shift_complete else ('Finish the day' if patient_index == 5 else 'Next neighbour'),Vector2(1127,842),Vector2(267,32),new_shift if shift_complete else next_patient,DARK,layer,15)
	else:
		var brew = button_at('Brew mixture',Vector2(1127,842),Vector2(166,32),start_mix,DARK,layer,17)
		brew.disabled = queue.size() < 2
		var clear = button_at('Clear order',Vector2(1301,842),Vector2(93,32),clear_queue,SAGE,layer,13)
		clear.disabled = queue.is_empty()
	phase_label = label_at('',Vector2(589,848),Vector2(288,27),16,PAPER,layer)
	if not mixing:
		phase_label.text = (Brewing.RECIPES[result_recipe].name if result_recipe >= 0 else 'Muddled brew') if has_result else ('All better. A warm goodbye.' if symptoms == 0 else 'The kettle is waiting.')
	label_at('Enter: brew / serve    P: pause    M: sound',Vector2(581,878),Vector2(350,18),12,Color('#473828'),layer)


func current_liquid():
	if has_result or symptoms == 0:
		return result_color
	var color = Color('#efdeb3')
	if not mixing:
		return color
	if is_stirring():
		var recipe = Brewing.resolve(queue)
		return Color(Brewing.RECIPES[recipe].color) if recipe >= 0 else Color('#a89272')
	var index = mini(int(animation_time/POUR_SECONDS),queue.size()-1)
	var t = fmod(animation_time,POUR_SECONDS)/POUR_SECONDS
	for i in range(index):
		color = color.lerp(Color(Brewing.INGREDIENTS[queue[i]].color),0.63)
	color = color.lerp(Color(Brewing.INGREDIENTS[queue[index]].color),0.63*clampf((t-24.0/72.0)/(18.0/72.0),0,1))
	if index == queue.size()-1 and t > 0.65:
		var recipe = Brewing.resolve(queue)
		var final_color = Color(Brewing.RECIPES[recipe].color) if recipe >= 0 else Color('#a89272')
		color = color.lerp(final_color,(t-0.65)/0.35)
	return color

func patient_expression():
	if symptoms == 0:
		return 'smile'
	if clock < patient_reaction_until:
		return patient_reaction
	if has_result:
		return 'smile'
	var phase = fposmod(clock+patient_index*1.37,10.5)
	if mixing:
		return 'smile' if phase < 1.5 else ('frown' if phase > 8.8 else 'neutral')
	return 'frown' if phase < 3.5 else 'neutral'

func paint_counter_patient():
	var origin = PATIENT_ORIGIN
	if (symptoms & Brewing.FLOATING) != 0:
		origin.y -= 8+sin(clock*1.5)*6
	var tint = Color.WHITE
	if (symptoms & Brewing.STONE) != 0:
		tint = Color('#a9b4a6')
	if (symptoms & Brewing.INVISIBLE) != 0:
		tint.a = 0.62
	patient_sprites.draw_person(self,patient_index,clock,patient_expression(),origin,tint)
	if (symptoms & Brewing.HICCUPS) != 0:
		for i in range(3):
			var rise = fposmod(clock*24+i*33,104)
			draw_arc(origin+Vector2(342+sin(clock+i)*9,204-rise),5+i,0,TAU,18,Color(0.9,0.85,0.98,0.65),1.5,true)
	if (symptoms & Brewing.BLOOM) != 0:
		for i in range(4):
			draw_symbol(origin+Vector2(160+i*58,108+sin(i*2.0)*25),'flower',Color('#efc28e'),7)
	# The patient stands on the far side of this counter edge. Only the
	# waist is occluded; their face and shoulders remain unobstructed.
	draw_rect(Rect2(356,534,750,24),Color('#c79962'))
	draw_line(Vector2(356,534),Vector2(1106,534),Color('#946b42'),3)
	draw_line(Vector2(356,557),Vector2(1106,557),Color('#e4bc7e'),2)

func _draw():
	if background:
		draw_texture_rect(background,Rect2(0,0,1440,900),false)
	else:
		draw_rect(Rect2(0,0,1440,900),Color('#d6c48c'))
	draw_rect(Rect2(0,0,1440,900),Color(1,0.93,0.75,0.04))
	paint_counter_patient()
	paper_panel(Rect2(24,18,1392,104),Color('#fff1d8'))
	paper_panel(Rect2(24,141,310,319))
	paper_panel(Rect2(24,478,310,396))
	paper_panel(Rect2(1106,142,310,732))
	box(Rect2(1219,134,86,16),Color('#9b8c60'),4)
	draw_line(Vector2(1127,565),Vector2(1394,565),Color('#cbb18b'),1)
	draw_line(Vector2(1127,711),Vector2(1394,711),Color('#cbb18b'),1)
	for i in range(6):
		var p = Vector2(108+(i%2)*142,602+int(i/2)*102)
		bottle(p,Color(Brewing.INGREDIENTS[i].color),0,0.57,true,Brewing.INGREDIENTS[i].symbol)
	var color = current_liquid()
	cauldron(POT,color,clock,mixing or has_result or symptoms == 0)
	paint_mixing_hands(color)
	# A wooden frame gives the filmed camera crop a visible stage boundary.
	# It masks the original frame exits without extending the painted limbs.
	draw_rect(Rect2(1068,564,38,274),Color('#c69a62'))
	draw_line(Vector2(1068,564),Vector2(1068,838),Color('#946b42'),3)
	draw_rect(Rect2(356,838,750,62),Color('#dfb47d'))
	draw_line(Vector2(356,838),Vector2(1106,838),Color('#946b42'),3)
	box(Rect2(572,842,312,36),Color('#526e5d'),13)
	if celebration > 0:
		for i in range(22):
			var t = 3.0-celebration
			var pos = Vector2(720+sin(i*2.31)*t*49,320-cos(i*1.73)*t*43-t*27)
			draw_symbol(pos,'flower',Color('#efcd79') if i%2 == 0 else Color('#d99b95'),4)
	if shift_complete:
		paper_panel(Rect2(427,591,585,135),Color('#fdf0cd'))
		ink_text('A good day at Hearthbrew',Vector2(466,642),31,DARK,true)
		ink_text('Six neighbours helped. %d / 18 stars.' % clinic_stars,Vector2(490,689),23,DARK)

func paint_mixing_hands(_color):
	# Each atlas frame contains the entire hand, forearm and held prop.
	# Native pixels at one fixed origin; no scaling, rotation or limb rig.
	var pouring = mixing and not is_stirring()
	var seconds = fmod(animation_time,POUR_SECONDS) if pouring else 0.0
	rotoscope.draw_frame(self,'pour' if pouring else 'idle',seconds,Vector2(430,628))
	var right_seconds = animation_time-pour_duration() if is_stirring() else 0.0
	rotoscope.draw_frame(self,'stir' if is_stirring() else 'idle_right',right_seconds,Vector2(604,568))

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			add_ingredient(event.keycode-KEY_1)
		elif event.keycode == KEY_BACKSPACE:
			remove_ingredient(queue.size()-1)
		elif event.keycode == KEY_ENTER:
			if has_result:
				serve()
			else:
				start_mix()
		elif event.keycode == KEY_P:
			toggle_pause()
		elif event.keycode == KEY_M:
			toggle_mute()


