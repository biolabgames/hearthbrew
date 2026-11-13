extends SceneTree
const H = preload('res://scripts/herbalism.gd')
const B = preload('res://brewing.gd')
var checks = 0
var failures = []
var game
var campaign

func _initialize():
	call_deferred('run')

func check(condition, description):
	checks += 1
	if not condition:
		failures.append(description)
		printerr('FAIL: '+description)

func press(words):
	for action in campaign.page.find_children('*','Button',true,false):
		if action.text == words and not action.disabled:
			action.pressed.emit()
			return true
	check(false,'Enabled action: '+words)
	return false

func capture(file_name):
	if '--capture' not in OS.get_cmdline_user_args(): return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png('res://previews/'+file_name+'.png') == OK,'Rendered '+file_name)

func brew(sequence):
	game.table_stock = sequence.filter(func(id): return id < B.BASE_INGREDIENT_COUNT)
	game.table_empty.clear()
	for ingredient in sequence:
		var before = campaign.herbs.inventory.duplicate()
		game.pour_ingredient(ingredient)
		check(game.pouring,'Actual pour starts for '+B.INGREDIENTS[ingredient].name)
		if ingredient < B.BASE_INGREDIENT_COUNT:
			check(campaign.herbs.inventory[ingredient] == before[ingredient]-1,'Actual pour spends one prepared bottle')
		else:
			check(campaign.herbs.inventory == before,'Combining blends does not spend raw bottles twice')
		game.finish_pour()
	game.start_mix()
	game.finish_mix()

