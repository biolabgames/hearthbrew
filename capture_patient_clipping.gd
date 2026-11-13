extends SceneTree
## Render regression: the patient's lowest floating pose must not alter the table.

func _initialize():
	call_deferred('capture')

func capture():
	var game = load('res://main.tscn').instantiate()
	root.add_child(game)
	game.muted = true
	game.set_process(false)
	game.load_patient(2)
	game.symptoms = game.Brewing.FLOATING
	game.refresh()
	game.campaign.speech_panel.hide()
	var table = Rect2i(464,524,512,30)
	for pose in range(3):
		game.clock = pose*PI/1.5
		game.update_presentation()
		game.patient_sprites.show()
		await process_frame
		await RenderingServer.frame_post_draw
		var with_patient = root.get_texture().get_image()
		if pose == 1:
			with_patient.save_png('res://previews/patient-counter-clip.png')
		game.patient_sprites.hide()
		await process_frame
		await RenderingServer.frame_post_draw
		var without_patient = root.get_texture().get_image()
		if with_patient.get_region(table).get_data() != without_patient.get_region(table).get_data():
			push_error('Patient appears over the table at floating pose '+str(pose))
			quit(1)
			return
		if pose == 1:
			# Ensure the comparison would catch the original overlap.
			game.patient_sprites.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
			game.patient_sprites.show()
			await process_frame
			await RenderingServer.frame_post_draw
			var unclipped = root.get_texture().get_image()
			if unclipped.get_region(table).get_data() == without_patient.get_region(table).get_data():
				push_error('Clipping comparison has no visible patient overlap to detect.')
				quit(1)
				return
			game.patient_sprites.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	print('PATIENT CLIPPING: 3 floating poses leave all pixels below the counter unchanged.')
	game.queue_free()
	await process_frame
	quit()
