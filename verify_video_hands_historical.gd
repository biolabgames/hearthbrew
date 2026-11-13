extends SceneTree

const Brewing = preload('res://brewing.gd')
var game
var failures = []
var checks = 0

func _initialize():
	call_deferred('run')

func check(condition, explanation):
	checks += 1
	if not condition:
		failures.append(explanation)
		printerr('FAIL: '+explanation)

func run():
	game = load('res://main.tscn').instantiate()
	root.add_child(game)
	game.muted = true
	await process_frame
	var args = OS.get_cmdline_user_args()
	if '--capture' in args:
		game.set_process(false)
		var mode = args[args.find('--phase')+1] if '--phase' in args else 'idle'
		if mode in ['book','pantry','table','clickpour','empty']:
			game.supplies.open('pantry')
			var collected = [6,2,0,3,11,5] if '--full-table' in args else ([0,2,0] if mode == 'pantry' else [0,2])
			for ingredient in collected:
				game.supplies.collect_bottle(ingredient)
			if mode in ['table','clickpour','empty']:
				game.supplies.bring_to_table()
				if mode == 'clickpour':
					game.pour_bottle(0)
					game.animation_time = game.POUR_SECONDS*0.46
					game.focused = true
					game._process(0.0)
				elif mode == 'empty':
					for slot in range(2):
						game.pour_bottle(slot)
						game.finish_pour()
			elif mode == 'book':
				if '--recipe' in args:
					game.pin_recipe(int(args[args.find('--recipe')+1]))
				game.supplies.open('book')
		if mode in ['reach','pour','stir','lift','result','cured']:
			for ingredient in [0,2]:
				stock_and_add(ingredient)
			game.start_mix()
			var poses = {'reach':0.16,'pour':0.46,'stir':0.76,'lift':0.94}
			game.animation_time = poses.get(mode,0.76)*game.POUR_SECONDS
			if mode == 'stir':
				game.animation_time = game.pour_duration()+game.STIR_SECONDS*0.4
			game.clock = 0.53
			game.phase_label.text = {'reach':'Lifting the flask','pour':'Pour 1 of 2 - Moonmilk','lift':'Returning the jar'}.get(mode,'Following the filmed hand movement')
			if mode in ['result','cured']:
				game.finish_mix()
			if mode == 'cured':
				game.serve()
		game.update_presentation()
		await process_frame
		await process_frame
		var image = root.get_texture().get_image()
		var target = args[args.find('--capture')+1]
		check(image != null and not image.is_empty(),'Rendered viewport contains pixels')
		if image:
			check(image.save_png(target) == OK,'Screenshot saves')
		print('CAPTURE: '+target)
	else:
		test_sprite_playback()
		test_user_video_sources()
		test_people()
		test_stir_timeline()
		test_rules()
		test_staged_recipes()
		test_supplies()
		test_click_pours()
		test_hand_choreography()
		test_controls()
		test_shift()
		test_mistakes()
		test_native_scenes()
		await process_frame
		for node in game.layer.find_children("*", "Control", true, false):
			if (node is Label or node is Button) and node.is_visible_in_tree() and not game.supplies.is_ancestor_of(node):
				check(node.position.x >= 0 and node.position.y >= 0 and node.position.x+node.size.x <= 1441 and node.position.y+node.size.y <= 901,'UI stays within the 1440 x 900 viewport')
	print('HEARTHBREW: %d checks, %d failures' % [checks,failures.size()])
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

func test_sprite_playback():
	var player = game.rotoscope
	check(player.errors.is_empty(),'Reference-based sprite manifest loads: '+str(player.errors))
	check(player.clips.has('pour') and player.clips.has('idle'),'Filmed pour and rest clips exist')
	check(player.clips.has('stir') and player.clips.has('idle_right'),'Filmed right-hand stirring and rest clips exist')
	check(not player.clips.has('serve'),'Unfilmed serving is not substituted with synthetic motion')
	check(player.frame_index('pour',0) == 0,'Pour starts at recorded frame zero')
	check(player.frame_index('pour',1.0) == 12,'Pour advances at twelve recorded frames per second')
	check(player.frame_index('pour',100) == 71,'Non-looping pour holds its last frame')
	check(player.frame_index('idle',0.5) == 0,'Rest loops its six recorded frames')
	check(player.source_rect('pour',0).size == Vector2(512,288),'Native source and destination use a fixed canvas')
	check(player.source_rect('pour',1.0).position == Vector2.ZERO,'Second atlas page starts at its first cell')
	for frame in range(72):
		var time = (frame+0.01)/12.0
		check(player.frame_index('pour',time) == frame,'Every recorded frame is reachable in order')
		check(player.source_rect('pour',time).size == Vector2(512,288),'Every frame retains its native dimensions')
	for frame in range(84):
		var time = (frame+0.01)/12.0
		check(player.frame_index('stir',time) == frame,'Every stirring frame follows recorded order')
		check(player.source_rect('stir',time).size == Vector2(512,288),'Stirring frame retains native dimensions')
	check(player.frame_index('stir',100) == 83,'Stirring holds its last recorded frame')
	check(player.source_rect('stir',6.0).position == Vector2.ZERO,'Seventh stirring page begins at the first cell')
	check(is_equal_approx(game.STIR_SECONDS,float(player.clips.stir.count)/player.clips.stir.fps),'Game timeline matches the complete filmed stirring clip')

