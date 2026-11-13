extends Control
## Recipe discovery, pantry basket and the bottles carried to the workbench.
const Brewing = preload('res://brewing.gd')
var game
var modal: Control
var book: Control
var pantry: Control
var search: LineEdit
var matches_only: CheckButton
var recipe_buttons = []
var pantry_buttons = []
var table_buttons = []
var basket = []
var basket_empty = []
var detail: Label
var basket_note: Label
var basket_buttons = []
var carry: Button
var pinned_note: Label
var pantry_open: Button
var mode = 'book'
var page_title: Label
var page_effect: Label
var page_number: Label
var supply_note: Label
var garden_link: Button
var emergency_button: Button
var page_bottles = []
var page_captions = []
var blend_buttons = []
var handwriting = SystemFont.new()
const BOTTLE_IMAGES = [
	preload('res://assets/potions/moonmilk.png'),
	preload('res://assets/potions/ember.png'),
	preload('res://assets/potions/dew.png'),
	preload('res://assets/potions/lavender.png'),
	preload('res://assets/potions/moss.png'),
	preload('res://assets/potions/honey.png'),
	preload('res://assets/potions/rose.png'),
	preload('res://assets/potions/ginger.png'),
	preload('res://assets/potions/valerian.png'),
	preload('res://assets/potions/silverleaf.png'),
	preload('res://assets/potions/starlight.png'),
	preload('res://assets/potions/burdock.png'),
]
const EMPTY_BOTTLE_IMAGES = [
	preload('res://assets/potions/empty/moonmilk.png'),
	preload('res://assets/potions/empty/ember.png'),
	preload('res://assets/potions/empty/dew.png'),
	preload('res://assets/potions/empty/lavender.png'),
	preload('res://assets/potions/empty/moss.png'),
	preload('res://assets/potions/empty/honey.png'),
	preload('res://assets/potions/empty/rose.png'),
	preload('res://assets/potions/empty/ginger.png'),
	preload('res://assets/potions/empty/valerian.png'),
	preload('res://assets/potions/empty/silverleaf.png'),
	preload('res://assets/potions/empty/starlight.png'),
	preload('res://assets/potions/empty/burdock.png'),
]

func bottle_at(parent, point, bottle_scale):
	var bottle = Node2D.new()
	parent.add_child(bottle)
	bottle.name = 'Bottle'
	bottle.position = point
	bottle.scale = Vector2.ONE*bottle_scale
	var artwork = Sprite2D.new()
	artwork.name = 'Artwork'
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bottle.add_child(artwork)
	tint_bottle(bottle,0)
	return bottle

func tint_bottle(bottle, index, empty = false):
	var artwork = bottle.get_node('Artwork')
	var images = EMPTY_BOTTLE_IMAGES if empty else BOTTLE_IMAGES
	artwork.texture = images[index if index < images.size() else 0]
	artwork.modulate = Color.WHITE if index < BOTTLE_IMAGES.size() else Color(Brewing.INGREDIENTS[index].color)
	artwork.scale = Vector2.ONE*(64.0/artwork.texture.get_height())

func label_at(parent, words, rect, font_size = 18):
	var node = Label.new()
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	node.text = words
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override('font_size',font_size)
	node.add_theme_color_override('font_color',Color('#355d4c'))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func button_at(parent, words, rect, callback):
	var node = Button.new()
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	node.text = words
	node.add_theme_font_size_override('font_size',16)
	var style = StyleBoxFlat.new()
	style.bg_color = Color('#e3d6b6')
	style.border_color = Color('#9a805a')
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	for state in ['normal','disabled']:
		node.add_theme_stylebox_override(state,style)
	var hover = style.duplicate()
	hover.bg_color = Color('#c5d0ae')
	node.add_theme_stylebox_override('hover',hover)
	node.add_theme_stylebox_override('pressed',hover)
	node.add_theme_color_override('font_color',Color('#355d4c'))
	node.add_theme_color_override('font_hover_color',Color('#355d4c'))
	node.add_theme_color_override('font_pressed_color',Color('#355d4c'))
	node.pressed.connect(callback)
	return node

