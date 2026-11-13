<!-- Current prop-free full-arm implementation: HANDS_ANIMATION.md. -->
# Editing Hearthbrew in Godot

Open `project.godot`, then `main.tscn`. The scene tree contains the room, interface
and audio player before the game runs. Press F5 to play.

## Scene map

| File | What to edit |
| --- | --- |
| `main.tscn` | Top-level room, interface and sound player |
| `scenes/mixing_room.tscn` | Background, counter, patient position, bottles, cauldron, hand placement and effects |
| `scenes/room_decor.tscn` | Paper panels, counter edge, clipboard clip and dividers |
| `scenes/counter_frame.tscn` | Foreground counter and animation status backing |
| `scenes/ui/interface.tscn` | Interface composition and shared theme |
| `scenes/ui/header.tscn` | Title, status, progress, speed and sound buttons |
| `scenes/ui/journal.tscn` | Eight recipe buttons and journal headings |
| `scenes/ui/shelf.tscn` | Six ingredient buttons and labels |
| `scenes/ui/clipboard.tscn` | Patient chart, pinned recipe, order slots and action buttons |
| `scenes/ui/phase_display.tscn` | Animation phase and keyboard help |
| `scenes/ui/shift_complete.tscn` | End-of-shift panel |
| `scenes/patients/patient_lineup.tscn` | Patient composition and symptom effects |
| `scenes/patients/*.tscn` | Each person's separate Body and Face sprites |
| `scenes/props/bottle_*.tscn` | Bottle glass, liquid, cork, label and symbol geometry |
| `scenes/props/cauldron.tscn` | Named bowl, handles, legs, rim, liquid and moon shapes |
| `scenes/props/left_hand.tscn`, `right_hand.tscn` | Complete generated AnimatedSprite2D limbs |
| `scenes/effects/*.tscn` | Bubble, steam, flower and symptom effect scenes |

Double-click an instance to edit its source scene. For a local change, use Godot's
Editable Children option. Labels, controls, Polygon2D points, Line2D points,
colours and panel styles are saved in the scenes. Gameplay updates text, enabled
states, visibility and animation without rebuilding the scene tree.

## Resources and assets

- `resources/data/ingredients.tres`, `recipes.tres`, `patients.tres` and
  `symptoms.tres`: edit the exported Entries dictionaries in the Inspector.
  Array order defines IDs; recipe sequences reference ingredient indices and
  patient allergies use an ingredient index or -1. Preserve the current six
  ingredients, eight recipes and six patients unless also extending the UI.
- `resources/hands/empty_hands.tres`: native SpriteFrames with all 72 pour,
  84 stir and two six-frame idle animations. Use the SpriteFrames editor to
  inspect the active complete generated redraws. Metadata retains reference footage and event frames.
- `resources/hands/user_video_traces.json`: historical rejected source contours, wrist/grip landmarks and pixel hashes.
- `assets/user-video-hands/*.png`: native pixel crops from the user's original recordings.
- `scenes/props/user_video_hand.tscn`: historical rejected footage/procedural renderer (not instantiated).
- `resources/interface_theme.tres`: shared default font and size. Individual
  scenes contain their label fonts and button style overrides.
- `assets/audio/*.wav`: saved chimes used by the scene's AudioStreamPlayer.
- Painted PNGs remain PNGs, referenced through Godot's normal texture importer.
  Original JSON manifests and source art remain as provenance. The active hand
  scenes load empty_hands.tres through the normal Godot resource importer.

scripts/stage.gd controls full-frame playback, balanced scales and stable idle
poses. See HANDS_ANIMATION.md for the separate prop interactions.
