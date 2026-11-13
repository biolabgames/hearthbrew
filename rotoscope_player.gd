extends RefCounted
## Timeline queries for the native SpriteFrames resource. AnimatedSprite2D
## nodes display the frames; JSON is retained for provenance only.
const FRAMES = preload('res://resources/hands/recorded_hands.tres')
var clips = {}
var errors: Array[String] = []
var provenance = ''

func load_manifest():
	clips.clear()
	errors.clear()
	provenance = FRAMES.get_meta('reference_footage','')
	for name in FRAMES.get_animation_names():
		var count = FRAMES.get_frame_count(name)
		if count == 0:
			errors.append(name+': missing animation frames.')
			continue
		clips[name] = {
			'count':count,'fps':FRAMES.get_animation_speed(name),
			'loop':FRAMES.get_animation_loop(name),
			'size':FRAMES.get_frame_texture(name,0).get_size(),
			'events':FRAMES.get_meta(name+'_events',{}),
			'source':FRAMES.get_meta(name+'_source','')
		}
	return errors.is_empty()

func frame_index(name: String, seconds: float):
	if not clips.has(name):
		return -1
	var clip = clips[name]
	var index = maxi(0,int(floor(maxf(0,seconds)*clip.fps)))
	return index%clip.count if clip.loop else mini(index,clip.count-1)

func source_rect(name: String, seconds: float):
	var index = frame_index(name,seconds)
	return FRAMES.get_frame_texture(name,index).region if index >= 0 else Rect2()

func event_frame(name: String, event: String):
	return int(clips[name].events.get(event,-1)) if clips.has(name) else -1
