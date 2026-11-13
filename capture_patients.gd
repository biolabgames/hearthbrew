extends SceneTree

func _initialize():
	call_deferred('capture')

func capture():
	var game = load('res://main.tscn').instantiate()
	root.add_child(game)
	game.muted = true
	game.set_process(false)
	await process_frame
	var args = OS.get_cmdline_user_args()
	var layers_preview = '--layers' in args
	var preview_root = 'res://previews/patient-layers' if layers_preview else 'res://previews/patients'
	var directory = ProjectSettings.globalize_path(preview_root+'/frames')
	DirAccess.make_dir_recursive_absolute(directory)
	for person in range(6):
		if layers_preview and person != 0:
			continue
		game.load_patient(person)
		# Preview the person after visibility/stone/levitation treatment so
		# all six designs can be inspected clearly, alongside remaining symptoms.
		game.symptoms &= ~(game.Brewing.INVISIBLE|game.Brewing.STONE|game.Brewing.FLOATING)
		for ingredient in game.Brewing.RECIPES[game.pinned].sequence:
			game.add_ingredient(ingredient)
		game.start_mix()
		for local in range(72):
			var seconds = local/12.0
			game.clock = seconds
			game.patient_reaction = ['frown','neutral','smile'][mini(int(seconds/2.0),2)]
			game.patient_reaction_until = 100.0
			game.animation_time = game.pour_duration()+seconds
			game._process(0.0)
			game.update_presentation()
			await process_frame
			await RenderingServer.frame_post_draw
			var pixels = root.get_texture().get_image()
			if pixels.save_png(directory+'/frame-%03d.png' % (person*72+local)) != OK:
				push_error('Patient preview could not be saved.')
				quit(1)
				return
			if local == 66:
				pixels.save_png(ProjectSettings.globalize_path(preview_root+'/'+game.patient().name.to_lower()+'.png'))
		print('PATIENT PREVIEW: '+game.patient().name+' captured.')
	game.queue_free()
	await process_frame
	quit()
