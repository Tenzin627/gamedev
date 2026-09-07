# Lung Sa — Canonical Vertical Slice

**Canonical content version:** September 2026 / v1.0  
**Target playtime:** 12–18 minutes; authored target ~15 minutes  
**Engine:** Godot 4.6.3

## Authority

This document is the repository implementation contract for the September 2026 **Lung Sa — Vertical Slice — Full Content Bible**.

When demo-specific content in older Phase documents conflicts with this file, **this file wins for the playable vertical slice**. Older Phase documents remain historical/reference material for reusable systems, architecture, presentation work, and full-game ideas.

Do not rewrite reusable systems as one-off tutorial code just to match the slice. Keep systems modular and data-driven; change the demo content/configuration that uses them.

## Slice promise

In one short showcase, the player should understand Lung Sa by:

1. arriving at a farm they somehow won;
2. discovering the farm carries an absurd debt;
3. farming by hand with four readable tools;
4. borrowing Brookfin to learn the battle triangle;
5. capturing Sprigbit as the first permanent creature;
6. assigning Sprigbit to Lucky Acre and watching it choose useful farm work automatically;
7. following old water records to Old Bell Crossing;
8. seeing the Black Ledger accept evidence the official record rejects;
9. encountering optional gambling/comedy through Toma without a progression lock; and
10. ending on a Whisperwood hook.

## Canonical counts

- **Playable region:** Heart Basin
- **Teased region:** Whisperwood
- **Playable locations:** Lucky Acre, North Trail, Old Bell Crossing
- **Authored NPCs:** Mei Fen, Iru Vale, Toma Reed — no filler NPCs in the slice
- **Creature families shown:** Rillip line through Brookfin; Sprigbit line through Sprigbit
- **Permanent captures:** 1 — Sprigbit
- **Main quests:** MQ00 + MQ01 complete; MQ02 begins
- **Optional side interactions:** 1 — Toma chance/work encounter
- **Tools:** 4
- **Crop:** 1 — Bellbean
- **Discovery:** 1 — Old Bell Crossing

## Canonical 15-minute flow

| Time | Beat | Required player action | Payoff |
| --- | --- | --- | --- |
| 0:00–1:30 | Lucky Acre Arrival | Move, inspect winning letter/deed, speak with Mei | Ownership joke, HUD, MQ00 |
| 1:30–4:00 | Make It Usable | Clear Young Willow + River Rock; till 3; plant 3; water 3 | Tools, inventory/hotbar, farming |
| 4:00–6:15 | Sprigbit in the Beans | Mei lends Brookfin; tutorial battle; capture Sprigbit | Battle triangle, capture, first creature |
| 6:15–8:00 | Put It to Work | Assign Sprigbit to Lucky Acre | Visible creature autonomy |
| 8:00–10:00 | Collection Notice | Iru arrives; debt + Black Ledger reveal | Narrative hook, Debt Ledger, MQ01 |
| 10:00–12:40 | Old Bell Crossing | Clear Thornfall; inspect 2 water markers; listen to bell | Tool gate, exploration, Discovery |
| 12:40–14:05 | Toma's Excellent Financial Advice | Optional Odd/Even wager or guaranteed Work route | Gambling/comedy without progression lock |
| 14:05–15:00 | The Ledger Writes Back | Read ledger evidence; MQ01 resolves; MQ02 begins | Whisperwood hook and clean end state |

No mandatory dialogue exchange should exceed roughly six clicks. The optional Toma interaction must not be required to reach the end hook.

## Fresh-save starting state

- Spawn: **Lucky Acre — farmhouse porch**
- Marks: **120**
- Debt: **888,888 Marks**
- Payment Gate I: **0 / 5,000 Marks** before the MQ00 compliance credit
- Permanent party: **empty**
- Temporary battle partner: none until Mei lends Brookfin
- Active quest: **MQ00 — Congratulations, You Owe Us**

### Starting inventory

- Field Hoe ×1
- Watering Can ×1
- Trail Axe ×1
- Stone Pick ×1
- Bellbean Seed ×3
- Field Snack ×2
- Lucky Acre Deed ×1

### Default hotbar

1. Field Hoe
2. Watering Can
3. Trail Axe
4. Stone Pick

Remaining slots are empty. Inventory/hotbar slots use the reusable shared slot system; no tutorial-only slot widgets.

## World contract

### Lucky Acre

Required content:

- farmhouse porch/spawn;
- mailbox with Winning Letter + deed inspection;
- locked house façade for the slice;
- starter field with three target plots;
- one Young Willow and one River Rock with clear collision/state;
- tool shed + Farm Assignment Post;
- irrigation edge;
- north gate;
- designer-defined Farm Work Zone.

