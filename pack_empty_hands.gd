extends SceneTree
func _initialize():
	var base = 'res://assets/rotoscope/empty-hands/'
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base))
	var hashes = {}
	for clip in ['pour','stir']:
		for page in range(1,7 if clip == 'pour' else 8):
			var name = '%s-%02d.png' % [clip,page]
			var source = base+'sources/'+name
			if clip == 'pour' and page == 6:
				source = 'res://assets/rotoscope/pour-06.png'
			var img = Image.load_from_file(ProjectSettings.globalize_path(source))
			if img == null:
				quit(1)
				return
			img.convert(Image.FORMAT_RGBA8)
			img.resize(2048,864,Image.INTERPOLATE_LANCZOS)
			img.save_png(base+name)
			hashes[name] = FileAccess.get_sha256(base+name)
			if page == 1:
				var idle = Image.create(2048,576,false,Image.FORMAT_RGBA8)
				for frame in range(6):
					var pos = Vector2i(frame%4*512,int(frame/4)*288)
					idle.blit_rect(img,Rect2i(pos,Vector2i(512,288)),pos)
				idle.save_png(base+('idle.png' if clip == 'pour' else 'idle-right.png'))
	var f = FileAccess.open(base+'manifest.json',FileAccess.WRITE)
	f.store_string(JSON.stringify({'tool':'built-in imagegen','change':'Remove painted props from complete generated arm frames','atlas_sha256':hashes},'  '))
	print('Packed complete empty-hand arm frames.')
	quit()
