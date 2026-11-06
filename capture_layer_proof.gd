extends SceneTree

class ProofSprite extends Control:
	var portraits
	var person = 0
	var seconds = 0.0
	var mood = 'neutral'
	var blank = false
	func _draw():
		draw_rect(Rect2(0,0,512,384),Color('#fff1d5'))
		if blank:
			draw_texture(portraits.people[person].body,Vector2.ZERO)
		else:
			portraits.draw_person(self,person,seconds,mood,Vector2.ZERO)

func _initialize():
	call_deferred('capture')

func capture():
	var portraits = load('res://patient_sprites.gd').new()
	if not portraits.load_people():
		push_error(str(portraits.errors))
		quit(1)
		return
	var actor = ProofSprite.new()
	actor.portraits = portraits
	root.add_child(actor)
	var directory = ProjectSettings.globalize_path('res://../work/patient-layers/render-proof')
	DirAccess.make_dir_recursive_absolute(directory)
	for person in range(6):
		actor.person = person
		for frame in range(-1,9):
			actor.blank = frame == -1
			if frame >= 0:
				actor.mood = portraits.MOODS[int(frame/3)]
				var period = 4.7+(person%3)*0.41
				actor.seconds = period-0.6-person*0.61+[0.35,0.03,0.10][frame%3]
				if portraits.frame_index(person,actor.seconds,actor.mood) != frame:
					push_error('Proof selected the wrong facial frame.')
					quit(1)
					return
			actor.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var pixels = root.get_texture().get_image().get_region(Rect2i(0,0,512,384))
			var suffix = 'blank' if frame < 0 else str(frame)
			if pixels.save_png(directory+'/'+portraits.people[person].name.to_lower()+'-'+suffix+'.png') != OK:
				quit(1)
				return
	print('LAYER PROOF: six blank bodies and 54 facial states rendered.')
	actor.queue_free()
	await process_frame
	quit()
