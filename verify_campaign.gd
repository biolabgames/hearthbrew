extends SceneTree
const B = preload('res://brewing.gd')
const Data = preload('res://scripts/campaign_data.gd')
var game
var campaign
var checks = 0
var failures = []

func _initialize():
	call_deferred('run')

func check(condition, words):
	checks += 1
	if not condition:
		failures.append(words)
		printerr('FAIL: '+words)

func mix(sequence):
	campaign.herbs.emergency_supplies(sequence)
	game.table_stock = sequence.duplicate()
	game.table_empty.clear()
	game.sync_table_bottles()
	for i in range(sequence.size()):
		game.pour_bottle(i)
		game.finish_pour()
	game.start_mix()
	game.finish_mix()

func remedy(index):
	var r = B.RECIPES[index]
	for stage in r.get('stages',[]):
		mix(stage.sequence)
		game.serve()
		check(game.stored_blends.has(stage.id),'Intermediate is bottled')
	if r.has('stages'):
		for ingredient in r.sequence:
			game.pour_ingredient(ingredient)
			game.finish_pour()
		game.start_mix()
		game.finish_mix()
	else:
		mix(r.sequence)
	check(game.result_recipe == index,'Real brewing resolves requested remedy')
	finish_botanical()
	game.serve()

func finish_botanical():
	var lesson = campaign.botanical_lesson()
	if lesson.is_empty() or game.result_recipe < 0 or (int(B.RECIPES[game.result_recipe].cure) & int(lesson.mask)) == 0: return
	var herbs = campaign.herbs
	herbs.cutting(int(lesson.herb))
	herbs.begin(int(lesson.herb),str(lesson.method))
	for step in range(3): herbs.step()
	herbs.attach(herbs.key(int(lesson.herb),str(lesson.method)))

func diagnose():
	for tool in range(5):
		campaign.examine(tool)
	campaign.hypothesis = game.symptoms
	campaign.confirm_diagnosis()
	check(campaign.diagnosed,'All current findings support diagnosis')
	campaign.close()
	campaign.strength = int(campaign.current_case().strength)

