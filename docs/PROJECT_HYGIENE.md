# Project Hygiene

This repository is the Phase 3 farm/resource/economy baseline for the 15-minute Lung Sa demo.

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

1. Run `python3 tests/static_audit.py`.
2. Run the Godot regression scenes listed in `docs/RELEASE_CHECKLIST.md`.
3. Complete `docs/PLAYTEST.md` in both directions.
4. Search for broken `res://` references, duplicate content IDs, and retired zone IDs.
5. Confirm no `.godot/`, builds, logs, backups, or temporary files are inside the archive.
