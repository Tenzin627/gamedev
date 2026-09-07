# Phase 8 Playtest — Unified UI + Character Dialogue

Run from a **fresh save** at 1280×720 first, then resize once to verify the stretch layout. Target: one compact fifteen-minute run plus a quick UI sweep.

## A. Global UI consistency
- [ ] HUD, Inventory, Creatures, Journal, Shop, Farm Crew, Storage, Build, Crafting, confirmations, reward cards, and Battle all read as one visual family.
- [ ] Primary panels use the same dark-jade/ink surface and gold-edged hierarchy.
- [ ] Buttons share the same corner radius, height, hover, pressed, disabled, and keyboard-focus treatment.
- [ ] Titles, kickers, body copy, and muted helper text have a consistent hierarchy.
- [ ] Item slots match the same button geometry rather than looking like a separate UI kit.
- [ ] Semantic colors remain readable: Attack / Speed / Guard, success, danger, and Ledger debt.
- [ ] No interactive screen uses an unexplained one-off text color or radically different panel shape.

## B. Character dialogue — Clash-style readability
- [ ] Talk to Mei, Ledger Clerk, Pao, and Tavi.
- [ ] Conversation appears as **large portrait on the left + speech panel on the right**.
- [ ] Portrait is crisp and readable at 1280×720.
- [ ] NPC role appears below the portrait.
- [ ] Speaker name is visually stronger than the dialogue body.
- [ ] Dialogue body is readable without covering the whole world view.
- [ ] Choice buttons use the same shared UI style and clearly show keyboard focus.
- [ ] First response is focused by default.
- [ ] `E` advances; `Esc` closes.
- [ ] Clicking while dialogue is open does not interact with the world behind it.
- [ ] Closing one conversation and opening another swaps the portrait/role correctly.

## C. HUD hierarchy
- [ ] World status, Quest tracker, Debt tracker, interaction prompt, menu hint, and hotbar do not overlap at 1280×720.
- [ ] Debt remains visually distinct through the Ledger accent without looking like a different game.
- [ ] Quest tracker and Debt tracker remain legible during Farm, Village, and Wilds traversal.
- [ ] Toast/status messages do not obscure dialogue or modal panels.

## D. Menu sweep
- [ ] `I` Inventory opens/closes cleanly; item slots and tooltips are consistent.
- [ ] `C` Creatures opens roster; Loadout and Evolution panels match roster styling.
- [ ] `J` Journal tabs, quest list, and detail panel match shared styling.
- [ ] `H` Farm Crew matches other menus and assignment buttons have obvious focus/selected states.
- [ ] Homestead Storage matches Inventory slot styling.
- [ ] Shop Buy/Sell tabs and item rows match the shared button system.
- [ ] Build/Crafting panels match the same title, helper, card, and close-button hierarchy.
- [ ] Confirmation and Fortune Reveal panels feel like modal variants of the same UI family.

## E. Battle UI
- [ ] Battle HUD still fits 1280×720 with no clipped panels.
- [ ] Command buttons and Action Picker share the same button geometry as overworld UI.
- [ ] Creature status cards and party strips share the same panel language.
- [ ] Attack / Speed / Guard semantic accents remain clear.
- [ ] Bond Wager remains visually related to battle and the Ledger/gambling identity.
- [ ] Victory / defeat / Bond / escape result screens remain readable and return correctly.

## F. Fifteen-minute route regression
- [ ] Inheritance reveal: **+1 FARM • +100,000 DEBT**.
- [ ] Ready Moonroot, farming, gathering, shipping, and shop still work.
- [ ] Farm ↔ Village ↔ Wilds transitions remain clean.
- [ ] Ledger starts **The Receipt That Bites Back**.
- [ ] Tavi → Brambleback Bond → Tavi pays **425**.
- [ ] Optional Lucky Bowl remains 55% / 20 stake / 80 payout / 10 stipend / one play.
- [ ] First Bond attempt remains free; maximum one paid retry remains 25.
- [ ] Farm Crew automation and storage delivery remain intact.
- [ ] 500-coin Ledger payment works and reveals **99,500** remaining.
- [ ] Play Again restarts cleanly.

## G. Phase 8 scope guard
- [ ] No new audio files, sound calls, music, or sound cues were added for Phase 8.
- [ ] No new particles, screen shake, combat VFX, reward VFX, or transition VFX were added for Phase 8.
- [ ] UI changes do not change economy, combat, Bond, farming, quest, wager, or debt rules.

## Acceptance
Phase 8 is accepted when every player-facing screen feels built from one UI kit, character conversations have the portrait-forward readability described above, and the complete Phase 3–7 fifteen-minute loop still works unchanged.
