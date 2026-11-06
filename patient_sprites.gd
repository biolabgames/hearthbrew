extends RefCounted

const FRAME_SIZE = Vector2i(512,384)
const FACE_FRAME_SIZE = Vector2i(128,128)
const MOODS = ['neutral','smile','frown']
var people = []
var errors: Array[String] = []

func load_people():
	people.clear()
	errors.clear()
	var path = 'res://assets/patients/layered/manifest.json'
	if not FileAccess.file_exists(path):
		errors.append('Patient sprite manifest is missing.')
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get('version',0) != 2:
		errors.append('Patient sprite manifest must be version 2 (static body and facial layers).')
		return false
	for person in data.get('people',[]):
		var body = Image.load_from_file(ProjectSettings.globalize_path(str(person.get('body',''))))
		var faces = Image.load_from_file(ProjectSettings.globalize_path(str(person.get('faces',''))))
		if body == null or body.is_empty() or body.get_size() != FRAME_SIZE:
			errors.append(str(person.get('name','Patient'))+': invalid static body.')
			continue
		if faces == null or faces.is_empty() or faces.get_size() != FACE_FRAME_SIZE*3:
			errors.append(str(person.get('name','Patient'))+': invalid facial overlay atlas.')
			continue
		if body.detect_alpha() == Image.ALPHA_NONE or faces.detect_alpha() == Image.ALPHA_NONE:
			errors.append(str(person.name)+': transparent body and face layers required.')
			continue
		var offset = person.get('face_offset',[200,96])
		var face_offset = Vector2(int(offset[0]),int(offset[1]))
		if not Rect2(Vector2.ZERO,Vector2(FRAME_SIZE)).encloses(Rect2(face_offset,Vector2(FACE_FRAME_SIZE))):
			errors.append(str(person.name)+': facial overlay exceeds body canvas.')
			continue
		people.append({'name':str(person.name),'body':ImageTexture.create_from_image(body),'faces':ImageTexture.create_from_image(faces),'face_offset':face_offset})
	if people.size() != 6:
		errors.append('Exactly six illustrated people are required.')
	return errors.is_empty()

func blink_column(person: int, seconds: float):
	# Brief half-close, full close, half-open; staggered per person.
	var period = 4.7+(person%3)*0.41
	var phase = fposmod(seconds+0.6+person*0.61,period)
	if phase < 0.06:
		return 1
	if phase < 0.15:
		return 2
	if phase < 0.23:
		return 1
	return 0

func frame_index(person: int, seconds: float, mood: String):
	var row = MOODS.find(mood)
	return maxi(0,row)*3+blink_column(person,seconds)

func source_rect(person: int, seconds: float, mood: String):
	var frame = frame_index(person,seconds,mood)
	return Rect2(Vector2(frame%3,int(frame/3))*Vector2(FACE_FRAME_SIZE),Vector2(FACE_FRAME_SIZE))

func draw_person(canvas: CanvasItem, person: int, seconds: float, mood: String, origin: Vector2, tint = Color.WHITE):
	if person < 0 or person >= people.size():
		return false
	canvas.draw_set_transform(Vector2.ZERO)
	# The very same blank-face body is always drawn first. Only the small
	# transparent facial-feature overlay changes with mood or blinking.
	var actor = people[person]
	canvas.draw_texture(actor.body,origin,tint)
	canvas.draw_texture_rect_region(actor.faces,Rect2(origin+actor.face_offset,Vector2(FACE_FRAME_SIZE)),source_rect(person,seconds,mood),tint)
	return true
