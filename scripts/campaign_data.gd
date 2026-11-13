extends RefCounted
## Authored appointments; actor IDs reference the existing, preserved village cast.
const B = preload('res://brewing.gd')
const CHAPTERS = [
	['A light in the window', 'Your first week begins. Listen, examine, and leave each neighbour better than you found them.', 'Poppy brings a letter: pale flowers have appeared beside the old mill. Nobody remembers planting them.'],
	['Strange little echoes', 'New preparations arrive from the herbalists. Separate blends must be bottled before combining.', 'Hazel finds silver dust in the bees\' pollen baskets. Cedar heard the mill bell ringing without a rope.'],
	['The same silver dust', 'The lantern and sample tray can distinguish ailments that sound alike. Check the whole picture.', 'Otis brings two water samples. Both are clear. Fern\'s scarf carries the same silver dust as Hazel\'s hive.'],
	['A pattern in the village', 'Several ailments may share one exposure. Record what you find before reaching for a remedy.', 'Moss identifies the dust as moonflower pollen. It glows under the revealing lantern; ordinary well sediment does not.'],
	['Familiar faces', 'Neighbours return with new evidence. A pulse charm now reveals the strength their magic can tolerate.', 'Poppy\'s delivery route, Pip\'s flour cart and Juniper\'s lessons all pass the mill garden. Indoor neighbours remain well.'],
	['Following the wind', 'Treat the person in front of you, even when you recognise the pattern. Their tolerance can change.', 'Cedar\'s bell log matches the evening gusts. The bell scatters pollen from the moonflowers; it is a carrier, not the source.'],
	['The root of the trouble', 'Use every tool and choose safe alternatives. A convincing explanation must fit all the evidence.', 'Moss finds roots wrapped around an old growth charm. The charm feeds the moonflowers. Garden hush can quiet the roots safely.'],
	['A quieter tomorrow', 'Help the last neighbours, then use the evidence to resolve the village mystery.', 'The mill garden is quiet. The neighbours bring supper, and the clinic window stays bright for anyone who needs it.']
]
## Each row: actor, symptom mask, preferred safe route, personal account.
const RETURNS = [
	[0,129,[8,16],'The letters near the mill make my eyelids heavy. By noon my cheeks burn too.'],
	[1,258,[17,1],'I took flour past the mill. The kitchen tilts even when I stand still, and I cannot get warm.'],
	[2,516,[18,2],'My feet drift again, but this time a peppery sneeze singed my spellbook.'],
	[3,72,[11,14],'Stone knuckles and flowers again. These roots seem buried deeper than before. Remember my Ember allergy.'],
	[4,2064,[20,12],'People lose sight of me between the shelves. Only my fingers leave a light on the books. The old cordial no longer holds my outline.'],
	[6,640,[16,18],'The hive is better, but I cleaned its dusty roof. Now I yawn and sneeze bright flecks.'],
	[7,260,[10,17],'The ferry feels unsteady on dry land. My boots will not quite touch the jetty. Honey has started making me itch.'],
	[8,513,[8,18],'I shook out the silver scarf. My cheeks grew hot and my sneezes burned tiny holes in it.'],
	[9,1056,[19,13],'I stopped ringing the bell, yet my words still return with bubbles between them. Quiet kettle only helped for a moment.'],
	[10,2304,[17,20],'I mapped the wind around the mill. Now the ink swims and my fingers light the page.'],
	[11,131,[16,15],'Warm face, icy hands, heavy eyes. All three began after I swept the mill steps. A simple temperature remedy has not held.'],
	[12,266,[17,9,11],'The room turns, I shiver, and my fingers are too stiff to cut glass.'],
	[13,580,[18,2,6],'The mill path lifted my boots. Then came sparks and little flowers in my cuffs.'],
	[14,1058,[19,1,5],'Our rehearsal beside the mill ended in shivers, bubbles and a chorus of my own voice.'],
	[15,2112,[20,6],'I repaired the mill bell. Glowing fingers are useful; the vines on my sleeves are less so.'],
	[16,641,[16,18,8],'I cooked for the helpers. After opening the mill window I grew sleepy, hot and sneezy.'],
	[17,2308,[2,17,20],'My puppets stayed grounded. I float, the floor rolls, and my hands glow like stage lights.'],
	[18,1033,[3,19,8],'The orchard breeze carried dust. My skin hardened, my voice doubled and my cheeks warmed.'],
	[19,2240,[16,20,6],'I found the growth charm under the flowers. Bringing it out left me sleepy, luminous and blooming.'],
	[0,2240,[16,20,14],'Everyone has sent a thank-you letter. I carried the root sample here; now my eyes droop, my hands shine and flowers follow me. Please use Garden hush on the enchanted roots as well.']
]