func test_people():
	var portraits = game.patient_sprites
	check(portraits.errors.is_empty(),'All human patient sprite sheets load: '+str(portraits.errors))
	check(portraits.people.size() == 20,'Twenty distinct illustrated clinic patients')
	for person in range(Brewing.PATIENTS.size()):
		check(portraits.people[person].name == Brewing.PATIENTS[person].name,'Sprite and clinic patient identity agree')
		for mood in ['neutral','smile','frown']:
			var rect = portraits.source_rect(person,1.0,mood)
			check(rect.size == Vector2(128,128),'Only a small native-sized face overlay changes')
		if person < 6:
			check(portraits.people[person].body.get_size() == Vector2(512,384),'Original patient keeps the static blank-face body')
			check(portraits.people[person].faces.get_size() == Vector2(384,384),'Original patient keeps the separate facial atlas')
		else:
			check(portraits.people[person].body.get_size().x >= 1000,'New patient has a complete expression sheet')
	check(portraits.blink_column(0,0.0) == 0,'Patient begins with open eyes')
	check(portraits.blink_column(0,4.13) == 1,'Blink starts with half-closed eyes')
	check(portraits.blink_column(0,4.20) == 2,'Blink fully closes the eyelids')
	check(portraits.blink_column(0,4.29) == 1,'Blink reopens through a half-lid frame')
	check(portraits.blink_column(0,4.40) == 0,'Blink returns to direct eye contact')
	check(portraits.frame_index(0,4.20,'smile') == 5,'Blink keeps the smiling mouth')
	check(portraits.frame_index(0,4.20,'frown') == 8,'Blink keeps the worried mouth')
	game.new_shift()
	check(game.patient_expression() == 'frown','Ill arrivals initially look concerned')
	game.patient_reaction_until = 0
	game.clock = 5.0
	stock_and_add(0)
	stock_and_add(2)
	game.start_mix()
	check(game.patient_expression() == 'neutral','Patient watches the brewing calmly')
	game.finish_mix()
	check(game.patient_expression() == 'smile','Finished remedy gets a hopeful smile')
	game.serve()
	check(game.patient_expression() == 'smile','Cured patient smiles with relief')
	game.new_shift()
	stock_and_add(4)
	stock_and_add(4)
	game.start_mix()
	game.finish_mix()
	game.serve()
	check(game.patient_expression() == 'frown','A mistaken treatment gets a worried reaction')
	for person in range(Brewing.PATIENTS.size()):
		game.load_patient(person)
		game.refresh()
		check(portraits.get_node('SymptomOverlay').effect_mask == game.symptoms,'Symptom effects follow the current patient')
		check(portraits.get_node('SymptomOverlay').z_index > portraits.people[person].node.z_index,'Symptom effects draw in front of the portrait')
		for node in game.layer.find_children("*", "Control", true, false):
			if (node is Label or node is Button) and node.is_visible_in_tree() and not game.supplies.is_ancestor_of(node):
				check(not node.get_rect().intersects(Rect2(440,180,560,350)),'Patient face and upper body stay clear of information controls')
	game.new_shift()

func test_stir_timeline():
	game.new_shift()
	game.focused = true
	stock_and_add(0)
	stock_and_add(2)
	var before_stir = game.current_liquid()
	game._process(1.0)
	check(not game.mixing and not game.has_result,'Completed pours wait for an explicit Stir click')
	check(not game.stage.held_spoon.visible and game.stage.get_node('RestingSpoon').visible,'Spoon stays on the table while waiting')
	game.layer.get_node('Clipboard/Primary').pressed.emit()
	check(game.mixing and game.is_stirring(),'Stir button starts the separate spoon sequence')
	game._process(1.0)
	check(game.stage.held_spoon.visible and not game.stage.get_node('RestingSpoon').visible,'Right hand picks up the table spoon')
	game.serve()
	check(game.served == 0,'A remedy cannot be served before stirring completes')
	game.toggle_pause()
	var before = game.animation_time
	var grip = game.stage.right_hand.position
	game._process(1.0)
	check(game.animation_time == before and game.stage.right_hand.position == grip,'Pause freezes hand and spoon together')
	game.toggle_pause()
	game.focused = false
	game._process(1.0)
	check(game.animation_time == before,'Focus loss freezes the spoon sequence')
	game.focused = true
	game.toggle_speed()
	game._process(0.125)
	check(is_equal_approx(game.animation_time,before+0.25),'Double speed applies to spoon movement')
	game.toggle_speed()
	game._process(game.STIR_SECONDS)
	check(game.has_result and not game.mixing and game.result_recipe == 0,'Completed stirring resolves the recipe')
	check(not game.stage.held_spoon.visible and game.stage.get_node('RestingSpoon').visible,'Spoon is returned and both hands finish empty')
	game.new_shift()