func panel_at(parent, rect):
	var node = Panel.new()
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	var style = StyleBoxFlat.new()
	style.bg_color = Color('#fff1d6')
	style.border_color = Color('#94704c')
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	node.add_theme_stylebox_override('panel',style)
	return node

func setup(owner_game):
	game = owner_game
	handwriting.font_names = PackedStringArray(['Segoe Print','Bradley Hand','Comic Sans MS','cursive'])
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_at(self,'The apothecary',Rect2(44,154,270,38),26)
	label_at(self,'READ  /  GATHER  /  BREW',Rect2(44,194,270,25),13)
	button_at(self,'1. Open recipe book',Rect2(44,291,270,48),func(): open('book'))
	pinned_note = label_at(self,'',Rect2(48,351,258,130),17)
	for i in range(2):
		var blend_button = button_at(self,'',Rect2(44,410+i*39,270,35),func():
			var stages = Brewing.RECIPES[game.pinned].get('stages',[])
			if i < stages.size():
				game.pour_ingredient(stages[i].id))
		blend_buttons.append(blend_button)
	pantry_open = button_at(self,'2. Visit the pantry',Rect2(44,493,270,48),func(): open('pantry'))
	var placement = RandomNumberGenerator.new()
	placement.randomize()
	for i in range(6):
		# Pick offsets once so refreshes and pours never shuffle the bottles.
		var point = Vector2(183+(i%3)*116,548+(i/3)*142)
		point += Vector2(placement.randf_range(-8,8),placement.randf_range(-18,18))
		var slot = button_at(self,'',Rect2(point,Vector2(90,112)),func():
			game.pour_bottle(i))
		# Only the bottle artwork sits on the wood; empty slots stay hidden.
		for state in ['normal','hover','pressed','disabled','focus']:
			slot.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		var bottle = bottle_at(slot,Vector2(45,56),1.6)
		bottle.rotation = placement.randf_range(-0.045,0.045)
		slot.mouse_entered.connect(func(): slot.get_node('Bottle').modulate = Color(1.12,1.12,1.12))
		slot.mouse_exited.connect(func(): slot.get_node('Bottle').modulate = Color.WHITE)
		table_buttons.append(slot)
	modal = Control.new()
	add_child(modal)
	modal.z_index = 20
	modal.size = Vector2(1440,900)
	var shade = ColorRect.new()
	modal.add_child(shade)
	shade.size = modal.size
	shade.color = Color(0.12,0.17,0.13,0.78)
	var page = panel_at(modal,Rect2(115,115,1210,690))
	button_at(page,'Recipe book',Rect2(26,22,180,44),func(): open('book'))
	button_at(page,'Pantry',Rect2(220,22,180,44),func(): open('pantry'))
	button_at(page,'Back to table  /  Esc',Rect2(952,22,230,44),close)
	book = preload('res://scripts/recipe_book.gd').new()
	page.add_child(book)
	book.position = Vector2(18,90)
	label_at(book,'The apothecary’s recipes',Rect2(28,14,280,38),23).add_theme_font_override('font',handwriting)
	search = LineEdit.new()
	book.add_child(search)
	search.position = Vector2(28,58)
	search.size = Vector2(274,36)
	search.placeholder_text = 'Find a remedy or ingredient…'
	var field_style = StyleBoxFlat.new()
	field_style.bg_color = Color('#efe1c3')
	field_style.content_margin_left = 10
	search.add_theme_stylebox_override('normal',field_style)
	search.add_theme_color_override('font_color',Color('#355d4c'))
	search.add_theme_color_override('font_placeholder_color',Color('#6b705b'))
	search.text_changed.connect(func(_text): refresh())
	matches_only = CheckButton.new()
	book.add_child(matches_only)
	matches_only.position = Vector2(22,100)
	matches_only.size = Vector2(286,32)
	matches_only.text = 'For this patient'
	matches_only.add_theme_color_override('font_color',Color('#355d4c'))
	matches_only.add_theme_color_override('font_hover_color',Color('#355d4c'))
	matches_only.add_theme_color_override('font_pressed_color',Color('#355d4c'))
	matches_only.toggled.connect(func(_value): refresh())
	var scroll = ScrollContainer.new()
	book.add_child(scroll)
	scroll.position = Vector2(28,144)
	scroll.size = Vector2(280,344)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list = VBoxContainer.new()
	scroll.add_child(list)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in range(Brewing.RECIPES.size()):
		var recipe = Brewing.RECIPES[i]
		var entry = button_at(list,recipe.name,Rect2(0,0,258,37),func(): game.pin_recipe(i))
		entry.custom_minimum_size = Vector2(258,37)
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.add_theme_font_size_override('font_size',15)
		recipe_buttons.append(entry)
	page_title = label_at(book,'',Rect2(365,18,700,49),32)
	page_title.add_theme_font_override('font',handwriting)
	page_effect = label_at(book,'',Rect2(368,74,730,30),17)
	for i in range(6):
		var bottle = bottle_at(book,Vector2(428+i*128,176),2.0)
		page_bottles.append(bottle)
		var caption = label_at(book,'',Rect2(369+i*128,240,124,62),18)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_override('font',handwriting)
		page_captions.append(caption)
	var instructions = ScrollContainer.new()
	book.add_child(instructions)
	instructions.position = Vector2(368,310)
	instructions.size = Vector2(752,174)
	instructions.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail = label_at(instructions,'',Rect2(0,0,732,0),19)
	detail.custom_minimum_size.x = 732
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_font_override('font',handwriting)
	button_at(book,'← Previous',Rect2(28,500,125,32),func(): turn_page(-1))
	button_at(book,'Next →',Rect2(177,500,125,32),func(): turn_page(1))
	page_number = label_at(book,'',Rect2(374,507,280,28),14)
	button_at(book,'Gather these bottles →',Rect2(814,496,313,39),func(): open('pantry'))
	pantry = Control.new()
	page.add_child(pantry)
	pantry.position = Vector2(26,92)
	label_at(pantry,'The woodland pantry',Rect2(0,0,750,40),28)
	supply_note = label_at(pantry,'',Rect2(0,43,750,40),16)
	for i in range(Brewing.BASE_INGREDIENT_COUNT):
		var ingredient = Brewing.INGREDIENTS[i]
		var card = button_at(pantry,'',Rect2((i%3)*246,92+(i/3)*112,232,102),func(): collect_bottle(i))
		card.tooltip_text = ingredient.description
		card.add_theme_font_size_override('font_size',17)
		var bottle = bottle_at(card,Vector2(116,36),0.9)
		tint_bottle(bottle,i)
		var caption = label_at(card,'',Rect2(4,59,224,42),15)
		caption.name = 'Caption'
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pantry_buttons.append(card)
	garden_link = button_at(pantry,'Grow, collect & prepare ingredients →',Rect2(0,544,724,38),func():
		if game.campaign and game.campaign.active: game.campaign.herbal_ui.open_ingredients())
	label_at(pantry,'Collected potions',Rect2(775,0,365,36),26)
	basket_note = label_at(pantry,'',Rect2(775,43,365,49),16)
	for i in range(6):
		var collected = button_at(pantry,'',Rect2(775,100+i*55,365,48),func(): remove_bottle(i))
		collected.alignment = HORIZONTAL_ALIGNMENT_LEFT
		collected.tooltip_text = 'Click to remove this bottle'
		basket_buttons.append(collected)
	emergency_button = button_at(pantry,'Request missing recipe supplies',Rect2(775,434,365,36),request_supplies)
	emergency_button.tooltip_text = 'Neighbours freely replace missing bottles for the pinned recipe. Garden preparation makes your regular stock.'
	carry = button_at(pantry,'',Rect2(775,482,365,46),bring_to_table)
	close()

