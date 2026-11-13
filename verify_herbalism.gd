extends SceneTree
const H = preload('res://scripts/herbalism.gd')
const B = preload('res://brewing.gd')
var game
var campaign
var checks = 0
var failures = []

func _initialize():
	call_deferred('run')

func check(condition, description):
	checks += 1
	if not condition:
		failures.append(description)
		printerr('FAIL: '+description)

func press(words):
	for button in campaign.page.find_children('*','Button',true,false):
		if button.text == words and not button.disabled:
			button.pressed.emit()
			return true
	check(false,'Enabled UI action exists: '+words)
	return false

func diagnose():
	for tool in range(5): campaign.examine(tool,false)
	campaign.hypothesis = game.symptoms
	campaign.confirm_diagnosis()
	campaign.close()
	campaign.strength = int(campaign.current_case().strength)

func mix(index):
	var recipe = B.RECIPES[index]
	for stage in recipe.get('stages',[]):
		mix_sequence(stage.sequence)
		game.serve()
	mix_sequence(recipe.sequence)

func mix_sequence(sequence):
	campaign.herbs.emergency_supplies(sequence)
	game.table_stock = sequence.filter(func(id): return id < B.BASE_INGREDIENT_COUNT)
	game.table_empty.clear()
	game.sync_table_bottles()
	for id in sequence:
		game.pour_ingredient(id)
		game.finish_pour()
	game.start_mix()
	game.finish_mix()

func prepare(herb, method):
	campaign.herbs.discover(herb)
	if int(campaign.herbs.raw[herb]) == 0: campaign.herbs.cutting(herb)
	check(campaign.herbs.begin(herb,method),'Preparation starts with a raw portion')
	for i in range(3): campaign.herbs.step()
	check(campaign.herbs.attach(campaign.herbs.key(herb,method)),'Prepared extract can be selected')

func capture(name):
	if '--capture' not in OS.get_cmdline_user_args(): return
	await process_frame
	await process_frame
	check(root.get_texture().get_image().save_png('res://previews/'+name+'.png') == OK,'Capture '+name)

