extends SceneTree

func _initialize():
	call_deferred('capture')

func capture():
	var game = load('res://main.tscn').instantiate()
	root.add_child(game)
	game.muted = true
	game.set_process(false)
	await process_frame
	game.add_ingredient(0)
	game.add_ingredient(2)
	game.start_mix()
	var target = ProjectSettings.globalize_path('res://previews/bare-arms')
	DirAccess.make_dir_recursive_absolute(target)
	for sample in [{'name':'idle','time':0.0},{'name':'pour','time':2.5},{'name':'stir','time':14.5}]:
		game.animation_time = sample.time
		game.clock = sample.time
		game._process(0.0)
		game.update_presentation()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(target+'/'+sample.name+'.png')
	game.queue_free()
	await process_frame
	quit()
