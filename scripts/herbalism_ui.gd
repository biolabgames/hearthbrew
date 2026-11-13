extends RefCounted
const H = preload('res://scripts/herbalism.gd')
const Sketch = preload('res://scripts/herb_sketch.gd')
const B = preload('res://brewing.gd')
var campaign
var selected = 0
var garden_patch = -1
var feedback = ''
var selected_ingredient = 0

func setup(owner_campaign):
	campaign = owner_campaign

func model():
	return campaign.herbs

func art(parent, herb, rect, age = 2, planter = true, progress = -1, grinding = false):
	var sketch = Sketch.new()
	parent.add_child(sketch)
	sketch.position = rect.position
	sketch.size = rect.size
	sketch.herb = herb
	sketch.growth = age
	sketch.planter = planter
	sketch.progress = progress
	sketch.grinding = grinding
	sketch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sketch

func frame(title, subtitle, section):
	campaign.clear_page(title,subtitle)
	campaign.view = section
	campaign.button('Preparation bench',Rect2(36,142,245,40),open_bench)
	campaign.button('Herb garden',Rect2(296,142,230,40),open_garden)
	campaign.button('Recipe ingredients',Rect2(542,142,260,40),open_ingredients)
	campaign.button('Return to clinic',Rect2(946,142,250,40),leave)

func leave():
	if campaign.evening: campaign.open_evening()
	elif campaign.completed: campaign.open_ending()
	else: campaign.close()

func changed(words, garden = false):
	feedback = words
	campaign.save_game()
	if garden: open_garden()
	else: open_bench()

func choose(index, garden):
	selected = int(model().known[index])
	if garden: open_garden()
	else: open_bench()

func selector(rect, garden):
	var choice = OptionButton.new()
	campaign.page.add_child(choice)
	choice.position = rect.position
	choice.size = rect.size
	for state in ['font_color','font_hover_color','font_pressed_color','font_focus_color']:
		choice.add_theme_color_override(state,Color('#355d4c'))
	choice.add_theme_color_override('font_disabled_color',Color('#777968'))
	var style = StyleBoxFlat.new()
	style.bg_color = Color('#e3d6b6')
	style.border_color = Color('#9f8664')
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	for state in ['normal','hover','pressed','focus','disabled']:
		choice.add_theme_stylebox_override(state,style)
	choice.add_theme_font_size_override('font_size',18)
	choice.disabled = not garden and not model().work.is_empty()
	if selected not in model().known: selected = 0
	var choices = model().known.filter(func(id): return garden or int(id) < 4)
	if selected not in choices: selected = 0
	for herb in choices:
		choice.add_item(H.HERBS[int(herb)].name)
	choice.select(choices.find(selected))
	choice.item_selected.connect(func(index): selected = int(choices[index]); open_garden() if garden else open_bench())

func select_garden_patch(index):
	garden_patch = index
	open_garden()

func open_garden():
	campaign.clear_page('','')
	campaign.view = 'garden'
	for child in campaign.page.get_children():
		campaign.page.remove_child(child)
		child.queue_free()
	campaign.page.position = Vector2.ZERO
	campaign.page.size = Vector2(1440,900)
	campaign.page.add_theme_stylebox_override('panel',StyleBoxEmpty.new())
	var garden = preload('res://scripts/garden_view.gd').new()
	campaign.page.add_child(garden)
	garden.setup(self)

