# Hearthbrew — The Mixing Room

A playable **Godot 4.7** spin-off of Potion Side Effects. A small woodland apothecary where
neighbours arrive with magical ailments and you mix their remedies by hand.

## Play

Double-click **Play.cmd** in this project folder.
The launcher uses the Godot executable already installed two folders above it.

Alternatively, import **project.godot** in Godot 4.7 and press **F5**. This also works after
moving the project elsewhere. It uses the Compatibility renderer and needs no plugins or API key.

## Your first remedy

The game now opens with **The Moonflower Letters**, an eight-day campaign with
40 appointments. Choose **Begin a new campaign** or **Continue saved campaign**.
Each appointment opens in the main room with the patient, visible symptom cues
and a fuller spoken account. Select **Diagnose patient** to open the diagnosis
panel. In the casebook, examine the patient, compare findings with the symptom guide,
select every supported symptom, and confirm your diagnosis before serving.
Return to the table to choose a remedy yourself. Later cases require the pulse
charm's preparation strength and compound remedies for deep-set enchantments.

**Free practice clinic** opens the original 20-patient shift with visible symptoms
and suggested recipes. The steps below describe its first remedy; in the campaign,
first examine Poppy with the temperature charm and confirm **Fever**.

1. Read Poppy's chart on the right: she has a fever.
2. Open the **recipe book**. Search for fever, or enable the current-symptoms filter.
3. Pin **Dewdrop draught** and read its ordered ingredients and notes.
4. Open the **pantry**, select **Moonmilk** and **Morning dew**, then click **Carry bottles to the table**.
5. Click Moonmilk on the table to pour it immediately. When the hand returns, click Dew to pour the next ingredient.
6. Click the **bowl** to mix, watch the right hand stir, then click **Serve Poppy**.

The pantry holds twelve ingredients: unlimited in practice, tracked bottle stock in campaigns.
Grow or collect materials and prepare bottles via **Garden & preparations → Recipe ingredients**.
Free **Request missing recipe supplies** refills in the pantry prevent shortages blocking treatment.
Your basket carries up to six bottles, including duplicates.
Click a shelf potion to collect another copy, or click a collected potion on the right to remove that copy;
the mixing flask takes two to four ordered pours. Each bottle becomes empty after its pour; duplicates
are separate bottles. Return empties to the pantry and collect fresh bottles for later treatments.
Each new patient starts with an empty table. Contents already poured stay in the kettle when their
empty bottles are returned. Escape closes the book or
pantry without applying uncarried basket changes.

The book contains twenty-one remedies for twelve symptoms, including alternative treatments for the original seven symptoms.
Search by recipe, symptom or ingredient, and check allergy and side-effect warnings before
choosing a treatment. Gathering bottles never fills the pouring order automatically.

## Features in this build

- A painted outdoor courtyard garden with two soil areas, stone paths and edging, ten growable herbs and a preparation bench. Examine the first three
  neighbours' samples, steep or grind their herbs, and add the prepared extract
  to a brewed remedy. Later finishes can treat a second symptom. Helping those
  neighbours opens two more planting patches and unlocks Hushbell. Growth follows clinic days;
  free common cuttings prevent shortages. Harvests make all botanical pantry ingredients;
  dew, honey and starlight come from daily collectors. Three preparation steps turn
  one raw portion into three bottles, with fast repeats after learning. Pantry stock
  is spent when poured, with free emergency refills. Garden and preparation progress save
  with the campaign, including unfinished work. See `HERBALISM.md`.

- Twelve pantry ingredients and twenty-one exact, ordered recipes. The first twelve are simple mixtures; the final nine require two separate blends and a final combination.
- A leather-bound recipe book with individual recipe pages, large painted bottle illustrations, handwritten ingredients and ordered instructions. Previous/Next follows the filtered contents.
- Twelve individual transparent watercolor potion bottles shared by the pantry, recipe book and table. Carried bottles sit directly on the wood without captions, with stable random offsets and slight angles in a loose three-column arrangement, preserving collection order and duplicate bottles.
- Searchable recipe book, symptom filter and a six-bottle carrying basket with individually removable collected potions.
- Twenty distinct human patients facing the player across the counter, with blinking, smiles and frowns. The original six are preserved; see `ROSTER.md` for the expansion.
- One fixed blank-face body per person, with separate facial overlays to prevent body flicker.
- Treatment-driven expressions and a right-hand clipboard for the chart, recipe and mixing order.
- Complete generated bare-arm and hand animation renders for both sides.
- Clicking a bottle plays its pour; Clicking the bowl starts the generated stirring animation. Both hands rest empty and carry separate selected-bottle/spoon props; see `HANDS_ANIMATION.md`.
- 72 pouring frames and 84 stirring frames at 12 fps, played from native-sized transparent sheets.
- Continuous colour blending, cauldron bubbles, steam and cure celebrations.
- A painted apothecary interior, warm paper interface and generated chime effects.
- A recipe journal, editable order slots, hints, patient charts and ingredient allergies.
- Unknown mixtures cause recoverable hiccups; unsuitable known remedies do not cure unrelated symptoms.
- One conditional side effect: Dewdrop draught gives a floating patient shivers.
- Three stars for using the minimum number of batches, two for one extra, one for more attempts.
- Click-triggered individual pours, followed by a separate stirring step. Empty bottles remain on the table until returned to the pantry.
- Pause, doubled animation speed, sound toggle, discard and restart controls.

