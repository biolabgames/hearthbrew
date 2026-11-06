extends RefCounted

# The atlas contains four distinct hand poses and a sleeve for each arm.
# Pivots are measured in the original 512 px cell. Grips are anchored to the
# actual prop contact, rather than rotating a hand somewhere near the prop.
const ATLAS_PATH = 'res://assets/hands-painted-v2.png'
const POSES = [
	{'cell':Vector2i(0,0),'anchor':Vector2(234,255),'wrist':Vector2(209,330),'scale':0.32},
	{'cell':Vector2i(1,0),'anchor':Vector2(300,180),'wrist':Vector2(188,330),'scale':0.34},
	{'cell':Vector2i(2,0),'anchor':Vector2(250,255),'wrist':Vector2(317,330),'scale':0.32},
	{'cell':Vector2i(0,1),'anchor':Vector2(161,90),'wrist':Vector2(314,330),'scale':0.29}
]
var texture: ImageTexture
var source_size = Vector2i.ZERO
var alpha_verified = false

func _init():
	var image = Image.load_from_file(ProjectSettings.globalize_path(ATLAS_PATH))
	if image and not image.is_empty():
		source_size = image.get_size()
		alpha_verified = image.detect_alpha() != Image.ALPHA_NONE and image.get_pixel(0,0).a < 0.01
		texture = ImageTexture.create_from_image(image)

func pose(center: Vector2, left: bool, holding: bool, angle: float, clock: float, active: bool):
	var index = (1 if holding else 0) if left else (3 if holding else 2)
	var data = POSES[index]
	# Slight pressure changes and breathing, never a rigid stationary stamp.
	var pressure = sin(clock*3.1+(0 if left else 1.4))
	var scale_factor = float(data.scale)
	var scale = Vector2(scale_factor*(1+pressure*0.006),scale_factor*(1-pressure*0.004))
	var transform = Transform2D(angle,Vector2.ZERO).scaled_local(scale)
	transform.origin = center
	return {
		'index':index,'left':left,'holding':holding,'center':center,
		'angle':angle,'anchor':data.anchor,'transform':transform,
		'wrist':transform*(data.wrist-data.anchor),
		'pressure':pressure,'active':active,'clock':clock
	}

func sleeve_transform(root_pos: Vector2, frame):
	# Skin overlaps underneath the hand. Keeping the generated cuff out of
	# the hand crop avoids doubled cuffs or a hard paper-cut wrist seam.
	var wrist = frame.wrist+(frame.center-frame.wrist).normalized()*13.0
	var delta = root_pos-wrist
	var angle = delta.angle()-PI/2.0
	# Painted linen tapers to a 33 px wrist. Only the sleeve's longitudinal
	# dimension changes with reach; hand anatomy retains its proportions.
	var scale = Vector2(0.30,delta.length()/465.0)
	return Transform2D(angle,Vector2.ZERO).scaled_local(scale).translated(wrist)

func draw_arm(canvas: CanvasItem, root_pos: Vector2, frame):
	if texture == null:
		return
	var transform = sleeve_transform(root_pos,frame)
	canvas.draw_set_transform_matrix(transform)
	var cell = Vector2(1 if frame.left else 2,1)
	var source = Rect2(cell*Vector2(source_size)/Vector2(3,2),Vector2(source_size)/Vector2(3,2))
	canvas.draw_texture_rect_region(texture,Rect2(-252,-24,512,512),source)
	canvas.draw_set_transform(Vector2.ZERO)

func draw_hand(canvas: CanvasItem, frame, reflected_color: Color):
	if texture == null:
		return
	var data = POSES[frame.index]
	var cell_size = Vector2(source_size)/Vector2(3,2)
	var source = Rect2(Vector2(data.cell)*cell_size,cell_size*Vector2(1,330.0/512.0))
	canvas.draw_set_transform_matrix(frame.transform)
	# A whisper of coloured bounce light from the luminous liquid; the
	# original warm window lighting and paper grain remain visible.
	var bounce = Color.WHITE.lerp(reflected_color.lightened(0.45),0.055 if frame.active else 0.018)
	canvas.draw_texture_rect_region(texture,Rect2(-data.anchor,Vector2(512,330)),source,bounce)
	canvas.draw_set_transform(Vector2.ZERO)

func valid():
	return texture != null and source_size.x >= 1200 and source_size.y >= 800 and alpha_verified
