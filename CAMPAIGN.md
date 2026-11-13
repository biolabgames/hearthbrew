# The Moonflower Letters

The default launch now offers an eight-day campaign, saved continuation, or the
original free practice clinic. The campaign has 40 appointments: the original
20 introductions followed by 20 authored returning visits, new symptom
combinations, personal accounts and a connected village mystery. Existing
patient artwork and the original catalogs are preserved.

## Playing

1. Each appointment begins in the main room with the patient and their expanded
   account beside the counter. Observable symptoms are already visible: flushed
   cheeks, cool blue skin and shivering, floating, stone colouring, fading,
   bubbles, flowers, sleep motes, dizziness, sparks, echoes and glowing hands.
   Select **Diagnose patient** or **Diagnosis & casebook** when ready.
   Temperature, lantern, listening/balance and sample tools record positive and
   negative evidence. Consult the scrollable symptom guide.
2. Select all supported symptoms and confirm the diagnosis. A guess without
   findings cannot be confirmed. Observable appearance and recorded diagnostic
   findings are separate; recipe filtering still follows collected evidence.
3. Choose a recipe, check allergies, fetch bottles, pour and stir as before.
   The campaign starts each appointment with the first book page, rather than
   automatically choosing the correct treatment.
4. From day five, examine the pulse charm. Faint, even and surging magic require
   gentle, standard and concentrated preparations respectively. Choose strength
   at the lower left **before stirring the final remedy**. Intermediate blends
   retain their ordinary preparation method.
5. Later samples identify deep-set enchantments that need compound alternatives.
   Star lantern, Stillwater elixir, Garden hush and Twilight harmony become
   necessary for particular anchored symptoms. Other symptoms remain treatable
   with simple mixtures. Wrong strength or an unsuitable simple preparation
   leaves the finished brew available to discard; nothing silently changes its
   strength after brewing.
6. After five appointments, read the day's letter and choose tomorrow's small
   improvement. Field notes record one useful examination in advance; arranging
   the workbench starts tomorrow at 2x speed. Both are optional conveniences,
   and animation speed/finish controls remain available normally.
7. The final appointment uses Garden hush on the enchanted root sample as well
   as treating Poppy. Resolve the source from the accumulated village evidence.
   The ending unlocks continuing clinic shifts, which shuffle proven safe case
   variants and retain diagnosis, tolerances and compound requirements.

Day one offers twelve simple recipes. Nine compound recipes become available on
day two. The authored campaign's recommended routes use all 21 remedies, including
allergy-safe substitutions. Later cases combine up to three simultaneous symptoms.
The journal records treated neighbours, stars, improvements, letters and active
play time. There is no appointment countdown or stock shortage.

## Saving and recovery

`user://hearthbrew_campaign_v1.json` contains the campaign. Save writes use a
temporary file and rename; invalid saves are retained and produce a readable
message. A separate confirmation protects an existing save when starting over.
Free practice does not overwrite the campaign save.
Resuming an appointment returns to the main room; saved evening and ending screens
remain available at their respective campaign milestones. Field notes record an
examination without automatically opening the diagnosis panel on the next day.

Saves occur on casebook actions, diagnoses, treatment, daily transitions, leaving
the application and closing it. Explicit **Save / main menu** is available in the
casebook and evening screens. A pour interrupted by saving resumes with that
bottle poured once; an interrupted stir resumes as a finished batch without
charging another batch. Finished remedies and bottled blends survive resuming.

## Pacing

The campaign aims to support a multi-hour first playthrough. Recommended routes
contain **176 batches and 441 pours**, with approximately **64.6 minutes of
animation at 1x**, before investigation, reading, gathering and decision time.
Players can halve or skip animation time, and experienced players will diagnose
faster. A 4–6 hour campaign remains a playtest target, not a measured promise.
The journal's active-time counter supports measuring real playthroughs; it pauses
when unfocused, in the main menu, during an explicit pause and after completion.

Continuing shifts reuse the authored, validated combinations in shuffled order;
they do not promise an unlimited supply of new stories or novel diagnoses.

## Implementation and verification

- `scripts/campaign_data.gd`: chapter letters, returning cases, tool findings.
- `scripts/campaign.gd`: campaign UI, diagnosis, progression, preparation rules,
  journal, persistence and continuing shifts.
- `main.gd`: hooks into the existing brewing and presentation loop.
- `verify_campaign.gd`: complete campaign through production pouring and brewing,
  compound requirements, wrong strengths, daily boundaries, save/resume,
  invalid saves, ending and solvable continuing shifts.

Run Godot with `--headless --path . --script verify_campaign.gd`. Add `-- --capture`
and omit `--headless` to render the casebook, guide, brewing, evening and ending
screens into `previews/campaign_*.png`. Tests use their own save filename. The
original `verify.gd` suite continues to exercise the free practice clinic.
