extends SceneTree

func _initialize():
	call_deferred('capture')

func capture():
	var portraits = load('res://scenes/patients/patient_lineup.tscn').instantiate()
	root.add_child(portraits)
	if not portraits.load_people():
		push_error(str(portraits.errors))
		quit(1)
		return
	var directory = ProjectSettings.globalize_path('res://previews/patient-layers/render-proof')
	DirAccess.make_dir_recursive_absolute(directory)
	for person in range(6):
		for frame in range(-1,9):
			var mood = portraits.MOODS[maxi(0,int(frame/3))]
			var period = 4.7+(person%3)*0.41
			var seconds = period-0.6-person*0.61+[0.35,0.03,0.10][maxi(frame,0)%3]
			portraits.update_person(person,seconds,mood,0)
			portraits.people[person].node.get_node('Face').visible = frame >= 0
			if frame >= 0 and portraits.frame_index(person,seconds,mood) != frame:
				push_error('Proof selected the wrong facial frame.')
				quit(1)
				return
			await process_frame
			await RenderingServer.frame_post_draw
			var pixels = root.get_texture().get_image().get_region(Rect2i(0,0,512,384))
			var suffix = 'blank' if frame < 0 else str(frame)
			if pixels.save_png(directory+'/'+portraits.people[person].name.to_lower()+'-'+suffix+'.png') != OK:
				quit(1)
				return
	print('LAYER PROOF: six blank bodies and 54 facial states rendered from native scenes.')
	portraits.queue_free()
	await process_frame
	quit()
