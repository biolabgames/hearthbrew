# The garden, recipe ingredients and preparation bench

This first playable expansion connects herb preparation to the existing clinic.
Open **Garden & preparations** in the header during a campaign. The original
practice clinic keeps its existing brewing rules.

## First three neighbours

Examine each neighbour's **Sample tray**. Poppy introduces cooling Moonleaf,
Pip introduces warming Emberroot, and Juniper introduces grounding Silverleaf.
The findings explain which preparation releases the needed property.

1. Select the identified herb at the preparation bench.
2. Choose **Steep** or **Grind** and complete its three interactions.
3. Return to the clinic and brew an appropriate existing recipe normally.
4. Return to the bench and select the bottled extract to add its finish.
5. Return to the clinic and serve. One extract is consumed per served treatment.

The first three botanical treatments teach this sequence. Once a preparation has
been completed, **Repeat learned preparation** can make another vial immediately.
Cancelling a partial preparation returns the raw portion. Removing a selected
finish or discarding its base remedy retains the unused extract.

Helping all three neighbours prepares two additional planting patches and gives
Hushbell seeds and three raw portions. This reward is recorded once. Afterwards,
finishes are optional and can treat a second symptom alongside a successful base
remedy. They cannot rescue an unsuitable mixture, cancel a base remedy's adverse
reaction, or replace the correct compound treatment for anchored magic. Ground
or steeped Silverleaf shares the existing Silverleaf ingredient allergy.

## Herb properties

| Herb | Steep | Grind |
| --- | --- | --- |
| Moonleaf | Fever | Glowing hands |
| Emberroot | Stone skin | Chills |
| Silverleaf | Dizziness | Floating |
| Hushbell | Echo voice | Drowsiness |

The pulse charm's Standard/Gentle/Concentrated setting still applies to the base
remedy. Herbal preparation is a separate choice about which ailment to address.

## Garden

The garden uses the approved straight courtyard illustration, with two long soil
areas, a central crazy-paved path, a T-junction to the cottage door and flush stone
edging. There are no timber beds or potting bench in the background. Herbs grow
as painted clumps rooted in the soil, with smaller silhouettes at younger stages.
Click a plant or small garden marker to inspect, harvest or clear it.
Click open soil to select seeds and plant there. The basket panel shows actions
for the selected patch. Growth changes the visible size of the herbs.

The two soil areas share six planting patches, four initially prepared. Three
start with mature plants; new herbs are identified through patient samples.
Harvesting provides three raw portions and leaves the perennial
plant to regrow. Growth takes two clinic-day transitions; there are no real-time
timers, watering chores or plant death. Patches can be cleared and replanted.

The evening screen includes **Visit the garden**. Growth advances after choosing
the evening improvement, or every five appointments in continuing clinic shifts.
Reopening a screen or reloading a save does not advance growth. **Request a free
common cutting** supplies one raw portion of a known herb whenever needed, so
planting choices cannot make a case impossible. Rotate herbs through the patches
to build ingredient stock; all ten species need not be planted simultaneously.

## Recipe ingredient sources

Open **Recipe ingredients** from the garden or preparation bench, or **Grow,
collect & prepare ingredients** from the pantry. Select a bottle to see its
source, raw portions, bottled stock and preparation action. These are fictional
game-world preparations.

| Recipe ingredient | Source | Preparation |
| --- | --- | --- |
| Moonmilk | Moonleaf leaves | Rinse, press, strain |
| Ember nectar | Emberroot roots | Slice, simmer, strain |
| Morning dew | Dew catcher | Decant, filter, bottle |
| Lavender mist | Lavender flowers | Gather, steam, condense |
| Moss cordial | Woodland moss | Rinse, infuse, strain |
| Sun honey | Neighbour's beehive | Open shared jar, strain, bottle |
| Rosewater | Rose petals | Separate, distil, collect |
| Ginger tincture | Ginger rhizomes | Wash, crush/steep, strain |
| Valerian drops | Valerian roots | Clean, infuse, strain |
| Silverleaf extract | Silverleaf leaves | Sort, press, filter |
| Starlight essence | Starlight collector | Open charged prism, condense, bottle |
| Burdock bitters | Burdock roots | Wash, macerate, strain |

