# Treatment reactions

Every neighbour has five expression states: neutral, smile, worried, disgust and delighted.
Each state retains the open, half-closed and closed eye sequence used for blinking.

- A muddled brew, unsuitable known remedy, allergy or harmful side effect triggers disgust for four seconds.
- A helpful treatment that leaves symptoms keeps the gentle smile.
- Clearing the last symptom triggers a broad, delighted expression for four seconds, then the regular relieved smile.
- Restarting or welcoming the next patient clears the previous reaction.

`main.gd` selects the expression from the treatment result. The reaction timer takes priority
over the persistent cured smile, so the delighted expression gets its full four seconds.
`patient_sprites.gd` displays special expressions on a separate `ReactionFace` sprite.
The original face layer returns for the existing neutral, smile and worried expressions.

The built-in imagegen tool authored the new facial reactions in
`assets/patients/reactions/<name>.png`. Each atlas has three rows (neutral reference,
delighted, disgust) and three eye columns. Exact prompts and source paths are in
`assets/patients/reactions/prompts.json`.

Existing body images, existing expression atlases and the character scenes are untouched.
For the original six, the new layer uses the existing feature mask with a small horizontal
extension for the broad smile. The other fourteen use the same feathered face area as their
existing expressions. Generated hair, clothing and background pixels outside those masks
never enter the render. The body stays fixed on its existing neutral image.

Run `verify.gd` for reaction timing, treatment outcomes, all twenty reaction layers and
blink frames. Run `capture_reactions.gd` with the Compatibility renderer for preview sheets
and a pixel comparison proving the body stays unchanged outside the face area.
Output goes to `previews/reactions/`, including `body-preservation.json`.

Validation on 12 November 2026: **2,330 gameplay checks, zero failures**.
All forty neutral-to-reaction render comparisons pass with **zero changed pixels
outside the facial area**. Preview sheets show both reactions for all twenty neighbours;
in-game screenshots show actual wrong-potion and cure outcomes for Poppy.
