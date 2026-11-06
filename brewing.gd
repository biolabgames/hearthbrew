extends RefCounted

# Recipe resolution is independent of the presentation and animation.
const FEVER = 1
const CHILLS = 2
const FLOATING = 4
const STONE = 8
const INVISIBLE = 16
const HICCUPS = 32
const BLOOM = 64

const INGREDIENTS = [
	{'name':'Moonmilk','short':'Moonmilk','color':'#f4dfb4','symbol':'moon','description':'A soft, creamy base.'},
	{'name':'Ember nectar','short':'Ember','color':'#ed866a','symbol':'flame','description':'A little bottled sunshine.'},
	{'name':'Morning dew','short':'Dew','color':'#6ebbc8','symbol':'drop','description':'Cool and clear as dawn.'},
	{'name':'Lavender mist','short':'Lavender','color':'#ae8bc7','symbol':'flower','description':'Dreamy, fragrant vapour.'},
	{'name':'Moss cordial','short':'Moss','color':'#8bb77a','symbol':'leaf','description':'Wild green woodland magic.'},
	{'name':'Sun honey','short':'Honey','color':'#e8b34e','symbol':'sun','description':'Golden, sticky and stubborn.'}
]

const RECIPES = [
	{'name':'Dewdrop draught','sequence':[0,2],'cure':FEVER,'color':'#79c9bc','effect':'Cures fever','note':'Moonmilk first, then morning dew. If the patient floats, it also causes shivers.'},
	{'name':'Cloud blanket','sequence':[2,0],'cure':CHILLS,'color':'#edc29a','effect':'Cures shivers','note':'Dew first, then moonmilk. The same pair, reversed, makes a warming remedy.'},
	{'name':'Rooted lullaby','sequence':[3,5,0],'cure':FLOATING,'color':'#c0a7c8','effect':'Cures floating','note':'Lavender, honey, then moonmilk. Calms the feet and brings them down to earth.'},
	{'name':'Softstep syrup','sequence':[4,2,5],'cure':STONE,'color':'#a5bd78','effect':'Cures stone skin','note':'Moss, dew, then honey. Softens stone without making a puddle.'},
	{'name':'Lantern cordial','sequence':[5,3,2],'cure':INVISIBLE,'color':'#e9ad7e','effect':'Cures invisibility','note':'Honey, lavender, then dew. Gives a missing face its outline again.'},
	{'name':'Quiet kettle','sequence':[0,3,5],'cure':HICCUPS,'color':'#c29bb8','effect':'Cures hiccups','note':'Moonmilk, lavender, then honey. No more accidental bubbles.'},
	{'name':'Petal polish','sequence':[4,5,2,0],'cure':BLOOM,'color':'#a8cbaa','effect':'Cures wild blooming','note':'Moss, honey, dew, then moonmilk. Four pours tame those wandering flowers.'},
	{'name':'Evening balance','sequence':[1,2,3,0],'cure':FEVER|CHILLS,'color':'#dba6ab','effect':'Cures fever + shivers','note':'Ember, dew, lavender, then moonmilk. A more complex remedy for mixed temperatures.'}
]

const SYMPTOMS = [
	{'bit':FEVER,'name':'Fever','color':'#cb6652'},
	{'bit':CHILLS,'name':'Shivers','color':'#4c91ad'},
	{'bit':FLOATING,'name':'Floating','color':'#9673b3'},
	{'bit':STONE,'name':'Stone skin','color':'#7f8b72'},
	{'bit':INVISIBLE,'name':'Invisible','color':'#668d92'},
	{'bit':HICCUPS,'name':'Bubble hiccups','color':'#bc7c9e'},
	{'bit':BLOOM,'name':'Wild blooming','color':'#639c61'}
]

const PATIENTS = [
	{'name':'Poppy','job':'The village postwoman','kind':'human','color':'#e4b38f','mask':FEVER,'minimum':1,'allergy':-1,'story':'Seventeen letters before breakfast. Now my cheeks feel like tiny ovens.','hint':'A cool draught should help. Start with Moonmilk, then add Dew.'},
	{'name':'Pip','job':'A very chilly village baker','kind':'human','color':'#b58a66','mask':CHILLS,'minimum':1,'allergy':-1,'story':'I fell asleep in the ice cellar. Even my apron is shivering.','hint':'Cloud blanket uses the first recipe\'s ingredients in reverse: Dew, then Moonmilk.'},
	{'name':'Juniper','job':'An apprentice cloud-witch','kind':'human','color':'#cd9db3','mask':FLOATING|HICCUPS,'minimum':2,'allergy':-1,'story':'My levitation lesson went splendidly. It is the landing and the hiccups I cannot manage.','hint':'Two problems need two remedies: Rooted lullaby and Quiet kettle.'},
	{'name':'Bramble','job':'The village rose gardener','kind':'human','color':'#a5bf78','mask':STONE|BLOOM,'minimum':2,'allergy':1,'story':'A garden charm gave me stone skin and daisies. Ember nectar makes me itch.','hint':'Use Softstep syrup and Petal polish. Keep Ember nectar out of the mixtures.'},
	{'name':'Mallow','job':'The disappearing librarian','kind':'human','color':'#b6b0c8','mask':INVISIBLE|HICCUPS,'minimum':2,'allergy':-1,'story':'Nobody sees me, but everyone hears me hiccup in the quiet section.','hint':'Lantern cordial will make Mallow visible. Quiet kettle will hush the hiccups.'},
	{'name':'Rowan','job':'A carpenter caught in a weather spell','kind':'human','color':'#db9969','mask':FEVER|CHILLS|FLOATING,'minimum':2,'allergy':-1,'story':'Hot cheeks, cold hands, feet in the air. That weather spell tasted terrible.','hint':'Evening balance cures both temperatures. Rooted lullaby brings Rowan down. A basic Dewdrop while floating adds shivers.'}
]

static func resolve(sequence):
	for i in range(RECIPES.size()):
		if RECIPES[i].sequence == sequence:
			return i
	return -1

static func blended_color(sequence):
	var result = Color('#f5dfb0')
	for i in sequence:
		result = result.lerp(Color(INGREDIENTS[i].color),0.63)
	return result

static func treat(mask, recipe_index, sequence, allergy):
	if allergy >= 0 and sequence.has(allergy):
		return {'mask':mask|BLOOM,'message':'An allergy has caused wild blooming. Check the patient chart before serving.','good':false}
	if recipe_index < 0:
		return {'mask':mask|HICCUPS,'message':'That muddled brew caused bubble hiccups. You can still put this right.','good':false}
	var recipe = RECIPES[recipe_index]
	var next = mask & ~int(recipe.cure)
	if recipe_index == 0 and (mask & FLOATING) != 0:
		next |= CHILLS
		return {'mask':next,'message':'Fever cooled, but a floating patient gets shivers from Dewdrop draught. Read the journal notes.','good':false}
	if next == mask:
		return {'mask':mask,'message':'A lovely brew, but it treats a different symptom. Read the patient chart.','good':false}
	return {'mask':next,'message':recipe.name+' worked. A little closer to feeling better.','good':true}

static func symptom_names(mask):
	var names = []
	for symptom in SYMPTOMS:
		if (mask & int(symptom.bit)) != 0:
			names.append(symptom.name)
	return names

