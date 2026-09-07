# Phase 8 — Unified UI + Character Dialogue Polish

Phase 8 is a presentation-only checkpoint for the fifteen-minute demo. It does **not** add audio, VFX, new gameplay systems, new regions, or new content loops.

## UI contract

Every current demo UI surface shares the same source-of-truth styling:

- `ui/shared/lung_sa_theme.tres` — global Godot theme baseline.
- `ui/shared/lung_sa_ui_style.gd` — runtime semantic styles and reusable helpers.
- `project.godot` — sets the global custom theme so unstyled controls inherit the same baseline automatically.

### Visual language

- dark jade / ink panels
- warm parchment text
- muted jade secondary text
- gold focus / primary-action accents
- consistent 14 px primary panel radius
- consistent 10 px button / slot radius
- 44 px minimum primary button height
- 2 px borders for elevated/modal surfaces
- one typography hierarchy: kicker → title → body → muted helper

Semantic colors remain intentionally distinct:

- Attack — warm red/orange
- Speed — teal
- Guard — green
- Success — green
- Danger — red
- Ledger / debt — terracotta red

These semantic colors may accent a shared component but do not replace the shared component style.

## Screen ownership

Static hierarchy remains in `.tscn` scenes. Scripts bind data and style repeated/dynamic rows only.

The shared style contract covers:

- HUD / debt / quest tracker
- hotbar and item slots
- interaction prompt and toast
- inventory
- shop / shipping
- quest journal
- farm storage / farm crew
- creature roster / loadout / evolution
- build and crafting panels
- confirmation and fortune reveal
- battle HUD / command picker / creature status / party strips / Bond wager
- vertical-slice welcome / completion surfaces

## Character dialogue direction

Dialogue uses a **character-forward mobile strategy-game layout** inspired by the readability of games such as Clash of Clans, while retaining Lung Sa's own Ledger / parchment / jade identity.

Layout:

`large character portrait | speaker / dialogue / response panel`

Rules:

1. Character art is large enough to read before the text.
2. Speaker name is the strongest text element.
3. NPC role sits with the portrait as a small identity tag.
4. Dialogue body is short, high-contrast, and never buried in a tiny bottom textbox.
5. Choices use the same button system as the rest of the game.
6. The first choice receives primary focus styling; keyboard/controller focus remains visible.
7. `E` advances and `Esc` closes.
8. Dialogue blocks click-through into gameplay.

## Portrait authoring

`NPCDefinition` now exposes:

- `portrait_texture` — preferred dialogue portrait.
- `world_texture` — overworld art and automatic portrait fallback.

This lets a designer replace a portrait in data without changing dialogue code. Current placeholder NPCs can continue using their world texture until dedicated portrait art is authored.

## Out of scope

Phase 8 intentionally adds **no**:

- audio
- music
- new sound cues
- particles
- screen shake
- new transition effects
- combat VFX
- reward VFX
- new gameplay mechanics

Existing earlier-phase presentation behavior remains untouched unless required for UI consistency.