func test_rules():
	check(Brewing.RECIPES.size() == 21,'Twenty-one authored recipes')
	for i in range(Brewing.RECIPES.size()):
		check(Brewing.resolve(Brewing.RECIPES[i].sequence) == i,'Each recipe resolves uniquely')
		check(Brewing.RECIPES[i].sequence.size() >= 2 and Brewing.RECIPES[i].sequence.size() <= 4,'Every recipe fits two to four pours')
	check(Brewing.resolve([0,2]) != Brewing.resolve([2,0]),'Reversing identical ingredients changes the output')
	check(Brewing.resolve([0,2,0]) == -1,'An extra ingredient invalidates an otherwise valid recipe')
	check(Brewing.resolve([0,0]) == -1,'An unknown duplicate combination becomes muddled')
	check(Brewing.resolve([0]) == -1,'A single ingredient is not a recipe')
	var side_effect = Brewing.treat(Brewing.FEVER|Brewing.FLOATING,0,[0,2],-1)
	check(side_effect.mask == (Brewing.CHILLS|Brewing.FLOATING),'Dewdrop side effect depends on existing floating symptom')
	var allergy = Brewing.treat(Brewing.STONE,7,[1,2,3,0],1)
	check(allergy.mask == (Brewing.STONE|Brewing.BLOOM),'Ember allergy causes blooming before a cure is applied')
	var wrong = Brewing.treat(Brewing.FEVER,1,[2,0],-1)
	check(wrong.mask == Brewing.FEVER,'A known but irrelevant remedy does not falsely cure the patient')
	var unknown = Brewing.treat(Brewing.FEVER,-1,[4,4],-1)
	check(unknown.mask == (Brewing.FEVER|Brewing.HICCUPS),'Muddled brew produces recoverable hiccups')
	check(Brewing.SYMPTOMS.size() == 12 and Brewing.symptom_names(4095).size() == 12,'All twelve symptoms have readable names')
	var bits = 0
	for symptom in Brewing.SYMPTOMS:
		var bit = int(symptom.bit)
		check(bit > 0 and (bit & (bit-1)) == 0 and (bits & bit) == 0,'Every symptom has a distinct power-of-two bit')
		bits |= bit
		var treatable = false
		for recipe in Brewing.RECIPES:
			treatable = treatable or (int(recipe.cure) & bit) != 0
		check(treatable,'Every symptom has an available remedy')
	var hashes = JSON.parse_string(FileAccess.get_file_as_string('res://resources/data/original_patient_hashes.json'))
	for entry in hashes:
		if not str(entry.Path).ends_with('patients.tres'):
			check(FileAccess.get_sha256(entry.Path).to_upper() == entry.Hash,'Original patient artwork and scene are unchanged')
	var original_catalog = load('res://resources/data/original_patients.tres').entries
	for i in range(6):
		check(Brewing.PATIENTS[i] == original_catalog[i],'Original patient data is unchanged')

func find_button(words):
	for node in game.layer.find_children("*", "Control", true, false):
		if node is Button and node.visible and node.text == words:
			return node
	return null

func test_controls():
	game.new_shift()
	game.start_mix()
	check(not game.mixing,'Empty queue cannot be brewed')
	stock_and_add(0)
	check(find_button('Stir mixture').disabled,'One ingredient keeps the brew control disabled')
	stock_and_add(2)
	check(not find_button('Stir mixture').disabled,'Two ingredients enable the brew control')
	stock_and_add(3)
	stock_and_add(5)
	stock_and_add(4)
	check(game.queue.size() == 4,'Queue has a hard four-ingredient capacity')
	game.remove_ingredient(1)
	check(game.queue == [0,3,5],'Removing a slot preserves the remaining order')
	game.clear_queue()
	game.table_stock = [0,1,2,3,4,5]
	game.table_empty.clear()
	for key in [KEY_1,KEY_3]:
		var event = InputEventKey.new()
		event.keycode = key
		event.pressed = true
		game._unhandled_input(event)
		game._process(game.POUR_SECONDS+0.01)
	check(game.queue == [0,2],'Keyboard ingredient shortcuts queue the correct pair')
	find_button('Stir mixture').pressed.emit()
	check(game.mixing and game.batches == 1,'Brew button starts the animation and counts one batch')
	game.start_mix()
	stock_and_add(4)
	game.clear_queue()
	game.remove_ingredient(0)
	check(game.queue == [0,2] and game.batches == 1,'Animation prevents duplicate brew and queue mutations')
	game.toggle_pause()
	var before = game.animation_time
	game._process(0.5)
	check(game.animation_time == before,'Pause freezes the hands timeline')
	game.toggle_pause()
	game.focused = false
	game._process(0.5)
	check(game.animation_time == before,'Losing focus freezes the hands timeline')
	game.focused = true
	game.toggle_speed()
	game._process(0.1)
	check(is_equal_approx(game.animation_time,before+0.2),'Double speed advances the timeline twice as fast')
	game.toggle_speed()
	check(game.current_liquid().is_equal_approx(Brewing.finished_color(game.queue)),'Stirring uses the finished ingredient colour')
	game._process(game.mix_duration()+0.1)
	check(not game.mixing and game.has_result and game.result_recipe == 0,'Timeline completion resolves the selected ordered recipe')
	check(game.result_color.is_equal_approx(Color(Brewing.RECIPES[0].color)),'Finished liquid matches the remedy colour')
	stock_and_add(5)
	check(game.queue == [0,2],'A finished result must be served or discarded before editing')
	game.discard()
	check(game.queue.is_empty() and not game.has_result,'Discard clears the flask without treating the patient')
	check(game.symptoms == Brewing.FEVER,'Discard does not secretly apply a cure')
	game.toggle_mute()
	check(not game.muted,'Sound toggle works')
	game.toggle_mute()

