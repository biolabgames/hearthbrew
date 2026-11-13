extends RefCounted
## Persistent garden and preparation rules; no real-time growth or scarce essentials.
const HERBS = [
	{'name':'Moonleaf','color':'#88bca4','part':'leaves','steep':1,'grind':2048,'note':'Pale leaves release cooling magic in water. Grinding releases their trapped light.'},
	{'name':'Emberroot','color':'#d99659','part':'roots','steep':8,'grind':2,'note':'Bruised roots release warmth. A slow infusion instead softens stony enchantments.'},
	{'name':'Silverleaf','color':'#a8babe','part':'leaves','steep':256,'grind':4,'note':'An infusion steadies spinning senses. Ground leaves anchor floating magic.'},
	{'name':'Hushbell','color':'#ae96bf','part':'flowers','steep':1024,'grind':128,'note':'Steep the bells to quiet echoes. Grind their seeds to disperse dream motes.'},
	{'name':'Lavender','color':'#ae8bc7','part':'flowers','note':'Steam fragrant flower spikes to bottle lavender mist.'},
	{'name':'Woodland moss','color':'#8bb77a','part':'moss','note':'Infuse a soft moss cushion to make moss cordial.'},
	{'name':'Rose','color':'#dc9ca9','part':'petals','note':'Distil fresh pink petals into rosewater.'},
	{'name':'Ginger','color':'#d79a55','part':'rhizomes','note':'Crush the peppery rhizome and strain ginger tincture.'},
	{'name':'Valerian','color':'#9eabc9','part':'roots','note':'Infuse the roots for calming valerian drops.'},
	{'name':'Burdock','color':'#ae9276','part':'roots','note':'Wash and crush the earthy roots for burdock bitters.'}
]
# One authoritative source for each of the twelve base recipe bottles.
# A raw portion produces three bottles; collection sources produce three portions per clinic day.
const SOURCES = [
	{'herb':0,'method':'Press leaves into moonmilk','steps':['Rinse the moonleaf','Press the pale leaf sap','Strain and bottle the moonmilk']},
	{'herb':1,'method':'Simmer roots into nectar','steps':['Slice the emberroot','Simmer the warm root syrup','Strain and bottle the nectar']},
	{'herb':-1,'name':'Dew catcher','method':'Filter collected dew','steps':['Decant the dew catcher','Filter the clear droplets','Bottle the morning dew']},
	{'herb':4,'method':'Steam lavender flowers','steps':['Gather fragrant flower heads','Steam the lavender','Condense and bottle the mist']},
	{'herb':5,'method':'Infuse woodland moss','steps':['Rinse the moss','Infuse in warm water','Strain and bottle the cordial']},
	{'herb':-1,'name':'Neighbour’s beehive','method':'Strain collected honey','steps':['Open the shared honey jar','Strain the golden honey','Bottle the sun honey']},
	{'herb':6,'method':'Distil rose petals','steps':['Separate the rose petals','Gently distil the petals','Collect and bottle rosewater']},
	{'herb':7,'method':'Crush ginger rhizomes','steps':['Wash the ginger rhizome','Crush and steep the ginger','Strain and bottle the tincture']},
	{'herb':8,'method':'Infuse valerian roots','steps':['Clean the valerian roots','Infuse the chopped roots','Strain and bottle the drops']},
	{'herb':2,'method':'Press silverleaf','steps':['Sort the silver leaves','Press the grounding leaf sap','Filter and bottle the extract']},
	{'herb':-1,'name':'Starlight collector','method':'Condense gathered starlight','steps':['Open the charged star prism','Condense its gathered light','Bottle the starlight essence']},
	{'herb':9,'method':'Macerate burdock roots','steps':['Wash the burdock roots','Crush and macerate the roots','Strain and bottle the bitters']}
]
const LESSONS = [
	{'actor':0,'mask':1,'herb':0,'method':'steep','clue':'Poppy brings pale moonleaf from her route. Its cooling property dissolves in water; grinding releases light instead. Finish a fever remedy with steeped Moonleaf.'},
	{'actor':1,'mask':2,'herb':1,'method':'grind','clue':'Pip brings an emberroot from the baker’s bed. Bruising its fibres releases warmth; soaking softens stone instead. Finish a chills remedy with ground Emberroot.'},
	{'actor':2,'mask':4,'herb':2,'method':'grind','clue':'Juniper brings silver leaves caught on her floating boots. Ground leaves carry anchoring magic; an infusion treats dizziness instead. Finish a floating remedy with ground Silverleaf.'}
]
var raw = [2,2,2,0,2,2,2,2,2,2]
var known = [0,4,5,6]
var plots = [{'herb':0,'age':2},{'herb':1,'age':2},{'herb':2,'age':2},{'herb':-1,'age':0},{'herb':-1,'age':0},{'herb':-1,'age':0}]
var extracts = {}
var mastered = []
var helped = []
var work = {}
var finish = ''
var enabled = true
var rewarded = false
var growth_day = 0
var inventory = [4,4,4,4,4,4,4,4,4,4,4,4]
var gathered = {'2':0,'5':0,'10':0}
var collected_day = {'2':-1,'5':-1,'10':-1}
var ingredient_work = {}
var learned_ingredients = []

