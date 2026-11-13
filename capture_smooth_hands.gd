extends SceneTree

func _initialize():
	call_deferred('capture')

func shot(game, name, seconds):
	game.animation_time = seconds
	game.focused = true
	game._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png('res://previews/smooth-hands/'+name+'.png')

func capture():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path('res://previews/smooth-hands'))
	var game = load('res://main.tscn').instantiate()
	root.add_child(game)
	game.muted = true
	game.set_process(false)
	await process_frame
	game.table_stock = [0,2]
	game.sync_table_bottles()
	game.refresh()
	await shot(game,'idle',0.0)
	game.pour_bottle(0)
	for sample in [['reach',0.5],['pickup',1.2],['pour',3.0],['return',4.9],['release',5.5]]:
		await shot(game,sample[0],sample[1])
	game.finish_pour()
	game.pour_bottle(1)
	game.finish_pour()
	await shot(game,'waiting-for-stir',game.pour_duration())
	game.layer.get_node('Clipboard/Primary').pressed.emit()
	for sample in [['spoon-pickup',1.0],['stir',3.0],['spoon-return',6.5]]:
		await shot(game,sample[0],game.pour_duration()+sample[1])
	game.finish_mix()
	await shot(game,'complete',game.mix_duration())
	game.queue_free()
	await process_frame
	quit()
