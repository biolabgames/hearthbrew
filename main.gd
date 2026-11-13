extends Control

const DARK = Color("#355d4c")
const SOUND_CUES = {
	"350_70": preload("res://assets/audio/350_70.wav"),
	"398_70": preload("res://assets/audio/398_70.wav"),
	"446_70": preload("res://assets/audio/446_70.wav"),
	"494_70": preload("res://assets/audio/494_70.wav"),
	"542_70": preload("res://assets/audio/542_70.wav"),
	"590_70": preload("res://assets/audio/590_70.wav"),
	"300_140": preload("res://assets/audio/300_140.wav"),
	"345_140": preload("res://assets/audio/345_140.wav"),
	"390_140": preload("res://assets/audio/390_140.wav"),
	"435_140": preload("res://assets/audio/435_140.wav"),
	"480_140": preload("res://assets/audio/480_140.wav"),
	"525_140": preload("res://assets/audio/525_140.wav"),
	"290_70": preload("res://assets/audio/290_70.wav"),
	"620_60": preload("res://assets/audio/620_60.wav"),
	"780_180": preload("res://assets/audio/780_180.wav"),
	"240_180": preload("res://assets/audio/240_180.wav"),
	"880_240": preload("res://assets/audio/880_240.wav"),
	"640_150": preload("res://assets/audio/640_150.wav"),
	"210_150": preload("res://assets/audio/210_150.wav")
}
var muted = false
@onready var sound: AudioStreamPlayer = $Sound
@onready var stage = $Stage
var rotoscope = preload("res://rotoscope_player.gd").new()

const Brewing = preload('res://brewing.gd')
const POUR_SECONDS = 6.0
const STIR_SECONDS = 7.0
@onready var patient_sprites = $Stage/Patients
var patient_reaction = 'neutral'
var patient_reaction_until = 0.0
const PATIENT_REACTION_SECONDS = 4.0
var layer: Control
var status_label: Label
var phase_label: Label
var patient_index = 0
var symptoms = 0
var queue = []
var table_stock = []
var table_empty = []
var pouring = false
var poured_count = 0
var active_table_slot = -1
var supplies
var campaign
var pinned = 0
var mixing = false
var animation_time = 0.0
var has_result = false
var result_recipe = -1
var result_blend = -1
var stored_blends = []
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
	Brewing.prepare_catalog()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotoscope.load_manifest()
	patient_sprites.load_people()
	layer = $Interface
	status_label = $Interface/Header/Status
	phase_label = $Interface/PhaseDisplay/Phase
	layer.action_requested.connect(_on_interface_action)
	$Interface/BowlInteraction.gui_input.connect(_on_bowl_input)
	supplies = preload('res://scripts/supplies.gd').new()
	layer.add_child(supplies)
	supplies.setup(self)
	$Interface/Journal.hide()
	$Interface/Shelf.hide()
	$Stage/Bottles.hide()
	load_patient(0)
	campaign = preload('res://scripts/campaign.gd').new()
	layer.add_child(campaign)
	campaign.setup(self)

func _on_interface_action(action: String, index: int):
	match action:
		'primary':
			if has_result:
				serve()
		'secondary':
			if has_result:
				discard()
			else:
				clear_queue()
		'advance':
			if shift_complete:
				new_shift()
			else:
				next_patient()
		'pin_recipe', 'add_ingredient', 'remove_ingredient':
			call(action,index)
		_:
			call(action)

func update_presentation():
	if is_node_ready():
		stage.update_state(self)

func patient():
	if campaign and campaign.active:
		return campaign.patient_record()
	return Brewing.PATIENTS[patient_index]

func visible_symptoms():
	return symptoms if not campaign or not campaign.active else symptoms & campaign.known_mask

func can_edit():
	return not mixing and not pouring and not has_result and symptoms != 0 and not shift_complete

func sync_table_bottles():
	while table_empty.size() < table_stock.size():
		table_empty.append(false)
	table_empty.resize(table_stock.size())

func pour_bottle(slot):
	sync_table_bottles()
	if slot < 0 or slot >= table_stock.size() or table_empty[slot]:
		return
	pour_ingredient(table_stock[slot],slot)

