# Lung Sa — Art & Animation Assets

## Ownership rule

**Tile art is for TileSets. Standalone gameplay objects use standalone assets.**

Do not recreate mixed-purpose atlases containing unrelated NPCs, creatures, tools, icons and props. Definitions/scenes should point directly to the visual they own.

## Folders

- `art/characters/player/` — player facing sprites.
- `art/characters/npcs/` — NPC sprites.
- `art/creatures/` — creature source art.
- `art/items/` — tool, material, food, consumable, farming and plant inventory art.
- `art/world/props/` — standalone props/interactables.
- `art/world/buildings/` — standalone buildings.
- `art/tiles/` — TileSet source art.
- `art/farming/` — farm grid/crop-stage tile art.
- `art/terrain/` — terrain TileSet sources.
- `art/audio/` — audio sources.

## Creature overworld animation

Creature species attach a `SpriteFrames` resource through `world_sprite_frames`. Use these names consistently:

`idle_n/e/s/w` and `walk_n/e/s/w`.

A practical source-sheet convention is south, west, east, north rows with 3–6 walk frames per direction. Idle may use one frame or a short breathing loop. The runtime depends on animation names, not source-sheet layout.

The same directional animation resource is used by wild and farm-working creatures. Battle presentation can continue using the species static texture separately.

## Visual consistency

World grid: **64×64 px**. Keep perspective, grounding, line weight, shadow logic, palette and apparent scale consistent across assets. Prefer explicit visual ownership over generic lookup helpers.