func open(which):
	mode = which
	if which == 'pantry':
		game.sync_table_bottles()
		basket = game.table_stock.duplicate()
		basket_empty = game.table_empty.duplicate()
	modal.show()
	book.visible = which == 'book'
	pantry.visible = which == 'pantry'
	refresh()
	if game.campaign:
		game.campaign.refresh()

func close():
	modal.hide()
	if game.campaign:
		game.campaign.refresh()
	if search:
		search.release_focus()

func turn_page(direction):
	var index = game.pinned+direction
	while index >= 0 and index < recipe_buttons.size():
		if recipe_buttons[index].visible:
			game.pin_recipe(index)
			return
		index += direction

func collect_bottle(index):
	if not game.can_edit() or basket.size() >= 6:
		return
	if tracked() and remaining(index) < 1: return
	basket.append(index)
	basket_empty.append(false)
	refresh()

func tracked():
	return game.campaign != null and game.campaign.active

func remaining(index):
	var count = int(game.campaign.herbs.inventory[index])
	for slot in range(basket.size()):
		if basket[slot] == index and not basket_empty[slot]: count -= 1
	return maxi(0,count)

func request_supplies():
	if not tracked() or not game.can_edit(): return
	var sequence = []
	var recipe = Brewing.RECIPES[game.pinned]
	for stage in recipe.get('stages',[{'sequence':recipe.sequence}]): sequence.append_array(stage.sequence)
	game.campaign.herbs.emergency_supplies(sequence)
	game.campaign.save_game()
	refresh()
	game.say('Neighbours supplied the missing bottles for '+recipe.name+'. Collect them from the shelves.')