func pour_ingredient(index, slot = -1):
	if not can_edit():
		return
	if queue.size() >= 4:
		say('The kettle holds at most four ingredients. Stir this mixture or clear it before pouring more.',false)
		return
	sync_table_bottles()
	if slot >= 0 and (slot >= table_stock.size() or table_stock[slot] != index or table_empty[slot]): return
	if slot < 0:
		for i in range(table_stock.size()):
			if table_stock[i] == index and not table_empty[i]:
				slot = i
				break
	if slot < 0 and not stored_blends.has(index):
		say('Fetch a full bottle of '+Brewing.INGREDIENTS[index].name+' from the pantry.',false)
		return
	if index < Brewing.BASE_INGREDIENT_COUNT and campaign and campaign.active and int(campaign.herbs.inventory[index]) < 1:
		say('No '+Brewing.INGREDIENTS[index].name+' left. Prepare more in the garden or request emergency supplies in the pantry.',false)
		return
	var previous_count = queue.size()
	add_ingredient(index)
	if queue.size() == previous_count:
		return
	if index < Brewing.BASE_INGREDIENT_COUNT and campaign and campaign.active:
		campaign.herbs.use_bottle(index)
	pouring = true
	active_table_slot = slot
	animation_time = previous_count*POUR_SECONDS
	last_sound_stage = -1
	paused = false
	message = 'Pouring '+Brewing.INGREDIENTS[index].name+' into the kettle.'
	refresh()
	if campaign and campaign.active: campaign.save_game()

func finish_pour():
	if not pouring:
		return
	if active_table_slot >= 0 and active_table_slot < table_empty.size():
		table_empty[active_table_slot] = true
	poured_count = queue.size()
	animation_time = pour_duration()
	pouring = false
	active_table_slot = -1
	paused = false
	message = 'Pour complete. Click another full bottle, or click the bowl to mix.' if queue.size() >= 2 else 'Pour complete. Click the next bottle in your recipe.'
	refresh()

func is_pouring():
	return pouring or (mixing and not is_stirring())

func load_patient(index):
	if campaign:
		campaign.speech_dismissed = false
		campaign.herbs.finish = ''
	patient_index = index
	symptoms = patient().mask
	queue.clear()
	table_stock.clear()
	table_empty.clear()
	pouring = false
	poured_count = 0
	active_table_slot = -1
	stored_blends.clear()
	result_blend = -1
	if supplies:
		supplies.close()
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
	pinned = [0,1,2,3,4,7][patient_index] if patient_index < 6 else int(patient().treatments[0])
	message = 'Read the chart, find a remedy in the recipe book, then fetch its bottles from the pantry.'
	message_good = true
	refresh()

func add_ingredient(index):
	if not can_edit():
		return
	if not table_stock.has(index) and not stored_blends.has(index):
		say('Fetch '+Brewing.INGREDIENTS[index].name+' from the pantry first.',false)
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
	poured_count = mini(poured_count,queue.size())
	refresh()
	tone(290,0.07)

func clear_queue():
	if not can_edit():
		return
	queue.clear()
	poured_count = 0
	refresh()
	say('Mixing order cleared. Poured ingredients have been used.' if campaign and campaign.active else 'Mixing order cleared. A fresh start costs nothing.')

func pin_recipe(index):
	if campaign and not campaign.recipe_available(index):
		say('Compound remedies arrive on day two. Today’s patients can all be helped with the twelve single-mixture recipes.',false)
		return
	pinned = index
	refresh()
	if not mixing:
		tone(620,0.06)

func _on_bowl_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not supplies.modal.visible:
		start_mix()

func can_stir():
	return can_edit() and queue.size() >= 2 and poured_count == queue.size()

func start_mix():
	if not can_edit() or queue.size() < 2:
		return
	if poured_count != queue.size():
		say('Pour the selected bottles first, then click the bowl to mix.',false)
		return
	if campaign and campaign.active:
		campaign.batch_strength = campaign.strength
	mixing = true
	animation_time = poured_count*POUR_SECONDS
	last_sound_stage = -1
	batches += 1
	result_recipe = -1
	result_blend = -1
	paused = false
	message = 'Stirring the poured ingredients.' if is_stirring() else 'Pour each ingredient, then stir the mixture. Watch the colours change.'
	message_good = true
	refresh()