func brew_recipe(recipe_index):
	for stage in Brewing.RECIPES[recipe_index].get('stages',[]):
		for ingredient in stage.sequence:
			stock_and_add(ingredient)
		game.start_mix()
		game._process(game.mix_duration()+0.1)
		check(game.result_blend == stage.id and game.result_recipe == -1,'Intermediate mixture resolves to its named blend')
		var treatments = game.served
		game.serve()
		check(game.stored_blends.has(stage.id) and game.served == treatments,'Bottling stores a blend without treating the patient')
	for ingredient in Brewing.RECIPES[recipe_index].sequence:
		stock_and_add(ingredient)
	game.start_mix()
	check(game.mixing,'A complete recipe enters the mixing phase')
	game._process(game.mix_duration()+0.1)
	check(game.has_result and game.result_recipe == recipe_index,'Recipe emerges after its full animation')
	game.serve()
	check(not game.has_result and game.queue.is_empty(),'Serving clears the ready flask and order')

func test_shift():
	game.new_shift()
	var cures = [[0],[1],[2,5],[3,6],[4,5],[7,2]]
	for i in range(6,Brewing.PATIENTS.size()):
		cures.append(Brewing.PATIENTS[i].treatments)
	for i in range(cures.size()):
		check(game.patient_index == i,'Patients progress in the intended order')
		for recipe in cures[i]:
			brew_recipe(recipe)
		check(game.symptoms == 0,'Each patient can be fully cured with authored recipes')
		check(game.patient_stars == 3,'Efficient treatment earns three stars')
		check(game.clinic_stars == (i+1)*3,'Stars accumulate exactly once')
		var old_score = game.clinic_stars
		game.serve()
		check(game.clinic_stars == old_score,'Repeated serve cannot duplicate rewards')
		game.next_patient()
	check(game.shift_complete and game.clinic_stars == 60,'All twenty patients complete the day with sixty stars')
	game.new_shift()
	check(game.patient_index == 0 and game.clinic_stars == 0,'A new shift resets progress and stars')

func test_mistakes():
	game.new_shift()
	stock_and_add(4)
	stock_and_add(4)
	game.start_mix()
	game.finish_mix()
	check(game.result_recipe == -1,'Finish-animation control still applies recipe validation')
	game.serve()
	check(game.symptoms == (Brewing.FEVER|Brewing.HICCUPS),'Serving a muddled batch causes the documented side effect')
	brew_recipe(0)
	brew_recipe(5)
	check(game.symptoms == 0,'A mistaken treatment is recoverable through later remedies')
	check(game.patient_stars == 1,'Extra batches reduce the efficiency award')
	game.restart_patient()
	check(game.symptoms == Brewing.FEVER and game.clinic_stars == 0,'Restart removes the previous award before replaying a patient')
	game.load_patient(3)
	brew_recipe(7)
	check((game.symptoms & Brewing.STONE) != 0 and (game.symptoms & Brewing.BLOOM) != 0,'Allergic patient stays ill after an Ember-containing treatment')
	game.restart_patient()
	check(game.batches == 0 and game.served == 0 and not game.mixing,'Restart restores a clean local attempt')


