extends SceneTree

# Deterministic rendered previews of footage-based sprite actions.
func _initialize():
	call_deferred('capture')

func capture():
	var game = load('res://main.tscn').instantiate()
	root.add_child(game)
	game.muted = true
	game.set_process(false)
	await process_frame
	for ingredient in [0,2]:
		game.add_ingredient(ingredient)
	game.start_mix()
	var args = OS.get_cmdline_user_args()
	var mode = args[args.find('--clip')+1] if '--clip' in args else 'pour'
	var count = 84 if mode == 'stir' else (240 if mode == 'mix' else 72)
	var target = ProjectSettings.globalize_path('res://previews/rotoscope/frames-'+mode)
	DirAccess.make_dir_recursive_absolute(target)
	for frame in range(count):
		game.animation_time = (frame+0.01)/12.0+(game.pour_duration() if mode == 'stir' else 0.0)
		game.clock = game.animation_time
		game._process(0.0)
		game.update_presentation()
		await process_frame
		await RenderingServer.frame_post_draw
		var error = root.get_texture().get_image().save_png(target+'/frame-%03d.png' % frame)
		if error != OK:
			push_error('Could not save rendered preview frame')
			quit(1)
			return
	print('MOTION PREVIEW: %d actual game frames saved (%s).' % [count,mode])
	game.queue_free()
	await process_frame
	quit()
