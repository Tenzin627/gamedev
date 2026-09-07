# Lung Sa — Current Architecture

## Core rule

**Designers author content and presentation; systems own behavior and runtime state.**

Use Resources for definitions, TileMapLayers for repeated world content, scenes for independently behaving objects, SpriteFrames for animation, and `.tscn` Control hierarchies for static UI layout. Add GDScript only for genuinely new mechanics.

## Runtime ownership

- **ContentDB** — discovers and validates `ContentDefinition` Resources under `res://data/`.
- **GameSession** — player/session runtime data.
- **WorldStateService** — persistent world flags and cross-zone state.
- **SceneRouter** — validated zone transitions, spawn handoff, transition input lock, fade, and destination title presentation.
- **WorldTimeService** — global game clock.
- **DebtService** — persistent Ledger balance/current collection state and validated payment.
- **QuestService** — authored quest runtime, generic gameplay-event progress, and rewards.
- **DemoStoryCoordinator** — slice-only opening/end sequencing; it does not own combat, farming, or quest rules.
- **RegionLocalSystem** children — zone-local farming, habitats, weather, encounters, waymarks and ecology.
- **CreatureCollectionModel** — persistent owned creatures and party state.
- **BattleStateModel** — encounter-only creature state.
- **BattleTurnResolver / BattleEffectPipeline** — combat rules and temporary effects.

## World authoring

World grid standard: **64×64 px**.

- Terrain, paths, water and repeated decoration → TileMapLayers.
- Repeated forage and ordinary gatherable resources → TileMapLayers with TileSet custom data.
- Farm build space and starter plots → designer-painted TileMapLayers; additional owned plots are runtime placement state.
- NPCs, creatures, stations, doors, unique landmarks and other independently behaving objects → reusable scenes.
- Runtime systems may create interaction proxies for painted content, but they do not own its art or placement.

Tile content binds directly through TileSet custom data:

`painted cell → content_id → ContentDB → PlantDefinition / GatherableResourceDefinition`

There is no numeric tile-content catalog and no code-driven art lookup.

## Farm contract

`FarmBuildArea` is the designer-painted boundary where farm plots may be placed. `StarterPlots` defines the fresh-game owned plots. `FarmOwnedPlots`, `FarmSoil`, and `FarmCrops` are runtime layers.

Farmer progression unlocks additional plot capacity rather than fixed land chunks: farm level 1 adds 1 bonus plot, level 2 adds 2, through level 5 adding 5. The player chooses the exact cells inside `FarmBuildArea`.

The farm scene position is the farm origin. Systems do not duplicate farm coordinates or width/height geometry.

### Farm helper automation

`FarmAssignmentSystem` persists which owned creature instances are assigned to the homestead. `FarmWorkAISystem` reads each species’ `FarmWorkProfileDefinition` and automatically selects the highest-priority useful job; designers do not author per-creature runtime task queues. `FarmStorageSystem` is the sink for automated crop/material output, and `FarmCreaturePresenterSystem` is presentation-only—it mirrors work/rest/carry state without owning simulation results.

Phase 5 helper output uses a farm-scene-configured yield multiplier (0.4 in the demo). Manual player harvesting/gathering continues to use full yield.

## Inventory contract

Pack, Quick Bar and Storage are separate item containers sharing slot-transfer behavior:

`ItemSlotWidget → ItemSlotContainerComponent → Inventory | Hotbar | Storage`

## Creature contract

Overworld AI is composition-based:

`Perception → AI Controller → behavior components → one movement owner`

Overworld animation comes from `CreatureSpeciesDefinition.world_sprite_frames`; battle presentation remains separate. Farm-work AI is a separate decision layer from wild overworld AI and battle AI. Wild creature interaction enters battle; Bond/capture is resolved only through the battle Bond command, so there is no parallel overworld capture flow.

## Battle contract

`Persistent creature → BattleStateFactory → BattleCreatureState → BattleTurnResolver → BattleEffectPipeline → UI`

Temporary battle buffs/statuses belong to battle state, not persistent creature data.

## UI contract