func source_name(ingredient):
	var source = SOURCES[ingredient]
	return HERBS[int(source.herb)].name if int(source.herb) >= 0 else source.name

func source_count(ingredient):
	var herb = int(SOURCES[ingredient].herb)
	return int(raw[herb]) if herb >= 0 else int(gathered[str(ingredient)])

func source_known(ingredient):
	var herb = int(SOURCES[ingredient].herb)
	return herb < 0 or herb in known

func collect_source(ingredient):
	var id = str(ingredient)
	if not gathered.has(id) or int(collected_day[id]) >= growth_day: return false
	gathered[id] = int(gathered[id])+3
	collected_day[id] = growth_day
	return true

func begin_ingredient(ingredient):
	if ingredient < 0 or ingredient >= SOURCES.size() or not work.is_empty() or not ingredient_work.is_empty(): return false
	if not source_known(ingredient) or source_count(ingredient) < 1: return false
	var herb = int(SOURCES[ingredient].herb)
	if herb >= 0: raw[herb] -= 1
	else: gathered[str(ingredient)] = int(gathered[str(ingredient)])-1
	ingredient_work = {'ingredient':ingredient,'step':0}
	return true

func step_ingredient():
	if ingredient_work.is_empty(): return false
	ingredient_work.step = int(ingredient_work.step)+1
	if int(ingredient_work.step) < 3: return false
	var ingredient = int(ingredient_work.ingredient)
	inventory[ingredient] += 3
	if ingredient not in learned_ingredients: learned_ingredients.append(ingredient)
	ingredient_work = {}
	return true

func cancel_ingredient():
	if ingredient_work.is_empty(): return
	var ingredient = int(ingredient_work.ingredient)
	var herb = int(SOURCES[ingredient].herb)
	if herb >= 0: raw[herb] += 1
	else: gathered[str(ingredient)] = int(gathered[str(ingredient)])+1
	ingredient_work = {}

func repeat_ingredient(ingredient):
	if ingredient not in learned_ingredients or not begin_ingredient(ingredient): return false
	for i in range(3): step_ingredient()
	return true

func use_bottle(ingredient):
	if ingredient < 0 or ingredient >= inventory.size() or inventory[ingredient] < 1: return false
	inventory[ingredient] -= 1
	return true

func emergency_supplies(sequence):
	# No currency or waiting gate: shortages must never block a patient's care.
	var needed = {}
	for ingredient in sequence:
		if ingredient >= 0 and ingredient < inventory.size(): needed[ingredient] = int(needed.get(ingredient,0))+1
	for ingredient in needed: inventory[ingredient] = maxi(inventory[ingredient],needed[ingredient])

func key(herb, method):
	return '%d:%s' % [herb,method]

func effect(extract):
	var parts = extract.split(':')
	return int(HERBS[int(parts[0])][parts[1]])