func test_native_scenes():
	game.new_shift()
	var stage = game.get_node('Stage')
	check(stage.scene_file_path == 'res://scenes/mixing_room.tscn','The room is a saved scene instance')
	check(stage.has_node('Cauldron/Effects/Bubble0') and stage.has_node('Cauldron/Effects/Steam2'),'Cauldron effects are saved with their prop scene')
	check(game.layer.scene_file_path == 'res://scenes/ui/interface.tscn','The interface is a saved scene instance')
	var controls = game.layer.find_children('*','Control',true,false)
	var ids = controls.map(func(node): return node.get_instance_id())
	var original_position = game.layer.get_node('Clipboard/RecipeName').position
	game.layer.get_node('Clipboard/RecipeName').position += Vector2(1,1)
	game.table_stock = [0,2]
	game.layer.get_node('Shelf/Ingredient0').pressed.emit()
	game.layer.get_node('Shelf/Ingredient2').pressed.emit()
	check(game.queue == [0,2],'Scene-authored ingredient signal bindings preserve the order')
	game.layer.get_node('Journal/Recipe1').pressed.emit()
	check(game.pinned == 1,'Scene-authored recipe signal selects the journal entry')
	check(game.layer.get_node('Clipboard/RecipeName').position == original_position+Vector2(1,1),'Refresh preserves editor-authored control positions')
	game.layer.get_node('Clipboard/RecipeName').position = original_position
	game.clear_queue()
	stock_and_add(0)
	stock_and_add(2)
	game.layer.get_node('Clipboard/Primary').pressed.emit()
	game.layer.get_node('Clipboard/Pause').pressed.emit()
	check(game.mixing and game.paused,'The scene pause button pauses the shared timeline')
	game.layer.get_node('Clipboard/Pause').pressed.emit()
	check(not game.paused,'The same scene button resumes the shared timeline')
	var left = stage.get_node('LeftHandPlacement/LeftHand')
	var right = stage.get_node('RightHandPlacement/RightHand')
	check(left.hand_size == right.hand_size and left.source_side == 'left' and right.source_side == 'right','Both hands have matched size and distinct original video sources')
	check(not stage.held_bottle.visible,'Left hand stays empty during stirring')
	for i in range(84):
		game.animation_time = game.pour_duration()+(i+0.01)/12.0
		game.update_presentation()
		var pose = right.transform
		game.update_presentation()
		check(right.transform == pose,'Hand pose is deterministic with no frame redraw wobble')
	game.layer.get_node('Clipboard/Finish').pressed.emit()
	check(game.has_result and not game.mixing,'The scene finish button resolves the brew')
	game.layer.get_node('Clipboard/Primary').pressed.emit()
	check(game.symptoms == 0,'The scene primary button serves the brew')
	game.layer.get_node('Clipboard/Next').pressed.emit()
	check(game.patient_index == 1,'The scene next button welcomes the next patient')
	check(ids == game.layer.find_children('*','Control',true,false).map(func(node): return node.get_instance_id()),'Gameplay keeps all editor-authored controls instead of rebuilding nodes')
	for i in range(Brewing.PATIENTS.size()):
		game.load_patient(i)
		check(game.patient_sprites.people[i].node.visible,'The selected patient scene is visible')
		check(game.patient_sprites.people[i].node.scene_file_path.ends_with('.tscn'),'Each patient is an instanced native scene')
	game.new_shift()

func stock_and_add(index):
	if not game.can_edit():
		return
	game.sync_table_bottles()
	var available = game.stored_blends.has(index)
	for slot in range(game.table_stock.size()):
		available = available or (game.table_stock[slot] == index and not game.table_empty[slot])
	if not available:
		game.table_stock.append(index)
	game.pour_ingredient(index)
	game.finish_pour()


