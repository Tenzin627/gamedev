# Lung Sa — 15-Minute Vertical Slice

## Canonical target

The playable vertical slice is now governed by the **September 2026 Vertical Slice Content Bible** and the repository implementation contract in `docs/VERTICAL_SLICE_CANON.md`.

Canonical route:

**Lucky Acre → North Trail → Old Bell Crossing**

Canonical showcase loop:

**win Lucky Acre → make three plots usable → borrow Brookfin → capture Sprigbit → assign Sprigbit to the farm → discover 888,888-Mark debt + Black Ledger → follow the old water record → register Old Bell Crossing → optional Toma chance/work interaction → MQ02 begins → Whisperwood hook**

The target is roughly **15 minutes** (12–18 minute acceptable range). The authored slice uses only **Mei Fen, Iru Vale, and Toma Reed**, has one permanent capture (**Sprigbit**), completes **MQ00 + MQ01**, begins **MQ02**, and does not require audio or showcase-only VFX.

## Migration status

The repository still contains the earlier Phase 8 playable baseline while the canonical September 2026 slice is migrated in. Treat the old Home Farm / Basin Village / Basin Wilds route, old demo debt/economy values, and older Phase-specific quest content as **implementation history**, not current content authority.

Migration is tracked under Linear **CHO-12** and its child issues. Reusable systems from the old slice should be preserved where they remain useful; demo-specific content should be replaced through the existing modular/data-driven architecture rather than duplicated as tutorial-only code.

## Engine version

Lung Sa is supported on **Godot 4.6.3**. `project.godot` declares the Godot 4.6 feature set, while CI pins the exact supported patch version to 4.6.3. Use Godot 4.6.3 for editor work, local play-tests, and release verification unless the project version policy is intentionally updated everywhere together.

## Start

Open `project.godot` in Godot 4.6.3 and run the project.

Current implementation main scene: `world/central_basin/zones/demo_farm.tscn`.

That scene remains the executable migration baseline until CHO-12 replaces the playable route with the canonical Lucky Acre → North Trail → Old Bell Crossing flow.

## Controls

Current baseline controls:

- WASD / arrows — Move
- E / Enter — Interact
- F — Selected tool / farm action
- 1–8 — Hotbar direct selection
- I — Inventory
- H — Farm/crew panel where available
- J — Journal
- Esc — Close / back
- Battle menus — mouse or keyboard/controller UI navigation

The canonical fresh-save hotbar starts with four tools in slots 1–4: Field Hoe, Watering Can, Trail Axe, Stone Pick. Input/config cleanup for the larger configurable hotbar remains tracked separately.

## Acceptance

The canonical content contract is `docs/VERTICAL_SLICE_CANON.md`.

A slice build is not accepted merely because the legacy Phase 8 regression passes. Canonical acceptance requires the September 2026 route/state/story conditions plus green GitHub CI and a clean fresh-save play-through.

## Source of truth

Current authority order for the playable vertical slice:

1. `docs/VERTICAL_SLICE_CANON.md` — **canonical September 2026 demo content contract**
2. `docs/ARCHITECTURE.md` — reusable system architecture
3. `docs/DESIGNER_WORKFLOW.md` — content-authoring workflow
4. `docs/PROJECT_HYGIENE.md` — repository/version/content hygiene
5. `docs/RELEASE_CHECKLIST.md` and `docs/PLAYTEST.md` — release/play-test checks; these are being migrated to the new canon under CHO-20

Historical/reference docs that must not override the current vertical-slice canon:

- `docs/PHASE2_ROUTE.md`
- `docs/PHASE3_ECONOMY.md`
- `docs/PHASE4_COMBAT_BOND.md`
- `docs/PHASE5_FARM_AUTOMATION.md`
- `docs/PHASE6_STORY_DEBT_QUEST.md`
- `docs/PHASE7_GAMBLING_IDENTITY.md`
- `docs/PHASE8_UI_DIALOGUE_POLISH.md`

Keep useful reusable-system decisions from those documents, but resolve demo-content conflicts in favor of `docs/VERTICAL_SLICE_CANON.md`.
