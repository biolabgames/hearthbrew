extends SceneTree

func _initialize():
	call_deferred('capture')

func caption(parent, words: String, point: Vector2, font_size = 15):
	var label = Label.new()
	parent.add_child(label)
	label.position = point
	label.text = words
	label.add_theme_font_size_override('font_size',font_size)
	label.add_theme_color_override('font_color',Color('#355d4c'))

func capture():
	var canvas = Node2D.new()
	root.add_child(canvas)
	var paper = Polygon2D.new()
	canvas.add_child(paper)
	paper.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1440,0),Vector2(1440,900),Vector2(0,900)])
	paper.color = Color('#fff1d8')
	var source = JSON.parse_string(FileAccess.get_file_as_string('res://resources/hands/user_video_traces.json'))
	var actors = []
	for side_index in range(2):
		var side = 'left' if side_index == 0 else 'right'
		var indices = [0,24,36,56] if side == 'left' else [0,24,42,72]
		for row in range(4):
			var frame = indices[row]
			var point = Vector2(side_index*720,row*218)
			var record = source.clips[side].frames[frame]
			caption(canvas,'%s: %s — frame %d (%.2fs)' % [side.to_upper(),source.clips[side].video,frame,frame/12.0],point+Vector2(10,8))
			var directory = 'rotoscope/native-frames/' if side == 'left' else 'rotoscope-010936/frames/'
			var pixels = Image.load_from_file(ProjectSettings.globalize_path('res://../work/'+directory+record.source_frame))
			var photo = Sprite2D.new()
			canvas.add_child(photo)
			photo.texture = ImageTexture.create_from_image(pixels)
			photo.centered = false
			photo.position = point+Vector2(10,45)
			photo.scale = Vector2.ONE*0.45
			var crop = Sprite2D.new()
			canvas.add_child(crop)
			var box = record.crop
			crop.texture = ImageTexture.create_from_image(pixels.get_region(Rect2i(box[0],box[1],128,128)))
			crop.centered = false
			crop.position = point+Vector2(245,38)
			crop.scale = Vector2.ONE*1.15
			var actor = load('res://scenes/props/user_video_hand.tscn').instantiate()
			actor.source_side = side
			canvas.add_child(actor)
			actor.get_node('Forearm').hide()
			actor.get_node('ArmOutline').hide()
			actor.get_node('ArmShadow').hide()
			actors.append([actor,frame,point+Vector2(570,110)])
			caption(canvas,'Original recording',point+Vector2(10,181))
			caption(canvas,'Unchanged crop',point+Vector2(245,190))
			caption(canvas,'In-game source pose',point+Vector2(455,190))
	await process_frame
	for sample in actors:
		sample[0].set_source_time(sample[1]/12.0)
		sample[0].position = sample[2]
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png('res://previews/user-video-proof.png')
	canvas.queue_free()
	await process_frame
	quit()
