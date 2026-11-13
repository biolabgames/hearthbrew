extends Node2D
## Stable matching empty hands, with textured forearms connected to elbows.
@export var mirrored = false
@export var hand_size = 1.25
@onready var graphic = $Graphic
@onready var arm: Polygon2D = $Forearm

func pose(grip: Vector2, angle: float, elbow: Vector2):
	position = grip
	rotation = angle
	var direction = -1.0 if mirrored else 1.0
	graphic.scale = Vector2(direction,1)*hand_size
	var a = Vector2(-72*direction,58)*hand_size
	var b = Vector2(-41*direction,73)*hand_size
	var end = to_local(elbow)
	var normal = (end-(a+b)*0.5).orthogonal().normalized()*35
	if (a-b).dot(normal) < 0:
		normal = -normal
	arm.polygon = PackedVector2Array([a,b,end-normal,end+normal])
	$ArmOutline.points = PackedVector2Array([b,end-normal,end+normal,a])
	$ArmShadow.polygon = PackedVector2Array([a,a.lerp(b,0.18),(end+normal).lerp(end-normal,0.18),end+normal])