func run():
	game = load('res://main.tscn').instantiate()
	game.set_meta('practice',true)
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.muted = true
	campaign = game.campaign
	campaign.save_path = 'user://campaign_verification.json'
	if '--capture' in OS.get_cmdline_user_args():
		campaign.open_menu()
		await capture('campaign_menu')
	check(Data.appointments().size() == 40,'Forty authored appointments')
	var used_recipes = []
	var planned_pours = 0
	var planned_batches = 0
	for c in Data.appointments():
		for id in c.route:
			if not used_recipes.has(id): used_recipes.append(id)
			var recipe = B.RECIPES[id]
			planned_batches += 1+recipe.get('stages',[]).size()
			planned_pours += recipe.sequence.size()
			for stage in recipe.get('stages',[]): planned_pours += stage.sequence.size()
	check(used_recipes.size() == 21,'Campaign routes use all twenty-one remedies')
	campaign.start_campaign()
	check(not campaign.modal.visible,'First appointment starts in the main room')
	check(game.patient_sprites.get_node('SymptomOverlay').visible,'Visible symptoms do not wait for diagnostic tests')
	check(game.patient_sprites.get_node('SymptomOverlay').effect_mask == B.FEVER,'Fever is visible on arrival')
	check(game.layer.z_index > game.patient_sprites.get_node('SymptomOverlay').z_index,'Patient effects stay behind diagnosis and other interface panels')
	check(game.patient_sprites.get_node('Effects').z_index > game.patient_sprites.people[19].node.z_index,'Bubbles and flowers draw above expanded portraits')
	if '--capture' in OS.get_cmdline_user_args():
		await capture('arrival_fever')
		game.get_node('Interface/Clipboard/Hint').pressed.emit()
		check(campaign.modal.visible and campaign.view == 'case','Diagnosis button opens diagnosis panel')
		await capture('arrival_diagnosis')
		campaign.close()
	check(campaign.recipe_available(11) and not campaign.recipe_available(12),'First day offers twelve simple recipes')
	check(game.visible_symptoms() == 0,'Recipe filter still requires examination findings')
	check(game.pinned == 0,'Campaign does not select a treatment for each case')
	campaign.hypothesis = B.FEVER
	campaign.confirm_diagnosis()
	check(not campaign.diagnosed,'Guessing without supporting findings is rejected')
	campaign.hypothesis = 4095
	campaign.examine(0)
	campaign.confirm_diagnosis()
	check(not campaign.diagnosed,'Selecting every symptom is rejected')
	diagnose()
	var symptom_choices = campaign.page.find_children('*','CheckButton',true,false)
	symptom_choices[0].button_pressed = false
	check(not campaign.diagnosed,'Changing a confirmed diagnosis requires reconfirmation')
	symptom_choices[0].button_pressed = true
	campaign.confirm_diagnosis()
	check(campaign.diagnosed,'Corrected diagnosis can be confirmed again')
	campaign.close()
	mix(B.RECIPES[0].sequence)
	campaign.diagnosed = false
	game.serve()
	check(game.symptoms == B.FEVER and game.has_result,'Unconfirmed treatment cannot be served or lost')
	campaign.diagnosed = true
	campaign.save_game()
	game.discard()
	campaign.load_game()
	check(game.has_result and game.result_recipe == 0 and game.queue == [0,2],'Finished brew survives save and resume')
	finish_botanical()
	game.serve()
	check(game.symptoms == 0,'Resumed brew cures patient')
	game.next_patient()
	check(campaign.cursor == 1 and game.patient_index == 1,'Appointments advance to correct portrait')
	check(not campaign.modal.visible,'Next appointment opens in the main room')
	check(game.patient_sprites.people[1].node.modulate.b > game.patient_sprites.people[1].node.modulate.r,'Cold patients have a blue tint')
	if '--capture' in OS.get_cmdline_user_args(): await capture('arrival_chills')
	# Check a saved, partially poured bottle resumes exactly once.
	game.table_stock = [2,0]
	game.table_empty = [false,false]
	game.pour_bottle(0)
	campaign.save_game()
	game.finish_pour()
	campaign.load_game()
	check(game.poured_count == 1 and game.table_empty == [true,false] and game.queue == [2],'Mid-pour save restores stable pour endpoint')
	check(not campaign.modal.visible,'Resuming an appointment returns to the main room')
	game.pour_bottle(1)
	game.finish_pour()
	game.start_mix()
	campaign.play_seconds = 123.5
	campaign.save_game()
	game.finish_mix()
	game.discard()
	campaign.load_game()
	check(game.has_result and not game.mixing and game.result_recipe == 1 and game.batches == 1,'Mid-stir save resumes completed batch without charging twice')
	check(campaign.play_seconds == 123.5,'Active play time survives resume')
	game.restart_patient()
	# Full campaign through production brewing, diagnosis and daily transitions.
	campaign.start_campaign()
	for appointment in range(40):
		check(campaign.cursor == appointment,'Campaign cursor matches appointment')
		check(game.patient_index == int(campaign.current_case().actor),'Returning visits retain the correct actor')
		check(not campaign.modal.visible,'Every appointment starts with the patient visible')
		check(game.patient().story.length() > str(campaign.current_case().story).length(),'Every appointment has a more detailed patient account')
		check(game.patient_sprites.get_node('SymptomOverlay').effect_mask == game.symptoms,'All active symptoms are visible before diagnosis')
		if appointment in [5,11,19] and '--capture' in OS.get_cmdline_user_args():
			await capture('arrival_case_%02d' % appointment)
		diagnose()
		if appointment == 20 and '--capture' in OS.get_cmdline_user_args():
			campaign.open_casebook()
			await capture('campaign_casebook')
			campaign.open_guide()
			await capture('campaign_guide')
			campaign.close()
			await capture('campaign_brewing')
		if appointment == 20:
			campaign.strength = 0
			mix(B.RECIPES[8].sequence)
			var before = game.symptoms
			game.serve()
			check(game.symptoms == before and game.has_result,'Incorrect strength leaves patient and brew recoverable')
			game.discard()
			campaign.strength = int(campaign.current_case().strength)
		var route = campaign.current_case().route.duplicate()
		if appointment == 24:
			mix(B.RECIPES[4].sequence)
			var anchored_mask = game.symptoms
			game.serve()
			check(game.symptoms == anchored_mask and game.has_result,'Anchored invisibility requires a compound alternative')
			game.discard()
			# Retry without keeping the deliberate test mistake in scoring.
			game.restart_patient()
			diagnose()
		for treatment in route:
			remedy(int(treatment))
		check(game.symptoms == 0,'Appointment %d has a safe complete treatment route' % appointment)
		if appointment != 20:
			check(game.patient_stars == 3,'Safe route receives perfect stars')
		game.next_patient()
		if appointment%5 == 4:
			check(campaign.evening,'Daily boundary opens evening instead of skipping')
			if appointment == 24 and '--capture' in OS.get_cmdline_user_args():
				await capture('campaign_evening')
			campaign.save_game()
			campaign.load_game()
			check(campaign.evening and campaign.cursor == appointment,'Evening survives reload')
			if appointment < 39:
				campaign.finish_evening('Field notes' if appointment%2 == 0 else 'Workbench')
			else:
				campaign.wrong_source('Review evidence')
				check(not campaign.completed,'Unsupported explanation cannot finish story')
				campaign.finish_story()
		await process_frame
	check(campaign.completed and campaign.history.size() == 40,'Ending records all forty completed visits')
	if '--capture' in OS.get_cmdline_user_args():
		await capture('campaign_ending')
	campaign.load_game()
	check(campaign.completed,'Campaign completion survives reload')
	campaign.start_replay()
	check(campaign.replay and not campaign.completed,'Post-campaign clinic opens')
	for i in range(40):
		campaign.cursor = i
		campaign.begin_case()
		check(not campaign.needs_pulse() or campaign.strength_picker.visible,'Shuffled tolerance cases always expose preparation selector')
		var mask = int(campaign.current_case().mask)
		var allergy = game.patient().allergy
		for id in campaign.current_case().route:
			var r = B.RECIPES[id]
			mask = B.treat(mask,id,r.sequence,allergy).mask
		check(mask == 0,'Replay keeps a solvable case variant')
	campaign.start_campaign()
	check(campaign.current_case().actor == 0 and campaign.current_case().mask == B.FEVER and campaign.cases[39].actor == 0,'New campaign after replay restores authored order')
	diagnose()
	mix([1,1])
	game.serve()
	check(not campaign.diagnosed and (game.symptoms & B.HICCUPS) != 0,'Unexpected side effect requires a fresh examination')
	diagnose()
	remedy(0)
	remedy(5)
	check(game.symptoms == 0,'Campaign mistakes remain fully recoverable')
	# Corrupt save should fail safely and retain current state.
	var file = FileAccess.open(campaign.save_path,FileAccess.WRITE)
	file.store_string('{"version":1}')
	file.close()
	var previous_cursor = campaign.cursor
	campaign.load_game()
	check(campaign.cursor == previous_cursor,'Malformed save preserves running state')
	campaign.active = false
	DirAccess.remove_absolute(campaign.save_path)
	print('CAMPAIGN: %d checks, %d failures' % [checks,failures.size()])
	print('PACING: authored routes have %d batches, %d pours; %.1f minutes of animation at 1x before diagnosis, reading and gathering.' % [planned_batches,planned_pours,(planned_batches*game.STIR_SECONDS+planned_pours*game.POUR_SECONDS)/60.0])
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func capture(filename):
	await process_frame
	await process_frame
	check(root.get_texture().get_image().save_png('res://previews/'+filename+'.png') == OK,'Rendered '+filename)
