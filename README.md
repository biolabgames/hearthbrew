# Hearthbrew — The Mixing Room

A playable **Godot 4.7** spin-off of Potion Side Effects. A small woodland apothecary where
neighbours arrive with magical ailments and you mix their remedies by hand.

## Play

In `C:\Users\biola\Dev\Godot 4.7\Steam games\hearthbrew`, double-click **Play.cmd**.
The launcher uses the Godot executable already installed two folders above it.

Alternatively, import **project.godot** in Godot 4.7 and press **F5**. This also works after
moving the project elsewhere. It uses the Compatibility renderer and needs no plugins or API key.

## Your first remedy

1. Poppy has a fever. Pin **Dewdrop draught** in the journal.
2. Select **Moonmilk**, then **Dew**, in that order.
3. Click **Brew mixture**. The left hand pours each ingredient, then the right hand stirs.
4. Watch the liquid take on each ingredient's colour, then become the finished draught.
5. Click **Serve Poppy**. When every symptom is gone, welcome the next neighbour.

The next patient needs those same two ingredients in **reverse order**. Later remedies need
three or four ingredients, and later patients need multiple treatments.

## Features in this build

- Six ingredients and eight exact, ordered recipes containing two to four pours.
- Six distinct human patients facing the player across the counter, with blinking, smiles and frowns.
- One fixed blank-face body per person, with separate facial overlays to prevent body flicker.
- Treatment-driven expressions and a right-hand clipboard for the chart, recipe and mixing order.
- Painted left and right hands with connected forearms, based on the two supplied recordings.
- 72 pouring frames and 84 stirring frames at 12 fps, played from native-sized transparent sheets.
- Continuous colour blending, cauldron bubbles, steam and cure celebrations.
- A painted apothecary interior, warm paper interface and generated chime effects.
- A recipe journal, editable order slots, hints, patient charts and ingredient allergies.
- Unknown mixtures cause recoverable hiccups; unsuitable known remedies do not cure unrelated symptoms.
- One conditional side effect: Dewdrop draught gives a floating patient shivers.
- Three stars for using the minimum number of batches, two for one extra, one for more attempts.
- Pause, doubled animation speed, sound toggle, discard and restart controls.

Mixing is automatic after selection. This build does not yet require mouse gestures for pouring
or stirring. Both arms use complete, fixed-size reference-based sprite frames;
shelf bottles and effects are drawn in Godot; patients and the interior use generated painted artwork.
This is an art-directed prototype, with no saved progression,
Steam integration or standalone exported executable yet.

## Controls

| Input | Action |
| --- | --- |
| Click a journal entry | Pin its ingredients, order, effect and notes |
| Click a bottle / keys 1–6 | Add an ingredient to the order |
| Click an order slot | Remove that ingredient and close the gap |
| Backspace | Remove the final queued ingredient |
| Enter | Brew the selected order, or serve the finished result |
| P | Pause/resume the mixing animation |
| M | Toggle sound |
| 1x / 2x speed | Change animation speed |
| Finish animation | Immediately complete the current animation, keeping the same recipe result |

You must serve or discard a finished brew before editing the next one. You cannot alter a batch
while it is being mixed. The hands timeline pauses when the window loses focus. Ingredients are
unlimited, so you can experiment and recover from mistakes without a game-over screen.

## Source

- `brewing.gd`: ingredients, recipes, patient data and treatment rules.
- `main.gd`: game state, ordered selection, animation timeline and layout.
- `art.gd`: illustrated vessels, portraits, effects, sound and sprite-player setup.
- `rotoscope_player.gd`: whole-frame atlas playback; no limb stretching or rotation.
- `patient_sprites.gd`: static bodies, face-only expression overlays and independently timed blinks.
- `assets/patients/layered`: active blank-face bodies, facial atlases, masks and version 2 manifest.
- `assets/patients`: six people, their original sheets, frame manifest and exact prompts.
- `assets/rotoscope`: current frame sheets, source redraws, provenance manifest and prompts.
- `assets/apothecary.png`: the generated background painting, stored locally in this project.
- `verify.gd`: rule, UI, progression, animation and recovery checks.
- `previews/rotoscope`: current rendered motion preview. Older previews show the retired rig.
- `ART_DIRECTION.md`: the visual brief, exact image-generation prompt and asset provenance.
- `PATIENT_ART.md`: character designs, reactions, counter framing and preview details.
- `VALIDATION.md`: checks performed and practical limits.

The original Potion Side Effects and the other four prototypes remain separate projects.

## Current animation limits

This is an AI-assisted painted draft based on `20261106_010812.mp4` and `20261106_010936.mp4`,
not precision manual rotoscoping. It follows the recorded left-hand pour gesture and right-hand
stirring action. Individual drawings still vary between frames. The pouring prop has a lid, which
remains in this draft. The second clip's thin utensil keeps its recorded shape with a wood finish.
The complete stirring action plays after all pours; serving animation still needs footage.
The previous stretching pose rig is no longer loaded. See `ROTOSCOPE_HANDS.md` for provenance.

