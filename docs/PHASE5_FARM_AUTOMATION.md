# Phase 5 — Creature Farm Automation

## Goal
Prove the Lung Sa homestead payoff in one readable loop:

**Bond creature → return home → assign to Farm → creature chooses useful work → goods reach Homestead Storage → creature rests when idle**

The player assigns creatures only. There is no per-job priority screen, work-zone editor, or manual task queue in the demo.

## Demo Crew

| Creature | Archetype | Automatic farm role |
| --- | --- | --- |
| Mossback | Guard | Harvest mature crops, plant stored seed, till a small amount of soil |
| Rillfin | Speed | Water planted crops, then plant stored seed |
| Brambleback | Attack | Gather nearby farm materials, harvest crops, then till |

Brambleback is the Phase 4 wild Bond target, so capturing it has an immediate visible homestead payoff.

## Assignment
- Home Farm contains a **Farm Crew Board**.
- Interact with it or press **H** while on Home Farm.
- Crew cap for the 15-minute demo is **3 creatures**.
- Clicking a creature toggles Assigned / Unassigned.
- Assignment persists with the Home Farm runtime state.
- Farm crew UI does not exist in Village or Wilds.

## Work Selection
Each species owns a data-driven `FarmWorkProfileDefinition`.

At each pulse the helper looks for the highest-priority useful job in its profile. Multiple assigned creatures reserve different crop cells/resource nodes so they do not intentionally choose the same task at once.

When no useful job exists the presenter returns to its shelter position and displays **Resting**.

## Output / Balance
Automation supports the player; it does not replace direct play.

- Helper crop harvest yield: **40% of the rolled manual yield**, minimum 1 item.
- Helper material drop yield: **40% of the rolled manual yield**, minimum 1 of each produced item.
- Work progress is intentionally visible rather than instant.
- Material nodes still require several helper work actions before depletion.
- Automatic planting consumes seeds from **Homestead Storage**, not the player's carried inventory.
- All automated crop/material outputs go to **Homestead Storage**.

## Presentation
Assigned creatures appear physically on Home Farm.

They walk toward their chosen task and show a compact state label:
- Watering
- Planting
- Tilling
- Harvesting
- Gathering Materials
- Carrying to Chest
- Resting

After a crop harvest or successful material payout, the presenter briefly returns toward the actual Homestead Storage chest before selecting more work.

## Scope Boundaries
Phase 5 intentionally does not add:
- individual job priorities
- schedules/shifts
- creature needs simulation
- hauling inventories per creature
- pathfinding-heavy logistics
- production chains
- breeding
- evolution requirements
- farm-specialization trees

Those are later-game candidates, not requirements for the 15-minute slice.
