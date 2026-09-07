# Phase 4 — Creature Combat + Battle Bond

Phase 4 proves the creature-facing half of the 15-minute demo without adding story orchestration.

## Active Demo Roster

| Creature | Archetype | Demo role |
| --- | --- | --- |
| Mossback | Guard | Starter; survives Attack creatures well |
| Rillfin | Speed | Starter; demonstrates switching and priority |
| Brambleback | Attack | Wild demo target; completes the archetype triangle |

Only these three species are in the active Phase 4 Wilds encounter pool. Evolution remains outside the demo flow.

## Battle Contract

Wild creature interaction always enters the dedicated turn-based battle scene.

Player commands are:

- **Moves** — use one equipped creature technique.
- **Item** — use a carried battle consumable.
- **Switch** — change the active creature; then wait one full player turn before switching again.
- **Escape** — leave a wild encounter and preserve current party HP.
- **Bond** — one standard attempt per wild encounter.

There is no timing minigame.

## Archetype Rule

**Attack > Speed > Guard > Attack**

Advantage applies a 1.25× damage multiplier. Disadvantage applies 0.80×. The HUD shows the current active matchup so the player does not need to memorize the triangle before experimenting.

## Bond Contract

Bond chance comes from the creature's base chance plus a bonus for weakening it.

For this vertical slice:

1. The player gets **one free standard Bond attempt**.
2. If it fails, the wild creature gets its normal response for that round.
3. On the next player turn, the player may choose **TEMPT FATE** once for **25 currency**.
4. If the paid retry fails, Bond is exhausted for that encounter.
5. A successful Bond ends the encounter immediately and adds the creature to the collection; if the active party has room, it joins the party automatically.

This is deliberately a small gambling-flavored decision, not a casino subsystem.

## Battle Outcomes

- **Victory:** wild spawn is cleared, currency/growth rewards are committed, current party HP persists, then the player returns to the Wilds.
- **Bond:** wild spawn is cleared, captured creature is stored, current party HP persists, then the player returns to the Wilds.
- **Escape:** wild spawn remains, current party HP persists, then the player returns to the Wilds.
- **Defeat:** party is fully restored and the player returns to the Home Farm.

Every outcome uses an explicit result overlay before scene return so completion never looks like a crash.