func run():
	var h = H.new()
	check(H.HERBS.size() == 10 and H.SOURCES.size() == 12,'Ten herbs and twelve ingredient sources')
	check(h.known == [0,4,5,6],'Starter seeds include lavender, moss and rose')
	h.discover(1)
	h.discover(2)
	check(7 in h.known and 8 in h.known and 9 in h.known,'Patient samples unlock new root crops')
	for actor in range(3): h.record_help(actor)
	check(h.known.size() == 10,'Neighbour reward completes the seed collection')
	for ingredient in range(12):
		var source = H.SOURCES[ingredient]
		var herb = int(source.herb)
		if herb >= 0:
			h.plots[3] = {'herb':-1,'age':0}
			check(h.plant(3,herb),'Plant source for '+B.INGREDIENTS[ingredient].name)
			check(not h.harvest(3),'Young ingredient herb cannot be harvested')
			h.grow(h.growth_day+2)
			check(h.harvest(3),'Mature source can be harvested')
		else:
			check(h.collect_source(ingredient),'Collect '+h.source_name(ingredient))
			check(not h.collect_source(ingredient),'Collection cannot repeat within clinic day')
		var raw_before = h.source_count(ingredient)
		var bottles = h.inventory[ingredient]
		check(h.begin_ingredient(ingredient),'Prepare source '+str(ingredient))
		check(h.source_count(ingredient) == raw_before-1,'Exactly one raw portion reserved')
		check(not h.begin(0,'steep') and not h.begin_ingredient(ingredient),'Preparations cannot overlap')
		h.step_ingredient()
		var save = JSON.parse_string(JSON.stringify(h.snapshot()))
		check(H.valid(save),'Partial ingredient work saves validly')
		var resumed = H.new()
		resumed.restore(save)
		check(resumed.ingredient_work.step == 1,'Partial ingredient work resumes at correct step')
		resumed.cancel_ingredient()
		check(resumed.source_count(ingredient) == raw_before,'Cancel returns correct source portion')
		h.step_ingredient()
		check(h.step_ingredient() and h.inventory[ingredient] == bottles+3,'Third step bottles three usable ingredients')
		check(h.repeat_ingredient(ingredient) and h.inventory[ingredient] == bottles+6,'Mastered ingredient preparation repeats')
	for ingredient in [2,5,10]:
		h.grow(h.growth_day+1)
		check(h.collect_source(ingredient),'Collectors renew on clinic day')
	var legacy = h.snapshot()
	for field in ['supply_version','inventory','gathered','collected_day','ingredient_work','learned_ingredients']: legacy.erase(field)
	legacy.raw = [2,2,2,0]
	legacy.known = [0,1,2]
	legacy.plots = [{'herb':0,'age':2},{'herb':1,'age':2},{'herb':2,'age':2},{'herb':-1,'age':0},{'herb':-1,'age':0},{'herb':-1,'age':0}]
	check(H.valid(legacy),'Old four-herb saves remain valid')
	var migrated = H.new()
	migrated.restore(JSON.parse_string(JSON.stringify(legacy)))
	check(migrated.raw.size() == 10 and 7 in migrated.known and 9 in migrated.known and H.valid(migrated.snapshot()),'Legacy migration preserves old herbs and adds new supplies')
	for field in ['inventory','gathered','collected_day','ingredient_work','learned_ingredients']:
		var bad = h.snapshot()
		bad[field] = null
		check(not H.valid(bad),'Malformed '+field+' rejected')
	var bad_count = h.snapshot()
	bad_count.inventory[0] = -1
	check(not H.valid(bad_count),'Negative bottle stock rejected')
	var bad_day = h.snapshot()
	bad_day.collected_day['2'] = h.growth_day+1
	check(not H.valid(bad_day),'Future collection dates rejected')
	game = load('res://main.tscn').instantiate()
	game.set_meta('practice',true)
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.muted = true
	campaign = game.campaign
	campaign.save_path = 'user://garden_ingredient_verification.json'
	campaign.start_campaign()
	for tool in range(5): campaign.examine(tool,false)
	campaign.hypothesis = game.symptoms
	campaign.confirm_diagnosis()
	campaign.close()
	campaign.herbs = h
	# Produce every recipe from grown/collected raw material, starting with zero bottles.
	for recipe_index in range(B.RECIPES.size()):
		h.inventory.fill(0)
		for ingredient in B.raw_ingredients(B.RECIPES[recipe_index]):
			if h.source_count(ingredient) == 0:
				var herb = int(H.SOURCES[ingredient].herb)
				if herb >= 0:
					h.plots[3] = {'herb':herb,'age':2}
					h.harvest(3)
				else:
					h.grow(h.growth_day+1)
					h.collect_source(ingredient)
			check(h.begin_ingredient(ingredient),'Recipe supply preparation starts')
			for step in range(3): h.step_ingredient()
		var recipe = B.RECIPES[recipe_index]
		for stage in recipe.get('stages',[]):
			brew(stage.sequence)
			game.serve()
		brew(recipe.sequence)
		check(game.result_recipe == recipe_index,'Garden sources brew '+recipe.name)
		game.discard()
	# Real pantry actions cannot duplicate stock or spend a bottle twice.
	h.inventory.fill(0)
	h.inventory[0] = 1
	game.table_stock.clear()
	game.table_empty.clear()
	game.supplies.open('pantry')
	game.supplies.collect_bottle(0)
	game.supplies.collect_bottle(0)
	check(game.supplies.basket.size() == 1 and h.inventory[0] == 1,'Basket prevents overbooking without spending stock')
	game.supplies.remove_bottle(0)
	check(h.inventory[0] == 1 and game.supplies.remaining(0) == 1,'Removing full bottle makes stock available')
	game.supplies.collect_bottle(0)
	game.supplies.bring_to_table()
	game.pour_bottle(0)
	check(h.inventory[0] == 0,'Campaign bottle consumed at pour start')
	campaign.save_game()
	campaign.load_game()
	h = campaign.herbs
	check(h.inventory[0] == 0 and game.table_empty[0] and game.poured_count == 1,'Save during pour resumes without double consumption')
	game.pour_bottle(0)
	check(h.inventory[0] == 0 and not game.pouring,'Empty bottle cannot pour again')
	game.clear_queue()
	game.table_stock = [0]
	game.table_empty = [false]
	game.pour_bottle(0)
	check(not game.pouring and game.queue.is_empty(),'Depleted stock blocks even a stale full bottle')
	game.pinned = 16
	game.supplies.open('pantry')
	game.supplies.request_supplies()
	for stage in B.RECIPES[16].stages:
		for ingredient in stage.sequence: check(h.inventory[ingredient] > 0,'Emergency recovery covers compound recipe')
	game.supplies.close()
	campaign.herbal_ui.selected_ingredient = 3
	campaign.herbal_ui.open_ingredients()
	if campaign.herbs.source_count(3) == 0: press('Request a free Lavender cutting')
	check(press('Prepare three bottles'),'Preparation reachable through actual UI')
	press('Gather fragrant flower heads')
	campaign.save_game()
	campaign.load_game()
	check(campaign.herbs.ingredient_work.step == 1,'Campaign save preserves partial ingredient work')
	campaign.herbal_ui.open_ingredients()
	await capture('garden_ingredient_preparation')
	press('Steam the lavender')
	press('Condense and bottle the mist')
	check(campaign.herbs.inventory[3] >= 3,'UI finishes real pantry bottles')
	campaign.herbal_ui.selected_ingredient = 10
	campaign.herbal_ui.open_ingredients()
	await capture('garden_collection')
	# Render all plant species at their real patch positions in two representative views.
	campaign.herbs.rewarded = true
	for i in range(6): campaign.herbs.plots[i] = {'herb':i+4,'age':2}
	campaign.herbal_ui.open_garden()
	await capture('garden_ingredients_mature')
	for i in range(6): campaign.herbs.plots[i].age = 0
	campaign.herbal_ui.open_garden()
	await capture('garden_ingredients_young')
	campaign.close()
	game.supplies.open('pantry')
	await capture('garden_pantry_stock')
	# Practice retains its unlimited stock and does not change campaign inventory.
	game.supplies.close()
	campaign.active = false
	game.clear_queue()
	game.table_stock = [0]
	game.table_empty = [false]
	var stock_before = campaign.herbs.inventory.duplicate()
	game.pour_bottle(0)
	check(game.pouring and campaign.herbs.inventory == stock_before,'Practice pours remain unlimited')
	game.finish_pour()
	DirAccess.remove_absolute(campaign.save_path)
	print('GARDEN INGREDIENTS: %d checks, %d failures' % [checks,failures.size()])
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