Young Willow and River Rock must remain physical blockers until cleared. Visual state, collision removal, and resource award happen together.

### North Trail

- forkless readable route;
- Water Marker 01;
- single Thornfall gate cleared by Trail Axe in at most two swings;
- Water Marker 02;
- reveal of Old Bell Crossing.

### Old Bell Crossing

- Old Bell — primary MQ01 interaction; **Listen** must work without an audio dependency;
- Crossing Plaque;
- Toma's blanket/table after Discovery;
- Willowmarket boundary tease with a readable boundary message rather than an invisible wall.

## Cast

### Mei Fen

Neighbor/co-op farmer and practical tutorial anchor. Warm, busy, direct. She lends Brookfin and teaches farming/assignment without becoming a detached tutorial narrator.

### Iru Vale

Junior Accord Office clerk. Procedure-first, visibly anxious. Delivers the debt notice and recognizes the Black Ledger.

### Toma Reed

Traveling cook and amateur chance-game enthusiast. Friendly hustler. His chance content is optional and always has a guaranteed work alternative.

## MQ00 — Congratulations, You Owe Us

Purpose: ownership → tools → farming → first battle/capture → autonomous creature work → debt reveal.

Required objectives:

1. Open the winning letter.
2. Talk to Mei.
3. Clear the starter field: Young Willow 0/1; River Rock 0/1.
4. Prepare the field: Till 0/3; Plant Bellbeans 0/3; Water 0/3.
5. Deal with the creature in the field.
6. Assign Sprigbit to Lucky Acre.
7. Speak with the Accord Office clerk.

MQ00 completes during the Iru/Black Ledger reveal.

Reward/state change:

- Ledger Case I;
- **+500 Mark compliance credit** toward Payment Gate I — this is **not spendable cash**;
- Debt Ledger UI unlocked;
- MQ01 starts immediately.

## Tutorial battle — Brookfin vs. Sprigbit

The battle teaches exactly:

**Attack > Speed > Guard > Attack**

There is **no timing/QTE input**.

### Brookfin — temporary Mei loan

- Speed archetype
- Lv. 6 equivalent
- HP 30 / ATK 7 / SPD 11 / GRD 6
- Moves: Quickstep, Reed Skip, Water Nip, River Set
- Trait: Courier

### Wild Sprigbit

- Guard archetype
- Lv. 3 equivalent
- HP 24 / ATK 5 / SPD 4 / GRD 9
- Moves: Nibble, Leaf Flick, Brace

### Authored tutorial beats

- Turn 1: Sprigbit shows Guard/Brace; highlight Quickstep — Speed beats Guard.
- Turn 2: Sprigbit shows Attack/Nibble; highlight River Set — Guard beats Attack.
- Turn 3: Sprigbit becomes Capture Ready.
- First eligible tutorial capture succeeds so RNG cannot break the showcase.

Fallbacks must remain explicit and recoverable:

- defeat → DEFEAT result + return to Lucky Acre; encounter remains available;
- Sprigbit defeated without capture → explicit fled result; encounter retriggers once;
- capture → explicit CAPTURE SUCCESSFUL result + trait choice + Continue.

After capture, Brookfin returns to Mei. Demo Sprigbit may receive Root Hold early as a vertical-slice content exception.

## Sprigbit capture result

- Species label: Verdant Grazer
- Archetype: Guard
- Rarity: Common
- Farm work: Planting → Watering → Light Harvesting
- Permanent demo moves: Nibble / Leaf Flick / Brace / Root Hold

### Trait choice — exactly one

- **Thick Hide** — reduces the first damaging hit after entering battle.
- **Workhorse** — heavy/routine farm jobs complete faster than the normal baseline.

The choice is permanent for that creature and persists through save/load.

## Farm assignment and autonomous work

The decision is **assign Sprigbit to Lucky Acre**, not assign it to an individual chore.

After confirmation:

- Sprigbit chooses a useful valid farm task automatically;
- preferred showcase behavior is watering a deliberately re-dried tutorial plot or planting a designated helper plot;
- first visible task should read clearly within roughly 5–8 seconds;
- if no work exists, Sprigbit visibly inspects/wanders and reports **No farm work available** instead of appearing broken.

Beginning/completing the first visible autonomous task triggers Iru's arrival.

## Debt and Black Ledger

Iru reveals:

- Outstanding debt: **888,888 Marks**
- Payment Gate I: **5,000 Marks**

After MQ00:

- Debt Ledger outstanding debt: **888,888**
- Payment Gate I: **500 / 5,000**
- Compliance credit: **+500 — Site claim verified**

The 500 is gate progress, not liquid Marks.

The Black Ledger is the story bridge: it accepts lived/local evidence that the official record rejects.

