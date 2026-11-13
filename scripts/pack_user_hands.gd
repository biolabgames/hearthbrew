extends SceneTree
## Crop and pack unchanged original video pixels, without resampling/redrawing.
func _initialize():
	var data = JSON.parse_string(FileAccess.get_file_as_string('res://resources/hands/user_video_traces.json'))
	var target = 'res://assets/user-video-hands/'
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target))
	for side in ['left','right']:
		var directory = 'res://../work/'+('rotoscope/native-frames/' if side == 'left' else 'rotoscope-010936/frames/')
		var frames = data.clips[side].frames
		for page in range(ceili(frames.size()/12.0)):
			var sheet = Image.create(512,384,false,Image.FORMAT_RGB8)
			for cell in range(12):
				var index = page*12+cell
				if index >= frames.size():
					break
				var record = frames[index]
				var original = Image.load_from_file(ProjectSettings.globalize_path(directory+record.source_frame))
				original.convert(Image.FORMAT_RGB8)
				var crop = record.crop
				var rectangle = Rect2i(int(crop[0]),int(crop[1]),128,128)
				sheet.blit_rect(original,rectangle,Vector2i(cell%4*128,int(cell/4)*128))
				var hash = HashingContext.new()
				hash.start(HashingContext.HASH_SHA256)
				hash.update(original.get_region(rectangle).get_data())
				record['crop_rgb_sha256'] = hash.finish().hex_encode()
			if sheet.save_png(target+'%s-%02d.png' % [side,page+1]) != OK:
				quit(1)
				return
	var file = FileAccess.open('res://resources/hands/user_video_traces.json',FileAccess.WRITE)
	file.store_string(JSON.stringify(data,'',false))
	print('Packed 156 unchanged user-video hand crops with source hashes.')
	quit()