func title(extract):
	var parts = extract.split(':')
	return ('Steeped ' if parts[1] == 'steep' else 'Ground ')+HERBS[int(parts[0])].name

func lesson(actor, mask):
	if not enabled or helped.has(actor): return {}
	for item in LESSONS:
		if item.actor == actor and (mask & int(item.mask)) != 0: return item
	return {}

func discover(herb):
	if not known.has(herb): known.append(herb)
	if herb == 1 and 7 not in known: known.append(7)
	if herb == 2:
		for extra in [8,9]:
			if extra not in known: known.append(extra)

func unlocked_beds():
	return 6 if rewarded else 4

func plant(slot, herb):
	if slot < 0 or slot >= unlocked_beds() or herb not in known or int(plots[slot].herb) != -1: return false
	plots[slot] = {'herb':herb,'age':0}
	return true

func harvest(slot):
	if slot < 0 or slot >= unlocked_beds() or int(plots[slot].herb) < 0 or int(plots[slot].age) < 2: return false
	raw[int(plots[slot].herb)] += 3
	plots[slot].age = 0
	return true

func grow(next_day):
	# Absolute clinic-day counter prevents reloads and repeated evening visits growing crops.
	if next_day <= growth_day: return
	for plot in plots:
		if int(plot.herb) >= 0: plot.age = mini(2,int(plot.age)+next_day-growth_day)
	growth_day = next_day

func cutting(herb):
	if herb not in known: return false
	raw[herb] += 1
	return true

func begin(herb, method):
	if not work.is_empty() or not ingredient_work.is_empty() or herb not in known or herb >= 4 or method not in ['steep','grind'] or int(raw[herb]) < 1: return false
	raw[herb] -= 1
	work = {'herb':herb,'method':method,'step':0}
	return true

func step():
	if work.is_empty(): return false
	work.step = int(work.step)+1
	if int(work.step) < 3: return false
	var id = key(int(work.herb),str(work.method))
	extracts[id] = int(extracts.get(id,0))+1
	if not mastered.has(id): mastered.append(id)
	work = {}
	return true

func repeat_preparation(herb, method):
	if key(herb,method) not in mastered or not begin(herb,method): return false
	for i in range(3): step()
	return true

func cancel():
	if work.is_empty(): return
	raw[int(work.herb)] += 1
	work = {}

func attach(id):
	if int(extracts.get(id,0)) < 1: return false
	finish = id
	return true

func consume():
	if finish.is_empty(): return
	extracts[finish] = int(extracts[finish])-1
	finish = ''

func record_help(actor):
	if actor not in [0,1,2] or helped.has(actor): return
	helped.append(actor)
	if helped.size() == 3:
		rewarded = true
		discover(3)
		raw[3] += 3

func snapshot():
	return {'raw':raw.duplicate(),'known':known.duplicate(),'plots':plots.duplicate(true),'extracts':extracts.duplicate(),'mastered':mastered.duplicate(),'helped':helped.duplicate(),'work':work.duplicate(),'finish':finish,'enabled':enabled,'rewarded':rewarded,'growth_day':growth_day,'supply_version':1,'inventory':inventory.duplicate(),'gathered':gathered.duplicate(),'collected_day':collected_day.duplicate(),'ingredient_work':ingredient_work.duplicate(),'learned_ingredients':learned_ingredients.duplicate()}

static func whole(value, low, high):
	return (value is int or value is float) and value == int(value) and value >= low and value <= high

static func valid_key(value):
	return value is String and value in ['0:steep','0:grind','1:steep','1:grind','2:steep','2:grind','3:steep','3:grind']

