extends SceneTree

func _initialize():
	call_deferred('capture')

func capture():
	RenderingServer.set_default_clear_color(Color('#527663'))
	var portraits = load('res://scenes/patients/patient_lineup.tscn').instantiate()
	root.add_child(portraits)
	var ready_only = '--ready-only' in OS.get_cmdline_user_args()
	if ready_only:
		for actor in portraits.get_children():
			if actor.has_node('Body') and not ResourceLoader.exists('res://assets/patients/reactions/'+str(actor.name).to_lower()+'.png'):
				portraits.remove_child(actor)
				actor.queue_free()
	if not portraits.load_people() and not ready_only:
		push_error(str(portraits.errors))
		quit(1)
		return
	var directory = 'res://previews/reactions'
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var delighted_sheet = Image.create(2560,1536,false,Image.FORMAT_RGBA8)
	var disgust_sheet = Image.create(2560,1536,false,Image.FORMAT_RGBA8)
	var reports = []
	var failures = 0
	for person in range(portraits.people.size()):
		var baseline: Image
		var actor = portraits.people[person].node
		var face_bounds = Rect2i(168,37,177,186) if actor.get_meta('full_portrait',false) else Rect2i(200,96,128,128)
		for mood in ['neutral','delighted','disgust']:
			var seconds = 4.7+(person%3)*0.41-0.6-person*0.61+0.35
			portraits.update_person(person,seconds,mood,0)
			await process_frame
			await RenderingServer.frame_post_draw
			var pixels = root.get_texture().get_image().get_region(Rect2i(0,0,512,384))
			pixels.convert(Image.FORMAT_RGBA8)
			if mood == 'neutral':
				baseline = pixels
				continue
			pixels.save_png(directory+'/'+str(actor.name).to_lower()+'-'+mood+'.png')
			var sheet = delighted_sheet if mood == 'delighted' else disgust_sheet
			sheet.blit_rect(pixels,Rect2i(0,0,512,384),Vector2i((person%5)*512,int(person/5)*384))
			var changed_outside_face = 0
			var changed_inside_face = 0
			for y in range(384):
				for x in range(512):
					if pixels.get_pixel(x,y) != baseline.get_pixel(x,y):
						if face_bounds.has_point(Vector2i(x,y)):
							changed_inside_face += 1
						else:
							changed_outside_face += 1
			if changed_outside_face != 0 or changed_inside_face == 0:
				failures += 1
			reports.append({'patient':str(actor.name),'mood':mood,'changed_inside_face':changed_inside_face,'changed_outside_face':changed_outside_face})
		print('REACTION PREVIEW: '+str(actor.name))
		delighted_sheet.save_png(directory+'/delighted-roster.png')
		disgust_sheet.save_png(directory+'/disgust-roster.png')
	var report = FileAccess.open(directory+'/body-preservation.json',FileAccess.WRITE)
	report.store_string(JSON.stringify({'failures':failures,'comparisons':reports},'\t'))
	print('REACTION PROOF: %d comparisons, %d failures.' % [reports.size(),failures])
	if not ready_only:
		portraits.queue_free()
		await process_frame
		var game = load('res://main.tscn').instantiate()
		root.add_child(game)
		game.muted = true
		await process_frame
		game.set_process(false)
		game.campaign.active = false
		game.campaign.modal.hide()
		game.campaign.speech_dismissed = true
		for mood in ['disgust','delighted']:
			game.new_shift()
			game.clock = 1.0
			game.queue = [4,4] if mood == 'disgust' else [0,2]
			game.has_result = true
			game.result_recipe = -1 if mood == 'disgust' else 0
			game.serve()
			game.update_presentation()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory+'/poppy-'+mood+'-in-game.png')
	quit(0 if failures == 0 else 1)
