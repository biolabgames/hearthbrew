extends Control
## Campaign state is independent of the original practice clinic and its roster.
const Data = preload('res://scripts/campaign_data.gd')
const B = preload('res://brewing.gd')
const Herbalism = preload('res://scripts/herbalism.gd')
var herbs = Herbalism.new()
var herbal_ui = preload('res://scripts/herbalism_ui.gd').new()
var garden_button: Button
const SAVE_PATH = 'user://hearthbrew_campaign_v1.json'
const SNAPSHOT_KEYS = ['patient_index','symptoms','queue','table_stock','table_empty','poured_count','stored_blends','pinned','has_result','result_recipe','result_blend','batches','served','clinic_stars','awarded','patient_stars','speed','muted']
var game
var active = false
var replay = false
var completed = false
var cursor = 0
var cases = Data.appointments()
var examined = []
var known_mask = 0
var hypothesis = 0
var diagnosed = false
var strength = 0
var batch_strength = 0
var history = []
var projects = []
var evening = false
var modal: Control
var page: Panel
var page_style: StyleBox
var notebook: Button
var strength_picker: OptionButton
var notice = ''
var diagnosis_feedback: Label
var save_path = SAVE_PATH
var play_seconds = 0.0
var view = 'menu'
var speech_panel: Panel
var speech_name: Label
var speech_text: RichTextLabel
var speech_dismissed = false

func _process(delta):
	if active and game.focused and not game.paused and not completed and (not modal.visible or view != 'menu'):
		play_seconds += delta