func pour_duration():
	return queue.size()*POUR_SECONDS

func mix_duration():
	return pour_duration()+STIR_SECONDS

func is_stirring():
	return mixing and animation_time >= pour_duration()

func finish_mix():
	if pouring:
		finish_pour()
		return
	if not mixing:
		return
	sync_table_bottles()
	for ingredient in queue.slice(poured_count):
		for slot in range(table_stock.size()):
			if table_stock[slot] == ingredient and not table_empty[slot]:
				table_empty[slot] = true
				break
	poured_count = queue.size()
	mixing = false
	has_result = true
	paused = false
	result_recipe = Brewing.resolve(queue)
	result_blend = Brewing.resolve_blend(queue) if result_recipe < 0 else -1
	result_color = Color(Brewing.RECIPES[result_recipe].color) if result_recipe >= 0 else Color('#a89272')
	if result_blend >= 0:
		result_color = Color(Brewing.INGREDIENTS[result_blend].color)
	message = (Brewing.RECIPES[result_recipe].name+' is ready. Serve it, or set it aside.') if result_recipe >= 0 else 'A muddled brew. No recipe matches this exact order. Discard it, or risk a taste.'
	if result_blend >= 0:
		message = Brewing.INGREDIENTS[result_blend].name+' is ready. Bottle it, then prepare the other blend.'
	message_good = result_recipe >= 0 or result_blend >= 0
	tone(780 if result_recipe >= 0 else 240,0.18)
	refresh()

func discard():
	if not has_result or mixing:
		return
	if campaign:
		campaign.herbs.finish = ''
	has_result = false
	queue.clear()
	poured_count = 0
	result_recipe = -1
	result_blend = -1
	result_color = Color('#efdeb3')
	refresh()
	say('The flask is rinsed. Check the order in the journal before the next batch.')

func serve():
	if not has_result or mixing or symptoms == 0:
		return
	if result_blend >= 0:
		if not stored_blends.has(result_blend):
			stored_blends.append(result_blend)
		message = Brewing.INGREDIENTS[result_blend].name+' bottled. Prepare the next blend, or pour the saved blends in recipe order.'
		queue.clear()
		poured_count = 0
		has_result = false
		result_blend = -1
		refresh()
		return
	if campaign and campaign.active and not campaign.before_serve():
		return
	var previous_mask = symptoms
	var outcome = Brewing.treat(symptoms,result_recipe,queue,patient().allergy)
	if campaign and campaign.active:
		outcome = campaign.apply_botanical(outcome)
		campaign.consume_botanical(previous_mask,int(outcome.mask))
	for ingredient in queue:
		stored_blends.erase(ingredient)
	patient_reaction = ('delighted' if outcome.mask == 0 else 'smile') if outcome.good else 'disgust'
	patient_reaction_until = clock+PATIENT_REACTION_SECONDS
	symptoms = outcome.mask
	served += 1
	has_result = false
	queue.clear()
	poured_count = 0
	result_recipe = -1
	if symptoms == 0:
		celebration = 3.0
		if not awarded:
			var minimum = int(patient().minimum)
			for treatment in patient().get('treatments',[]):
				minimum += Brewing.RECIPES[treatment].get('stages',[]).size()
			patient_stars = 3 if batches <= minimum else (2 if batches == minimum+1 else 1)
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
	if campaign and campaign.active:
		campaign.after_treatment(previous_mask)

func next_patient():
	if campaign and campaign.active:
		campaign.advance()
		return
	if symptoms != 0:
		return
	if patient_index == Brewing.PATIENTS.size()-1:
		shift_complete = true
		message = 'A good day at the apothecary. %d neighbours helped. %d / %d stars.' % [Brewing.PATIENTS.size(),clinic_stars,Brewing.PATIENTS.size()*3]
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
	if campaign and campaign.active:
		campaign.begin_case()