func open_bench():
	if not model().work.is_empty(): selected = int(model().work.herb)
	frame('The preparation bench','Prepare an extract, brew a matching remedy, then return here to add the botanical finish before serving.','bench')
	var lesson = model().lesson(int(campaign.current_case().actor),campaign.game.symptoms)
	var clue = lesson.clue if not lesson.is_empty() else 'A botanical finish can treat a second ailment alongside a successful remedy. Anchored magic still needs its compound remedy. An unsafe base brew cannot be rescued by an extract.'
	campaign.reading(clue,Rect2(36,198,1160,74))
	selector(Rect2(36,290,430,42),false)
	campaign.label('%d raw portions available' % int(model().raw[selected]),Rect2(36,340,430,28),17)
	campaign.reading(H.HERBS[selected].note,Rect2(36,378,510,70))
	if model().work.is_empty():
		art(campaign.page,selected,Rect2(65,457,220,117),2,false)
		for i in range(2):
			var method = 'steep' if i == 0 else 'grind'
			var effect_name = ', '.join(B.symptom_names(int(H.HERBS[selected][method])))
			var action = campaign.button(('Steep' if i == 0 else 'Grind')+' · '+effect_name,Rect2(36+i*270,584,255,43),func():
				if model().begin(selected,method): changed('Follow the three preparation steps below.'))
			action.disabled = int(model().raw[selected]) < 1 or not model().ingredient_work.is_empty()
			var repeat_button = campaign.button('Repeat learned preparation',Rect2(36+i*270,637,255,37),func():
				if model().repeat_preparation(selected,method): changed('Prepared another '+model().title(model().key(selected,method))+'.'))
			repeat_button.disabled = model().key(selected,method) not in model().mastered or int(model().raw[selected]) < 1 or not model().ingredient_work.is_empty()
	else:
		var work = model().work
		var steep = ['Place leaves in the infuser','Pour warm water over the herb','Strain the infusion into a vial']
		var grind = ['Place the herb in the mortar','Crush the fibres with the pestle','Collect the ground extract in a vial']
		var steps = steep if work.method == 'steep' else grind
		art(campaign.page,int(work.herb),Rect2(65,486,370,84),2,false,int(work.step),work.method == 'grind')
		campaign.label('%s · step %d / 3' % [H.HERBS[int(work.herb)].name,int(work.step)+1],Rect2(36,456,430,27),18)
		campaign.button(steps[int(work.step)],Rect2(36,584,525,48),func():
			var ready = model().step()
			changed('Extract bottled. Brew a matching remedy, then add your finish.' if ready else 'The herb is changing. Continue preparing it.'))
		campaign.button('Put the herb away',Rect2(36,642,525,37),func(): model().cancel(); changed('The raw portion has been returned to your basket.'))
	campaign.label('PREPARED EXTRACTS',Rect2(625,290,570,30),19)
	var line = 0
	for id in model().extracts:
		if int(model().extracts[id]) <= 0: continue
		var extract = str(id)
		var caption = '%s ×%d · %s' % [model().title(id),int(model().extracts[id]),', '.join(B.symptom_names(model().effect(id)))]
		var ready = campaign.game.has_result and campaign.game.result_recipe >= 0
		var add = campaign.button(('✓ ' if model().finish == id else '')+caption,Rect2(625,334+line*39,570,35),func():
			if model().attach(extract): changed('Finish selected. Return to the clinic and serve your remedy.'))
		add.disabled = not ready
		add.tooltip_text = 'Brew a finished remedy first. An extract is used only when you serve.'
		line += 1
	if line == 0:
		campaign.reading('Your prepared vials will appear here.\n\nSteeping and grinding release different properties from the same herb. Read the patient’s clue and check the effects before choosing.',Rect2(625,345,565,175))
	var finish_name = 'No botanical finish selected.' if model().finish == '' else 'Selected: '+model().title(model().finish)
	campaign.label(finish_name,Rect2(625,653,570,32),17)
	if model().finish != '':
		campaign.button('Remove finish',Rect2(953,695,240,37),func(): model().finish = ''; changed('Finish removed. The extract is still in your basket.'))
	campaign.label(feedback,Rect2(36,697,880,45),16)

func ingredient_changed(words):
	feedback = words
	campaign.save_game()
	open_ingredients()

