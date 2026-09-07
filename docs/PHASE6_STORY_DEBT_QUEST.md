# Phase 6 — Story, Debt & Quest Loop

Phase 6 wraps the existing farming, selling, combat, Bond, and farm-automation systems in the fifteen-minute demo's narrative spine.

## Narrative Contract

The player won the Home Farm through a questionable wager and inherited **100,000 coins of Ledger debt** with it.

The active demo collection is:

- **First collection due:** 500 coins
- **Outstanding total before payment:** 100,000 coins
- **Outstanding total after payment:** 99,500 coins

Debt is runtime state owned by `DebtService`; quests do not directly own the wallet or debt balance.

## Main Demo Quest

**The Receipt That Bites Back**

1. Speak with the Ledger Clerk in Basin Village.
2. The Clerk starts the quest and points the player to Tavi.
3. Speak with Tavi.
4. Tavi explains that a Brambleback ate his rent receipt and now counts as the Ledger's legal witness.
5. Travel to Basin Wilds.
6. Bond a Brambleback using the existing Phase 4 Battle Bond flow.
7. Return to Tavi with a Brambleback owned.
8. Tavi resolves the paperwork and the quest completes for **425 coins**.

The quest uses authored quest objectives and dialogue conditions/actions. Combat remains unaware of this specific story; it only reports the generic `BOND_CREATURE` event already used by `QuestService`.

## Optional Wager Side Quest

**Pao's Sure Thing**

- Speak with Pao to accept the one-shot side quest.
- Use the Lucky Bowl beside the Ledger office.
- Stake: **20 coins**.
- Win chance: **55%**.
- Win payout: **80 coins** before the quest reward.
- The wager can be played only once per session.
- Completing the wager once, win or lose, completes the side quest for **35 coins**.

The wager is deliberately small. It demonstrates the game's chance/debt tone without becoming a repeatable money farm or a required progression gate.

## Debt Payoff

The payment desk beside the Ledger Clerk reads the actual wallet state.

- It refuses partial payment.
- It requires the full 500-coin first collection.
- Paying subtracts 500 currency through `DebtService`.
- The first-payment world flag is set only after successful payment.
- The demo completion panel then reveals the remaining **99,500** balance.

## Economy Intent

The main quest reward is 425 coins by design.

With the Phase 3 conservative farm/resource loop (~63 coins) and the 40-coin starting wallet:

- 40 start + 63 loop + 425 quest = **528**
- one 25-coin paid Bond retry still leaves **503**

This means normal play reaches the 500 collection without requiring the optional wager, while careless spending or skipped selling can create a small additional money problem.

## UI Contract

Every normal HUD contains a compact **THE LEDGER** debt widget showing:

- current collection progress / due amount
- current carried currency
- remaining total after payment

The quest tracker remains data-driven through the active Story Chain. After the main quest is complete but before debt payment, the Story Chain's `post_quest_hint` directs the player back to the Ledger payment desk.

## Scope Boundaries

Phase 6 does not add:

- a casino
- repeatable gambling economy
- full Ledger mystery exposition
- regional factions
- branching main story consequences
- advanced cutscenes
- final presentation/VFX treatment

Those are later-content or Phase 7/8 concerns. Phase 6 only proves that the existing gameplay systems now have a clear comedic reason to be used.