const FIRST_ACCOUNTS = [
	'Seventeen letters before breakfast, and now my cheeks feel like tiny ovens. Even the cool air by your door has not helped. I had to stop halfway up the lane to rest; could you see what is making me so warm?',
	'I fell asleep in the ice cellar while the dough was rising. I have been back beside the oven for an hour, but my hands are still icy and my teeth keep chattering. It is rather difficult to knead bread like this.',
	'My levitation lesson went splendidly until I tried to land. My boots keep drifting above the path, and every time I ask for help a bubble escapes instead. I tied myself to the gate while I waited for you to open.',
	'A garden charm left my knuckles stiff and grey, and little daisies keep pushing out of my sleeves. I cannot bend my fingers enough to hold the shears. Please remember that Ember nectar makes me itch.',
	'The library readers keep walking straight past me, as though I am not there. Then a loud bubble gives me away at the worst possible moment. I would like my outline back, and a little peace for the quiet section.',
	'That weather spell tasted terrible. My cheeks are burning, my fingers feel frozen, and my boots will not stay on the floor. I tried sitting down, but the chair and I seem to disagree about where the ground is.',
	'My bees found a moonflower yesterday. Since checking the hive I can barely keep my eyes open, even after a full night in bed. I keep losing my place while counting the frames, and I nearly nodded off on the walk here.',
	'The pond keeps turning cartwheels even when I stand safely on the bank. I have to hold the ferry rail to feel steady, and looking down at the water makes it worse. Could you help the shore stay still for a while?',
	'Every sneeze sends a bright little spark through my pincushion. My nose prickles just before it happens, and I have already singed two hems this morning. I brought a damp cloth so your curtains would be safe.',
	'I swallowed a bell charm on my night round, which was a very poor idea. Each word comes back to me several times after I stop speaking. I tried whispering, but the echoes woke the whole watch house anyway.',
	'My hands have been shining since I opened an enchanted map. Even with the lamps out, there is a golden light between my fingers. It washes out the fine lines on the parchment, and gloves do not seem to hide it.',
	'A sleepy spell drifted through the mill this morning. My forehead feels hot, but my eyelids are so heavy that I keep forgetting what I was saying. I left the machinery stopped; I could not trust myself beside it.',
	'The glass cooled too quickly, and now I cannot get warm either. My hands tremble even in my thickest gloves, while the workshop seems to tilt whenever I look up. I had to leave the cutting tools alone.',
	'Those silver mushrooms made my feet drift off the path. Their peppery cousins set my nose tingling, and now the sneezes throw sparks as well. I have kept the basket outside; I do not want anyone else trying them.',
	'I meant to teach the choir a round. Now my voice keeps answering itself, with bubbles interrupting the notes. Even when I take a quiet breath and start again, the little chorus follows me. Rehearsal has become rather confusing.',
	'An invisibility gear slipped while I was repairing a clock. My sleeves seem to disappear, but my fingers shine brightly enough to light the mechanism. People keep seeing the light and asking where the rest of me went.',
	'I added too much dream pepper to the soup. Since tasting it I keep nodding off, then waking with a sneeze full of sparks. I have put the pot aside and asked someone else to watch the stove until I feel steady again.',
	'My puppet’s spinning spell caught me instead. The floor seems to roll when I turn my head, and my hands glow through the puppet’s cloth sleeves. I cannot keep the strings straight long enough to finish the show.',
	'The singing pear tree left my skin stiff and stony. Now each word I speak comes back in a second voice, even when nobody is near me. I tried asking the tree to stop, but that only made a rather large duet.',
	'I tried a bedtime garden charm, and I suspect I mixed up a page. I can barely keep my eyes open, my fingers shine under the blankets, and new flowers keep growing from my sleeves. It has not been a restful night.'
]

