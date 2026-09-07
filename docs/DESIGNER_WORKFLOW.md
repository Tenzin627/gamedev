# Lung Sa — Designer Workflow

## Default workflow

**Create data → paint repeated content or place a reusable scene → edit Inspector → validate → play-test.**

`ContentDB` automatically discovers valid `ContentDefinition` `.tres` files under `res://data/`; `res://data/templates/` is ignored at runtime.

Use the **Lung Sa Designer** dock to create supported content Resources, generate linked starter bundles, place world objects, inspect dependencies, delete unused content safely, validate the project and launch focused play-tests.

## Low-code workflow

1. Choose one of the 22 content presets and click **Create from Preset**.
2. Give the file a useful name. The dock generates a unique content ID automatically.
3. Fill the plain Inspector fields and assign art/resources.
4. Place the corresponding reusable scene or paint the appropriate TileMap layer.
5. Click **Validate Content** and then **Play-test Current Scene**.

For a connected starting point, use:

- **Create NPC + Dialogue + Quest** — creates three editable resources and links the NPC to its dialogue.
- **Create Region + Zone + Story** — creates and links the region, initial zone and story-chain resources. Assign scene paths and story steps afterward.

## Duplicate, inspect and remove

Select a content resource in the FileSystem/Inspector, then use:

- **Duplicate Selected** to create a variant with a new unique ID.
- **Show Dependencies** to list every scene, resource or script that refers to it.
- **Safe Delete Selected** to delete only when no references remain.
- **Open Content Folder** to jump to related resources.

Safe Delete intentionally refuses referenced content. Remove or replace those references first, validate, and then delete.

## Repeated world content

Use TileMapLayers instead of one scene per ordinary plant/tree/rock.

- `StaticProps` — repeated non-stateful props.
- `Forage` — collectible plants.
- `ResourceTiles` — common tool-gathered resources.

For a forage tile, set TileSet custom data:
- `content_kind = forage`
- `content_id = <PlantDefinition ID>`
- unique `tile_key`
- optional prompt/radius/priority

For a gatherable tile, set:
- `content_kind = gatherable`
- `content_id = <GatherableResourceDefinition ID>`
- unique live `tile_key`
- `depleted_tile_key`
- prompt/radius/priority

Author collision on the TileSet tile. The generic tile-content system handles interaction, drops, persistence, depletion and respawn.

## Farm

Open `world/shared/farming/farm_plot_visual.tscn`.

- Paint `FarmBuildArea` to define the **only space where farm plots may ever be placed**. This is the designer boundary, not player ownership.
- Paint `StarterPlots` to choose exactly which cells are already owned in a fresh game.
- Do **not** paint runtime state into `FarmOwnedPlots`, `FarmSoil`, or `FarmCrops`; gameplay owns those layers.
- Move the entire farm by moving the farm scene node.

Farmer progression controls capacity. Level 1 unlocks 1 bonus plot, level 2 unlocks 2 more, then 3, 4, and 5. The player places those unlocked cells freely inside `FarmBuildArea` from the Build menu. No fixed expansion scene or code edit is required.

## Habitats

Habitats remain scenes because they define behavioral spawn areas. Select a `HabitatArea2D`, edit its definition/size in Inspector, and resize/reposition it visually in the editor. Individual wild creatures are runtime actors spawned from habitat data.

## Creatures

Species presentation is definition-owned:
- `world_texture` — static fallback / battle presentation.
- `world_sprite_frames` — overworld animation.
- `world_visual_scale` / `world_visual_offset` — grounding.

Standard overworld animation names:
- `idle_n`, `idle_e`, `idle_s`, `idle_w`
- `walk_n`, `walk_e`, `walk_s`, `walk_w`

Wild and farm-working creatures choose direction automatically from movement. Replace SpriteFrames content; do not change movement code to change animation art.

## Standalone objects