Each bottle click plays one recorded pour; clicking the bowl plays the recorded stirring sequence.
This build does not yet require mouse gestures. Both arms use complete, fixed-size reference-based sprite frames;
effects use editable Godot scene geometry; potion bottles, patients and the interior use generated painted artwork.
Campaign progress saves automatically, including diagnoses, work in progress,
daily improvements, visit history and the ending. This is still an art-directed
prototype without Steam integration or a standalone exported executable.
See `CAMPAIGN.md` for progression, save behaviour and pacing limits.

For advanced recipes, gather the raw ingredients illustrated on the page. Pour the first
blend's ingredients in order, brew, then click **Bottle blend**. Repeat for the second blend.
Click the two saved **Pour [blend name]** buttons beneath the pinned recipe in the book's
specified order, brew again, and serve. Intermediates cannot be fetched from the pantry or
served to patients. Their ingredients still count for allergies; required preparation batches
are included in the perfect-star allowance. Each blend is consumed when the final brew is served.
Handwriting uses the platform's Segoe Print, Bradley Hand or Comic Sans MS font when available.

## Controls

| Input | Action |
| --- | --- |
| Open recipe book | Search and pin a remedy, ordered ingredients and warnings |
| Visit pantry | Pack bottles, then carry them to the table |
| Click a bottle / keys 1–6 | Add an ingredient to the order |
| Click an order slot | Remove that ingredient and close the gap |
| Backspace | Remove the final queued ingredient |
| Click the bowl | Mix after at least two ingredients have been poured |
| Enter | Keyboard shortcut to mix, or serve the finished result |
| P | Pause/resume the mixing animation |
| M | Toggle sound |
| 1x / 2x speed | Change animation speed |
| Finish animation | Immediately complete the current animation, keeping the same recipe result |

You must serve or discard a finished brew before editing the next one. You cannot alter a batch
while it is being mixed. The hands timeline pauses when the window loses focus.
Practice ingredients are unlimited; campaign emergency supplies let you recover
from shortages and mistakes without a game-over screen.

## Source

- `main.tscn`: scene composition, including room, interface and sound player.
- `scenes/`: editable room, UI panels, bottles, cauldron, hands, patients and effects.
- `resources/data/`: `.tres` ingredient, recipe, symptom and patient catalogs.
- `scripts/stage.gd`: complete generated sprite playback and balanced placement.
- `resources/hands/empty_hands.tres`: active complete generated limbs with painted props removed.
- `assets/rotoscope/bare-arm-sources/`: preserved generated full-arm source exports.
- `resources/hands/recorded_hands.tres`: preserved original animation reference.
- `resources/interface_theme.tres`: shared UI theme.
- `assets/audio/`: saved chime files.
- `brewing.gd`: treatment rules and recipe resolution using resource catalogs.
- `main.gd`: game state, input, ordered selection and animation timeline.
- `scripts/stage.gd`: synchronizes existing visual nodes with gameplay.
- `scripts/supplies.gd`: recipe discovery, pantry basket, carrying and table-bottle UI.
- `rotoscope_player.gd`: queries the preserved recorded animation resource.
- `patient_sprites.gd`: controls saved patient sprites, expressions and symptom effects.
- `SCENES.md`: scene map and editor instructions.
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

## Current animation

The complete generated renders have been edited to remove painted props. Both
hands rest empty, the left carries the selected bottle, and Clicking the bowl starts
spoon pickup and return. Eased whole-arm motion and a fixed idle reduce shaking;
some frame-to-frame painted variation remains. See HANDS_ANIMATION.md.
