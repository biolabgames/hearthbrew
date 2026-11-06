# Video-reference hand animation draft

The game now uses rotoscope_player.gd and transparent sheets in assets/rotoscope.
The old painted_hands.gd and V2 image are historical assets and are not loaded.

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
