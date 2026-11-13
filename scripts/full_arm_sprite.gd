extends AnimatedSprite2D
## Render every pixel of the complete generated frame. A lower-arm mesh extension
## keeps the painted hand at a stable size while its forearm reaches the screen edge.
func extend_forearm(anchor: Vector2, root_world: Vector2, right: bool):
	self_modulate = Color(1,1,1,0)
	var atlas: AtlasTexture = sprite_frames.get_frame_texture(animation,frame)
	var mesh: Polygon2D = $FullArm
	mesh.texture = atlas.atlas
	var root_local = Vector2(470 if right else 60,278)
	var displacement = to_local(root_world)-root_local
	var wrist_y = minf(anchor.y+65.0,245.0)
	var vertices = PackedVector2Array()
	var texcoords = PackedVector2Array()
	var rows = [0.0,wrist_y,lerpf(wrist_y,288.0,0.5),288.0]
	for y in rows:
		var blend = clampf((y-wrist_y)/(288.0-wrist_y),0.0,1.0)
		for x in [0.0,512.0]:
			vertices.append(Vector2(x,y)+displacement*blend)
			texcoords.append(atlas.region.position+Vector2(x,y))
	mesh.polygon = vertices
	mesh.uv = texcoords
	mesh.polygons = [PackedInt32Array([0,1,3,2]),PackedInt32Array([2,3,5,4]),PackedInt32Array([4,5,7,6])]
