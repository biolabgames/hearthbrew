# Validation

Engine: **Godot 4.7.stable.official.5b4e0cb0f** on Windows, Compatibility renderer.

The included `verify.gd` completed **870 checks with zero failures** after separating static patient bodies from animated faces.

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

