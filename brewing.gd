extends RefCounted

# Recipe resolution is independent of the presentation and animation.
const FEVER = 1
const CHILLS = 2
const FLOATING = 4
const STONE = 8
const INVISIBLE = 16
const HICCUPS = 32
const BLOOM = 64
const DROWSINESS = 128
const DIZZINESS = 256
const SPARKS = 512
const ECHO = 1024
const GLOW = 2048

static var INGREDIENTS = preload("res://resources/data/ingredients.tres").entries

static var RECIPES = preload("res://resources/data/recipes.tres").entries

static var SYMPTOMS = preload("res://resources/data/symptoms.tres").entries

static var PATIENTS = preload("res://resources/data/patients.tres").entries

const BASE_INGREDIENT_COUNT = 12
static var blends = []
static var prepared_catalog = false

static func prepare_catalog():
	if prepared_catalog:
		return
	prepared_catalog = true
	for recipe in RECIPES:
		if not recipe.has('stages'):
			continue
		recipe.sequence = []
		recipe.note = 'Brew '+recipe.stages[0].name+' and '+recipe.stages[1].name+' separately. Bottle each, then combine in that order.'
		for stage in recipe.stages:
			var id = INGREDIENTS.size()
			stage.id = id
			var color = blended_color(stage.sequence).to_html(false)
			INGREDIENTS.append({'name':stage.name,'short':stage.name,'color':'#'+color,'description':'Brew and bottle this blend before combining.','symbol':'drop'})
			blends.append(stage)
			recipe.sequence.append(id)

static func resolve_blend(sequence):
	for stage in blends:
		if stage.sequence == sequence:
			return int(stage.id)
	return -1

static func finished_color(sequence):
	var recipe = resolve(sequence)
	if recipe >= 0:
		return Color(RECIPES[recipe].color)
	var blend = resolve_blend(sequence)
	return Color(INGREDIENTS[blend].color) if blend >= 0 else Color('#a89272')

static func raw_ingredients(recipe):
	var result = []
	for stage in recipe.get('stages',[{'sequence':recipe.sequence}]):
		for ingredient in stage.sequence:
			if not result.has(ingredient):
				result.append(ingredient)
	return result

static func contains_ingredient(sequence, ingredient):
	for id in sequence:
		if id == ingredient:
			return true
		for stage in blends:
			if stage.id == id and stage.sequence.has(ingredient):
				return true
	return false

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
	if allergy >= 0 and contains_ingredient(sequence,allergy):
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

