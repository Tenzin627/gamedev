# Phase 7 — Gambling Identity + Payoff Presentation

Phase 7 does **not** add a casino system. It gives the existing fifteen-minute loop one coherent presentation language built around **chance, debt, wagers, stamps, and reveals**.

## Presentation rules

1. **Show the odds.** Risk is playful, not deceptive. Lucky Bowl displays its 55% chance, stake, payout, and one-play limit before currency is spent. Battle Bond continues to display its calculated Bond chance.
2. **One meaningful throw.** Lucky Bowl is one-shot. Battle Bond has one free attempt and at most one paid retry. No repeatable gambling grind is part of this slice.
3. **Ledger = pressure.** Debt uses collection numbers, OPEN/READY/PAID stamps, wallet shortfall, and a funding bar.
4. **Fortune reveal = payoff.** Main-quest rewards, the Lucky Bowl result, and the opening inheritance use the same reveal-card language.
5. **Gambling is flavor around the core loop.** Farming, exploration, battle, Bond, creature work, and quests remain the game; gambling gives them personality and risk/reward decisions.

## Lucky Bowl contract

- Stake: **20 coins**
- Displayed win chance: **55%**
- Bowl payout on win: **80 coins**
- Pao research stipend on quest completion: **10 coins**
- Loss net: **−10 coins**
- Win net: **+70 coins**
- Plays per session: **1**

The wager is fully optional. The normal farm + main-quest route can still fund the 500-coin collection after one paid Bond retry.

## Battle Bond presentation

The mechanics are unchanged from Phase 4:

- one free Bond attempt;
- chance improves as the wild creature is weakened;
- one paid retry costs 25 coins;
- no further retries.

Phase 7 presents this as **BOND WAGER → free throw → TEMPT FATE → fortune settled/spent** with a visible chance bar and wallet/cost information.

## Ledger presentation

The persistent HUD shows:

- `THE LEDGER • COLLECTION 01`
- `OPEN`, `READY`, or `PAID` stamp state;
- 500-coin due amount;
- current wallet and shortfall;
- a funds-ready progress bar;
- 99,500 remaining after payment.

The payment desk uses explicit confirmation before taking currency and states the debt balance before and after the stamp.

## Reveal surfaces

`FortuneRevealPanel` is a reusable HUD surface for:

- inheritance reveal;
- quest payout reveal;
- Lucky Bowl win/loss result;
- future compact reward/fortune reveals.

It is presentation-only. It does not own quest, economy, debt, or battle rules.

## Scope deliberately excluded

- casino building;
- slot machines or repeatable tables;
- real-money systems;
- purchasable currency;
- loot-box store;
- gambling progression tree;
- repeatable wagering grind;
- advanced reward-wheel systems.

Those are not needed to prove Lung Sa's identity in a fifteen-minute vertical slice.
