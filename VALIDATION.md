# Validation

## Painted continuous herb garden — 12 November 2026

Replaced the garden's six cards with a full-screen painted outdoor environment
matching the apothecary room. The final artwork follows the user's corrections:
one continuous soil plot, the original chunky green timber edging, no internal
dividers or paths, and a narrower back edge with converging side boards.

Four painted transparent herb sprites grow in selectable patches inside that
one shared plot. Garden controls inspect the selected plant or open soil.
Existing save fields retain the six planting locations without a schema change.
Other campaign panels restore their original position, size and paper styling
when leaving the garden.

- Garden/preparation suite with OpenGL captures: **67 checks, zero failures**.
  Added checks for the installed environment, actual herb-atlas alpha, all six
  root positions inside the receding soil polygon, clicking a planting location,
  and restoring the preparation screen after leaving the full-screen garden.
- Complete campaign suite: **631 checks, zero failures**.
- Visually inspected the rendered `previews/herbalism_garden.png` and the final
  background and transparent herb atlas. Adjusted plant positions for the
  corrected perspective and separated the small garden markers.
- Final assets are `assets/garden/herb-garden.png` and `herb-plants.png`;
  built-in imagegen prompts and provenance are in `assets/garden/prompts.json`.

## Garden and botanical preparation — 12 November 2026

- Original practice suite: **2,330 checks, zero failures**.
- Complete campaign suite: **631 checks, zero failures**, using prepared botanical
  finishes for the first three neighbours and preserving all 40 treatment routes.
- Dedicated herbalism suite with OpenGL captures: **57 checks, zero failures**.
  Covers three-step preparation through real UI buttons, learned shortcuts,
  harvesting and two-day regrowth, planting, free cuttings, one-time neighbour
  rewards, raw stock and extract consumption, partial-work and selected-finish
  saves, JSON numeric normalization, invalid botanical saves, and legacy saves.
- Production brewing checks confirm that a complementary extract can treat a
  second symptom, cannot bypass anchored magic or rescue an unsafe brew, and
  respects the shared Silverleaf allergy.
- Visually inspected `previews/herbalism_casebook.png`, `herbalism_garden.png`,
  `herbalism_bench.png` and `herbalism_steeping.png`. Adjusted selector contrast,
  preparation-art placement and casebook subtitle length. Botanical findings
  appear before the ordinary sample findings so introductory clues are visible.

Tests use separate verification saves under `.godot/test-user`. No player save
was used. The existing Windows certificate-store warning remains unrelated to
local gameplay. These checks establish functional recovery and presentation;
human playtesting is still needed to assess pacing and the additional trips
between the bench and clinic. See `HERBALISM.md` for rules and scope.

The 12 November facial reaction expansion passes **2,330 checks with zero failures**.
All 20 patients have blinking disgust and delighted reactions. Cure delight lasts four
seconds before returning to the regular smile. Forty OpenGL render comparisons confirm
zero changed pixels outside the face area. See `FACIAL_REACTIONS.md` and `previews/reactions/`.

The empty-hand full-arm update passes **1,879 checks with zero failures**.
Coverage includes edited atlas hashes, native complete limb sprites, carried
selected-bottle artwork, empty resting prop state, one visible spoon during
pickup/stir/return, continuous grip paths, duplicate bottle handling, explicit
Stir, pause/focus/speed, recipes and patients. Rendered idle, pickup, pour,
stir and return captures are in previews/smooth-hands/.
The empty-hand edits were made with built-in imagegen; complete original
renders remain intact. Action frames retain some painted redraw variation.

The recipe-book and staged-brewing update passes **1,876 checks with zero failures**.
It adds rendered checks of simple and advanced
recipe pages in `previews/recipe-book.png` and `previews/recipe-book-staged.png`.
Gameplay coverage includes all nine staged recipes, unique intermediate pour orders,
reversed-order rejection, prevention of bypassing stages with raw ingredients, bottling
without treatment, saved-blend consumption, inherited allergies and fair efficiency scoring.

The 10 November roster expansion passes **1,653 checks with zero failures**:
20 playable patients, 12 distinct symptom bits, 21 unique remedies, original six
patient data and artwork preservation, and a complete 60-star clinic shift.
OpenGL screenshots for every patient are saved in `previews/roster/`.
See `ROSTER.md` for the added characters, symptoms and asset workflow.

Engine: **Godot 4.7.stable.official.5b4e0cb0f** on Windows, Compatibility renderer.

The included `verify.gd` completed **1,071 checks with zero failures** after the
10 November 2026 scene and resource conversion. The pre-conversion baseline was
870 checks with zero failures. Existing UI checks now traverse the scene hierarchy.

