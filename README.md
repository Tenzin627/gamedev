# Lung Sa — 15-Minute Vertical Slice

Current checkpoint: **Phase 8 — Unified UI + Character Dialogue Polish** (`0.90.0-phase8-ui-dialogue-polish`).

Demo route:

**Home Farm ↔ Basin Village ↔ Basin Wilds**

Current playable loop:

**inherit farm + debt → farm / gather / sell → Ledger → funny village job → Wilds battle / Bond → 425-coin payout → optional transparent wager → pay 500 → reveal 99,500 remaining**

Phase 8 keeps that complete loop intact and unifies the presentation through one global theme and one shared UI style contract. Character conversations now use a large portrait + speech-panel layout inspired by the readability of Clash of Clans-style character dialogue, while retaining Lung Sa's jade/ink/ledger identity. **No audio or VFX are added in Phase 8.**

## Engine version

Lung Sa is supported on **Godot 4.6.3**. `project.godot` declares the Godot 4.6 feature set, while CI pins the exact supported patch version to 4.6.3. Use Godot 4.6.3 for editor work, local play-tests, and release verification unless the project version policy is intentionally updated everywhere together.

## Start
Open `project.godot` in Godot 4.6.3 and run the project. Main scene: `world/central_basin/zones/demo_farm.tscn`.

## Controls
- WASD / arrows — Move
- E / Enter — Interact
- F — Selected tool / farm action
- 1–8 — Hotbar
- I — Inventory
- H — Farm Crew on Home Farm
- J — Journal
- Esc — Close / back
- Battle menus — mouse or keyboard/controller UI navigation

## Acceptance
Use `docs/PLAYTEST.md`. Phase 8 UI rules are documented in `docs/PHASE8_UI_DIALOGUE_POLISH.md`.

## Source-of-truth docs
- `docs/ARCHITECTURE.md`
- `docs/DESIGNER_WORKFLOW.md`
- `docs/ART_ASSETS.md`
- `docs/PHASE2_ROUTE.md`
- `docs/PHASE3_ECONOMY.md`
- `docs/PHASE4_COMBAT_BOND.md`
- `docs/PHASE5_FARM_AUTOMATION.md`
- `docs/PHASE6_STORY_DEBT_QUEST.md`
- `docs/PHASE7_GAMBLING_IDENTITY.md`
- `docs/PHASE8_UI_DIALOGUE_POLISH.md`
- `docs/PLAYTEST.md`
- `docs/PROJECT_HYGIENE.md`
- `docs/RELEASE_CHECKLIST.md`
