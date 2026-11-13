<!-- Current prop-free full-arm implementation: HANDS_ANIMATION.md. -->
# Active generated full-arm renders — 10 November 2026

The complete generated hands and forearms are restored together. See HANDS_ANIMATION.md for playback and separate prop interactions.

The active pouring, stirring and idle atlases now use bare forearms in place of the
baggy green sleeves and cuffs. Hands have smoother shading and reduced wrinkles,
veins, freckles and nail detail. All 156 action frames were redrawn using built-in
imagegen. The original painted sources remain available in their existing folders.

Selected new exports and the generation prompt are in assets/rotoscope/bare-arm-sources.
Run pack_arm_redraw.gd to normalize the exports to the existing 2048 x 864 atlas grid
and regenerate both six-frame idle sheets. Export normalization happens offline;
playback still uses complete 512 x 288 frames at their native size. The original
timing, event frames and drawing origins remain unchanged. Generated redraws may
vary slightly in anatomy between frames and remain draft artwork.

The subsequent size pass enlarges the smaller left resting arm by 30% and reduces
the right arm by 20%, with uniform scaling of each complete frame. The left pour
smoothly returns to 100% while raised to compensate for its closer filmed pose.
Drawing origins compensate around the left grip and right counter exit. This
supersedes the original native-size-only presentation described below.

Run capture_arm_redraw.gd for current idle, pour and stir screenshots in
previews/bare-arms. Older preview folders show the previous sleeve artwork.
The historical process and original source metadata below describe the earlier art.

# Original video-reference hand animation draft

Playback now uses native AnimatedSprite2D hand scenes and
resources/hands/recorded_hands.tres. rotoscope_player.gd queries that resource
for timeline validation. Transparent sheets remain in assets/rotoscope.
The retired painted_hands.gd pose rig has been removed; the V2 image remains a
historical asset. See SCENES.md for the current editor workflow.

## Source and playback

References: the user's 20261106_010812.mp4 (left pour, approximately 6.03 seconds) and
20261106_010936.mp4 (right stir, approximately 7.22 seconds), both 1920 x 1080.
The originals are untouched in .codex-attachments and are not bundled as game art.
manifest.json records its SHA256, each sampled timestamp, crop and packed-frame hash.

- 72 consecutive sampled frames from 0 to 5.9167 seconds, at 12 fps.
- Recorded left-hand reach, grasp, lift, wrist tilt, straighten, return and release.
- Six initial rest frames form the idle clip.
- Complete connected hand, forearm and held prop in every frame.
- Six 2048 x 864 transparent pour pages; fixed 512 x 288 frame canvases, four columns.
- One 2048 x 576 idle page.
- 84 right-hand stirring frames from the second recording's first seven seconds, at 12 fps.
- Seven stirring atlas pages and one right-hand rest page with the same native grid.
- Native-pixel crops and transparent padding during packing; no resampling.
- Source and destination rectangles have identical dimensions during playback.
- One fixed drawing origin, no per-part transforms, arm stretching, rigging or tweened poses.

Godot may uniformly resize the entire game viewport to fit its window.

## Art process and limits

Built-in image_gen reference-based editing painted sampled footage in the warm watercolor
style of assets/apothecary.png. Left-hand redraws are in painted-sources, right-hand redraws
in stir-painted-sources. Left-hand prompts are in prompts.json and all seven right-hand prompts
in stir-prompts.json. The early left-hand batch-3 entry is a specification summary.
No CLI/API fallback was used.

This is an AI-assisted painted motion draft, not precision manually traced rotoscoping.
The broad sequence follows the source, but proportions, sleeve folds and prop details vary
between drawings. Anatomical and temporal cleanup remains before final production art.
The recorded jar has a lid; the draft preserves that prop rather than claiming a real liquid pour.
The right-hand footage shows a thin straight utensil; its recorded shape and movement are
retained with a warm wood finish. It has not been replaced with an invented spoon shape.
Only the serving animation remains pending in the manifest.

An early batch copied poses from another atlas instead of following each reference.
Rejected sheets were moved to work/rotoscope/rejected-pose-copies and are not loaded.
Selected retries use the matching footage contact sheet and background style only.

## Gameplay and review

Each ingredient plays the six-second left-hand sequence. After the final pour, the complete
seven-second right-hand sequence plays once, then the remedy becomes ready. 2x speed, pause,
focus loss and finish controls apply to both phases. Serving is locked until mixing completes.
Liquid colour starts changing at tilt frame 24 and stays continuous into stirring.
Patient and recipe rules are unchanged. Both actions use fixed origins and native frame sizes.
A wooden foreground frame covers the original camera-frame exits; no limb is extended to hide them.

Run Play Hearthbrew.cmd, then brew Moonmilk followed by Dew.
previews/rotoscope/left-hand-preview.mp4 is a six-second actual in-game render.
previews/rotoscope/pour-and-stir-preview.mp4 shows a complete two-ingredient batch and ready state.
capture_motion.gd renders the poses through the game scene.
work/rotoscope/pack_painted.py packs the native-pixel drawings without resizing.
Run work/rotoscope-010936/pack_stir.py afterwards to add right-hand sheets and provenance.
verify.gd checks all 156 action-frame indices, native dimensions, atlas transitions, clip endpoints,
the pour-to-stir boundary, colour continuity, pause, focus, speed and premature-serving lock,
along with existing recipe, control, patient and recovery behavior.

## Footage still needed

Use a fixed first-person camera with the same sleeve and framing. Show the visible forearm
and leave space around the fingers. A plain contrasting table helps tracing.

1. Pick up a finished bottle and offer it forward to serve.

Hold the start and end poses for about one second. Five to eight seconds per action is enough.
A later uncapped-bottle take would let the final pouring prop match the intended action.