func remove_bottle(slot):
	if not game.can_edit() or slot < 0 or slot >= basket.size():
		return
	basket.remove_at(slot)
	basket_empty.remove_at(slot)
	refresh()

func bring_to_table():
	if not game.can_edit():
		return
	game.table_stock = basket.duplicate()
	game.table_empty = basket_empty.duplicate()
	# Contents already poured stay in the kettle when their empty bottle is returned.
	var retained = game.queue.slice(0,game.poured_count)
	for index in game.queue.slice(game.poured_count):
		if game.table_stock.has(index) or game.stored_blends.has(index):
			retained.append(index)
	game.queue = retained
	close()
	game.say('Click a full bottle to pour it into the kettle. Follow the recipe order.')
	game.refresh()
	if tracked(): game.campaign.save_game()

func refresh():
	var recipe = Brewing.RECIPES[game.pinned]
	var order = []
	var needed = Brewing.raw_ingredients(recipe)
	for index in recipe.sequence:
		order.append(Brewing.INGREDIENTS[index].short)
	var warning = ''
	if needed.has(game.patient().allergy):
		warning = '\nALLERGY: contains '+Brewing.INGREDIENTS[game.patient().allergy].name+'. Choose another remedy.'
	elif game.pinned == 0 and (game.visible_symptoms() & Brewing.FLOATING) != 0:
		warning = '\nCAUTION: causes shivers while the patient is floating.'
	pinned_note.text = 'PINNED RECIPE\n'+recipe.name+'\n\n'+' → '.join(order)
	var stages = recipe.get('stages',[])
	for i in range(blend_buttons.size()):
		blend_buttons[i].visible = i < stages.size()
		if i < stages.size():
			var ready = game.stored_blends.has(stages[i].id)
			blend_buttons[i].text = ('Pour ' if ready else 'Prepare: ')+stages[i].name
			blend_buttons[i].disabled = not ready or not game.can_edit()
	if not stages.is_empty():
		pinned_note.text = 'PINNED RECIPE\n'+recipe.name+' · 3 stages'
	page_title.text = recipe.name
	page_effect.text = recipe.effect+'  ·  '+('One simple mixture' if stages.is_empty() else 'Two separate blends, then combine')
	page_number.text = 'RECIPE %02d   /   %02d' % [game.pinned+1,Brewing.RECIPES.size()]
	if game.campaign and game.campaign.active and not game.campaign.recipe_available(12):
		page_number.text = '12 remedies · compound recipes arrive day 2'
	# Each bottle is a large, colour-matched illustration with its full ingredient name.
	for i in range(page_bottles.size()):
		page_bottles[i].visible = i < needed.size()
		page_captions[i].visible = i < needed.size()
		if i < needed.size():
			tint_bottle(page_bottles[i],needed[i])
			page_captions[i].text = Brewing.INGREDIENTS[needed[i]].name
	if stages.is_empty():
		detail.text = 'Pour in order: '+' → '.join(order)+'.\nStir, then serve the finished remedy.\n\n'+recipe.note+warning
	else:
		detail.text = ''
		for i in range(stages.size()):
			var pours = []
			for ingredient in stages[i].sequence:
				pours.append(Brewing.INGREDIENTS[ingredient].short)
			detail.text += '%d. %s: %s. Stir & bottle.\n' % [i+1,stages[i].name,' → '.join(pours)]
		detail.text += '3. Pour %s → %s. Stir, then serve.\nKeep blends separate until step 3.' % [stages[0].name,stages[1].name]+warning
	detail.add_theme_color_override('font_color',Color('#9b5145') if not warning.is_empty() else Color('#355d4c'))
	var query = search.text.strip_edges().to_lower()
	for i in range(recipe_buttons.size()):
		var entry = Brewing.RECIPES[i]
		var terms = entry.name+' '+entry.effect+' '+entry.note
		for ingredient in Brewing.raw_ingredients(entry):
			terms += ' '+Brewing.INGREDIENTS[ingredient].name
		var relevant = (int(entry.cure) & game.visible_symptoms()) != 0
		var unlocked = not game.campaign or game.campaign.recipe_available(i)
		recipe_buttons[i].visible = unlocked and (query.is_empty() or query in terms.to_lower()) and (not matches_only.button_pressed or relevant)
		recipe_buttons[i].text = ('● ' if i == game.pinned else '%02d  ' % [i+1])+entry.name
	basket_note.text = '%d / 6 bottles. Click a collected potion to remove it.' % basket.size() if not basket.is_empty() else 'Your basket is empty. Collect potions from the shelves.'
	for i in range(basket_buttons.size()):
		basket_buttons[i].visible = i < basket.size()
		basket_buttons[i].disabled = not game.can_edit()
		if i < basket.size():
			basket_buttons[i].text = '  %d. %s%s   ×' % [i+1,Brewing.INGREDIENTS[basket[i]].name,' (empty)' if basket_empty[i] else '']
	for i in range(pantry_buttons.size()):
		var count = remaining(i) if tracked() else -1
		pantry_buttons[i].get_node('Caption').text = Brewing.INGREDIENTS[i].name+('\n%d available' % count if tracked() else '\nUnlimited practice supply')
		pantry_buttons[i].tooltip_text = Brewing.INGREDIENTS[i].description+('\nSource: '+game.campaign.herbs.source_name(i)+' · prepare at the garden bench.' if tracked() else '')
		pantry_buttons[i].disabled = not game.can_edit() or basket.size() == 6 or (tracked() and count == 0)
	supply_note.text = 'Your prepared stock · bottles are spent when poured. Removing a full bottle returns it to the shelf.' if tracked() else 'Practice pantry · unlimited bottles for experimenting.'
	garden_link.visible = tracked()
	emergency_button.visible = tracked()
	emergency_button.disabled = not game.can_edit()
	carry.text = 'Carry %d bottles to the table  →' % basket.size()
	carry.disabled = not game.can_edit()
	pantry_open.disabled = not game.can_edit()
	game.sync_table_bottles()
	for i in range(table_buttons.size()):
		var stocked = i < game.table_stock.size()
		table_buttons[i].visible = stocked
		if stocked:
			table_buttons[i].tooltip_text = Brewing.INGREDIENTS[game.table_stock[i]].name+(' — empty; return to pantry for a fresh bottle' if game.table_empty[i] else ' — click to pour')
			tint_bottle(table_buttons[i].get_node('Bottle'),game.table_stock[i],game.table_empty[i])
		table_buttons[i].disabled = not game.can_edit() or not stocked or (stocked and game.table_empty[i])