func test_supplies():
	game.new_shift()
	check(Brewing.BASE_INGREDIENT_COUNT == 12 and game.supplies.pantry_buttons.size() == 12,'Twelve raw pantry ingredients; blends must be brewed')
	var pantry_ui = game.supplies
	pantry_ui.open('pantry')
	for ingredient in [0,2,0]:
		pantry_ui.pantry_buttons[ingredient].pressed.emit()
	check(pantry_ui.basket == [0,2,0],'Repeated shelf clicks collect separate duplicate bottles')
	check(pantry_ui.basket_buttons[0].visible and pantry_ui.basket_buttons[2].visible and 'Moonmilk' in pantry_ui.basket_buttons[2].text,'Collected list shows each duplicate as its own entry')
	pantry_ui.basket_buttons[0].pressed.emit()
	check(pantry_ui.basket == [2,0],'Clicking a collected potion removes only that copy and preserves order')
	pantry_ui.collect_bottle(0)
	pantry_ui.bring_to_table()
	check(game.table_stock == [2,0,0],'Carrying preserves duplicate bottles on the table')
	check(pantry_ui.table_buttons[0].position.x < pantry_ui.table_buttons[1].position.x and pantry_ui.table_buttons[1].position.x < pantry_ui.table_buttons[2].position.x,'Selected bottles read left to right across the first row')
	check(pantry_ui.table_buttons[3].position.y > pantry_ui.table_buttons[0].position.y and pantry_ui.table_buttons[3].position.x < pantry_ui.table_buttons[1].position.x,'Fourth bottle begins the next loose row at the left')
	check(not pantry_ui.table_buttons[3].visible,'Unoccupied table positions have no visible placeholders')
	for slot in range(3):
		var artwork = pantry_ui.table_buttons[slot].get_node('Bottle/Artwork')
		check(artwork.texture == pantry_ui.BOTTLE_IMAGES[game.table_stock[slot]],'Each placed bottle displays its selected ingredient artwork')
	game.add_ingredient(0)
	pantry_ui.open('pantry')
	pantry_ui.basket_buttons[1].pressed.emit()
	pantry_ui.bring_to_table()
	check(game.table_stock == [2,0] and game.queue == [0],'Returning one duplicate keeps the remaining bottle and its queued pour')
	pantry_ui.open('pantry')
	pantry_ui.basket_buttons[1].pressed.emit()
	pantry_ui.bring_to_table()
	check(game.table_stock == [2] and game.queue.is_empty(),'Returning the last copy removes unavailable queued pours')
	game.new_shift()
	game.add_ingredient(0)
	check(game.queue.is_empty(),'Unfetched bottles cannot be poured')
	var ui = game.supplies
	ui.open('book')
	ui.search.text = 'stone skin'
	ui.refresh()
	check(ui.recipe_buttons[3].visible and ui.recipe_buttons[11].visible and not ui.recipe_buttons[0].visible,'Book searches symptom across old and new remedies')
	ui.search.text = ''
	ui.search.text = 'Starlight essence'
	ui.refresh()
	check(ui.recipe_buttons[12].visible and not ui.recipe_buttons[0].visible,'Book searches full ingredient names')
	ui.search.text = ''
	ui.matches_only.button_pressed = true
	ui.refresh()
	check(ui.recipe_buttons[8].visible and not ui.recipe_buttons[3].visible,'Book filters current patient symptoms')
	ui.matches_only.button_pressed = false
	game.pin_recipe(8)
	ui.open('pantry')
	for index in [6,2,0]:
		ui.pantry_buttons[index].pressed.emit()
	check(game.table_stock.is_empty(),'Basket does not teleport bottles onto table')
	ui.bring_to_table()
	check(game.table_stock == [6,2,0] and not ui.modal.visible,'Carry action delivers selected bottles and returns to table')
	check(game.queue.is_empty(),'Collecting bottles leaves pour order to the player')
	for slot in range(3):
		ui.table_buttons[slot].pressed.emit()
		game._process(game.POUR_SECONDS+0.01)
	check(game.queue == [6,2,0],'Fetched table bottle controls queue pours in clicked order')
	game.start_mix()
	ui.open('pantry')
	ui.collect_bottle(11)
	ui.bring_to_table()
	check(game.table_stock == [6,2,0],'Pantry cannot change bottles during mixing')
	ui.close()
	game.finish_mix()
	check(game.result_recipe == 8,'New ingredient recipe resolves through complete mixing flow')
	game.serve()
	check(game.symptoms == 0,'New remedy cures patient')
	game.load_patient(3)
	game.pin_recipe(7)
	check('ALLERGY' in ui.detail.text,'Book warns about pinned recipe allergies')
	game.load_patient(5)
	game.pin_recipe(0)
	check('CAUTION' in ui.detail.text,'Book warns about conditional shivers')
	ui.open('pantry')
	for index in range(7):
		ui.collect_bottle(index)
	check(ui.basket.size() == 6,'Pantry basket capacity is enforced')
	ui.bring_to_table()
	game.add_ingredient(0)
	ui.open('pantry')
	ui.remove_bottle(ui.basket.find(0))
	ui.bring_to_table()
	check(not game.queue.has(0),'Returning a bottle removes its pending pour')
	game.new_shift()
	check(game.table_stock.is_empty() and not ui.modal.visible,'New patient resets the workbench and closes pantry')
	for i in range(8,16):
		var recipe = Brewing.RECIPES[i]
		check(Brewing.treat(int(recipe.cure),i,recipe.sequence,-1).mask == 0,'Each new remedy cures its advertised symptoms')