func open_ingredients():
	if not model().ingredient_work.is_empty(): selected_ingredient = int(model().ingredient_work.ingredient)
	frame('Garden ingredients','Harvest or collect raw materials, prepare three bottles, then fetch them from the pantry.','ingredients')
	var ingredient = selected_ingredient
	var source = H.SOURCES[ingredient]
	var herb = int(source.herb)
	campaign.label('BOTTLED STOCK',Rect2(36,202,350,32),19)
	for i in range(H.SOURCES.size()):
		var caption = '%s · %d' % [B.INGREDIENTS[i].name,int(model().inventory[i])]
		var entry = campaign.button(('✓ ' if i == ingredient else '')+caption,Rect2(36,244+i*33,350,30),func(): selected_ingredient = i; open_ingredients())
		entry.disabled = not model().ingredient_work.is_empty()
		entry.tooltip_text = 'Source: '+model().source_name(i)
	campaign.label(B.INGREDIENTS[ingredient].name,Rect2(426,200,744,42),28)
	campaign.reading('Source: '+model().source_name(ingredient)+'\n'+source.method+' · one raw portion makes three bottles.',Rect2(426,251,744,65))
	campaign.label('Raw portions: %d     Bottles in stock: %d' % [model().source_count(ingredient),int(model().inventory[ingredient])],Rect2(426,328,744,32),19)
	if herb >= 0:
		var botanical = TextureRect.new()
		campaign.page.add_child(botanical)
		botanical.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		botanical.texture = preload('res://scripts/garden_view.gd').botanical_texture(herb)
		botanical.position = Vector2(970,375)
		botanical.size = Vector2(196,190)
		botanical.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		botanical.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ongoing = not model().ingredient_work.is_empty()
	if ongoing:
		var step_index = int(model().ingredient_work.step)
		campaign.label('Preparation · step %d / 3' % [step_index+1],Rect2(426,386,510,32),20)
		campaign.button(source.steps[step_index],Rect2(426,438,510,48),func():
			var complete = model().step_ingredient()
			ingredient_changed('Three bottles added to pantry stock.' if complete else 'Continue preparing your ingredient.'))
		campaign.button('Cancel · return raw portion',Rect2(426,500,510,38),func(): model().cancel_ingredient(); ingredient_changed('Your raw portion was returned.'))
	else:
		var prepare = campaign.button('Prepare three bottles',Rect2(426,386,510,48),func():
			if model().begin_ingredient(ingredient): ingredient_changed('Follow the three preparation steps.'))
		prepare.disabled = not model().source_known(ingredient) or model().source_count(ingredient) < 1 or not model().work.is_empty()
		var repeat_action = campaign.button('Repeat learned preparation',Rect2(426,448,510,38),func():
			if model().repeat_ingredient(ingredient): ingredient_changed('Three more bottles added to pantry stock.'))
		repeat_action.disabled = ingredient not in model().learned_ingredients or prepare.disabled
		if herb < 0:
			var collect = campaign.button('Collect from '+source.name,Rect2(426,504,510,42),func():
				if model().collect_source(ingredient): ingredient_changed('Three raw portions collected. The source renews next clinic day.'))
			collect.disabled = int(model().collected_day[str(ingredient)]) >= model().growth_day
			campaign.label('Available once per clinic day; collectors work while you see patients.',Rect2(426,558,744,50),16)
		elif model().source_known(ingredient):
			campaign.button('Request a free '+H.HERBS[herb].name+' cutting',Rect2(426,504,510,42),func():
				model().cutting(herb)
				ingredient_changed('A neighbour shared one raw portion. Grow your own for three portions per harvest.'))
			campaign.label('Plant these seeds in open garden soil. Harvest three portions after two clinic days.',Rect2(426,558,744,50),16)
		else:
			campaign.reading('Identify patient samples to unlock these seeds. Pip introduces Ginger with Emberroot; Juniper introduces Valerian and Burdock with Silverleaf. Emergency pantry supplies remain available.',Rect2(426,503,744,100))
	if not model().work.is_empty():
		campaign.label('Finish or cancel the herbal preparation at the preparation bench first.',Rect2(426,615,744,43),17)
	campaign.button('Open pantry stock',Rect2(426,663,320,40),func(): campaign.close(); campaign.game.supplies.open('pantry'))
	campaign.label(feedback,Rect2(36,710,1160,40),16)