const RETURN_DETAILS = [
	'I slept all night, so this feels different from an ordinary early start. The warmth and heavy eyes begin together after that part of my route.',
	'I have warmed myself by the oven, but the shaking will not settle. Even the tiles look as though they are sliding sideways.',
	'I can hold the drifting down with a rope, but the sparks come without warning. Both started after our lesson beside the mill.',
	'The new flowers return as soon as I brush them away. My fingers are stiff enough that I needed help fastening my coat.',
	'I can see the light from my fingers through a book, but the hand holding it fades at the edges. It makes shelving rather unsettling.',
	'I rested before coming, but my eyes still close by themselves. The sneezes leave warm specks on my apron, even away from the hive.',
	'Tying the ferry up did not stop the rolling feeling. I had to hold a fence on the way here to keep my boots near the ground.',
	'The warmth never quite leaves my face, and the prickling in my nose keeps returning. I have wrapped the scarf up rather than shake it again.',
	'Even speaking slowly leaves a second voice behind me. The bubbles interrupt my breath, so I have asked someone else to make tonight’s calls.',
	'I waited until I was off the ferry, but the swimming lines did not settle. Covering my hands dims the paper only a little.',
	'I keep drifting off in my chair, then waking because I feel too hot and too cold at once. I have left the mill closed for the morning.',
	'My fingertips barely bend around a cup. When I try to stand, the room tilts again, and another shiver runs right through my coat.',
	'I used a walking stick to keep myself near the path. By the time I reached the village, the flowers were tangled around it and my sneezes had singed a leaf.',
	'We moved the rehearsal indoors, but I still cannot get warm. Each attempt at a note comes back to me with a bubble in the middle.',
	'The light shines even when I put my tools down. The little shoots keep catching in the hinges, and pulling them away only seems to encourage them.',
	'I stepped outside for fresh air, but my cheeks stayed warm. Then I nearly fell asleep standing up, just before another shower of sparks.',
	'I have tied the puppet strings away for now. Even without the spinning spell running, my feet drift and I cannot quite trust the floor.',
	'I cannot close my fingers around the pruning knife. The warmth in my face and that answering voice have stayed with me all the way from the orchard.',
	'I put the charm in a covered basket. Even after washing, I could not dim my fingers, keep my eyes open, or stop the shoots curling from my cuffs.',
	'I have kept the roots wrapped up on the walk here. I would like to deliver the last letters without nodding off or leaving petals through everybody’s doorway.'
]

static func detailed_story(appointment):
	var actor = int(appointment.actor)
	var original = B.PATIENTS[actor]
	if appointment.story == original.story:
		return FIRST_ACCOUNTS[actor]
	for i in range(RETURNS.size()):
		if int(RETURNS[i][0]) == actor and int(RETURNS[i][1]) == int(appointment.mask):
			return str(appointment.story)+' '+RETURN_DETAILS[i]
	return str(appointment.story)

static func appointments():
	var result = []
	var initial_routes = [[0],[1],[2,5],[3,6],[4,5],[2,7]]
	for i in range(B.PATIENTS.size()):
		var p = B.PATIENTS[i]
		result.append({'actor':i,'mask':int(p.mask),'route':initial_routes[i] if i < 6 else p.treatments.duplicate(),'story':p.story,'strength':0})
	for i in range(RETURNS.size()):
		var row = RETURNS[i]
		result.append({'actor':row[0],'mask':row[1],'route':row[2].duplicate(),'story':row[3],'strength':1 if i % 2 == 0 else 2})
	# Late cases introduce deep-set magic: the sample tray explains when a
	# compound alternative is necessary, rather than hiding an arbitrary rule.
	for pair in [[23,64],[24,16],[28,32],[30,3],[39,64]]:
		result[pair[0]].resistant = pair[1]
	result[26].allergy = 5
	return result

## Tool groups include negative findings, so every hypothesis is testable.
const TOOLS = ['Temperature charm','Revealing lantern','Listen & balance','Sample tray','Pulse charm']
const FINDINGS = [
	[1,0,'Cheeks warm the charm red.','The temperature charm stays clear.'],
	[2,0,'Cold ripples cross the charm.','No cold ripples appear.'],
	[4,2,'Boots lift clear of the floor on the balance mat.','Both boots stay grounded.'],
	[8,1,'The lantern catches a stony grain across the skin.','Skin reflects softly, without stone grain.'],
	[16,1,'The lantern reveals gaps in the patient\'s outline.','The outline is continuous.'],
	[32,2,'Bubbles interrupt a held note.','A held note stays free of bubbles.'],
	[64,3,'Fresh petals unfurl in the cuff sample.','No fresh petals grow in the sample.'],
	[128,3,'Dream motes settle on the sample tray.','No dream motes settle.'],
	[256,2,'The balance needle spins while both eyes follow it.','The balance needle stays steady.'],
	[512,3,'A sneeze leaves bright embers on the tray.','The sneeze sample contains no embers.'],
	[1024,2,'One spoken word returns in three distinct echoes.','Each word sounds once.'],
	[2048,1,'The hands keep shining inside the shaded lantern box.','The shaded hands emit no light.']
]
const STRENGTHS = ['Standard','Gentle','Concentrated']
const PULSE = ['The charm beats evenly: use STANDARD preparations.','The charm flickers faintly: use GENTLE preparations.','The charm surges brightly: use CONCENTRATED preparations.']
