extends Control
## Two soil areas around the courtyard paths; patches have no physical dividers.
const H = preload('res://scripts/herbalism.gd')
const ROOTS = [Vector2(560,422),Vector2(405,603),Vector2(950,448),Vector2(285,765),Vector2(1040,595),Vector2(1210,760)]
var ui
var atlas: Texture2D
var selected_patch = 0

func setup(owner_ui):
	ui = owner_ui
	selected_patch = ui.garden_patch
	size = Vector2(1440,900)
	name = 'HerbGarden'
	atlas = load('res://assets/garden/herb-plants.png')
	var backdrop = TextureRect.new()
	add_child(backdrop)
	backdrop.name = 'PaintedGarden'
	backdrop.texture = load('res://assets/garden/ingredient-garden.png')
	backdrop.size = size
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(6): draw_patch(i)
	var heading = panel(Rect2(26,22,1388,106),0.96)
	text(heading,'The apothecary garden',Rect2(22,8,650,43),32)
	text(heading,'Click a herb or open soil · grow ingredients for your recipes',Rect2(24,58,610,28),17)
	button(heading,'Recipe ingredients',Rect2(643,25,213,45),ui.open_ingredients)
	button(heading,'Preparation bench',Rect2(872,25,230,45),ui.open_bench)
	button(heading,'Return to clinic',Rect2(1120,25,245,45),ui.leave)
	if selected_patch >= 0: information()
	var footer = panel(Rect2(26,829,1388,48),0.96)
	text(footer,ui.feedback if ui.feedback != '' else 'Herbs regrow in two clinic days. Harvest three portions; free cuttings are always available.',Rect2(18,6,1350,36),17)

func herbs():
	return ui.model()

func panel(rect, opacity = 0.95):
	var card = ui.campaign.game.supplies.panel_at(self,rect)
	var style = card.get_theme_stylebox('panel').duplicate()
	style.bg_color.a = opacity
	card.add_theme_stylebox_override('panel',style)
	return card

func text(parent, words, rect, font_size = 18):
	return ui.campaign.game.supplies.label_at(parent,words,rect,font_size)

func button(parent, words, rect, callback):
	var action = ui.campaign.game.supplies.button_at(parent,words,rect,callback)
	action.add_theme_color_override('font_disabled_color',Color('#777968'))
	return action

static func botanical_texture(herb):
	var region = AtlasTexture.new()
	region.atlas = load('res://assets/garden/herb-plants.png') if herb < 4 else load('res://assets/garden/ingredient-plants.png')
	var columns = 2 if herb < 4 else 3
	var cell = region.atlas.get_size()/Vector2(columns,2)
	var slot = herb if herb < 4 else herb-4
	region.region = Rect2(Vector2(slot%columns,int(slot/columns))*cell,cell)
	# Leave a sampling gutter below the new atlas's top row to exclude the next row's tips.
	if herb >= 4 and slot < 3: region.region.size.y -= 24
	return region

func plant_sprite(herb, root, extent, flip = false):
	var sprite = TextureRect.new()
	add_child(sprite)
	sprite.texture = botanical_texture(herb)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size = Vector2(extent,extent)
	sprite.position = root-Vector2(extent*0.5,extent*0.94)
	sprite.flip_h = flip
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sprite

func draw_patch(index):
	var plot = herbs().plots[index]
	var root = ROOTS[index]
	var available = index < herbs().unlocked_beds()
	var herb = int(plot.herb)
	var footprint = 150.0 if index < 3 else 190.0
	if herb >= 0:
		var growth = int(plot.age)
		var scale_factor = [0.32,0.64,1.0][growth]
		# Three overlapping painted clumps form a natural patch, rather than a UI tile.
		plant_sprite(herb,root+Vector2(-56,-1),footprint*0.64*scale_factor,true)
		plant_sprite(herb,root+Vector2(61,-6),footprint*0.62*scale_factor)
		plant_sprite(herb,root+Vector2(0,9),footprint*0.78*scale_factor)
	var hotspot = Button.new()
	add_child(hotspot)
	hotspot.name = 'Patch%d' % index
	hotspot.position = root-Vector2(footprint*0.48,footprint*0.8)
	hotspot.size = Vector2(footprint*0.96,footprint*0.9)
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ['normal','pressed','disabled']:
		hotspot.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(1.0,0.94,0.66,0.08)
	hover.border_color = Color(1.0,0.92,0.65,0.75)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(60)
	hotspot.add_theme_stylebox_override('hover',hover)
	hotspot.add_theme_stylebox_override('focus',hover)
	hotspot.pressed.connect(func(): ui.select_garden_patch(index))
	var caption = H.HERBS[herb].name if herb >= 0 else ('Ready for seeds' if available else 'Wild soil')
	if herb >= 0:
		caption += ' · harvest' if int(plot.age) == 2 else ' · growing'
	hotspot.tooltip_text = caption
	# Small wooden garden markers sit in the earth; the soil has no internal borders.
	var marker = button(self,caption,Rect2(root.x-90,root.y+8,180,31),func(): ui.select_garden_patch(index))
	marker.name = 'Marker%d' % index
	marker.add_theme_font_size_override('font_size',15)
	var timber = StyleBoxFlat.new()
	timber.bg_color = Color('#d9bc83')
	timber.border_color = Color('#80653f')
	timber.set_border_width_all(1)
	timber.set_corner_radius_all(3)
	marker.add_theme_stylebox_override('normal',timber)
	if index == selected_patch:
		var active = timber.duplicate()
		active.bg_color = Color('#efe3ad')
		active.set_border_width_all(2)
		marker.add_theme_stylebox_override('normal',active)