Conversion checks cover native scene instances, saved button signals, stable
control identities, preservation of edited control positions, all 72 left-hand
and 84 right-hand AnimatedSprite2D frames, pause/resume, finishing, serving and
patient advancement. See `SCENES.md` for the editable files.

The older art-validation results below describe existing asset provenance;
the conversion does not claim a new manual review of every source frame.

Coverage includes:

- Six patient identities, static 512 x 384 bodies and separate native 128 x 128 facial overlays.
- Actual Godot OpenGL captures of all 54 expression/blink states: pixel comparison found ZERO
  changed pixels outside the facial overlay rectangle. Blank bodies were also rendered separately.
- Open, half-closed and closed eyelids, reopening, and blinking within smiles and frowns.
- Concern on arrival, calm watching, hopeful smiles, relief after cure and concern after mistakes.
- All six patients' face and upper-body area stays clear of information controls.
- Six native-resolution in-game screenshots and a 432-frame, 36-second expression preview were
  rendered with the OpenGL Compatibility renderer. Every patient's framing and sidebar text
  were visually inspected. A contact sheet contains unchanged crops from those game renders.

- All 72 video-reference frames are addressable in chronological order at 12 fps.
- Fixed native frame dimensions, six atlas pages, page transitions and non-looping endpoint.
- All 84 right-hand stirring frames, native dimensions, seventh page and non-looping endpoint.
- Two six-frame rest clips and absence of an invented serving clip.
- Pour-to-stir timing, continuous liquid colour, pause, focus, speed and serving lock during stirring.
- An actual 72-frame OpenGL game render encoded as a six-second 1440 x 900 MP4.
- A combined 240-frame OpenGL render covering two pours, the stir and the completed remedy.

The tests verify playback and game behavior. They do not certify artistic anatomy or exact
rotoscope fidelity; the AI-assisted painted drawings still need temporal cleanup.

- Unique resolution of all eight ordered recipes and their two-to-four-ingredient bounds.
- The same pair in reverse order producing a different output.
- Invalid extra ingredients and unknown duplicate combinations.
- Conditional side effects, ingredient allergies and irrelevant treatments.
- Ingredient count limits, keyboard shortcuts, removal while preserving order and button callbacks.
- Locking the queue during mixing and while a finished brew awaits a decision.
- Pause, focus loss, doubled animation speed and intermediate liquid colour changes.
- Automatic animation completion and correct finished remedy colour.
- Serving, discarding, restarting and finishing a full six-patient clinic with 18 stars.
- Recovery after a muddled brew and correct efficiency scoring.
- Viewport containment of the final test state's UI controls.

## Historical V2 validation (retired rig)

Earlier renderer captures were produced for idle, reaching, pouring, stirring, lifting, finished and cured states.
Visual inspection led to improved disabled-text contrast and positioning of the moving vessels
and hands below the instruction panel. The updated captures are in `previews/hands-v2`.

The updated hand atlas was checked for genuine alpha transparency and successful loading.
The original simplified hands were replaced with painted poses and matching stitched linen
sleeves. Wrist crops and overlapping sleeve joins were adjusted after visual inspection, and
spoon lifting and pour-flow transitions were changed to follow continuous eased paths.

The restricted test environment emits a Godot startup message about reading Windows root
certificates. Godot falls back to its built-in certificate bundle; this game has no networking.
Tests used temporary editor data directories in the working folder, leaving normal editor
settings untouched.

This validates the tested gameplay paths and rendered states. It does not establish commercial
balance, controller support, save migration, other-machine compatibility or a production-ready
character-art pipeline. The launcher runs the source project using the existing Godot engine.

## Recipe book and pantry expansion

Headless `verify.gd` covers 12 ingredients and 16 unique recipes, symptom and ingredient
search, patient filtering, allergy and floating warnings, basket capacity, explicit carrying,
table button signals, blocking unfetched pours and pantry edits during mixing, returned
bottle queue cleanup, new-patient reset, all new treatment effects, and the existing six-patient shift.
Rendered previews: `previews/recipe-book.png`, `previews/pantry.png`, `previews/table.png`.
Godot emits an environment certificate-store warning; local gameplay checks and captures succeed.

## Moonflower Letters campaign — 12 November 2026

- Original `verify.gd`: **1,888 checks, zero failures**.
- `verify_campaign.gd -- --capture`: **509 checks, zero failures**, including
  a complete 40-appointment playthrough through the real pouring, intermediate
  bottling, mixing and serving functions. Recommended routes use all 21 remedies.
