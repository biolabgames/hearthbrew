extends RefCounted

# Complete first-person hand + forearm frames only. No bones, meshes,
# rotation, per-part transforms, image stretching or pose interpolation.
# Motion is baked into complete frames derived from filmed references.
const MANIFEST_PATH = 'res://assets/rotoscope/manifest.json'
var clips = {}
var errors: Array[String] = []
var provenance = ''

func load_manifest(path = MANIFEST_PATH):
	clips.clear()
	errors.clear()
	if not FileAccess.file_exists(path):
		errors.append('Rotoscoped sprite sheets have not been supplied.')
		return false
	var file = FileAccess.open(path,FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get('version',0) != 1:
		errors.append('Expected a version 1 rotoscope manifest.')
		return false
	provenance = str(data.get('reference_footage','')).strip_edges()
	if provenance.is_empty():
		errors.append('Identify the actual filmed motion used to trace these frames.')
		return false
	var definitions = data.get('clips',{})
	if not definitions is Dictionary:
		errors.append('Clips must be named manifest entries.')
		return false
	for name in definitions:
		load_clip(str(name),definitions[name])
	for required in data.get('required_clips',['idle','pour']):
		if not clips.has(required):
			errors.append('Missing reference-based animation: '+required)
	return errors.is_empty()

func load_clip(name: String, data):
	if not data is Dictionary:
		errors.append(name+': expected clip data.')
		return
	var dimensions = data.get('frame_size',[])
	if not dimensions is Array or dimensions.size() != 2:
		errors.append(name+': frame_size must be [width,height].')
		return
	var size = Vector2i(int(dimensions[0]),int(dimensions[1]))
	var count = int(data.get('frame_count',0))
	var columns = int(data.get('columns',0))
	var fps = float(data.get('fps',0))
	if size.x <= 0 or size.y <= 0 or count <= 0 or columns <= 0 or fps <= 0:
		errors.append(name+': invalid frame size, count, columns or frame rate.')
		return
	var pages = []
	var remaining = count
	for page in data.get('pages',[{'sheet':data.get('sheet',''),'frame_count':count}]):
		var page_count = int(page.get('frame_count',0))
		var sheet_path = str(page.get('sheet',''))
		if not sheet_path.begins_with('res://assets/rotoscope/') or page_count <= 0:
			errors.append(name+': invalid local atlas page.')
			return
		var image = Image.load_from_file(ProjectSettings.globalize_path(sheet_path))
		var rows = ceili(float(page_count)/columns)
		if image == null or image.is_empty() or image.get_size() != Vector2i(size.x*columns,size.y*rows):
			errors.append(name+': atlas dimensions do not match the native frame grid.')
			return
		if image.detect_alpha() == Image.ALPHA_NONE:
			errors.append(name+': a transparent background is required.')
			return
		pages.append({'texture':ImageTexture.create_from_image(image),'count':page_count})
		remaining -= page_count
	if remaining != 0:
		errors.append(name+': atlas page counts do not match the clip.')
		return
	clips[name] = {
		'pages':pages,'size':size,
		'count':count,'columns':columns,'fps':fps,
		'loop':bool(data.get('loop',false)),
		'events':data.get('events',{}),'source':str(data.get('source_clip',''))
	}

func frame_index(name: String, seconds: float):
	if not clips.has(name):
		return -1
	var clip = clips[name]
	var index = maxi(0,int(floor(maxf(0,seconds)*clip.fps)))
	return index%clip.count if clip.loop else mini(index,clip.count-1)

func source_rect(name: String, seconds: float):
	var index = frame_index(name,seconds)
	if index < 0:
		return Rect2()
	var clip = clips[name]
	for page in clip.pages:
		if index < page.count:
			break
		index -= page.count
	return Rect2(Vector2(index%clip.columns,int(index/clip.columns))*Vector2(clip.size),Vector2(clip.size))

func draw_frame(canvas: CanvasItem, name: String, seconds: float, origin: Vector2):
	if not clips.has(name):
		return false
	var clip = clips[name]
	var index = frame_index(name,seconds)
	var texture = clip.pages[0].texture
	for page in clip.pages:
		if index < page.count:
			texture = page.texture
			break
		index -= page.count
	# Source and destination sizes are identical. Frame content already
	# contains the complete traced reach, grip, wrist and forearm movement.
	canvas.draw_set_transform( Vector2.ZERO )
	canvas.draw_texture_rect_region(texture,Rect2(origin,Vector2(clip.size)),source_rect(name,seconds))
	return true

func event_frame(name: String, event: String):
	if not clips.has(name):
		return -1
	return int(clips[name].events.get(event,-1))
