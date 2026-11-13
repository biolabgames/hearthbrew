extends Node2D
## Updates existing scene nodes from the gameplay timeline. Layout and artwork
## belong to the .tscn scenes; no visual nodes are constructed at runtime.

const LEFT_REST = Vector2(580,770)
const RIGHT_REST = Vector2(965,770)
const SPOON_REST = Vector2(1040,640)
@onready var left_hand = $LeftHandPlacement/LeftHand
@onready var right_hand = $RightHandPlacement/RightHand
@onready var held_bottle: Sprite2D = $LeftHandPlacement/LeftHand/CarriedProp/HeldBottle
@onready var held_spoon = $RightHandPlacement/RightHand/CarriedProp/HeldSpoon
var hand_phase = 'idle'
var held_table_slot = -1

func ease_between(seconds: float, start: float, end: float) -> float:
	var t = clampf((seconds-start)/(end-start),0.0,1.0)
	return t*t*t*(t*(t*6.0-15.0)+10.0)

func travel(a: Vector2, b: Vector2, seconds: float, start: float, end: float, lift: float = 0.0) -> Vector2:
	var t = ease_between(seconds,start,end)
	return a.lerp(b,t)+Vector2(0,-sin(t*PI)*lift)

func set_hand(hand: AnimatedSprite2D, clip: String, seconds: float):
	hand.animation = clip
	hand.frame = clampi(int(maxf(seconds,0.0)*12.0),0,hand.sprite_frames.get_frame_count(clip)-1)

func grip_anchor(hand: AnimatedSprite2D, right: bool) -> Vector2:
	var keys = [[0,180,125],[8,185,125],[11,215,125],[12,240,80],[23,270,75],[24,210,65],[35,225,65],[36,250,65],[47,255,80],[48,210,95],[56,195,125],[59,180,125],[60,180,125],[71,180,125]]
	if right:
		keys = [[0,280,155],[8,250,170],[11,285,150],[12,340,165],[15,300,80],[23,220,100],[24,250,75],[35,220,100],[36,280,80],[47,270,95],[48,265,80],[59,175,85],[60,250,100],[71,270,190],[72,280,140],[83,240,145]]
	var frame = hand.frame if hand.animation in [&'pour',&'stir'] else 0
	for i in range(keys.size()-1):
		if frame <= keys[i+1][0]:
			var t = float(frame-keys[i][0])/float(keys[i+1][0]-keys[i][0])
			return Vector2(keys[i][1],keys[i][2]).lerp(Vector2(keys[i+1][1],keys[i+1][2]),t)
	return Vector2(keys[-1][1],keys[-1][2])

func place_full_arm(hand: AnimatedSprite2D, grip: Vector2, right: bool):
	var anchor = grip_anchor(hand,right)
	# Preserve hand size; extend only the lower part of the complete painted frame.
	var size = 0.8 if right else (1.0 if hand.animation == &'pour' else 1.3)
	hand.scale = Vector2.ONE*size
	hand.position = grip-anchor*size
	var root_point = Vector2(1080,930) if right else Vector2(clampf(grip.x-200,0,430),930)
	hand.extend_forearm(anchor,root_point,right)

