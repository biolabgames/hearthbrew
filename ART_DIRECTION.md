<!-- Current prop-free full-arm implementation: HANDS_ANIMATION.md. -->
# Active generated full-arm renders — 10 November 2026

The complete generated hands and forearms are restored together. See HANDS_ANIMATION.md for playback and separate prop interactions.

The active animation has been redrawn with bare forearms and simplified hand detail.
Baggy sleeves and cuffs have been removed across pouring, stirring and idle frames.
See ROTOSCOPE_HANDS.md and assets/rotoscope/bare-arm-sources/prompt.json.

The current build also includes six illustrated human patients across the counter, each with
nine expression/blink frames. Patient information and recipe controls are on the right-hand
clipboard. See PATIENT_ART.md and assets/patients/prompts.json for current character artwork.

The active animation uses the supplied video. See ROTOSCOPE_HANDS.md and assets/rotoscope/prompts.json. The painted V2 rig described below is historical and is no longer loaded by the game.

# Art direction and asset provenance

User brief: a more cartoonish Studio Ghibli-inspired look, with a visual first-person potion
mixing sequence, two hands and arms, and liquids changing colour as they combine.

This prototype uses warm hand-painted countryside fantasy, rounded cartoon forms, ink outlines,
honey-coloured wood, sage sleeves, terracotta, cream paper and jewel-coloured glass.

The background at `assets/apothecary.png` was generated with the **built-in imagegen tool**.
The selected image was copied into this project so the game does not depend on an external image
location or any network connection. No CLI/API fallback or API key was used.

The hands and arms now use a second generated asset, `assets/hands-painted-v2.png`, created
with the built-in imagegen tool using the background as a style reference. It contains four hand
poses and two matching linen sleeves on a transparent atlas. Fingernails, knuckle and palm
creases, freckles, veins, cloth grain, seams and cuff stitching are painted into this asset.

Godot animates measured grip pivots, wrist movement, sleeve reach, breathing and subtle pressure
changes. The bottle and spoon sit at the actual grasp points. Spoon dipping and lifting follow
continuous paths, and the pour stream eases in and out. This remains live game animation rather
than a pre-rendered movie; the number, order and colours of pours come from the chosen batch.

## Exact generation prompt

> Use case: stylized-concept. Asset type: background artwork for a playable first-person 2D Godot potion mixing game, landscape 16:10 composition. Create a cozy woodland apothecary interior in the style of Studio Ghibli but more cartoonish: expressive rounded shapes, charming slightly wonky hand-drawn ink contours, hand-painted watercolor and gouache textures, warm honey sunlight, sage-green timber, buttercream walls, terracotta, moss and peach, jewel-coloured glass. First-person view across an empty wide honey-wood mixing counter occupying the lower 45 percent of the image, its center completely empty to overlay animated game hands and a cauldron. Background top half has shelves of tiny potion bottles and hanging herbs, on left a sunlit arched window overlooking a lush little garden, right softly cluttered cabinets and dried flowers. A gentle inviting magical countryside atmosphere. Detailed at edges, calm low contrast in center and table. No people, no hands, no arms, no cauldron, no lettering, no text, no UI, no logo or watermark. Flat illustrated game background, not a screenshot, not photorealistic. The game will add its own moving hands, patients and vessels over this background.

## Asset paths

Installed game asset:
`C:\Users\biola\Dev\Godot 4.7\Steam games\hearthbrew\assets\apothecary.png`

Deliverable copy:
`C:\Users\biola\Documents\Codex\2026-11-05\i-n\outputs\Hearthbrew\assets\apothecary.png`

The exact hand-atlas prompt and local asset path are recorded in `HANDS_ART.md`.

