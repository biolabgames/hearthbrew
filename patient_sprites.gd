extends Node2D
## Bodies, face atlases and effect pools are authored in .tscn files.
const FRAME_SIZE = Vector2i(512,384)
const FACE_FRAME_SIZE = Vector2i(128,128)
const MOODS = ['neutral','smile','frown']
const REACTION_ROWS = {'delighted':1,'disgust':2}
const REACTION_SHADER = preload('res://assets/patients/reactions/reaction_face.gdshader')
const ORIGINAL_CHEEKS = [Vector2(274,154),Vector2(256,152),Vector2(264,152),Vector2(264,152),Vector2(264,152),Vector2(256,152)]
const Brewing = preload('res://brewing.gd')
@export var counter_clip_rect = Rect2()
var people = []
var errors: Array[String] = []

func _ready():
	if counter_clip_rect.has_area():
		clip_children = CanvasItem.CLIP_CHILDREN_ONLY

func _draw():
	if counter_clip_rect.has_area():
		draw_rect(counter_clip_rect,Color.WHITE)

func load_people():
	people.clear()
	errors.clear()
	for actor in get_children():
		if not actor.has_node('Body'):
			continue
		var layered = actor.has_node('Face')
		var body = actor.get_node('Body')
		if actor.get_meta('full_portrait',false):
			body.scale = Vector2(1536,1152)/body.texture.get_size()
			actor.get_node('Face').scale = body.scale
		var face = actor.get_node('Face')
		var slug = str(actor.name).to_lower()
		var reaction_texture = load('res://assets/patients/reactions/'+slug+'.png') as Texture2D
		var reaction = actor.get_node_or_null('ReactionFace') as Sprite2D
		if reaction == null:
			reaction = Sprite2D.new()
			reaction.name = 'ReactionFace'
			actor.add_child(reaction)
		reaction.texture = reaction_texture
		reaction.centered = false
		reaction.hframes = 3
		reaction.vframes = 3
		reaction.position = face.position
		reaction.visible = false
		if reaction_texture:
			reaction.scale = face.scale*face.texture.get_size()/reaction_texture.get_size()
		else:
			errors.append('Missing reaction faces for '+str(actor.name))
		var material = ShaderMaterial.new()
		material.shader = REACTION_SHADER
		material.set_shader_parameter('full_portrait',actor.get_meta('full_portrait',false))
		if not actor.get_meta('full_portrait',false):
			material.set_shader_parameter('feature_mask',load('res://assets/patients/layered/'+slug+'-face-mask.png'))
		reaction.material = material
		people.append({'name':str(actor.name),'body':body.texture,'faces':face.texture,'layered':layered,'node':actor,'origin':actor.position,'reactions':reaction_texture,'reaction_node':reaction})
	if people.size() != Brewing.PATIENTS.size():
		errors.append('Every catalog patient needs an illustrated scene.')
	return errors.is_empty()

func blink_column(person: int, seconds: float):
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
	if REACTION_ROWS.has(mood):
		return int(REACTION_ROWS[mood])*3+blink_column(person,seconds)
	return maxi(0,MOODS.find(mood))*3+blink_column(person,seconds)

func source_rect(person: int, seconds: float, mood: String):
	var frame = frame_index(person,seconds,mood)
	return Rect2(Vector2(frame%3,int(frame/3))*Vector2(FACE_FRAME_SIZE),Vector2(FACE_FRAME_SIZE))

func update_person(person: int, seconds: float, mood: String, symptoms: int):
	var offset = Vector2.ZERO
	if (symptoms & Brewing.FLOATING) != 0:
		offset.y += (1.0-cos(seconds*1.5))*6.0
	var tint = Color('#a9b4a6') if (symptoms & Brewing.STONE) != 0 else Color.WHITE
	if (symptoms & Brewing.CHILLS) != 0:
		tint *= Color('#d4e4fa')
		offset.x += sin(seconds*33.0)*0.85
	if (symptoms & Brewing.DIZZINESS) != 0:
		offset.x += sin(seconds*1.8)*1.7
	if (symptoms & Brewing.INVISIBLE) != 0:
		tint.a = 0.62
	for i in range(people.size()):
		var actor = people[i].node
		actor.visible = i == person
		if i == person:
			actor.position = people[i].origin+offset
			actor.modulate = tint
			var face = actor.get_node('Face' if people[i].layered else 'Body')
			var reacting = REACTION_ROWS.has(mood)
			face.visible = not reacting
			people[i].reaction_node.visible = reacting
			if reacting:
				people[i].reaction_node.frame = frame_index(person,seconds,mood)
			else:
				face.frame = frame_index(person,seconds,mood)
	# These authored parents start hidden in the scene; individual child visibility
	# alone cannot show the symptoms until their parent is visible too.
	$Effects.visible = symptoms != 0
	$Effects.z_index = 1
	$SymptomOverlay.visible = symptoms != 0
	for i in range(3):
		var bubble = $Effects.get_node('Hiccup'+str(i))
		bubble.visible = (symptoms & Brewing.HICCUPS) != 0
		var rise = fposmod(seconds*24+i*33,104)
		bubble.position = people[person].origin+offset+Vector2(342+sin(seconds+i)*9,204-rise)
		bubble.scale = Vector2.ONE*(5+i)
		bubble.modulate = Color(0.9,0.85,0.98,0.65)
		bubble.get_child(0).width = 1.5/(5+i)
	for i in range(4):
		var flower = $Effects.get_node('Bloom'+str(i))
		flower.visible = (symptoms & Brewing.BLOOM) != 0
		flower.position = people[person].origin+offset+Vector2(150 if i%2 == 0 else 360,310+int(i/2)*24+sin(seconds+i)*2)
	$SymptomOverlay.effect_mask = symptoms
	$SymptomOverlay.effect_time = seconds
	$SymptomOverlay.effect_origin = people[person].origin+offset
	$SymptomOverlay.face_center = Vector2(256,143) if people[person].node.get_meta('full_portrait',false) else ORIGINAL_CHEEKS[person]
	$SymptomOverlay.modulate.a = tint.a
	$SymptomOverlay.queue_redraw()
