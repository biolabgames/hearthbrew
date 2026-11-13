extends Node2D
## Each side uses its own real video frames, contours, wrist and grip landmarks.
## No generated hand texture, mirrored substitute, or invented finger pose.
@export_enum('left','right') var source_side = 'left'
@export var hand_size = 1.0
static var source_data = {}
static var textures = {}
var source_cursor = 0.0
var source_frame = 0
var wrist_center = Vector2.ZERO
var wrist_normal = Vector2.RIGHT
@onready var hand: Polygon2D = $Graphic/Hand

func _ready():
	if source_data.is_empty():
		source_data = JSON.parse_string(FileAccess.get_file_as_string('res://resources/hands/user_video_traces.json'))
	for side in ['left','right']:
		if not textures.has(side):
			textures[side] = []
			for page in range(6 if side == 'left' else 7):
				var path = 'res://assets/user-video-hands/%s-%02d.png' % [side,page+1]
				textures[side].append(ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path))))
	hand.material = hand.material.duplicate()
	set_source_time(0.0)

func point(value) -> Vector2:
	return Vector2(value[0],value[1])

func source_grip(index: float) -> Vector2:
	var frames = source_data.clips[source_side].frames
	index = clampf(index,0,frames.size()-1)
	var a = int(floor(index))
	return point(frames[a].grip).lerp(point(frames[mini(a+1,frames.size()-1)].grip),index-a)

func recorded_offset(index: float, reference: float) -> Vector2:
	return source_grip(index)-source_grip(reference)

func set_source_time(seconds: float):
	if source_data.is_empty():
		return
	var clip = source_data.clips[source_side]
	var frames = clip.frames
	source_cursor = clampf(seconds*12.0,0,frames.size()-1)
	source_frame = int(floor(source_cursor))
	var next = mini(source_frame+1,frames.size()-1)
	var weight = source_cursor-source_frame
	var a = frames[source_frame]
	var b = frames[next]
	var scale_factor = float(clip.scale)*hand_size
	var anchor_a = point(a.grip)
	var anchor_b = point(b.grip)
	var vertices = PackedVector2Array()
	var uv = PackedVector2Array()
	var cell = source_frame%12
	var offset = Vector2(cell%4*128,int(cell/4)*128)
	# Close the loop only after the recorded action has returned to rest.
	var settle = smoothstep(frames.size()-7.0,frames.size()-1.0,source_cursor)
	for i in range(64):
		var local_a = point(a.contour[i])-anchor_a
		var local_b = point(b.contour[i])-anchor_b
		var local_point = local_a.lerp(local_b,weight)
		var resting = point(frames[0].contour[i])-point(frames[0].grip)
		vertices.append(local_point.lerp(resting,settle)*scale_factor)
		# Stabilize geometry only. UVs must follow the unsmoothed source
		# contour, otherwise moving fingers can sample nearby desk pixels.
		uv.append(point(a.raw_contour[i])-Vector2(a.crop[0],a.crop[1])+offset)
	hand.polygon = vertices
	hand.uv = uv
	hand.texture = textures[source_side][int(source_frame/12)]
	hand.material.set_shader_parameter('skin_mid',float(a.skin_luma))
	$Graphic/Contour.points = vertices+PackedVector2Array([vertices[0]])
	var local_wrist = (point(a.wrist)-anchor_a).lerp(point(b.wrist)-anchor_b,weight)
	local_wrist = local_wrist.lerp(point(frames[0].wrist)-point(frames[0].grip),settle)
	wrist_center = local_wrist*scale_factor
	var palm = (point(a.palm)-anchor_a).lerp(point(b.palm)-anchor_b,weight)*scale_factor
	# The clothing boundary is only a tracking landmark. Attach the bare
	# forearm to the actual stabilized skin contour, with a small overlap,
	# so dark cuff pixels cannot leave a gap between hand and forearm.
	var closest = vertices[0]
	var distance = INF
	for i in range(vertices.size()):
		var candidate = Geometry2D.get_closest_point_to_segment(wrist_center,vertices[i],vertices[(i+1)%vertices.size()])
		var candidate_distance = candidate.distance_squared_to(wrist_center)
		if candidate_distance < distance:
			distance = candidate_distance
			closest = candidate
	wrist_center = closest.move_toward(palm,10.0)
	wrist_normal = (palm-wrist_center).orthogonal().normalized()

func pose(grip: Vector2, elbow: Vector2):
	position = grip
	rotation = 0.0
	var a = wrist_center+wrist_normal*22.0
	var b = wrist_center-wrist_normal*22.0
	var end = to_local(elbow)
	var normal = (end-wrist_center).orthogonal().normalized()*35
	if (a-b).dot(normal) < 0:
		normal = -normal
	$Forearm.polygon = PackedVector2Array([a,b,end-normal,end+normal])
	$ArmOutline.points = PackedVector2Array([b,end-normal,end+normal,a])
	$ArmShadow.polygon = PackedVector2Array([a,a.lerp(b,0.2),(end+normal).lerp(end-normal,0.2),end+normal])