func run():
	var h = H.new()
	check(h.plots.size() == 6 and h.unlocked_beds() == 4,'Six beds with four initially restored')
	check(not h.plant(4,0) and not h.harvest(5),'Unrestored beds cannot be used')
	check(not h.plant(3,3),'Undiscovered herbs cannot be planted')
	check(h.harvest(0) and h.raw[0] == 5,'Mature herbs yield three portions')
	check(not h.harvest(0),'Harvest cannot repeat before regrowth')
	h.grow(1)
	h.grow(1)
	check(h.plots[0].age == 1,'Repeated day transition cannot grow plants twice')
	h.grow(2)
	check(h.harvest(0),'Perennial regrows after two clinic days')
	check(h.plant(3,0) and not h.plant(3,0),'Seeds occupy an empty bed once')
	check(h.begin(0,'steep') and not h.begin(0,'grind'),'Only one preparation can run at a time')
	check(not h.step(),'First interaction does not complete extract')
	var saved_work = JSON.parse_string(JSON.stringify(h.snapshot()))
	check(H.valid(saved_work),'Partial preparation has a valid save')
	var restored = H.new()
	restored.restore(saved_work)
	check(restored.work.step == 1 and restored.known.has(0),'JSON restore normalizes numeric herb identities')
	var count = restored.raw[0]
	restored.cancel()
	check(restored.raw[0] == count+1,'Cancelling returns the reserved raw herb')
	h.step()
	check(h.step() and h.work.is_empty(),'Three interactions bottle one extract')
	check(h.effect('0:steep') == B.FEVER and h.effect('0:grind') == B.GLOW,'Preparation method changes medicinal property')
	check(h.repeat_preparation(0,'steep') and not h.repeat_preparation(0,'grind'),'Only mastered methods can be repeated quickly')
	check(h.attach('0:steep'),'Prepared extract selected')
	h.consume()
	check(h.extracts['0:steep'] == 1 and h.finish == '','Serving spends exactly one extract')
	for actor in range(3): h.record_help(actor)
	h.record_help(2)
	check(h.rewarded and h.known.has(3) and h.raw[3] == 3 and h.unlocked_beds() == 6,'Three unique neighbours grant one garden restoration and Hushbell gift')
	var bad = h.snapshot()
	bad.extracts['unknown'] = 1
	check(not H.valid(bad),'Invalid extract identifiers rejected')
	bad = h.snapshot()
	bad.work = {'herb':99,'method':'steep','step':0}
	check(not H.valid(bad),'Invalid working herb rejected')
	bad = h.snapshot()
	bad.finish = '3:steep'
	check(not H.valid(bad),'Unavailable selected extract rejected')
	game = load('res://main.tscn').instantiate()
	game.set_meta('practice',true)
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.muted = true
	campaign = game.campaign
	campaign.save_path = 'user://herbalism_verification.json'
	campaign.start_campaign()
	check(campaign.garden_button.visible,'Campaign exposes garden and bench navigation')
	diagnose()
	campaign.open_casebook()
	await capture('herbalism_casebook')
	campaign.close()
	mix(0)
	game.serve()
	check(game.has_result and game.symptoms == B.FEVER,'Missing introductory finish keeps brew recoverable')
	campaign.herbal_ui.open_bench()
	check(press('Steep · Fever'),'Player chooses cooling preparation at the bench')
	press('Place leaves in the infuser')
	campaign.save_game()
	campaign.load_game()
	check(campaign.herbs.work.step == 1 and game.has_result,'Partial preparation and brewed remedy survive campaign resume together')
	campaign.herbal_ui.open_bench()
	press('Pour warm water over the herb')
	await capture('herbalism_steeping')
	press('Strain the infusion into a vial')
	press('Steeped Moonleaf ×1 · Fever')
	campaign.close()
	campaign.save_game()
	campaign.load_game()
	check(campaign.herbs.finish == '0:steep','Selected finish survives save/resume')
	game.serve()
	check(game.symptoms == 0 and campaign.herbs.helped == [0] and campaign.herbs.extracts['0:steep'] == 0,'Actual treatment consumes extract and records Poppy’s recovery')
	game.next_patient()
	diagnose()
	check(campaign.herbs.known.has(1),'Pip’s sample identifies Emberroot')
	mix(1)
	prepare(1,'steep')
	game.serve()
	check(game.has_result and game.symptoms == B.CHILLS and campaign.herbs.extracts['1:steep'] == 1,'Wrong preparation is recoverable and does not spend the extract')
	prepare(1,'grind')
	game.serve()
	check(game.symptoms == 0 and campaign.herbs.helped.has(1),'Ground root completes Pip’s treatment')
	game.next_patient()
	diagnose()
	mix(2)
	prepare(2,'grind')
	game.serve()
	mix(5)
	game.serve()
	check(game.symptoms == 0 and campaign.herbs.rewarded,'Juniper’s treatment unlocks neighbour garden reward')
	campaign.herbal_ui.open_garden()
	var garden = campaign.page.get_node('HerbGarden')
	check(garden.get_node('PaintedGarden').texture != null,'Garden uses the installed painted environment')
	check(garden.atlas.get_image().get_pixel(0,0).a == 0,'Painted herb sprites retain genuine transparency')
	var left_soil = PackedVector2Array([Vector2(475,363),Vector2(669,363),Vector2(515,866),Vector2(18,866)])
	var right_soil = PackedVector2Array([Vector2(758,363),Vector2(963,363),Vector2(1420,865),Vector2(946,865)])
	for position in garden.ROOTS:
		check(Geometry2D.is_point_in_polygon(position,left_soil) or Geometry2D.is_point_in_polygon(position,right_soil),'Herb root lies within courtyard soil, clear of main path')
	await capture('herbalism_garden')
	campaign.herbal_ui.selected = 3
	garden.get_node('Patch3').pressed.emit()
	check(campaign.herbal_ui.garden_patch == 3,'Clicking open soil selects its planting location')
	check(press('Plant selected herb'),'New seeds plant through garden UI')
	check(int(campaign.herbs.plots[3].herb) == 3,'Selected Hushbell occupies first empty bed')
	campaign.herbal_ui.open_bench()
	check(campaign.page.position == Vector2(100,70) and campaign.page.size == Vector2(1240,760),'Leaving the full-screen garden restores the bench layout')
	await capture('herbalism_bench')
	# A later mixed case can be treated with one base remedy plus a complementary extract.
	campaign.cursor = 5
	campaign.begin_case()
	diagnose()
	check((game.symptoms & B.FLOATING) != 0 and (game.symptoms & B.FEVER) != 0,'Mixed-case fixture includes floating and fever')
	mix(2)
	prepare(0,'steep')
	var before = game.symptoms
	game.serve()
	check(game.symptoms == (before & ~B.FLOATING & ~B.FEVER),'Complementary extract cures an additional symptom through production treatment')
	# Extracts must not bypass a compound requirement.
	campaign.cursor = 30
	campaign.begin_case()
	diagnose()
	mix(16)
	prepare(0,'steep')
	var anchored_before = game.symptoms
	game.serve()
	check(game.has_result and game.symptoms == anchored_before and campaign.herbs.finish == '0:steep','Complementary finish cannot bypass anchored temperature magic')
	var unsafe = campaign.apply_botanical({'mask':game.symptoms,'message':'Unsafe brew','good':false})
	check(unsafe.mask == game.symptoms,'An extract cannot rescue an unsafe brew')
	campaign.herbs.finish = ''
	game.serve()
	check((game.symptoms & B.DROWSINESS) == 0 and (game.symptoms & B.FEVER) != 0,'Base compound remains usable after removing inappropriate finish')
	campaign.cursor = 5
	campaign.begin_case()
	campaign.current_case().allergy = 9
	diagnose()
	mix(2)
	prepare(2,'grind')
	var allergy_before = game.symptoms
	game.serve()
	check(game.symptoms == (allergy_before | B.BLOOM) and not campaign.diagnosed,'Botanical Silverleaf respects shared ingredient allergy and requires reexamination')
	# Full legacy saves remain playable, without newly required tutorial steps.
	campaign.start_campaign()
	diagnose()
	mix(0)
	campaign.save_game()
	var legacy = JSON.parse_string(FileAccess.get_file_as_string(campaign.save_path))
	legacy.erase('herbalism')
	var file = FileAccess.open(campaign.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	campaign.load_game()
	game.serve()
	check(game.symptoms == 0 and not campaign.herbs.enabled,'Legacy campaign continues without botanical gates')
	campaign.active = false
	DirAccess.remove_absolute(campaign.save_path)
	print('HERBALISM: %d checks, %d failures' % [checks,failures.size()])
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