func test_click_pours():
	game.new_shift()
	game.focused = true
	game.speed = 1.0
	var ui = game.supplies
	ui.open('pantry')
	for ingredient in [0,2,0]:
		ui.collect_bottle(ingredient)
	ui.bring_to_table()
	ui.table_buttons[0].pressed.emit()
	check(game.pouring and not game.mixing and game.queue == [0],'Clicking a bottle starts its individual pour immediately')
	check(game.stage.hand_phase == 'reach_bottle' and not game.stage.held_bottle.visible,'Bottle click first reaches with an empty hand')
	check(not game.table_empty[0] and not game.table_empty[2],'Bottle stays full until its pour finishes; duplicate starts full')
	ui.table_buttons[1].pressed.emit()
	check(game.queue == [0],'Clicks during a pour cannot interrupt or add another ingredient')
	game.toggle_pause()
	game._process(1.0)
	check(game.pouring and game.animation_time == 0.0,'Pause freezes an individual bottle pour')
	game.toggle_pause()
	game.focused = false
	game._process(1.0)
	check(game.animation_time == 0.0,'Focus loss freezes an individual bottle pour')
	game.focused = true
	game.animation_time = 1.4
	game.update_presentation()
	check(game.stage.held_bottle.visible and game.stage.held_bottle.texture == ui.BOTTLE_IMAGES[0],'Picked-up bottle uses the clicked ingredient artwork')
	check(not ui.table_buttons[0].get_node('Bottle').visible and ui.table_buttons[2].get_node('Bottle').visible,'Only the selected duplicate leaves its table slot')
	game.animation_time = 3.0
	game.update_presentation()
	check(game.stage.get_node('PourStream').visible,'Liquid stream appears only while the bottle is tilted')
	game.animation_time = 5.5
	game.update_presentation()
	check(not game.stage.held_bottle.visible and ui.table_buttons[0].get_node('Bottle').visible,'Bottle is put back before the empty hand retreats')
	game.animation_time = 0.0
	game._process(game.POUR_SECONDS+0.01)
	check(not game.pouring and game.poured_count == 1 and game.table_empty == [true,false,false],'Completed pour empties only the clicked copy')
	check(ui.table_buttons[0].get_node('Bottle/Artwork').texture == ui.EMPTY_BOTTLE_IMAGES[0],'Completed pour swaps the clicked bottle to its empty artwork')
	check(ui.table_buttons[2].get_node('Bottle/Artwork').texture == ui.BOTTLE_IMAGES[0],'An unpoured duplicate keeps its filled artwork')
	check(ui.table_buttons[0].disabled and not ui.table_buttons[2].disabled,'Empty bottles cannot be poured; full duplicates remain available')
	ui.table_buttons[0].pressed.emit()
	check(game.queue == [0] and not game.pouring,'An empty bottle cannot add another pour')
	var first_color = game.current_liquid()
	ui.table_buttons[1].pressed.emit()
	check(game.pouring and game.queue == [0,2] and game.animation_time == game.POUR_SECONDS,'Next bottle plays one new pour and preserves ingredient order')
	check(game.current_liquid().is_equal_approx(first_color),'Next pour begins with the liquid already in the kettle')
	game._process(game.POUR_SECONDS+0.01)
	game.layer.get_node('Clipboard/Primary').pressed.emit()
	check(game.mixing and game.is_stirring() and game.animation_time == game.pour_duration(),'Stir starts after completed pours without replaying them')
	check(game.batches == 1,'Individual pours and stirring count as one batch')
	game._process(game.STIR_SECONDS+0.01)
	check(game.has_result and game.result_recipe == 0,'Click-poured ingredients produce the correct recipe after stirring')
	game.serve()
	check(game.table_empty == [true,true,false] and game.poured_count == 0,'Serving preserves each empty bottle and clears the kettle')
	game.new_shift()
	ui.open('pantry')
	for ingredient in [0,0,2]:
		ui.collect_bottle(ingredient)
	ui.bring_to_table()
	ui.table_buttons[0].pressed.emit()
	game.layer.get_node('Clipboard/Finish').pressed.emit()
	check(not game.pouring and not game.has_result and game.table_empty[0],'Finish animation completes only the active pour, without resolving a premature brew')
	ui.open('pantry')
	ui.remove_bottle(0)
	ui.collect_bottle(0)
	ui.bring_to_table()
	check(game.table_stock == [0,2,0] and game.table_empty == [false,false,false],'Returning an empty copy and collecting a fresh bottle preserves the other copies')
	check(game.queue == [0] and game.poured_count == 1,'Returning an empty bottle keeps its poured contents in the kettle')
	game.new_shift()
	check(game.table_empty.is_empty() and not game.pouring and game.poured_count == 0,'New patient clears empty bottles and pour state')

func test_staged_recipes():
	game.new_shift()
	check(not Brewing.RECIPES[0].has('stages') and not Brewing.RECIPES[7].has('stages'),'Early remedies stay single-stage')
	for i in range(12,Brewing.RECIPES.size()):
		var recipe = Brewing.RECIPES[i]
		check(recipe.stages.size() == 2,'Later remedies require two independent blends')
		var flattened = []
		for stage in recipe.stages:
			flattened.append_array(stage.sequence)
			check(Brewing.resolve_blend(stage.sequence) == stage.id,'Every authored intermediate blend has a unique order')
			var reverse = stage.sequence.duplicate()
			reverse.reverse()
			check(Brewing.resolve_blend(reverse) != stage.id,'Wrong pour order cannot create the intended intermediate blend')
		check(Brewing.resolve(flattened) == -1,'Pouring all raw ingredients together cannot bypass the stages')
		var reversed = recipe.sequence.duplicate()
		reversed.reverse()
		check(Brewing.resolve(reversed) == -1,'Final blend order matters')
		check(Brewing.treat(recipe.cure,i,recipe.sequence,recipe.stages[0].sequence[0]).good == false,'Allergies carry through intermediate blends')
		game.load_patient(6)
		game.symptoms = recipe.cure
		game.pin_recipe(i)
		brew_recipe(i)
		check(game.symptoms == 0,'Every advanced recipe can be brewed from raw bottles through both intermediates')
	game.new_shift()
	game.pin_recipe(16)
	game.add_ingredient(Brewing.RECIPES[16].sequence[0])
	check(game.queue.is_empty(),'An unprepared blend cannot be poured')
	game.load_patient(6)
	brew_recipe(16)
	check(game.symptoms == 0 and game.stored_blends.is_empty(),'A staged remedy cures its patient and consumes both saved blends')
	check(game.patient_stars == 3,'Required intermediate batches preserve a perfect efficiency award')
	game.new_shift()


