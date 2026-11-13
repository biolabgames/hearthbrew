extends SceneTree

# Import generated atlas exports into the existing fixed animation grid.
# This is offline normalization only; playback still draws native 512x288 frames.
func _initialize():
	var base = 'res://assets/rotoscope/'
	var sources = base+'bare-arm-sources/'
	var hashes = {}
	for clip in ['pour','stir']:
		var count = 6 if clip == 'pour' else 7
		for page in range(1,count+1):
			var name = '%s-%02d.png' % [clip,page]
			var image = Image.load_from_file(ProjectSettings.globalize_path(sources+name))
			if image == null or image.is_empty():
				push_error('Missing redraw: '+name)
				quit(1)
				return
			image.convert(Image.FORMAT_RGBA8)
			image.resize(2048,864,Image.INTERPOLATE_LANCZOS)
			if not save_image(image,base+name):
				quit(1)
				return
			hashes[name] = FileAccess.get_sha256(base+name)
			if page == 1:
				var idle = Image.create(2048,576,false,Image.FORMAT_RGBA8)
				for frame in range(6):
					var offset = Vector2i(frame%4*512,int(frame/4)*288)
					idle.blit_rect(image,Rect2i(offset,Vector2i(512,288)),offset)
				if not save_image(idle,base+('idle.png' if clip == 'pour' else 'idle-right.png')):
					quit(1)
					return
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(base+'manifest.json'))
	manifest['arm_redraw'] = {
		'date':'2026-11-10', 'tool':'built-in imagegen',
		'changes':'Bare forearms replace baggy sleeves and cuffs; simplified hand shading and detail.',
		'prompt':'bare-arm-sources/prompt.json',
		'normalization':'Generated exports normalized offline to 2048x864; native 512x288 playback unchanged.',
		'atlas_sha256':hashes,
		'original_metadata':'frames and stir_frames retain the original painted-source crop and hash provenance.'
	}
	var file = FileAccess.open(base+'manifest.json',FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,'  ',false))
	print('Imported all 156 bare-arm action frames and regenerated both idle sheets.')
	quit()

func save_image(image: Image, path: String) -> bool:
	for attempt in range(5):
		if image.save_png(path) == OK:
			return true
		OS.delay_msec(100)
	return false