Use scenes for NPCs, creatures, shops, stations, entrances, waymarks, story landmarks, unique chests/doors and other objects with independent behavior/state. Their visual ownership should be explicit in the scene or definition Inspector.

## UI

If you need to judge or change a UI element visually, its static hierarchy belongs in `.tscn`.

- edit layout, anchors, margins, containers and stable labels/buttons in the scene;
- edit shared baseline styling in `ui/shared/lung_sa_theme.tres`;
- let code populate variable lists such as inventory slots, creature rows, shop stock, move choices and quest entries;
- keep stable node names referenced by scripts.

Do not create a whole panel from `PanelContainer.new()`, `VBoxContainer.new()`, etc. Dynamic repeated entries are allowed.

## Art ownership

Standalone characters, creatures, items, buildings and unique props reference standalone images directly. TileSet art is reserved for content painted through TileMapLayers. Do not restore mixed-purpose world/basin sprite atlases or ID-to-art guessing code.

## Validation

Inside Godot, use **Validate Content Files** in the Designer dock.

From a terminal:

```bash
python tests/static_audit.py
```

Then run `tests/health_runner.tscn`, `tests/vertical_slice_regression.tscn`, and `tests/inventory_transfer_test.tscn` in Godot before treating a checkpoint as runtime-clean. The dock can open the tests folder and play the current test scene.

## Add content to the Build menu

### Building / decoration / creature habitat
1. Duplicate a `BuildingDefinition` in `data/building/`.
2. Set `content_id`, name, description, `world_texture`, footprint and costs.
3. Set `menu_category` to `building`, `decoration`, or `habitat`.
4. Set `menu_order` for where it appears.
5. Run the game and press **B**. No build-menu code edit is required.

### Farm plots
1. Open `FarmPlotVisual.tscn`.
2. Paint `FarmBuildArea` to enlarge/reduce the legal farm-placement space.
3. Paint `StarterPlots` only for plots the player owns at a fresh start.
4. Farmer level automatically unlocks 1–5 additional plots per level; the Build menu shows how many are available to place.

No expansion IDs, fixed rectangles, or GDScript edits are required.

### Tool upgrade
1. Add or duplicate a `ToolUpgradeDefinition` in `data/exploration/`.
2. Set source tool, upgraded tool, material costs, coin cost and any progression tag.
3. It appears automatically under **Tools**.

Build-menu rule: content should be added through Resources/scenes, not by adding IDs to menu scripts.


## Designer Dock

The Lung Sa Designer dock is a workflow hub. Detailed editing stays in Godot's Inspector, TileMap editor, SpriteFrames editor and scene editor so ordinary content creation remains low-code without maintaining a second custom editor.


## Inventory / Hotbar / Storage interaction

ItemSlotWidget is the shared drag/drop surface. PACK and the persistent QUICK BAR remain interactive together while Inventory is open. Storage screens expose CHEST + PACK + QUICK BAR in one workspace. Do not create special-case item movement code in individual screens; bind ItemSlotWidget to an ItemSlotContainerComponent and use the shared transfer API.

## Habitat creature spawning

Edit habitat resources in `data/habitats/`. The common controls are intentionally grouped at the top of the Inspector:

- **Max Creatures Alive** — population cap for that habitat.
- **Initial Creatures** — target population when the zone first loads.
- **Respawn Delay Seconds** — wait after a successful refill before another group can appear.
- **Spawn Entries** — species allowed in the habitat.
  - **Species ID** — creature to spawn.
  - **Spawn Weight** — relative chance versus other species; `3` vs `1` is roughly 75% vs 25%.
  - **Min / Max Group Size** — number of that species created by one refill attempt.
- **Minimum Player Distance** — no pop-in close to the player.
- **Creature Spacing** — prevents wild creatures stacking on each other.

Example: `Max Creatures Alive = 6`, `Initial Creatures = 3`, and group size `1–2` means the habitat begins around 3 creatures and gradually refills toward 6 as creatures are removed. Designers should normally tune these fields only; the region spawner itself is infrastructure.
