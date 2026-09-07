# Project Hygiene

This repository contains reusable full-game systems plus a playable vertical slice. The **September 2026 canonical vertical-slice target** is defined in `docs/VERTICAL_SLICE_CANON.md`.

Older Phase documents remain useful implementation history, but they do not override the current playable-slice content contract when they conflict with `docs/VERTICAL_SLICE_CANON.md`.

## Engine version policy

- Supported editor/runtime version: **Godot 4.6.3**.
- `project.godot` declares `config/features=PackedStringArray("4.6")`; that records the 4.6 feature family, while CI pins the exact supported patch version to 4.6.3.
- Use Godot 4.6.3 for normal editor work, local play-tests, release verification, and CI parity.
- Do not open/save the project in an older or newer Godot version as part of normal development. Treat any engine upgrade as an intentional project-wide change: update `project.godot` as needed, README instructions, developer/release docs, and CI together.

## Content authority policy

For the playable vertical slice:

1. `docs/VERTICAL_SLICE_CANON.md` is the current demo-content authority.
2. Architecture/system docs define reusable system contracts unless the canonical slice explicitly requires a different content configuration.
3. Phase 2–8 docs are historical/reference material. Preserve useful reusable-system decisions, but do not use obsolete route, quest, debt, NPC, reward, or gambling values as current demo canon.
4. If implementation and canon differ during migration, document the gap and track it rather than silently changing the canon or pretending the old implementation is authoritative.
5. New tutorial/demo behavior should use reusable components, resources, services, signals, and shared UI. Do not fork parallel tutorial-only implementations when the existing system can be configured or extended cleanly.

## Canonical slice geography

The September 2026 demo target uses:

- **Heart Basin** as the playable region;
- **Lucky Acre** as the starting/farm location;
- a short **North Trail**;
- **Old Bell Crossing** as the exploration/discovery destination;
- **Whisperwood** as a teased next-region hook only.

Old Home Farm / Basin Village / Basin Wilds content may remain in the repository during migration or as reusable/full-game material, but it is not the canonical September 2026 demo route.

## Canonical slice content boundaries

Authored slice NPCs:

- Mei Fen
- Iru Vale
- Toma Reed

Canonical tutorial creatures:

- Brookfin — temporary Mei loan
- Sprigbit — first permanent capture

Canonical quest state:

- MQ00 completes
- MQ01 completes
- MQ02 begins

Canonical debt state after MQ00:

- Outstanding debt: **888,888 Marks**
- Payment Gate I: **500 / 5,000**
- The 500-Mark compliance credit is gate progress, not spendable currency.

## Keep

- Godot `.uid` sidecars for scripts/shaders.
- Asset `.import` sidecars that store source import settings.
- Reusable systems needed by the vertical slice or full game.
- Designer templates under `data/templates/`, using lowercase `snake_case` filenames.
- Data-driven content definitions, reusable scenes, shared UI components, services, and regression tests.
- Historical Phase docs when they still explain system design or migration history.

## Do not commit

- `.godot/` editor/import cache.
- exported builds, `.pck` files, logs, screenshots, IDE state, OS metadata, backups, temp files, or user saves.
- parallel implementations of existing gameplay systems.
- temporary duplicate content resources that differ only because the canonical migration was implemented by copy/paste rather than data/configuration.

## Do not make these required vertical-slice content

The canonical September 2026 slice explicitly does not require:

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
- permanent starter choice;
- fake instant crop growth;
- audio dependency;
- showcase-only VFX dependency.

Reusable systems for these features may remain in the repository. They simply must not become required dependencies of the canonical 15-minute showcase.

## Before handoff

1. Confirm Godot 4.6.3 is being used.
2. Confirm the tested content target is `docs/VERTICAL_SLICE_CANON.md`, not an obsolete Phase route.
3. Run `python3 tests/static_audit.py`.
4. Run the GitHub/Godot regression suite.
5. Complete the current canonical play-test/release checklist once CHO-20 has migrated those docs/tests.
6. Search for broken `res://` references, duplicate content IDs, obsolete demo-specific IDs, and accidental parallel implementations.
7. Confirm no `.godot/`, builds, logs, backups, temporary files, or user saves are committed.
8. Verify a clean save can enter and finish the canonical slice without developer intervention.