Each raw portion becomes **three bottles** after three preparation interactions.
Completed methods unlock **Repeat learned preparation**. Cancellation returns
the reserved portion, including collected materials. Ingredient preparation and
botanical finish preparation share the bench: finish or cancel one before
starting the other. Hushbell remains a special botanical finish, not a pantry
bottle source.

Moonleaf, lavender, moss and rose seeds are known initially. Pip's sample unlocks
Emberroot and Ginger; Juniper's unlocks Silverleaf, Valerian and Burdock. The
three-neighbour reward still unlocks Hushbell. The three collection sources are
available immediately and each yields three raw portions once per clinic day.
The shared honey jar and automatically charged prism require no real-time clock
or new day/night screen. Revisiting and saving cannot refresh collection.

## Pantry and brewing

New campaigns start with four bottles of each ingredient. Campaign stock is
finite and shared by garden preparation and the pantry. The pantry shows how
many bottles remain available after full bottles in the current basket. Picking
up or removing bottles does not consume them; a valid pour consumes exactly one
bottle at its start. Clearing or discarding a poured brew does not refund stock.
Unpoured bottles remain in stock when the basket is cancelled or patients change.
Compound blends consume base ingredients once, while preparing the intermediate
blends; combining them does not charge base bottles again.

**Request missing recipe supplies** in the pantry tops up missing base bottles
for the complete pinned recipe, counting duplicates across compound stages.
This is free and always available during a brewable appointment. It supplies
bottles, not a finished treatment, so diagnosis and recipe order still matter.
Practice mode keeps unlimited bottles and does not spend campaign inventory.

## Persistence and compatibility

Campaign saves include raw portions, known herbs, six planting states, prepared
extracts, learned methods, helped neighbours, garden restoration, day growth,
partial preparations, twelve bottle counts, collected materials, collection days,
learned ingredient methods and the selected finish. JSON numbers are normalized on
restore, and malformed herbal state is rejected before modifying the live game.
Verification uses separate save files and does not touch the player's campaign.

Older four-herb saves keep their plant identities, raw portions, progress and
unfinished extracts. Migration appends the six new species, grants seeds
appropriate to already identified samples, and adds starter bottle stock.
Older campaign saves without herbal state retain their original treatment
requirements and get optional access to all ten herbs. Unpoured carried bottles
are covered by migration stock. Starting a new campaign enables the three
introductory botanical cases. Malformed ingredient counts and work states are
rejected before the live campaign is modified.

## Scope and verification

The garden uses local artwork generated with built-in imagegen: the painted
outdoor environment and transparent atlases for all ten herbs. The approved
environment is `assets/garden/ingredient-garden.png`; its source is
`output/outdoor-garden/07-courtyard-no-bench.png`. Original source paths and
reference roles are in `assets/garden/prompts.json`; the new plant atlas prompt
is in `assets/garden/ingredient-plants-prompt.txt`. The new atlas uses a 3×2 grid:
Lavender, moss, Rose / Ginger, Valerian, Burdock.
The preparation bench retains its earlier schematic interaction drawings.
It does not add a walkable outdoor area, weather, crop genetics, or a new story
chapter. First-time preparation uses three deliberate interactions; repeat
preparations are fast. Human playtesting is still needed to judge whether the
extra clinic/bench trips feel satisfying.

- `scripts/herbalism.gd`: persistent herb, garden and preparation rules.
- `scripts/herbalism_ui.gd`: garden and bench screens in the campaign interface.
- `scripts/garden_view.gd`: full-screen painted garden and interactive herb patches.
- `scripts/herb_sketch.gd`: reusable botanical and preparation drawings.
- `verify_herbalism.gd`: botanical model, production brewing, UI actions, persistence,
  recovery, allergy and compound-requirement checks.
- `verify_garden_ingredients.gd`: all twelve sources and all twenty-one recipes
  from prepared stock, planting/regrowth, collection limits, cancellation,
  migration, invalid saves, actual pantry/pour consumption, emergency recovery,
  ingredient UI, practice compatibility and rendered captures.

Run `Godot --headless --path . --script verify_herbalism.gd`. For rendered captures,
omit `--headless` and append `-- --capture`. Screenshots are saved to
`previews/herbalism_*.png`.

Run `Godot --headless --path . --script verify_garden_ingredients.gd` for the
ingredient loop. For visual checks omit `--headless` and append `-- --capture`;
these captures use the `previews/garden_*` prefix and separate verification saves.
