# Lung Sa — Vertical Slice Release Checklist

Current checkpoint: **Phase 8 — Unified UI + Character Dialogue Polish**.

## Static / content
- [ ] `python tests/static_audit.py` passes.
- [ ] `python tests/phase3_economy_test.py` passes.
- [ ] `python tests/phase4_combat_bond_test.py` passes.
- [ ] `python tests/phase5_farm_automation_test.py` passes.
- [ ] `python tests/phase6_story_debt_test.py` passes.
- [ ] `python tests/phase7_gambling_identity_test.py` passes.
- [ ] `python tests/phase8_ui_dialogue_test.py` passes.
- [ ] Godot runtime regression scenes for Phases 4–8 pass.
- [ ] No broken `res://` references or orphan sidecars.

## Phase 8 UI contract
- [ ] Version is `0.90.0-phase8-ui-dialogue-polish`.
- [ ] `project.godot` uses `ui/shared/lung_sa_theme.tres` as the global custom theme.
- [ ] Interactive UI scripts use `LungSaUIStyle` rather than independent palettes.
- [ ] Primary panel radius = 14; button/slot radius = 10; primary button minimum height = 44.
- [ ] Modal, elevated, ordinary, battle, and character-frame variants remain semantic variants of the same style family.
- [ ] One-off static font-color overrides are absent from interactive UI scenes; semantic colors are applied by the shared style helper.

## Dialogue contract
- [ ] Dialogue layout contains Portrait Frame, role tag, speaker name, body, choices, and continue footer.
- [ ] `NPCDefinition.portrait_texture` can replace dialogue art without code changes.
- [ ] `world_texture` remains a safe portrait fallback.
- [ ] Dialogue blocks click-through and preserves visible keyboard/controller focus.
- [ ] Dialogue choices use the shared button style.

## Gameplay regression
- [ ] Phase 3 farm/economy remains intact.
- [ ] Phase 4 combat/Bond remains intact.
- [ ] Phase 5 farm automation remains intact.
- [ ] Phase 6 story/debt chain remains intact.
- [ ] Phase 7 wager/reveal identity remains intact.
- [ ] Debt remains 100,000 total / 500 first collection / 99,500 after payment.
- [ ] Main quest reward remains 425.
- [ ] Lucky Bowl remains 55% odds / 20 stake / 80 payout / 10 stipend / one play.

## Runtime
- [ ] Use Godot 4.6.3 for editor and release verification.
- [ ] `project.godot` still declares the Godot 4.6 feature set.
- [ ] Complete `docs/PLAYTEST.md` in Godot 4.6.3.
- [ ] No parser errors or red debugger output.
- [ ] No HUD overlap at 1280×720.
- [ ] All modal panels close cleanly and restore focus.
- [ ] Dialogue portraits/roles change correctly between NPCs.
- [ ] Battle UI remains unclipped and readable.
- [ ] Restart resets the slice cleanly.

## Scope
- [ ] **No audio or music added in Phase 8.**
- [ ] **No VFX, particles, screen shake, or new transition effects added in Phase 8.**
- [ ] No casino system, real-money monetization, repeatable gambling grind, PvP, tournaments, new region, or late-game system is added.