## MQ01 — The Bell That Isn't Decorative

Required objectives:

1. Clear the Thornfall on the north trail.
2. Follow Water Marker 01 and 02.
3. Listen to the Old Bell.
4. Read the new Black Ledger entry.

Old Bell Crossing is the slice's one Discovery. The Discovery popup must explain at least one concrete consequence, including Explorer progress +1 and the Bellkeeper record.

MQ01 reward/state:

- Bellkeeper Songbook — Page 1;
- Old Bell Crossing Discovery registered;
- MQ02 unlocked.

## Toma optional interaction

**A Perfectly Sensible Investment** unlocks after Old Bell Crossing Discovery.

- Wager: 10 Marks
- Choose Odd or Even
- Toma shakes three bellstones; total pips determine result
- Win: **+20 Marks net** + Bent Bell Token
- Lose: **-10 Marks** + Bent Bell Token
- Decline is valid
- Work route: carry a stone crate; **+10 Marks guaranteed**; same side-content resolution
- Once only in the vertical slice

Gambling is optional world flavor. It never blocks progression and has no premium/real-money dependency.

## MQ02 — A Payment of Questionable Origin

MQ02 begins but does not complete in the slice.

- Objective: Pay 5,000 Marks toward the debt
- Slice starting progress: **500 / 5,000**
- Valid long-term routes include farming, selling, work, and optional wagers; no single route is required.

## Final Whisperwood hook

The final Black Ledger beat names **WHISPERWOOD** and a permit/Root Court conflict.

End state must clearly communicate:

- LUCKY ACRE CLAIMED
- SPRIGBIT CAPTURED
- OLD BELL CROSSING RECORDED
- Debt remaining: 888,888 Marks
- Payment Gate I: 500 / 5,000
- Next: Whisperwood

The demo ends cleanly after this state; it must never look frozen or unfinished.

## UI contract

Required surfaces:

- HUD: player status, compact quest tracker, hotbar, interaction prompt
- reusable inventory/hotbar slot surface
- portrait dialogue + choices
- Battle HUD with move framework and relevant commands
- explicit Battle Result / Defeat / Capture Success screens
- two-card Trait Choice
- Farm Assignment
- Discovery popup
- Debt Ledger
- Demo End card

Presentation remains uniform and portrait-driven. No required audio/VFX content is part of slice acceptance.

## Explicitly out of scope for the canonical slice

Do not add these as required vertical-slice content:

- creature evolution or breeding;
- seasons or weather production modifiers;
- crafting tree;
- building expansion;
- full shops;
- tournament PvP or multiplayer;
- fast-travel network;
- advanced cooking;
- dungeon/boss content;
- multi-region traversal;
- permanent starter-choice system;
- fake instant crop-growth requirement;
- audio dependency;
- showcase-only VFX dependency.

Reusable full-game systems may remain in the repository, but the canonical demo must not require them.

## Acceptance checklist

The slice is not done until all are true:

- [ ] Clean save can finish without developer intervention.
- [ ] HUD spawns without overlap.
- [ ] Mei is available at the correct objective.
- [ ] Every inventory/hotbar slot uses the reusable slot scene/system.
- [ ] Field Hoe, Watering Can, Trail Axe, and Stone Pick work on intended targets and reject wrong targets clearly.
- [ ] Young Willow, River Rock, and Thornfall collision matches visual state.
- [ ] Battle contains no timing/QTE.
- [ ] Triangle is clearly communicated as Attack > Speed > Guard > Attack.
- [ ] Capture can be used once; tutorial eligible capture succeeds; fallbacks exist.
- [ ] Victory, defeat, and capture always end in explicit result UI with Continue.
- [ ] Trait choice is exactly Thick Hide vs Workhorse and persists.
- [ ] Sprigbit is assigned to the farm, not a specific chore.
- [ ] Sprigbit visibly performs useful autonomous work or reports No farm work available.
- [ ] Debt Ledger shows 888,888 and 500 / 5,000 after MQ00.
- [ ] Quest tracker always communicates the next required action.
- [ ] Old Bell Listen works without audio.
- [ ] Discovery popup explains a concrete consequence and registers Old Bell Crossing.
- [ ] Toma's wager is optional and has a guaranteed work alternative.
- [ ] Only Mei, Iru, and Toma appear as authored slice NPCs.
- [ ] Final Ledger hook names Whisperwood and the demo ends cleanly.

## Migration note

The repository currently contains an older Phase 8 playable slice. Migration to this canon is tracked in Linear under CHO-12 and its child issues. Until that migration is complete, distinguish **current implementation** from **canonical target** in reviews and documentation rather than silently treating old demo content as authoritative.
