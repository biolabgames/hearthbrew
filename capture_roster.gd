extends SceneTree

func _initialize():
	call_deferred('capture')

func capture():
	var game = load('res://main.tscn').instantiate()
	root.add_child(game)
	game.muted = true
	await process_frame
	game.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path('res://previews/roster'))
	var contact = Image.create(2560,1536,false,Image.FORMAT_RGBA8)
	for i in range(game.Brewing.PATIENTS.size()):
		game.load_patient(i)
		game.clock = 1.0
		game.patient_reaction = 'neutral'
		game.patient_reaction_until = 100
		game.update_presentation()
		await process_frame
		await RenderingServer.frame_post_draw
		var pixels = root.get_texture().get_image()
		pixels.save_png('res://previews/roster/%02d-%s.png' % [i+1,game.patient().name.to_lower()])
		contact.blit_rect(pixels,Rect2i(464,166,512,384),Vector2i((i%5)*512,int(i/5)*384))
	contact.save_png('res://previews/roster/contact-sheet.png')
	print('ROSTER PREVIEW: captured all twenty patients.')
	quit()
