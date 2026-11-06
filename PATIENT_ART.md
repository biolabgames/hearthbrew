# Six people at the counter

The active clinic patients are now human, standing on the far side of the counter and facing
the player. Their information, pinned recipe, ingredient order and brew controls are on the
right-hand clipboard. The journal and ingredient shelf remain on the left. Status messages
appear beneath the title, leaving the central face and torso clear of information panels.

## People

| Person | Design |
| --- | --- |
| Poppy | Auburn-haired postwoman, freckles, red scarf, navy courier waistcoat |
| Pip | Curly-haired young baker, spectacles, mustard scarf, cream apron |
| Juniper | Apprentice weather witch, dark curls, lavender ribbon and dress, knitted shawl |
| Bramble | Older gardener, silver hair and beard, ochre knitwear, green overalls |
| Mallow | Bob-haired librarian, gold spectacles, teal cardigan and flower brooch |
| Rowan | Carpenter, salt-and-pepper hair, moustache, rust shirt and ochre waistcoat |

Names and recipe requirements are retained. Jobs and dialogue now describe people instead
of the previous animal portraits. All six meet the player's gaze when their eyes are open.

## Animation

Each person has ONE static 512 x 384 body PNG, with an empty face, and a separate 384 x 384
atlas containing nine small 128 x 128 facial overlays. The active files and version 2 manifest
are in assets/patients/layered. The same body texture is drawn for every expression and blink.
Only the transparent facial-feature overlay changes, at a fixed offset of (200,96).
Rows are neutral, smile and frown. Columns are open, half-closed and closed eyes.
Eyes, brows, nose and mouth are superimposed on the blank skin. Glasses, facial hair, clothing,
hair outline, neck, arms and torso use one fixed base, with facial feature zones handling
the visible expression. There is no body-frame switching, stretching or pose interpolation.
The original nine whole-bust frames are retained as source art and are no longer animated.

Blink intervals range from 4.7 to 5.52 seconds and are staggered per person. A blink closes
through a half-lid frame, holds shut briefly, and opens through a half-lid frame.
Patients arrive concerned, watch calmly while the player mixes, and occasionally vary their
expression. They smile hopefully at a finished remedy, smile after helpful treatment, and
frown after a mistake. A fully cured patient keeps smiling until the next neighbour arrives.
Magical floating, invisibility, stone tint, hiccup bubbles and flowers remain visible where relevant.

## Assets and generation

The built-in image_gen tool generated the original character art and edited the blank-face
skin. No CLI/API fallback or API key was used. Original art prompts are in
assets/patients/prompts.json; the blank-face edit prompt is in assets/patients/layered/prompts.json.
Layer assembly preserves the original neutral body pixels outside tightly limited facial
feature zones. Existing generated expressions are cropped into face-only overlays with soft
alpha edges. The blank-face skin comes from the selected image edit; bodies are not redrawn.
Each body and face has its own saved asset, with hashes and feature masks recorded beside them.
work/patient-layers/build_layers.py reproduces assembly. Original sheets remain as provenance.

This is generated game artwork, not filmed rotoscoping. The existing reference-based hand
sprites remain separate. Facial features vary with expression; the body is identical across them.

## Validation and previews

verify.gd covers patient identity, atlas loading, native dimensions, blink progression,
blinking while smiling/frowning, treatment reactions, and keeping the face/body clear of UI.
Existing recipes, controls, patient progression and hand-animation tests also pass.

capture_layer_proof.gd rendered six blank bases and all 54 facial states using Godot OpenGL.
work/patient-layers/check_render_proof.py compared the actual pixels: ZERO changed pixels
outside the face overlay area. The result is recorded in work/patient-layers/render-proof.json.
previews/patient-layers contains the current blank-body contact sheet and six-second game preview.

previews/patients contains the earlier whole-bust previews, kept as historical references.
The preview deliberately cycles concerned, neutral and smiling expressions for each person.
Visibility, stone and levitation symptoms are cleared for the showcase so the designs can be
inspected; remaining symptoms and recorded hand movements are rendered by the game scene.
Normal play uses the treatment-driven reaction logic and each patient's complete starting symptoms.