- Verified evidence-supported diagnoses, invalid hypotheses, reconfirmation after
  changing a diagnosis, strength selection, anchored enchantments, safe allergy
  alternatives, treatment recovery and appropriate star awards.
- Verified case advancement, all eight evenings, both daily improvements, the
  mystery conclusion, persistent completion, replay case solvability and restoring
  authored order when beginning a new campaign after shuffled clinic shifts.
- Verified saving/resuming finished remedies, mid-pour and mid-stir checkpoints,
  active play time, and rejection of an invalid save without replacing live state.
- Rendered and visually inspected casebook, symptom guide, preparation selector,
  evening and ending screens. Corrected diagnosis-label contrast and ending totals.
  Captures, including the launch menu, are `previews/campaign_*.png`.

Tests used `.godot/test-user` for application data and a separate verification save
filename. No player campaign save was used. The environment's Windows certificate
store warning still appears; it does not affect these local tests.

The authored routes contain 176 batches and 441 pours, or 64.6 minutes of animation
at normal speed before investigation, gathering and reading. This is a pacing
baseline, not a measured campaign duration. Human playtests are still needed to
establish typical completion time and tune the 4–6 hour target. Save migration
between future schema versions is not implemented.

## Patient arrival and observable symptoms — 12 November 2026

Appointments now open in the main room, including restarts, next-day arrivals,
continuing shifts and resumed appointments. Field-note assistance no longer
opens a panel automatically. **Diagnose patient** opens the diagnosis panel.
All 40 appointments have expanded personal accounts, shown in a scrollable
dialogue card beside the counter; existing saves receive the expanded wording
without changing their stored appointment data.

Patient appearance now uses the full active symptom mask, independently of
recorded diagnostic findings and recipe filtering. Fever adds soft cheek flushes;
chills add a subtle blue tint and shivering. Existing magical symptom effects
are enabled by showing their previously hidden parent nodes. Combined ailments
retain their simultaneous effects, and curing symptoms removes their cues.
Flowers now grow near the sleeves rather than appearing beside the head.
The interface draws above the effects so cheeks and particles cannot show through
the diagnosis panel.

The updated original suite passes **1,909 checks**. The campaign capture suite
passes **644 checks**, including room-first arrivals throughout all 40 visits,
resuming in the room, opening diagnosis via its actual button, fuller dialogue,
visible symptoms before examination, and correct interface layering. Captures
in `previews/arrival_*.png` show fever, chills, mixed temperatures and floating,
expanded patients, multiple magical symptoms and the diagnosis panel.

## Garden ingredient loop — 13 November 2026

The approved courtyard background is now the production garden, with clickable
herbs in the bare soil around the paved T-junction. Six additional transparent
plant sprites complete ten growable herbs. All twelve base ingredients have a
defined plant or collection source. Three-step preparation turns one raw portion
into three pantry bottles; completed methods support fast repeats. Dew, shared
honey and stored starlight renew once per clinic day. Ingredient preparation and
botanical finish work cannot overlap.

Campaign pours consume tracked bottles once, at pour start. Pantry selection
cannot overbook stock, and unpoured bottles are not spent by cancelling a basket
or changing patients. Discarding a poured mixture does not refund stock.
Compound blending does not double-charge base ingredients. A free pantry action
replaces missing bottles for the pinned recipe, including duplicate ingredients
across its intermediate blends. Practice stock remains unlimited.

Four-herb saves migrate without changing old herb identities or treatment rules;
new material counts, collector days, work-in-progress and bottle inventory are
validated and persisted. Save-during-pour resumes the stable endpoint without
spending stock twice. Verification uses separate saves and workspace-local Godot
user directories rather than the player's campaign file.

Passing suites:

- `verify.gd`: 2,330 checks.
- `verify_campaign.gd`: 631 checks, including the forty-appointment campaign.
- `verify_herbalism.gd`: 63 checks.
- `verify_garden_ingredients.gd`: 458 checks with rendered captures; covers all
  twelve sources and all twenty-one actual recipes starting from zero bottles,
  plus regrowth, collection limits, cancellation, save migration, malformed saves,
  pantry stock, emergency recovery and practice compatibility.

Rendered screenshots were inspected for path clearance, plant placement,
growing/mature silhouettes, clipped artwork and readable ingredient controls:
`previews/garden_ingredients_mature.png`, `garden_ingredients_young.png`,
`garden_ingredient_preparation.png`, `garden_collection.png` and
`garden_pantry_stock.png`. Game balance and the frequency of emergency refills
still need human playtesting.