Static layout belongs in `.tscn`; shared baseline styling belongs in `ui/shared/lung_sa_theme.tres`, which is also configured as the project-wide custom theme. `ui/shared/lung_sa_ui_style.gd` owns semantic variants such as elevated panels, modal panels, character frames, battle accents, buttons, tabs, HP bars, titles, kickers, and muted text.

Scripts bind data and may instantiate repeated rows/slots/cards whose count is unknown at design time. Every interactive UI panel must use the shared style helper rather than inventing its own palette, radius, focus border, or button state. Semantic gameplay colors may accent a shared component but do not replace the shared component language.

Do not build an entire screen in `_ready()` and do not hide designer-facing presentation in code.

### Phase 8 character dialogue contract

`NPCDefinition → DialogueCoordinator → DialoguePanel`

`NPCDefinition.portrait_texture` is the preferred conversation portrait. `world_texture` is the automatic fallback, so portrait art is data-swappable without code changes. Dialogue uses a bottom character-forward composition: large portrait card + role tag + speaker-led speech panel + shared response buttons. The dialogue root blocks gameplay click-through and preserves keyboard/controller focus.


## Phase 6 story/debt contract

The fifteen-minute story is data-first:

`DialogueDefinition → ContentAction → QuestService → generic gameplay events → quest completion`

Debt is deliberately separate:

`wallet / selling / quest rewards → DebtService → Ledger payment desk → world flag / demo completion`

The main quest listens to the same generic `BOND_CREATURE` event used by any authored quest; battle code contains no Tavi/Ledger-specific branch. The optional Lucky Bowl is a small Village interaction and cannot repeat within the same session. `DemoStoryCoordinator` owns only the one-time opening message and final completion panel/restart handoff.

## Change discipline

During the vertical slice, prefer fixing, replacing or removing existing implementation over adding parallel systems. Keep slice-specific bootstrap/sequencing under `vertical_slice/`; retired slice content must not remain embedded in reusable systems or foundation maps. Run the static audit and Godot regression scenes after architecture changes.

## Homestead Build Menu

The homestead uses one menu-driven build flow rather than separate world-only benches and hard-coded build cycling.

- `B` opens `BuildMenuPanel`.
- **Farm Plots** reads `FarmPlotSystem`. Farmer level grants 1–5 additional plot slots per level; the player places the unlocked plots on any empty cell inside the designer-painted `FarmBuildArea`.
- **Tools** reads every `ToolUpgradeDefinition` from `ContentDB` and performs the upgrade from the menu.
- **Buildings**, **Decorations**, and **Habitats** read `BuildingDefinition.menu_category` and begin mouse/grid placement through `BuildingPlacementController`.
- Static menu layout lives in `.tscn`; only repeated item cards are populated from data at runtime.
- Placement/save behavior remains centralized in `BuildingPlacementController`; content definitions do not contain gameplay code.

`BuildingDefinition.menu_category` is the designer-facing catalog switch. Current values are `building`, `decoration`, and `habitat`. `menu_order` controls display order.

## Phase 7 gambling-identity contract

Phase 7 is a **presentation layer over existing rules**, not a new progression system.

- `FortuneRevealPanel` owns only reveal-card UI and focus/blocking behavior.
- `CoreHUD` queues authored quest payout reveals until other modal dialogue is closed.
- `VillageWagerTable` owns the one-shot Lucky Bowl transaction and discloses odds/cost/payout before confirmation.
- `QuestService` still owns quest completion and the 10-coin Lucky Bowl research stipend.
- `BattleBondService` still owns Bond attempt rules/currency deduction; `BondEncounterPanel` only presents those rules as a wager.
- `DebtService` still owns debt state/payment; `DebtTrackerWidget` and `DebtPaymentDesk` only present collection pressure and confirmation.
- Gambling presentation must never be required to understand hidden odds: all costs and chances are displayed before a spend.

## Phase 8 presentation scope

Phase 8 is UI-only. It adds no audio, music, sound cues, particles, screen shake, combat VFX, reward VFX, or new gameplay mechanics. Existing earlier-phase presentation behavior remains unchanged unless necessary for UI consistency.