func test_hand_choreography():
	game.new_shift()
	game.table_stock = [2,0,2]
	game.sync_table_bottles()
	game.refresh()
	var stage = game.stage
	check(not stage.held_bottle.visible and not stage.held_spoon.visible,'Both resting hands are empty')
	check(stage.left_hand.position == stage.LEFT_REST and stage.right_hand.position == stage.RIGHT_REST,'Both hands begin in their stable resting poses')
	game.pour_bottle(2)
	game.animation_time = 2.8
	game.update_presentation()
	check(stage.held_bottle.texture == game.supplies.BOTTLE_IMAGES[2],'Dew pickup shows Dew rather than a generic jar')
	check(stage.held_table_slot == 2 and game.supplies.table_buttons[0].get_node('Bottle').visible,'Selected duplicate is tracked by table slot')
	check(stage.right_hand.position == stage.RIGHT_REST and not stage.held_spoon.visible,'Right hand waits empty throughout pouring')
	for boundary in [0.9,1.1,2.0,2.6,3.7,4.3,5.2,6.0]:
		game.animation_time = boundary-0.0001
		game.update_presentation()
		var previous = stage.left_hand.position
		var angle = stage.left_hand.rotation
		game.animation_time = boundary+0.0001
		game.update_presentation()
		check(previous.distance_to(stage.left_hand.position) < 0.1 and absf(angle-stage.left_hand.rotation) < 0.01,'Bottle phase boundaries have no position or rotation snaps')
	game.finish_pour()
	game.pour_bottle(1)
	game.finish_pour()
	game._process(10.0)
	check(not game.mixing and not stage.held_spoon.visible,'Waiting does not automatically start stirring')
	game.layer.get_node('Clipboard/Primary').pressed.emit()
	for boundary in [0.8,1.5,5.3,6.2,7.0]:
		game.animation_time = game.pour_duration()+boundary-0.0001
		game.update_presentation()
		var previous = stage.right_hand.position
		var angle = stage.right_hand.rotation
		game.animation_time = game.pour_duration()+boundary+0.0001
		game.update_presentation()
		check(previous.distance_to(stage.right_hand.position) < 0.1 and absf(angle-stage.right_hand.rotation) < 0.01,'Spoon phase boundaries have no position or rotation snaps')
	game.animation_time = game.pour_duration()+6.5
	game.update_presentation()
	check(not stage.held_spoon.visible and stage.get_node('RestingSpoon').visible,'Spoon is set down before the right hand retreats')
	game.finish_mix()
	check(stage.left_hand.position == stage.LEFT_REST and stage.right_hand.position == stage.RIGHT_REST,'Both hands finish in their original resting poses')
	game.new_shift()

func test_user_video_sources():
	var data = JSON.parse_string(FileAccess.get_file_as_string('res://resources/hands/user_video_traces.json'))
	for side in ['left','right']:
		var clip = data.clips[side]
		check(clip.frames.size() == (72 if side == 'left' else 84),'Original sampled video frames are retained for '+side)
		check(clip.video == ('20261106_010812.mp4' if side == 'left' else '20261106_010936.mp4'),'Hand source identifies the user recording')
		var pages = []
		for page in range(6 if side == 'left' else 7):
			pages.append(Image.load_from_file(ProjectSettings.globalize_path('res://assets/user-video-hands/%s-%02d.png' % [side,page+1])))
		for record in clip.frames:
			var cell = int(record.index)%12
			var pixels = pages[int(record.index/12)].get_region(Rect2i(cell%4*128,int(cell/4)*128,128,128))
			pixels.convert(Image.FORMAT_RGB8)
			var hash = HashingContext.new()
			hash.start(HashingContext.HASH_SHA256)
			hash.update(pixels.get_data())
			check(hash.finish().hex_encode() == record.crop_rgb_sha256,'Packed hand pixels match the original video crop')
			var directory = 'rotoscope/native-frames/' if side == 'left' else 'rotoscope-010936/frames/'
			var path = ProjectSettings.globalize_path('res://../work/'+directory+record.source_frame)
			check(FileAccess.get_sha256(path) == record.source_sha256,'Source frame provenance matches the unchanged user recording sample')
			check(record.contour.size() == 64,'Every source frame has an interpolatable recorded silhouette')
	var left = game.stage.left_hand
	var right = game.stage.right_hand
	left.set_source_time(0.0)
	var first = left.get_node('Graphic/Hand').polygon
	left.set_source_time(3.0)
	check(left.get_node('Graphic/Hand').polygon != first,'Recorded finger and wrist poses change during pouring')
	left.set_source_time(0.0)
	right.set_source_time(0.0)
	check(left.get_node('Graphic/Hand').polygon != right.get_node('Graphic/Hand').polygon,'Right hand is not a mirrored left-hand replacement')
	check(left.get_script().resource_path.ends_with('user_video_hand.gd') and right.get_script().resource_path.ends_with('user_video_hand.gd'),'Visible hands are driven by the user-video renderer')
	game.update_presentation()