static func valid(data):
	if not data is Dictionary: return false
	for field in ['raw','known','plots','extracts','mastered','helped','work','finish','enabled','rewarded','growth_day']:
		if not data.has(field): return false
	if not whole(data.growth_day,0,1000000): return false
	var modern = data.has('supply_version')
	if modern and data.supply_version != 1: return false
	if not data.raw is Array or data.raw.size() != (HERBS.size() if modern else 4): return false
	for count in data.raw:
		if not whole(count,0,1000000): return false
	for field in ['known','helped']:
		if not data[field] is Array: return false
		var seen = []
		for id in data[field]:
			if not whole(id,0,(HERBS.size()-1 if modern else 3) if field == 'known' else 2) or id in seen: return false
			seen.append(id)
	if not data.plots is Array or data.plots.size() != 6: return false
	for plot in data.plots:
		if not plot is Dictionary or not whole(plot.get('herb',-2),-1,HERBS.size()-1 if modern else 3) or not whole(plot.get('age',-1),0,2): return false
	if not data.extracts is Dictionary: return false
	for id in data.extracts:
		if not valid_key(id) or not whole(data.extracts[id],0,1000000): return false
	if not data.mastered is Array: return false
	for id in data.mastered:
		if not valid_key(id): return false
	if not data.work is Dictionary: return false
	if not data.work.is_empty():
		if not whole(data.work.get('herb',-1),0,3) or data.work.get('method','') not in ['steep','grind'] or not whole(data.work.get('step',-1),0,2): return false
	if not data.finish is String or (data.finish != '' and (not valid_key(data.finish) or data.extracts.get(data.finish,0) < 1)): return false
	if modern:
		for field in ['inventory','gathered','collected_day','ingredient_work','learned_ingredients']:
			if not data.has(field): return false
		if not data.inventory is Array or data.inventory.size() != 12: return false
		for count in data.inventory:
			if not whole(count,0,1000000): return false
		if not data.gathered is Dictionary or not data.collected_day is Dictionary: return false
		if data.gathered.size() != 3 or data.collected_day.size() != 3: return false
		for id in ['2','5','10']:
			if not whole(data.gathered.get(id,-1),0,1000000) or not whole(data.collected_day.get(id,-2),-1,data.growth_day): return false
		if not data.ingredient_work is Dictionary: return false
		if not data.ingredient_work.is_empty():
			if not data.work.is_empty() or not whole(data.ingredient_work.get('ingredient',-1),0,11) or not whole(data.ingredient_work.get('step',-1),0,2): return false
		if not data.learned_ingredients is Array: return false
		for id in data.learned_ingredients:
			if not whole(id,0,11): return false
	return data.enabled is bool and data.rewarded is bool and whole(data.growth_day,0,1000000)

func restore(data):
	raw = data.raw.duplicate()
	known = data.known.duplicate()
	for i in range(known.size()): known[i] = int(known[i])
	plots = data.plots.duplicate(true)
	extracts = data.extracts.duplicate()
	mastered = data.mastered.duplicate()
	helped = data.helped.duplicate()
	work = data.work.duplicate()
	finish = data.finish
	enabled = data.enabled
	rewarded = data.rewarded
	growth_day = int(data.growth_day)
	if data.has('supply_version'):
		inventory = data.inventory.duplicate()
		gathered = data.gathered.duplicate()
		collected_day = data.collected_day.duplicate()
		ingredient_work = data.ingredient_work.duplicate()
		learned_ingredients = data.learned_ingredients.duplicate()
	else:
		# Append new botanicals without changing old identities or existing plantings.
		raw.append_array([2,2,2,2,2,2])
		for id in [4,5,6]: discover(id)
		if 1 in known: discover(1)
		if 2 in known: discover(2)
	# JSON parses numbers as floats; Array membership distinguishes those from ints.
	for values in [raw,known,helped,inventory,learned_ingredients]:
		for i in range(values.size()): values[i] = int(values[i])
	for plot in plots:
		plot.herb = int(plot.herb)
		plot.age = int(plot.age)
	if not work.is_empty():
		work.herb = int(work.herb)
		work.step = int(work.step)
	for id in extracts: extracts[id] = int(extracts[id])
	for id in gathered:
		gathered[id] = int(gathered[id])
		collected_day[id] = int(collected_day[id])
	if not ingredient_work.is_empty():
		ingredient_work.ingredient = int(ingredient_work.ingredient)
		ingredient_work.step = int(ingredient_work.step)
