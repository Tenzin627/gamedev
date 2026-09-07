# Project Hygiene

This repository is the Phase 3 farm/resource/economy baseline for the 15-minute Lung Sa demo.

## Engine version policy

- Supported editor/runtime version: **Godot 4.6.3**.
- `project.godot` declares `config/features=PackedStringArray("4.6")`; that records the 4.6 feature family, while CI pins the exact supported patch version to 4.6.3.
- Use Godot 4.6.3 for normal editor work, local play-tests, release verification, and CI parity.
- Do not open/save the project in an older or newer Godot version as part of normal development. Treat any engine upgrade as an intentional project-wide change: update `project.godot` as needed, README instructions, developer/release docs, and CI together.

## Keep

- Godot `.uid` sidecars for scripts/shaders.
- Asset `.import` sidecars that store source import settings.
- Reusable systems needed by the later demo phases.
- Designer templates under `data/templates/`, using lowercase `snake_case` filenames.
- Exactly three authored Central Basin demo zone scenes: `demo_farm`, `demo_village`, and `demo_wilds`.

## Do not commit

- `.godot/` editor/import cache.
- exported builds, `.pck` files, logs, screenshots, IDE state, OS metadata, backups, temp files, or user saves.
- retired West Meadow / Riverbend authored route content.
- parallel implementations of existing gameplay systems.
- final story/debt/gambling content before its implementation phase unless a temporary placeholder is explicitly tagged as such.

## Map ownership rule

- Home Farm owns farm-management systems and has no wild spawning.
- Basin Village owns social/service anchors and has no wild spawning.
- Home Farm owns the tiny tutorial gathering set plus farming/storage/economy teaching.
- Basin Wilds owns the richer encounter, gathering, and discovery space.
- Farm and Wilds never connect directly in the 15-minute route.

## Before handoff

1. Confirm Godot 4.6.3 is being used.
2. Run `python3 tests/static_audit.py`.
3. Run the Godot regression scenes listed in `docs/RELEASE_CHECKLIST.md`.
4. Complete `docs/PLAYTEST.md` in both directions.
5. Search for broken `res://` references, duplicate content IDs, and retired zone IDs.
6. Confirm no `.godot/`, builds, logs, backups, or temporary files are inside the archive.