func hint():
	if campaign and campaign.active:
		campaign.open_casebook()
		return
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
	if mixing or pouring:
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
		if campaign and campaign.active:
			campaign.save_game()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true

func _process(delta):
	if campaign and campaign.modal and campaign.modal.visible:
		return
	clock += delta
	celebration = maxf(0,celebration-delta)
	if (mixing or pouring) and not paused and focused:
		animation_time += delta*speed
		var stage = int(animation_time/POUR_SECONDS)
		if stage != last_sound_stage and stage < queue.size():
			last_sound_stage = stage
			tone(300+queue[stage]*45,0.14)
		if pouring and animation_time >= pour_duration():
			finish_pour()
		elif mixing and animation_time >= mix_duration():
			finish_mix()
	if (mixing or pouring) and phase_label:
		var index = mini(int(animation_time/POUR_SECONDS),queue.size()-1)
		if paused or not focused:
			phase_label.text = 'PAUSED - P to resume'
		elif is_stirring():
			phase_label.text = 'Stirring the mixture'
		else:
			phase_label.text = 'Pour %d of %d  -  %s' % [index+1,queue.size(),Brewing.INGREDIENTS[queue[index]].name]
	update_presentation()

func refresh():
	status_label.text = message
	status_label.add_theme_color_override('font_color',DARK if message_good else Color('#a35843'))
	$Interface/Header/Progress.text = 'Neighbour %d / %d\nClinic stars: %d / %d' % [patient_index+1,Brewing.PATIENTS.size(),clinic_stars,Brewing.PATIENTS.size()*3]
	$Interface/Header/Speed.text = '%dx speed' % int(speed)
	$Interface/Header/Sound.text = 'Sound off' if muted else 'Sound on'
	for i in range(8):
		var button = $Interface/Journal.get_node('Recipe'+str(i))
		button.text = Brewing.RECIPES[i].name
		button.tooltip_text = Brewing.RECIPES[i].effect
		button.set_pressed_no_signal(pinned == i)
	for i in range(6):
		$Interface/Shelf.get_node('Ingredient'+str(i)).disabled = not can_edit()
		$Interface/Shelf.get_node('Ingredient'+str(i)).tooltip_text = Brewing.INGREDIENTS[i].description
		$Interface/Shelf.get_node('IngredientName'+str(i)).text = '%d. %s' % [i+1,Brewing.INGREDIENTS[i].short]
	var chart = $Interface/Clipboard
	chart.get_node('ChartNumber').text = 'PATIENT %02d / CLINIC CHART' % (patient_index+1)
	chart.get_node('PatientName').text = patient().name
	chart.get_node('PatientJob').text = patient().job
	chart.get_node('Symptoms').text = ', '.join(Brewing.symptom_names(symptoms)) if symptoms != 0 else 'Feeling wonderful!  %d / 3 stars' % patient_stars
	chart.get_node('Symptoms').add_theme_color_override('font_color',Color('#a35843') if symptoms != 0 else DARK)
	chart.get_node('Allergy').text = 'Allergy: '+Brewing.INGREDIENTS[patient().allergy].name if patient().allergy >= 0 else 'No known ingredient allergies.'
	chart.get_node('Allergy').add_theme_color_override('font_color',Color('#a35843') if patient().allergy >= 0 else DARK)
	chart.get_node('Story').text = '"'+patient().story+'"'
	chart.get_node('TreatmentCount').text = 'Batches: %d   Treatments: %d' % [batches,served]
	chart.get_node('Restart').disabled = mixing or pouring
	var recipe = Brewing.RECIPES[pinned]
	chart.get_node('RecipeEffect').text = recipe.effect.to_upper()
	chart.get_node('RecipeName').text = recipe.name
	chart.get_node('RecipeNote').text = recipe.note
	for i in range(4):
		var slot = chart.get_node('Slot'+str(i))
		slot.text = '%d. %s' % [i+1,Brewing.INGREDIENTS[queue[i]].short] if i < queue.size() else '%d. empty' % (i+1)
		slot.disabled = not can_edit() or i >= queue.size()
		slot.set_pressed_no_signal(i < queue.size())
	chart.get_node('Primary').visible = has_result and not mixing and not pouring and symptoms != 0
	$Interface/BowlInteraction.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_stir() else Control.CURSOR_ARROW
	$Interface/BowlInteraction.tooltip_text = 'Click the bowl to mix.' if can_stir() else 'Pour at least two ingredients, then click the bowl to mix.'
	chart.get_node('Secondary').visible = not mixing and not pouring and symptoms != 0
	chart.get_node('Pause').visible = mixing or pouring
	chart.get_node('Finish').visible = mixing or pouring
	chart.get_node('Next').visible = not mixing and symptoms == 0
	chart.get_node('Pause').text = 'Resume' if paused else 'Pause'
	chart.get_node('Primary').text = ('Bottle blend' if result_blend >= 0 else 'Serve '+patient().name) if has_result else 'Stir mixture'
	chart.get_node('Primary').disabled = not has_result and (queue.size() < 2 or poured_count != queue.size())
	chart.get_node('Secondary').text = 'Discard brew' if has_result else 'Clear order'
	chart.get_node('Secondary').disabled = not has_result and queue.is_empty()
	chart.get_node('Next').text = 'Start a new shift' if shift_complete else ('Finish the day' if patient_index == Brewing.PATIENTS.size()-1 else 'Next neighbour')
	if not mixing and not pouring:
		phase_label.text = (Brewing.INGREDIENTS[result_blend].name if result_blend >= 0 else (Brewing.RECIPES[result_recipe].name if result_recipe >= 0 else 'Muddled brew')) if has_result else ('All better. A warm goodbye.' if symptoms == 0 else 'The kettle is waiting.')
		if not has_result and poured_count > 0:
			phase_label.text = 'Click the bowl to mix.' if can_stir() else 'Choose the next bottle.'
	if supplies:
		supplies.refresh()
	if campaign:
		campaign.refresh()
	update_presentation()


