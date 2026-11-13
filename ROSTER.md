# Clinic roster expansion

Treatment expressions now also include disgust for wrong potions and four seconds of
delight when cured. See `FACIAL_REACTIONS.md` for timing, art and preservation checks.

The clinic now has 20 playable neighbours, 12 symptoms and 21 remedies.
The original six patient entries, character scenes, bodies and facial atlases are unchanged.
They remain the first six arrivals with the same dialogue, allergies, hints and treatment puzzles.

| New neighbour | Village role | Starting symptoms |
| --- | --- | --- |
| Hazel | Beekeeper | Drowsiness |
| Otis | Ferryman | Dizziness |
| Fern | Seamstress | Spark sneezes |
| Cedar | Night watchman | Echo voice |
| Tansy | Mapmaker | Glowing hands |
| Hugo | Mill keeper | Drowsiness, fever |
| Iris | Stained-glass maker | Dizziness, shivers |
| Alder | Mushroom forager | Spark sneezes, floating |
| Clover | Choir leader | Echo voice, bubble hiccups |
| Wren | Clockwork repairer | Glowing hands, invisibility |
| Saffron | Soup cook | Drowsiness, spark sneezes |
| Felix | Puppeteer | Dizziness, glowing hands |
| Dahlia | Orchard keeper | Stone skin, echo voice |
| Moss | Apprentice herbalist | Drowsiness, glowing hands, wild blooming |

The complete symptom set is fever, shivers, floating, stone skin, invisibility,
bubble hiccups, wild blooming, drowsiness, dizziness, spark sneezes, echo voice and glowing hands.
The five added symptoms have dedicated animated effects and searchable remedies:
Wakebell tonic, Steady shore, Spark hush, Single voice and Dusk veil.
All use the existing pantry ingredients and brewing controls.

Progress, completion text and star totals follow the catalog size: 20 neighbours and 60 stars.
Each new patient has an explicit treatment route and an achievable three-star batch target.

## Art and future edits

The built-in imagegen tool generated fourteen individual painted expression sheets.
Assets are saved in `assets/patients/expanded/`; each scene is in `scenes/patients/`.
The exact shared prompt and character descriptions are recorded alongside the assets.
New portraits keep the neutral body fixed and overlay only a feathered face region
from the expression sheet. Eyes blink through open, half-closed and closed states;
the treatment reaction selects neutral, smiling or worried expressions.
The original six continue using their existing separate body and facial atlases.

Gameplay catalogs remain editable in `resources/data/*.tres`.
`resources/data/roster_expansion.json` and `scripts/build_roster.py` reproduce the additions.
Edit the JSON before rebuilding; rebuilding replaces expansion entries and scenes.
Original art hashes and a copy of the original patient catalog support preservation checks.
`verify.gd` passes 1,653 checks with zero failures, covering all twelve symptom bits,
recipes, all twenty patients, original character preservation and a complete 60-star shift.
`capture_roster.gd` produces one in-game screenshot per neighbour in `previews/roster/`.