func setup(owner_game):
	game = owner_game
	herbal_ui.setup(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	garden_button = game.supplies.button_at(self,'Garden & preparations',Rect2(650,32,270,42),herbal_ui.open_bench)
	garden_button.add_theme_font_size_override('font_size',17)
	garden_button.hide()
	notebook = game.supplies.button_at(self,'Diagnosis & casebook',Rect2(44,235,270,48),open_casebook)
	speech_panel = game.supplies.panel_at(self,Rect2(548,508,544,126))
	speech_name = game.supplies.label_at(speech_panel,'',Rect2(16,7,512,25),17)
	speech_text = RichTextLabel.new()
	speech_panel.add_child(speech_text)
	speech_text.position = Vector2(16,35)
	speech_text.size = Vector2(512,80)
	speech_text.add_theme_font_size_override('normal_font_size',16)
	speech_text.add_theme_color_override('default_color',Color('#355d4c'))
	speech_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	speech_text.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	speech_panel.tooltip_text = 'Click to dismiss. Click the short account on the right to read again.'
	speech_panel.gui_input.connect(func(event): _on_speech_input(event,false))
	speech_text.gui_input.connect(func(event): _on_speech_input(event,false))
	var short_account = game.get_node('Interface/Clipboard/Story')
	short_account.mouse_filter = Control.MOUSE_FILTER_STOP
	short_account.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	short_account.tooltip_text = 'Click to hear the full account again.'
	short_account.gui_input.connect(func(event): _on_speech_input(event,true))
	strength_picker = OptionButton.new()
	add_child(strength_picker)
	strength_picker.position = Vector2(44,840)
	strength_picker.size = Vector2(270,36)
	strength_picker.add_theme_font_size_override('font_size',16)
	for state in ['font_color','font_hover_color','font_pressed_color','font_focus_color']:
		strength_picker.add_theme_color_override(state,Color('#355d4c'))
	var picker_style = StyleBoxFlat.new()
	picker_style.bg_color = Color('#e3d6b6')
	picker_style.set_corner_radius_all(7)
	for state in ['normal','hover','pressed','focus']:
		strength_picker.add_theme_stylebox_override(state,picker_style)
	for s in Data.STRENGTHS:
		strength_picker.add_item(s+' preparation')
	strength_picker.item_selected.connect(func(index): strength = index; save_game())
	modal = Control.new()
	add_child(modal)
	modal.z_index = 30
	modal.size = Vector2(1440,900)
	var shade = ColorRect.new()
	modal.add_child(shade)
	shade.size = modal.size
	shade.color = Color(0.07,0.12,0.10,0.91)
	page = game.supplies.panel_at(modal,Rect2(100,70,1240,760))
	page_style = page.get_theme_stylebox('panel')
	modal.hide()
	strength_picker.hide()
	var args = OS.get_cmdline_args()
	if not ('--script' in args or '-s' in args) and not game.has_meta('practice'):
		open_menu()

func day():
	return int(cursor/5)

func _on_speech_input(event, show_speech):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		speech_dismissed = not show_speech
		refresh()
		get_viewport().set_input_as_handled()

func current_case():
	return cases[cursor]

func needs_pulse():
	return day() >= 4 or (replay and int(current_case().strength) != 0)

func recipe_available(index):
	return not active or replay or day() >= 1 or index < 12

func patient_record():
	var c = current_case()
	var p = B.PATIENTS[int(c.actor)].duplicate(true)
	p.mask = c.mask
	p.story = Data.detailed_story(c)
	if not replay:
		var botanical = herbs.lesson(int(c.actor),int(c.mask))
		if not botanical.is_empty():
			var accounts = [
				'I brought these pale leaves from my route. Gran used to steep them when my cheeks burned. I wonder what makes them cool?',
				'There is an emberroot in my basket from the baker’s garden. The old gardener said its warmth stays inside until you bruise the fibres.',
				'These silver leaves caught on my boots by the mill. The book says they can anchor drifting magic, but only when ground. Perhaps they could help?'
			]
			p.story += '\n\n'+accounts[int(c.actor)]
	if c.has('allergy'):
		p.allergy = int(c.allergy)
	p.treatments = c.route
	p.minimum = c.route.size()
	p.hint = 'Collect the tool findings, match them to the symptom guide, then choose a safe remedy. Review every ingredient for allergies.'
	return p

func start_campaign():
	herbs = Herbalism.new()
	herbal_ui.feedback = ''
	herbal_ui.garden_patch = -1
	herbal_ui.selected = 0
	active = true
	replay = false
	completed = false
	cases = Data.appointments()
	cursor = 0
	history.clear()
	projects.clear()
	game.clinic_stars = 0
	play_seconds = 0.0
	begin_case()

func begin_case():
	evening = false
	examined.clear()
	known_mask = 0
	hypothesis = 0
	diagnosed = false
	strength = 0
	batch_strength = 0
	herbs.finish = ''
	notice = ''
	game.load_patient(int(current_case().actor))
	game.pinned = 0
	game.message = 'Listen to your neighbour and observe their symptoms. Select Diagnose patient when you are ready.'
	if not botanical_lesson().is_empty():
		game.message = 'A neighbour brought an unfamiliar herb. Examine the sample tray, then visit Garden & preparations.'
	close()

func botanical_lesson():
	return {} if replay else herbs.lesson(int(current_case().actor),game.symptoms)

func clear_page(title, subtitle = ''):
	game.supplies.close()
	page.position = Vector2(100,70)
	page.size = Vector2(1240,760)
	page.add_theme_stylebox_override('panel',page_style)
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()
	modal.show()
	label(title,Rect2(36,20,1160,46),30)
	label(subtitle,Rect2(36,72,1160,76),17)

func label(words, rect, font_size = 18):
	return game.supplies.label_at(page,words,rect,font_size)

func button(words, rect, callback):
	var control = game.supplies.button_at(page,words,rect,callback)
	control.add_theme_color_override('font_disabled_color',Color('#777968'))
	return control

func reading(words, rect):
	var text = RichTextLabel.new()
	page.add_child(text)
	text.position = rect.position
	text.size = rect.size
	text.add_theme_font_size_override('normal_font_size',18)
	text.add_theme_color_override('default_color',Color('#355d4c'))
	text.text = words
	return text

func close():
	if not active or evening or completed:
		return
	modal.hide()
	view = 'room'
	game.refresh()
	save_game()

func open_menu():
	view = 'menu'
	clear_page('Hearthbrew — The Moonflower Letters','An eight-day story of strange ailments, familiar neighbours and a village learning to mend.\nProgress saves automatically. No appointments have a time limit.')
	reading('Listen → examine → diagnose → prepare → brew\n\n40 authored appointments follow the existing village cast. Later visits introduce combined ailments, magical tolerances and a mystery linking the clinic to the old mill.\n\nThe casebook contains a symptom guide, visit history and village evidence. Brewing remains hands-on, with the animation speed and finish controls available throughout.',Rect2(40,180,1130,260))
	button('Begin a new campaign',Rect2(40,475,355,48),func():
		if FileAccess.file_exists(save_path):
			confirm_new()
		else:
			start_campaign())
	var resume_button = button('Continue saved campaign',Rect2(425,475,355,48),load_game)
	resume_button.disabled = not FileAccess.file_exists(save_path)
	button('Free practice clinic',Rect2(810,475,355,48),func():
		active = false
		modal.hide()
		strength_picker.hide()
		game.new_shift())
	if active:
		button('Back to current campaign',Rect2(40,550,355,45),func():
			if completed: open_ending()
			elif evening: open_evening()
			else: close())
	label(notice,Rect2(40,630,1130,70),17)

func confirm_new():
	clear_page('Start again?','A new campaign replaces your existing campaign save. Free practice keeps the campaign save intact.')
	button('Keep my save',Rect2(40,200,360,50),open_menu)
	button('Replace save & begin',Rect2(440,200,360,50),start_campaign)

func open_casebook():
	if not active:
		open_menu()
		return
	if completed:
		open_ending()
		return
	if evening:
		open_evening()
		return
	view = 'case'
	var heading = 'Clinic shifts · Case %d / 40' % [cursor+1] if replay else 'Day %d · %s · Visit %d / 5' % [day()+1,Data.CHAPTERS[day()][0],cursor%5+1]
	clear_page(heading,'%s: “%s”' % [game.patient().name,current_case().story])
	for i in range(Data.TOOLS.size()):
		var tool = i
		var b = button(('✓ ' if examined.has(i) else '')+Data.TOOLS[i],Rect2(36+i*235,155,225,42),func(): examine(tool))
		b.disabled = i == 4 and not needs_pulse()
	var evidence = 'FINDINGS\n\n'
	if examined.has(3) and not botanical_lesson().is_empty():
		evidence = 'BOTANICAL SAMPLE\n'+botanical_lesson().clue+'\n\nFINDINGS\n\n'
	for f in Data.FINDINGS:
		if examined.has(int(f[1])):
			evidence += ('• '+str(f[2] if (game.symptoms & int(f[0])) != 0 else f[3])+'\n')
	if examined.has(4):
		evidence += '\n'+Data.PULSE[int(current_case().strength)]
	if examined.has(3) and int(current_case().get('resistant',0)) != 0:
		evidence += '\n\nThe sample holds anchored magic. '+', '.join(B.symptom_names(int(current_case().resistant)))+' need compound remedies made from separately bottled blends.'
	if examined.is_empty():
		evidence += 'Choose a tool above. Record both positive and negative findings. The guide explains what each finding means.'
	reading(evidence,Rect2(36,215,615,335))
	label('YOUR DIAGNOSIS · select every current symptom',Rect2(680,215,520,30),17)
	for i in range(B.SYMPTOMS.size()):
		var bit = int(B.SYMPTOMS[i].bit)
		var choice = CheckButton.new()
		page.add_child(choice)
		choice.position = Vector2(680+(i%2)*255,255+int(i/2)*43)
		choice.size = Vector2(250,40)
		choice.text = B.SYMPTOMS[i].name
		choice.add_theme_font_size_override('font_size',16)
		for state in ['font_color','font_hover_color','font_pressed_color','font_hover_pressed_color','font_focus_color']:
			choice.add_theme_color_override(state,Color('#355d4c'))
		choice.set_pressed_no_signal((hypothesis & bit) != 0)
		choice.toggled.connect(func(on):
			hypothesis = hypothesis | bit if on else hypothesis & ~bit
			diagnosed = false
			notice = 'Diagnosis changed. Confirm it against the recorded findings before serving.'
			if is_instance_valid(diagnosis_feedback): diagnosis_feedback.text = notice
			game.refresh()
			save_game())
	button('Confirm diagnosis',Rect2(680,530,490,44),confirm_diagnosis)
	diagnosis_feedback = label(notice if not notice.is_empty() else ('Diagnosis confirmed. Choose a remedy and check allergies.' if diagnosed else 'Evidence first: the recipe filter follows your recorded findings.'),Rect2(36,585,1140,65),18)
	button('Symptom guide',Rect2(36,670,230,42),open_guide)
	button('Village journal',Rect2(281,670,230,42),open_journal)
	button('Return to brewing',Rect2(526,670,300,42),close)
	button('Save / main menu',Rect2(841,670,330,42),func(): save_game(); open_menu())

func examine(tool, show_panel = true):
	if tool == 4 and not needs_pulse():
		return
	if not examined.has(tool):
		examined.append(tool)
	if tool == 3 and not botanical_lesson().is_empty():
		herbs.discover(int(botanical_lesson().herb))
	known_mask = 0
	for f in Data.FINDINGS:
		if examined.has(int(f[1])):
			known_mask |= game.symptoms & int(f[0])
	notice = ''
	save_game()
	if show_panel:
		open_casebook()

func confirm_diagnosis():
	if hypothesis != game.symptoms or (known_mask & hypothesis) != hypothesis:
		notice = 'The evidence does not support this diagnosis yet. Compare each selected symptom with the guide, and examine any missing areas.'
		diagnosed = false
	elif needs_pulse() and not examined.has(4):
		notice = 'The ailments fit. Check the pulse charm as well: later cases need the correct preparation strength.'
	elif (day() >= 4 or int(current_case().get('resistant',0)) != 0) and not examined.has(3):
		notice = 'Check the sample tray for deep-set enchantments before choosing your treatment.'
	else:
		diagnosed = true
		notice = 'Diagnosis confirmed. '+(Data.PULSE[int(current_case().strength)] if needs_pulse() else 'Use a standard preparation.')
	game.refresh()
	save_game()
	open_casebook()

func open_guide():
	view = 'guide'
	clear_page('The field guide','Tool findings distinguish similar complaints. Multiple findings may mean several symptoms; treatment can require several remedies.')
	var words = ''
	for i in range(Data.FINDINGS.size()):
		var f = Data.FINDINGS[i]
		words += '%s · %s\n%s\n\n' % [B.SYMPTOMS[i].name,Data.TOOLS[int(f[1])],f[2]]
	words += 'PREPARATION STRENGTH\nFrom day five, and in clinic shifts with a pulse charm, examine the pulse: faint = gentle; even = standard; surging = concentrated. Select strength before stirring each final remedy. Intermediate blends use the ordinary method.\n\nDEEP-SET MAGIC\nLater sample trays can reveal anchored enchantments. The named symptoms need a compound remedy. For example, Star lantern treats anchored invisibility, Stillwater elixir treats anchored hiccups, Garden hush treats anchored blooming, and Twilight harmony treats anchored temperatures. Other symptoms can still use simple remedies.\n\nSAFE TREATMENT\nRead allergy warnings and recipe notes. Treat floating before using Dewdrop draught, or choose its safe Rosecool alternative. A wrong preparation must be discarded and brewed again. New side effects need a fresh examination.'
	words += '\n\nBOTANICAL PREPARATION\nExamine the first three neighbours’ samples to identify Moonleaf, Emberroot and Silverleaf. Steep or grind a portion at Garden & preparations, brew the usual remedy, then select a bottled extract at the bench before serving. Each herb has different properties when steeped or ground. Later, an extract can treat a second symptom alongside a successful remedy. It cannot rescue an unsafe brew or replace a compound remedy for anchored magic. Silverleaf finishes share the Silverleaf allergy warning. Used extracts are consumed; unused finishes can be removed without loss.\n\nGARDEN\nHerbs regrow in two clinic days and give three portions. Free common cuttings prevent shortages. Helping Poppy, Pip and Juniper with their botanical treatments prepares two more planting patches and unlocks Hushbell. Growth continues every five appointments in continuing clinic shifts.'
	words += '\n\nRECIPE INGREDIENTS\nOpen Recipe ingredients from the garden, bench or pantry. One harvested portion makes three pantry bottles after three preparation steps; learned preparations can be repeated immediately. Moonleaf makes moonmilk and Emberroot makes ember nectar. Lavender, moss and rose seeds are available immediately; Pip also unlocks Ginger, and Juniper unlocks Valerian and Burdock. Collect dew, shared honey and starlight once per clinic day. These are game-world magical preparations. Pantry bottles are spent when poured, including discarded brews; unpoured bottles remain in stock. Request missing recipe supplies in the pantry for a free emergency refill. Practice mode remains unlimited.'
	reading(words,Rect2(40,165,1140,470))
	button('Back to case',Rect2(40,670,320,42),open_casebook)

func open_journal():
	view = 'journal'
	clear_page('The village journal','Letters, completed appointments and the evidence you have gathered. The source must explain the whole pattern.')
	var words = 'Time at the clinic: %d minutes\n\nCURRENT CHAPTER\n' % int(play_seconds/60.0)+Data.CHAPTERS[day()][1]+'\n\nVILLAGE EVIDENCE\n'
	for i in range(day()):
		words += 'Day %d: %s\n\n' % [i+1,Data.CHAPTERS[i][2]]
	words += '\nCOMPLETED VISITS\n'
	for entry in history:
		words += entry+'\n'
	if history.is_empty():
		words += 'Your first patient is waiting. Findings stay in the current casebook until their visit ends.'
	words += '\n\nCLINIC IMPROVEMENTS\n'+'; '.join(projects)
	words += '\n\nRECIPE PROGRESSION\nTwelve single-mixture remedies are available on day one. Nine compound remedies arrive on day two, including two separately bottled blends and a final combination.'
	words += '\n\nTHE APOTHECARY GARDEN\n%d / 10 herbs discovered. %d / 3 botanical neighbours helped.\n' % [herbs.known.size(),herbs.helped.size()]
	words += 'Poppy, Pip and Juniper prepared two more planting patches and brought Hushbell seeds. The whole shared plot is available.' if herbs.rewarded else 'Help the first three neighbours with botanical finishes to prepare two more planting patches and discover Hushbell.'
	for id in herbs.mastered:
		words += '\n'+herbs.title(id)+': '+', '.join(B.symptom_names(herbs.effect(id)))
	words += '\n\nPANTRY STOCK\n'
	for i in range(B.BASE_INGREDIENT_COUNT): words += '%s: %d bottles · %s\n' % [B.INGREDIENTS[i].name,int(herbs.inventory[i]),herbs.source_name(i)]
	reading(words,Rect2(40,165,1140,470))
	button('Back',Rect2(40,670,320,42),open_casebook)

func before_serve():
	if not diagnosed:
		game.say('Select Diagnose patient and confirm the diagnosis before serving a remedy.',false)
		return false
	if not replay and cursor == 39 and game.result_recipe >= 0 and (int(B.RECIPES[game.result_recipe].cure) & B.BLOOM) != 0 and game.result_recipe != 14:
		game.say('The final root sample needs Garden hush. Use that remedy for Poppy’s blooming so the enchanted roots can be quieted too.',false)
		return false
	if batch_strength != int(current_case().strength):
		game.say('This preparation has the wrong strength. Discard it, set the strength shown by the pulse charm, and brew again.',false)
		return false
	if game.result_recipe >= 0:
		var recipe = B.RECIPES[game.result_recipe]
		var anchored = int(current_case().get('resistant',0)) & game.symptoms & int(recipe.cure)
		if anchored != 0 and recipe.get('stages',[]).is_empty():
			game.say('The sample showed anchored magic. This symptom needs a compound remedy; check the field guide for alternatives.',false)
			return false
		var lesson = botanical_lesson()
		if not lesson.is_empty() and (int(recipe.cure) & int(lesson.mask)) != 0:
			if not examined.has(3) or herbs.finish != herbs.key(int(lesson.herb),str(lesson.method)):
				game.say('Examine the sample tray, then add the matching botanical finish at Garden & preparations. Your brewed remedy is kept.',false)
				return false
		if herbs.finish != '':
			var botanical_mask = herbs.effect(herbs.finish)
			if (botanical_mask & game.symptoms) == 0:
				game.say('This extract supports a different ailment. Remove or replace the finish at the preparation bench; your remedy is kept.',false)
				return false
			if (botanical_mask & int(current_case().get('resistant',0))) != 0 and (recipe.get('stages',[]).is_empty() or (botanical_mask & int(recipe.cure)) == 0):
				game.say('This botanical finish cannot clear anchored magic. Brew the compound remedy for that symptom.',false)
				return false
	return true

func apply_botanical(outcome):
	# An appropriate finish can treat a second symptom, but never rescue an unsafe base brew.
	if herbs.finish.begins_with('2:') and int(game.patient().allergy) == 9:
		return {'mask':game.symptoms | B.BLOOM,'message':'Silverleaf in the botanical finish triggered an allergy. Treat the blooming and choose another preparation.','good':false}
	if outcome.good and herbs.finish != '':
		outcome.mask = int(outcome.mask) & ~herbs.effect(herbs.finish)
		outcome.message += ' '+herbs.title(herbs.finish)+' supports the treatment.'
	return outcome

func consume_botanical(previous_mask, next_mask):
	var lesson = botanical_lesson()
	if not lesson.is_empty() and (previous_mask & int(lesson.mask)) != 0 and (next_mask & int(lesson.mask)) == 0 and herbs.finish == herbs.key(int(lesson.herb),str(lesson.method)):
		herbs.record_help(int(current_case().actor))
	herbs.consume()

func after_treatment(previous_mask):
	known_mask &= game.symptoms
	hypothesis &= game.symptoms
	if (game.symptoms & ~previous_mask) != 0:
		diagnosed = false
		examined.clear()
		known_mask = 0
	if game.symptoms == 0:
		game.say('%s feels better. %d stars. Their letter will join your journal.' % [game.patient().name,game.patient_stars])
		if herbs.rewarded and herbs.helped.size() == 3 and int(current_case().actor) == 2 and not replay:
			game.say('Poppy, Pip and Juniper prepare more of the garden and bring Hushbell seeds. Visit your garden to see their gift!')
	game.refresh()
	save_game()

func advance():
	if game.symptoms != 0:
		return
	if not evening:
		history.append('Day %d · %s · %s · %d stars' % [day()+1,game.patient().name,', '.join(B.symptom_names(int(current_case().mask))),game.patient_stars])
	if cursor%5 == 4 and not replay:
		evening = true
		save_game()
		open_evening()
	else:
		if replay and cursor%5 == 4: herbs.grow(herbs.growth_day+1)
		cursor += 1
		if cursor >= cases.size():
			cursor = 0
			if replay:
				cases.shuffle()
		begin_case()

func open_evening():
	view = 'evening'
	clear_page('Evening · Day %d complete' % [day()+1],Data.CHAPTERS[day()][2])
	reading('Five neighbours helped today.\n\nClinic stars: %d / %d\n\n%s\n\nYour work is saved. You can close the game here and continue tomorrow.' % [game.clinic_stars,(cursor+1)*3,('Before tomorrow, choose a small improvement. Both projects remain available on later evenings.' if day() < 7 else 'The cases are connected. Choose the source supported by the letters and sample findings to finish the story.')],Rect2(40,180,1130,230))
	if day() < 7:
		button('Study field notes',Rect2(40,470,530,55),func(): finish_evening('Field notes'))
		button('Arrange the workbench',Rect2(615,470,555,55),func(): finish_evening('Workbench'))
		label('Field notes: tomorrow begins with one examination recorded.\nWorkbench: tomorrow begins at 2× animation speed. You can always change speed yourself.',Rect2(40,550,1130,76),18)
	else:
		button('The village well',Rect2(40,465,350,60),func(): wrong_source('The water samples were clear. What explains the silver pollen and glowing roots?'))
		button('The mill bell itself',Rect2(425,465,350,60),func(): wrong_source('The bell carried pollen on the wind. Moss found something else feeding the flowers.'))
		button('The enchanted moonflower roots',Rect2(810,465,365,60),finish_story)
	label(notice,Rect2(40,640,1130,60),18)
	button('Visit the garden',Rect2(850,700,320,36),herbal_ui.open_garden)
	button('Save / main menu',Rect2(40,700,320,36),func(): save_game(); open_menu())

func finish_evening(project):
	if not evening or day() >= 7: return
	projects.append('Day %d: %s' % [day()+1,project])
	cursor += 1
	herbs.grow(herbs.growth_day+1)
	begin_case()
	if project == 'Field notes':
		# Assistance records a relevant tool, while the player still forms the diagnosis.
		for f in Data.FINDINGS:
			if (int(current_case().mask) & int(f[0])) != 0:
				examine(int(f[1]),false)
				break
	else:
		game.speed = 2.0
	game.refresh()
	save_game()

func wrong_source(words):
	notice = words
	open_evening()

func finish_story():
	completed = true
	evening = false
	save_game()
	open_ending()

func open_ending():
	view = 'ending'
	clear_page('A quieter tomorrow','The moonflowers were being fed by the buried growth charm. You quieted the enchanted roots with Garden hush and helped the village recover.')
	reading('Poppy hangs the final letter beside your window. Hazel brings honey, Pip brings bread, and Moss plants ordinary flowers along the mill path.\n\n40 appointments completed · %d / 120 stars · %d minutes at the clinic\n\nThe clinic remains open. Free practice offers the original roster. Continuing clinic shifts mix safe case variants, with diagnosis and preparation strengths still required.\n\nThank you for keeping the light on.' % [game.clinic_stars,int(play_seconds/60.0)],Rect2(40,180,1130,290))
	button('Continue clinic shifts',Rect2(40,550,535,55),start_replay)
	button('Save / main menu',Rect2(615,550,555,55),open_menu)

func start_replay():
	# Authored, proven-solvable combinations preserve allergies and safe routes.
	replay = true
	completed = false
	evening = false
	cases = Data.appointments()
	cases.shuffle()
	cursor = 0
	game.clinic_stars = 0
	begin_case()

func refresh():
	var room_visible = not game.supplies.modal.visible
	if garden_button:
		garden_button.visible = room_visible and active
		garden_button.disabled = game.mixing or game.pouring
		garden_button.text = 'Finish: '+herbs.title(herbs.finish) if herbs.finish != '' else 'Garden & preparations'
		garden_button.tooltip_text = 'Prepare herbs and tend your garden.' if herbs.finish == '' else herbs.title(herbs.finish)+' · '+', '.join(B.symptom_names(herbs.effect(herbs.finish)))
	notebook.visible = room_visible
	var account = game.patient().story if active else Data.detailed_story({'actor':game.patient_index,'story':game.patient().story,'mask':game.patient().mask})
	speech_panel.visible = room_visible and not speech_dismissed and not game.mixing and not game.pouring
	speech_name.text = game.patient().name+' says…'
	var words = '“'+account+'”' if game.symptoms != 0 else '“That feels so much better. Thank you for taking the time to help me.”'
	if speech_text.text != words:
		speech_text.text = words
		speech_text.scroll_to_line(0)
	strength_picker.visible = room_visible and active and needs_pulse()
	strength_picker.select(strength)
	strength_picker.disabled = game.mixing or game.pouring or game.has_result
	if not active:
		game.get_node('Interface/Clipboard/Hint').text = 'Hint'
		return
	game.get_node('Interface/Header/Progress').text = ('Clinic shifts' if replay else 'Day %d / 8' % [day()+1])+' · Case %d / 40\n%d clinic stars' % [cursor+1,game.clinic_stars]
	var chart = game.get_node('Interface/Clipboard')
	chart.get_node('Symptoms').text = (', '.join(B.symptom_names(game.symptoms)) if diagnosed else 'Awaiting diagnosis') if game.symptoms != 0 else 'Feeling wonderful!'
	chart.get_node('Hint').text = 'Diagnose patient'
	var brief = str(current_case().story)
	chart.get_node('Story').text = '“'+brief.left(110)+('…' if brief.length() > 110 else '')+'”'
	chart.get_node('Next').text = 'Close the clinic for today' if cursor%5 == 4 and not replay else 'Next appointment'

func save_game():
	if not active:
		return
	var snapshot = {}
	for key in SNAPSHOT_KEYS:
		snapshot[key] = game.get(key)
	# A save made during animation resumes its stable endpoint, without replaying input.
	if game.pouring:
		snapshot.poured_count = game.queue.size()
		if game.active_table_slot >= 0:
			snapshot.table_empty = game.table_empty.duplicate()
			snapshot.table_empty[game.active_table_slot] = true
	if game.mixing:
		snapshot.has_result = true
		snapshot.result_recipe = B.resolve(game.queue)
		snapshot.result_blend = B.resolve_blend(game.queue) if snapshot.result_recipe < 0 else -1
	var data = {'version':1,'cursor':cursor,'cases':cases,'examined':examined,'known_mask':known_mask,'hypothesis':hypothesis,'diagnosed':diagnosed,'strength':strength,'batch_strength':batch_strength,'history':history,'projects':projects,'evening':evening,'completed':completed,'replay':replay,'play_seconds':play_seconds,'game':snapshot}
	data.herbalism = herbs.snapshot()
	var file = FileAccess.open(save_path+'.tmp',FileAccess.WRITE)
	if file == null:
		game.say('Could not save campaign: '+error_string(FileAccess.get_open_error()),false)
		return
	file.store_string(JSON.stringify(data))
	file.close()
	var err = DirAccess.rename_absolute(save_path+'.tmp',save_path)
	if err != OK:
		game.say('Could not finish saving campaign: '+error_string(err),false)

func load_game():
	if not FileAccess.file_exists(save_path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not valid_save(data):
		notice = 'This save could not be read. Your file has been kept; you can start a new campaign.'
		open_menu()
		return
	active = true
	cursor = int(data.cursor)
	cases = data.cases
	for c in cases:
		c.actor = int(c.actor)
		c.mask = int(c.mask)
		c.strength = int(c.strength)
		c.route = integers(c.route)
	game.load_patient(int(current_case().actor))
	for key in SNAPSHOT_KEYS:
		var value = data.game[key]
		if key in ['queue','table_stock','stored_blends']:
			value = integers(value)
		elif value is float and key != 'speed':
			value = int(value)
		game.set(key,value)
	examined = integers(data.examined)
	known_mask = int(data.known_mask)
	hypothesis = int(data.hypothesis)
	diagnosed = data.diagnosed
	strength = int(data.strength)
	batch_strength = int(data.batch_strength)
	history = data.history
	projects = data.projects
	evening = data.evening
	completed = data.completed
	replay = data.replay
	play_seconds = float(data.get('play_seconds',0.0))
	herbs = Herbalism.new()
	if data.has('herbalism'):
		herbs.restore(data.herbalism)
	else:
		# Earlier saves retain their existing treatment routes; the garden is optional.
		herbs.enabled = false
		herbs.known = [0,1,2,3,4,5,6,7,8,9]
	if not data.has('herbalism') or not data.herbalism.has('supply_version'):
		var carried = []
		for i in range(game.table_stock.size()):
			if not game.table_empty[i]: carried.append(game.table_stock[i])
		herbs.emergency_supplies(carried)
	herbal_ui.feedback = ''
	herbal_ui.garden_patch = -1
	game.result_color = B.finished_color(game.queue) if game.has_result else Color('#efdeb3')
	game.refresh()
	if completed: open_ending()
	elif evening: open_evening()
	else: close()

func integers(values):
	var result = []
	for value in values:
		result.append(int(value))
	return result

func valid_save(data):
	if not data is Dictionary or data.get('version') != 1:
		return false
	if data.has('herbalism') and not Herbalism.valid(data.herbalism): return false
	var saved_time = data.get('play_seconds',0.0)
	if not (saved_time is float or saved_time is int) or saved_time < 0:
		return false
	for key in ['cursor','cases','examined','known_mask','hypothesis','diagnosed','strength','batch_strength','history','projects','evening','completed','replay','game']:
		if not data.has(key): return false
	if not number_in(data.cursor,0,39) or not data.cases is Array or data.cases.size() != 40:
		return false
	for key in ['diagnosed','evening','completed','replay']:
		if not data[key] is bool: return false
	for key in ['known_mask','hypothesis']:
		if not number_in(data[key],0,4095): return false
	for key in ['strength','batch_strength']:
		if not number_in(data[key],0,2): return false
	for key in ['history','projects']:
		if not data[key] is Array: return false
		for line in data[key]:
			if not line is String: return false
	if not int_array(data.examined,0,4): return false
	for c in data.cases:
		if not c is Dictionary: return false
		for key in ['actor','mask','route','story','strength']:
			if not c.has(key): return false
		if not number_in(c.actor,0,B.PATIENTS.size()-1) or not number_in(c.mask,1,4095) or not number_in(c.strength,0,2): return false
		if not c.story is String or not int_array(c.route,0,B.RECIPES.size()-1) or c.route.is_empty(): return false
		if c.has('resistant') and not number_in(c.resistant,0,4095): return false
		if c.has('allergy') and not number_in(c.allergy,-1,B.BASE_INGREDIENT_COUNT-1): return false
	if not data.game is Dictionary: return false
	var state = data.game
	for key in SNAPSHOT_KEYS:
		if not state.has(key): return false
	for key in ['has_result','awarded','muted']:
		if not state[key] is bool: return false
	for key in ['batches','served','clinic_stars']:
		if not number_in(state[key],0,1000000): return false
	if not number_in(state.patient_stars,0,3) or not number_in(state.speed,1,2): return false
	if not number_in(state.patient_index,0,B.PATIENTS.size()-1) or int(state.patient_index) != int(data.cases[int(data.cursor)].actor): return false
	if not number_in(state.symptoms,0,4095) or not number_in(state.pinned,0,B.RECIPES.size()-1): return false
	if not number_in(state.result_recipe,-1,B.RECIPES.size()-1) or not number_in(state.result_blend,-1,B.INGREDIENTS.size()-1): return false
	if not int_array(state.queue,0,B.INGREDIENTS.size()-1) or state.queue.size() > 4: return false
	if not number_in(state.poured_count,0,state.queue.size()): return false
	if not int_array(state.table_stock,0,B.BASE_INGREDIENT_COUNT-1) or state.table_stock.size() > 6: return false
	if not state.table_empty is Array or state.table_empty.size() != state.table_stock.size(): return false
	for empty in state.table_empty:
		if not empty is bool: return false
	return int_array(state.stored_blends,B.BASE_INGREDIENT_COUNT,B.INGREDIENTS.size()-1)

func number_in(value, minimum, maximum):
	return (value is int or value is float) and value == int(value) and value >= minimum and value <= maximum

func int_array(values, minimum, maximum):
	if not values is Array: return false
	for value in values:
		if not number_in(value,minimum,maximum): return false
	return true
