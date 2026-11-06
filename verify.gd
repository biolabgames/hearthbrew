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
		if mode in ['reach','pour','stir','lift','result','cured']:
			for ingredient in [0,2]:
				game.add_ingredient(ingredient)
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
		game.queue_redraw()
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
		test_people()
		test_stir_timeline()
		test_rules()
		test_controls()
		test_shift()
		test_mistakes()
		await process_frame
		for node in game.layer.get_children():
			if node is Control:
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
	check(portraits.people.size() == 6,'Six distinct illustrated humans replace the old animal portraits')
	for person in range(6):
		check(portraits.people[person].name == Brewing.PATIENTS[person].name,'Sprite and clinic patient identity agree')
		for mood in ['neutral','smile','frown']:
			var rect = portraits.source_rect(person,1.0,mood)
			check(rect.size == Vector2(128,128),'Only a small native-sized face overlay changes')
		check(portraits.people[person].body.get_size() == Vector2(512,384),'Each patient has one static blank-face body')
		check(portraits.people[person].faces.get_size() == Vector2(384,384),'Expressions are stored separately from the body')
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
	game.add_ingredient(0)
	game.add_ingredient(2)
	game.start_mix()
	check(game.patient_expression() == 'neutral','Patient watches the brewing calmly')
	game.finish_mix()
	check(game.patient_expression() == 'smile','Finished remedy gets a hopeful smile')
	game.serve()
	check(game.patient_expression() == 'smile','Cured patient smiles with relief')
	game.new_shift()
	game.add_ingredient(4)
	game.add_ingredient(4)
	game.start_mix()
	game.finish_mix()
	game.serve()
	check(game.patient_expression() == 'frown','A mistaken treatment gets a worried reaction')
	for person in range(6):
		game.load_patient(person)
		game.refresh()
		for node in game.layer.get_children():
			if node is Control:
				check(not node.get_rect().intersects(Rect2(440,180,560,350)),'Patient face and upper body stay clear of information controls')
	game.new_shift()

func test_stir_timeline():
	game.new_shift()
	game.add_ingredient(0)
	game.add_ingredient(2)
	game.start_mix()
	game._process(game.pour_duration()-0.01)
	check(game.mixing and not game.is_stirring(),'Final pour remains active before the stirring boundary')
	var near_final = game.current_liquid()
	game._process(0.02)
	check(game.mixing and game.is_stirring() and not game.has_result,'Pours transition into stirring before remedy completion')
	check(game.phase_label.text == 'Stirring the mixture','The interface identifies the stirring stage')
	var stirred = game.current_liquid()
	check(absf(stirred.r-near_final.r)+absf(stirred.g-near_final.g)+absf(stirred.b-near_final.b) < 0.01,'Colour stays continuous across the pour-to-stir boundary')
	game.serve()
	check(game.served == 0,'A remedy cannot be served before the stir finishes')
	game.toggle_pause()
	var before = game.animation_time
	game._process(1.0)
	check(game.animation_time == before,'Pause freezes the recorded stirring movement')
	game.toggle_pause()
	game.focused = false
	game._process(1.0)
	check(game.animation_time == before,'Focus loss freezes the recorded stirring movement')
	game.focused = true
	game.toggle_speed()
	game._process(0.125)
	check(is_equal_approx(game.animation_time,before+0.25),'Double speed also applies during stirring')
	game.toggle_speed()
	game._process(game.STIR_SECONDS)
	check(game.has_result and not game.mixing and game.result_recipe == 0,'Completed stirring resolves the correct remedy')
	game.new_shift()

func test_rules():
	check(Brewing.RECIPES.size() == 8,'Eight authored recipes')
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
	check(Brewing.symptom_names(127).size() == 7,'All seven symptoms have readable names')

func find_button(words):
	for node in game.layer.get_children():
		if node is Button and node.text == words:
			return node
	return null

func test_controls():
	game.new_shift()
	game.start_mix()
	check(not game.mixing,'Empty queue cannot be brewed')
	game.add_ingredient(0)
	check(find_button('Brew mixture').disabled,'One ingredient keeps the brew control disabled')
	game.add_ingredient(2)
	check(not find_button('Brew mixture').disabled,'Two ingredients enable the brew control')
	game.add_ingredient(3)
	game.add_ingredient(5)
	game.add_ingredient(4)
	check(game.queue.size() == 4,'Queue has a hard four-ingredient capacity')
	game.remove_ingredient(1)
	check(game.queue == [0,3,5],'Removing a slot preserves the remaining order')
	game.clear_queue()
	for key in [KEY_1,KEY_3]:
		var event = InputEventKey.new()
		event.keycode = key
		event.pressed = true
		game._unhandled_input(event)
	check(game.queue == [0,2],'Keyboard ingredient shortcuts queue the correct pair')
	find_button('Brew mixture').pressed.emit()
	check(game.mixing and game.batches == 1,'Brew button starts the animation and counts one batch')
	game.start_mix()
	game.add_ingredient(4)
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
	var early_color = game.current_liquid()
	game.animation_time = game.POUR_SECONDS*0.56
	check(not game.current_liquid().is_equal_approx(early_color),'Liquid changes colour during the pour')
	game._process(game.mix_duration()+0.1)
	check(not game.mixing and game.has_result and game.result_recipe == 0,'Timeline completion resolves the selected ordered recipe')
	check(game.result_color.is_equal_approx(Color(Brewing.RECIPES[0].color)),'Finished liquid matches the remedy colour')
	game.add_ingredient(5)
	check(game.queue == [0,2],'A finished result must be served or discarded before editing')
	game.discard()
	check(game.queue.is_empty() and not game.has_result,'Discard clears the flask without treating the patient')
	check(game.symptoms == Brewing.FEVER,'Discard does not secretly apply a cure')
	game.toggle_mute()
	check(not game.muted,'Sound toggle works')
	game.toggle_mute()

func brew_recipe(recipe_index):
	for ingredient in Brewing.RECIPES[recipe_index].sequence:
		game.add_ingredient(ingredient)
	game.start_mix()
	check(game.mixing,'A complete recipe enters the mixing phase')
	game._process(game.mix_duration()+0.1)
	check(game.has_result and game.result_recipe == recipe_index,'Recipe emerges after its full animation')
	game.serve()
	check(not game.has_result and game.queue.is_empty(),'Serving clears the ready flask and order')

func test_shift():
	game.new_shift()
	var cures = [[0],[1],[2,5],[3,6],[4,5],[7,2]]
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
	check(game.shift_complete and game.clinic_stars == 18,'All six patients complete the day with 18 stars')
	game.new_shift()
	check(game.patient_index == 0 and game.clinic_stars == 0,'A new shift resets progress and stars')

func test_mistakes():
	game.new_shift()
	game.add_ingredient(4)
	game.add_ingredient(4)
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

