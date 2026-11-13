extends SceneTree
## Visual proof of every full/empty sprite pair on an opaque warm background.
const IDS = ['moonmilk','ember','dew','lavender','moss','honey','rose','ginger','valerian','silverleaf','starlight','burdock']
const Brewing = preload('res://brewing.gd')

func _initialize():
	call_deferred('capture')

func caption(parent, words, point, width, font_size):
	var label = Label.new()
	parent.add_child(label)
	label.text = words
	label.position = point
	label.size = Vector2(width,28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override('font_size',font_size)
	label.add_theme_color_override('font_color',Color('#493522'))

func capture():
	var page = ColorRect.new()
	root.add_child(page)
	page.color = Color('#dfba83')
	page.size = Vector2(1440,900)
	for i in range(IDS.size()):
		var origin = Vector2((i%4)*360,20+(i/4)*290)
		caption(page,Brewing.INGREDIENTS[i].name,origin,360,22)
		for state in range(2):
			var sprite = Sprite2D.new()
			page.add_child(sprite)
			var directory = 'empty/' if state == 1 else ''
			sprite.texture = load('res://assets/potions/'+directory+IDS[i]+'.png')
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.scale = Vector2.ONE*(210.0/sprite.texture.get_height())
			sprite.position = origin+Vector2(100+state*160,145)
			caption(page,'Full' if state == 0 else 'Empty',origin+Vector2(20+state*160,252),160,15)
	await process_frame
	await RenderingServer.frame_post_draw
	var target = 'res://previews/potion-variants.png'
	var error = root.get_texture().get_image().save_png(target)
	print('POTION VARIANTS: '+target)
	quit(0 if error == OK else 1)