func current_liquid():
	if has_result or symptoms == 0:
		return result_color
	var color = Color('#efdeb3')
	if not mixing and not pouring:
		for ingredient in queue.slice(0,poured_count):
			color = color.lerp(Color(Brewing.INGREDIENTS[ingredient].color),0.63)
		return color
	if is_stirring():
		return Brewing.finished_color(queue)
	var index = mini(int(animation_time/POUR_SECONDS),queue.size()-1)
	var t = fmod(animation_time,POUR_SECONDS)/POUR_SECONDS
	for i in range(index):
		color = color.lerp(Color(Brewing.INGREDIENTS[queue[i]].color),0.63)
	color = color.lerp(Color(Brewing.INGREDIENTS[queue[index]].color),0.63*clampf((t-24.0/72.0)/(18.0/72.0),0,1))
	if mixing and index == queue.size()-1 and t > 0.65:
		var final_color = Brewing.finished_color(queue)
		color = color.lerp(final_color,(t-0.65)/0.35)
	return color

func patient_expression():
	if clock < patient_reaction_until:
		return patient_reaction
	if symptoms == 0:
		return 'smile'
	if has_result:
		return 'smile'
	var phase = fposmod(clock+patient_index*1.37,10.5)
	if mixing:
		return 'smile' if phase < 1.5 else ('frown' if phase > 8.8 else 'neutral')
	return 'frown' if phase < 3.5 else 'neutral'

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if campaign and campaign.modal.visible:
			if event.keycode == KEY_ESCAPE:
				campaign.close()
			get_viewport().set_input_as_handled()
			return
		if supplies.modal.visible:
			if event.keycode == KEY_ESCAPE:
				supplies.close()
			return
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			var slot_index = event.keycode-KEY_1
			if slot_index < table_stock.size():
				pour_bottle(slot_index)
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



func tone(hz = 440.0, duration = 0.12):
	if muted:
		return
	var key = '%d_%d' % [int(hz),roundi(duration*1000)]
	sound.stream = SOUND_CUES.get(key)
	if sound.stream:
		sound.play()

func _exit_tree():
	if campaign and campaign.active:
		campaign.save_game()
	if sound:
		sound.stop()