func information():
	var patch = herbs().plots[selected_patch]
	var herb = int(patch.herb)
	var available = selected_patch < herbs().unlocked_beds()
	var card = panel(Rect2(26 if selected_patch in [2,4,5] else 1110,243,304,566),0.96)
	text(card,'GARDEN BASKET',Rect2(20,17,264,25),15)
	button(card,'×',Rect2(252,10,36,32),func(): ui.select_garden_patch(-1))
	text(card,H.HERBS[herb].name if herb >= 0 else ('Open soil' if available else 'Room to grow'),Rect2(20,51,264,40),27)
	if herb >= 0:
		text(card,'Ready to harvest · 3 portions' if int(patch.age) == 2 else 'Regrowing · %d clinic day(s)' % [2-int(patch.age)],Rect2(20,99,264,49),17)
		text(card,H.HERBS[herb].note,Rect2(20,159,264,104),17)
		var harvest = button(card,'Harvest',Rect2(20,278,264,42),func():
			if herbs().harvest(selected_patch): ui.changed('Three portions gathered. The herb will regrow in two clinic days.',true))
		harvest.disabled = int(patch.age) < 2
		button(card,'Clear this patch',Rect2(20,331,264,36),func():
			herbs().plots[selected_patch] = {'herb':-1,'age':0}
			ui.changed('The soil is ready. Choose seeds for this patch.',true))
		text(card,'In your basket: %d portions' % int(herbs().raw[herb]),Rect2(20,385,264,40),18)
		var cutting = button(card,'Request a free cutting',Rect2(20,446,264,42),func():
			if herb in herbs().known:
				herbs().cutting(herb)
				ui.changed('A neighbour shares a fresh cutting.',true))
		cutting.disabled = herb not in herbs().known
		# Samples still introduce unidentified herbs before they can be prepared.
		if herb not in herbs().known:
			text(card,'Examine the patient’s sample to learn this herb’s preparation.',Rect2(20,502,264,51),15)
	elif available:
		text(card,'Choose a herb from your seed collection. It grows here in the shared plot and is ready after two clinic days.',Rect2(20,108,264,109),17)
		var picker = OptionButton.new()
		card.add_child(picker)
		picker.name = 'SeedSelection'
		picker.position = Vector2(20,237)
		picker.size = Vector2(264,44)
		if ui.selected not in herbs().known: ui.selected = 0
		for id in herbs().known: picker.add_item(H.HERBS[int(id)].name)
		picker.select(herbs().known.find(ui.selected))
		picker.add_theme_color_override('font_color',Color('#355d4c'))
		var seed_style = StyleBoxFlat.new()
		seed_style.bg_color = Color('#e3d6b6')
		seed_style.set_corner_radius_all(7)
		seed_style.content_margin_left = 10
		for state in ['normal','hover','pressed','focus']: picker.add_theme_stylebox_override(state,seed_style)
		picker.item_selected.connect(func(index): ui.selected = int(herbs().known[index]))
		button(card,'Plant selected herb',Rect2(20,304,264,46),func():
			if herbs().plant(selected_patch,ui.selected): ui.changed(H.HERBS[ui.selected].name+' planted in the shared herb plot.',true))
		text(card,'Seeds are free. Mature plants provide three portions and regrow after harvesting.',Rect2(20,386,264,110),17)
	else:
		text(card,'Poppy, Pip and Juniper will help prepare this part of the soil after their botanical treatments.',Rect2(20,110,264,130),18)
		text(card,'Their gift makes room for two more herb patches and brings Hushbell seeds. Both soil areas share your seed collection.',Rect2(20,280,264,160),17)
	text(card,'%d / %d herbs discovered' % [herbs().known.size(),H.HERBS.size()],Rect2(20,530,264,25),15)