func update_hands(game):
	game.sync_table_bottles()
	var pouring = game.is_pouring()
	var stirring = game.is_stirring()
	var seconds = fmod(game.animation_time,game.POUR_SECONDS) if pouring else 0.0
	set_hand(left_hand,'pour' if pouring else 'idle',seconds)
	set_hand(right_hand,'stir' if stirring else 'idle_right',game.animation_time-game.pour_duration() if stirring else 0.0)
	var left_grip = LEFT_REST
	var right_grip = RIGHT_REST
	held_bottle.visible = false
	held_spoon.visible = false
	held_table_slot = -1
	hand_phase = 'idle'
	$RestingSpoon.visible = true
	$RestingSpoon.position = SPOON_REST
	$PourStream.visible = false
	for slot in range(mini(game.table_stock.size(),game.supplies.table_buttons.size())):
		var bottle = game.supplies.table_buttons[slot].get_node('Bottle')
		bottle.visible = true
		game.supplies.tint_bottle(bottle,game.table_stock[slot],game.table_empty[slot])
	if pouring and not game.queue.is_empty():
		var ingredient = game.queue[mini(int(game.animation_time/game.POUR_SECONDS),game.queue.size()-1)]
		var slot = game.active_table_slot
		var pickup = Vector2(390,650)
		if slot >= 0 and slot < game.supplies.table_buttons.size():
			pickup = game.supplies.table_buttons[slot].get_node('Bottle').global_position
		var above_pot = Vector2(650,614)
		if seconds < 0.9:
			hand_phase = 'reach_bottle'
			left_grip = travel(LEFT_REST,pickup,seconds,0,0.9,16)
		elif seconds < 2.0:
			hand_phase = 'lift_bottle'
			left_grip = travel(pickup,above_pot,seconds,1.1,2.0,20)
		elif seconds < 4.3:
			hand_phase = 'pour_bottle'
			left_grip = above_pot
		elif seconds < 5.2:
			hand_phase = 'return_bottle'
			left_grip = travel(above_pot,pickup,seconds,4.3,5.2,20)
		else:
			hand_phase = 'release_bottle'
			left_grip = travel(pickup,LEFT_REST,seconds,5.2,6.0,16)
		held_bottle.visible = seconds >= 0.9 and seconds < 5.2
		var images = game.supplies.EMPTY_BOTTLE_IMAGES if seconds >= 3.8 else game.supplies.BOTTLE_IMAGES
		held_bottle.texture = images[ingredient if ingredient < images.size() else 0]
		held_bottle.modulate = Color.WHITE if ingredient < images.size() else Color(game.Brewing.INGREDIENTS[ingredient].color)
		if slot >= 0 and slot < game.supplies.table_buttons.size():
			var bottle = game.supplies.table_buttons[slot].get_node('Bottle')
			bottle.visible = not held_bottle.visible
			if held_bottle.visible:
				held_table_slot = slot
			elif seconds >= 5.2:
				game.supplies.tint_bottle(bottle,ingredient,true)
		$PourStream.visible = seconds >= 2.6 and seconds < 3.7
		$PourStream.default_color = Color(game.Brewing.INGREDIENTS[ingredient].color).lightened(0.12)
	if stirring:
		seconds = game.animation_time-game.pour_duration()
		var above_pot = Vector2(815,630)
		if seconds < 0.8:
			hand_phase = 'reach_spoon'
			right_grip = travel(RIGHT_REST,SPOON_REST,seconds,0,0.8,12)
		elif seconds < 1.5:
			hand_phase = 'lift_spoon'
			right_grip = travel(SPOON_REST,above_pot,seconds,0.8,1.5,20)
		elif seconds < 5.3:
			hand_phase = 'stir'
			var t = (seconds-1.5)/3.8
			right_grip = above_pot+Vector2(sin(t*TAU*2)*24,(1-cos(t*TAU*2))*7)*sin(t*PI)
		elif seconds < 6.2:
			hand_phase = 'return_spoon'
			right_grip = travel(above_pot,SPOON_REST,seconds,5.3,6.2,20)
		else:
			hand_phase = 'release_spoon'
			right_grip = travel(SPOON_REST,RIGHT_REST,seconds,6.2,7.0,12)
		held_spoon.visible = seconds >= 0.8 and seconds < 6.2
		$RestingSpoon.visible = not held_spoon.visible
	place_full_arm(left_hand,left_grip,false)
	place_full_arm(right_hand,right_grip,true)
	# Props are behind the intact painted fingers, at world size independent of arm scale.
	held_bottle.global_position = left_grip
	held_bottle.global_scale = Vector2.ONE*(102.4/held_bottle.texture.get_height()) if held_bottle.texture else Vector2.ONE
	held_bottle.global_rotation = 1.5*ease_between(seconds,2.0,2.6)*(1.0-ease_between(seconds,3.7,4.3)) if pouring else 0.0
	held_spoon.global_position = right_grip
	held_spoon.global_scale = Vector2.ONE
	held_spoon.global_rotation = 0.0
	if $PourStream.visible:
		var mouth = held_bottle.global_position+Vector2(0,-51).rotated(held_bottle.global_rotation)
		$PourStream.points = PackedVector2Array([mouth,mouth.lerp(Vector2(715,688),0.45)+Vector2(7,0),Vector2(715,688)])

func update_state(game):
	var color = game.current_liquid()
	var filled = game.mixing or game.pouring or game.poured_count > 0 or game.has_result or game.symptoms == 0
	$Cauldron/Liquid.color = color if filled else Color('#9a9d83')
	# Appearance is observable before any tests; recipe filtering still uses findings.
	$Patients.update_person(game.patient_index,game.clock,game.patient_expression(),game.symptoms)
	update_hands(game)
	for i in range(4):
		var bubble = $Cauldron/Effects.get_node('Bubble'+str(i))
		bubble.visible = filled
		bubble.position = Vector2(sin(game.clock*1.3+i*1.9)*76,cos(game.clock+i)*20)
		var radius = 3+fmod(game.clock*8+i*3,9)
		bubble.scale = Vector2.ONE*radius
		bubble.get_child(0).width = 1.5/radius
		bubble.modulate = color.lightened(0.32)
	for i in range(3):
		var steam = $Cauldron/Effects.get_node('Steam'+str(i))
		var height = fmod(game.clock*26+i*43,103)
		steam.visible = filled
		steam.position = Vector2(-44+i*44+sin(game.clock*2+i)*7,-height-35)
		steam.scale = Vector2(8+height*0.08,12+height*0.1)
		steam.modulate = Color('#f9efd9')
		steam.modulate.a = (1-height/103.0)*0.55
	for i in range(22):
		var flower = $Celebration.get_node('Flower'+str(i))
		flower.visible = game.celebration > 0
		var t = 3.0-game.celebration
		flower.position = Vector2(sin(i*2.31)*t*49,-cos(i*1.73)*t*43-t*27)
	$ShiftComplete.visible = game.shift_complete
	$ShiftComplete/Summary.text = 'Six neighbours helped. %d / 18 stars.' % game.clinic_stars
