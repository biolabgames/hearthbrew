# Painted hands — version 2

The hand and sleeve atlas was made with the built-in **imagegen** tool, using
`assets/apothecary.png` as a style and palette reference. No API or CLI fallback was used.

Saved asset: `C:\Users\biola\Dev\Godot 4.7\Steam games\hearthbrew\assets\hands-painted-v2.png`.

This is a 1536 x 1024 PNG with genuine alpha transparency, split into six 512 px cells.
Its RGB preview may display background colours behind the sprites; those pixels are transparent
when rendered in Godot. The game loads the asset directly and needs no online service.

## Exact generation prompt

Use case: stylized-concept. Create a production-ready TRANSPARENT sprite atlas for the first-person hands and arms in a cozy hand-painted potion-mixing game. The attached apothecary background is STYLE AND PALETTE REFERENCE ONLY. Match its delicate brown ink contour, watercolor/gouache washes, paper grain, soft warm sunlight from upper-left, sage green linen, cream cuffs, and believable but friendly cartoon anatomy. The hand detail should be substantially more human than a mitten: exactly five anatomically plausible fingers, unequal finger lengths, tapered fingertips, subtle oval fingernails, delicate cuticles, knuckle folds, palm creases, thumb mound, warm rose fingertips, faint freckles, gentle blue wrist veins. Same adult artisan's light-medium warm tan skin on all hands, no jewelry. Not photorealistic, not flat vector art.

EXACT LAYOUT: a 1536x1024 landscape sheet, 3 equal columns and 2 equal rows, SIX SEPARATE ISOLATED ASSETS, each centered in its own cell with at least 45 pixels of transparent margin, no asset touches any other cell. No labels or grid lines. ALL hands upright, fingertips at top and wrist at bottom. TOP LEFT: left hand relaxed, viewed from its back at a three-quarter first-person angle, four softly bent fingers and thumb at the right. TOP MIDDLE: left hand curled naturally around an invisible small flask, showing the backs and nails of four curled fingers and a clearly opposed thumb; leave the central grip area clear for a separately drawn bottle; NO bottle in this asset. TOP RIGHT: right hand relaxed, viewed from its back at a three-quarter first-person angle, thumb at the left. BOTTOM LEFT: right hand delicately pinching an invisible slender stirring spoon between thumb and index finger, remaining three fingers curled naturally; NO spoon in this asset. BOTTOM MIDDLE: a long left forearm sleeve asset WITHOUT ANY HAND, upright wrist at top, upper arm cropped at bottom, tapering from broad bottom to narrower top, sage green woven linen with softly painted folds, turned-back cream cuff with stitching and two small seam stitches, a short bare wrist extending above the cuff; length approximately 420 pixels. BOTTOM RIGHT: matching right forearm sleeve asset WITHOUT ANY HAND, same clothing and proportions with slightly different natural folds, wrist at top and broad upper arm at bottom. The arm sprites will be articulated separately from the hands. Keep each asset entirely inside its cell. Genuine transparent alpha background, no checkerboard, no background scene, no shadows outside the silhouettes, no text, no objects in the hands.

## Integration

The four hand crops stop above the generated cuffs, avoiding doubled wrist cuffs. Separate sleeve
art overlaps underneath the hand, and each hand rotates around a measured bottle or spoon contact.
Anatomy keeps its proportions while sleeves adapt to the distance from the off-screen elbows.
The atlas's painted detail replaces the original ellipse-and-capsule hands.

All existing recipes and patient rules remain in `brewing.gd`.
