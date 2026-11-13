# Complete generated arms with empty hands

Both visible limbs use resources/hands/empty_hands.tres: the same complete
connected generated arm-and-hand renders, edited with built-in imagegen to remove
the painted jar and spoon. No separate procedural forearms or footage cutouts are
used. Original approved renders remain unchanged in assets/rotoscope/.

Edited exports are preserved in assets/rotoscope/empty-hands/sources/ with the
prompt and source mapping in prompts.json. pack_empty_hands.gd normalizes the
4-by-3 sheets to the existing 512-by-288 frame grid and rebuilds idle sheets.
The last pour page was already empty and is copied without an art edit.

At rest both hands are empty. Clicking a table bottle reaches for that copy,
hides its tabletop sprite while carried, pours its ingredient, returns its empty
sprite, and withdraws. The actual selected bottle artwork is shown in the hand.
Stir mixture explicitly starts spoon pickup, stirring, return and withdrawal.
The table spoon and held spoon are never visible simultaneously.

Props sit behind the painted fingers. Whole-frame placement follows grip anchors;
forearms and hands stay joined in each complete image. Reach and return paths
use eased motion, and idle holds still. Action frames retain some painted redraw
variation. Hand sizes use the prior balanced baselines, with a textured mesh extending only the lower painted forearm to the screen edge.
The hand retains its size; no replacement forearm is drawn.

verify.gd checks gameplay, edited asset hashes, full sprite provenance, continuous
grip paths and prop visibility. Current captures are in previews/smooth-hands/.
