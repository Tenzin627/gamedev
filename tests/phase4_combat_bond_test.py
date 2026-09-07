#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

def int_value(path: str, key: str) -> int:
    m = re.search(rf"^{re.escape(key)} = (\d+)$", text(path), re.M)
    if not m:
        raise AssertionError(f"{path}: missing integer {key}")
    return int(m.group(1))

profile = text("data/profiles/active_game_profile.tres")
for species in ("creature.mossback.baby", "creature.rillfin.baby"):
    assert species in profile, f"starter party missing {species}"
assert 'item_id = &"item.field_poultice"' in profile
assert "amount = 2" in profile

expected = {
    "data/creatures/mossback_baby.tres": "Guard",
    "data/creatures/rillfin_baby.tres": "Speed",
    "data/creatures/brambleback_baby.tres": "Attack",
}
for path, archetype in expected.items():
    creature = text(path)
    assert f'archetype = "{archetype}"' in creature, f"{path} must be {archetype}"

habitat = text("data/habitats/central_basin_riverbank.tres")
for species in ("creature.mossback.baby", "creature.rillfin.baby", "creature.brambleback.baby"):
    assert species in habitat, f"Wilds habitat missing {species}"
assert int_value("data/battle/standard_ruleset.tres", "party_size") == 3
assert int_value("data/battle/standard_ruleset.tres", "active_creatures_per_side") == 1
assert int_value("data/battle/standard_ruleset.tres", "switch_cooldown_turns") == 1

resolver = text("systems/battle/battle_turn_resolver.gd")
for relation in (
    'attacker_archetype == &"attack" and defender_archetype == &"speed"',
    'attacker_archetype == &"speed" and defender_archetype == &"guard"',
    'attacker_archetype == &"guard" and defender_archetype == &"attack"',
):
    assert relation in resolver, f"missing triangle relation: {relation}"

spell = text("data/spells/bond_spell.tres")
assert int_value("data/spells/bond_spell.tres", "retry_currency_cost") == 25
assert int_value("data/spells/bond_spell.tres", "standard_attempts_per_encounter") == 1
assert int_value("data/spells/bond_spell.tres", "max_paid_retries_per_encounter") == 1

bond_service = text("systems/battle/battle_bond_service.gd")
assert "model.bond_paid_attempts >= max_paid_retries" in bond_service
assert "currency - cost" in bond_service
command_menu = text("ui/battle/battle_command_menu.gd")
assert 'bond_button.text = "BOND\\nNo attempts remain"' in command_menu
assert 'bond_button.text = "BOND\\nTempt Fate once"' in command_menu

hud = text("ui/battle/battle_hud.gd")
assert "_refresh_matchup_hint" in hud
assert "YOUR ADVANTAGE" in hud and "WILD ADVANTAGE" in hud

outcome = text("systems/battle/outcomes/battle_outcome_service.gd")
assert "collection.restore_party_health()" in outcome
controller = text("world/battle/battle_scene_controller.gd")
assert 'return_scene = SceneRouter.DEFAULT_SCENE_PATH' in controller
assert 'reason == &"bonded"' in controller
assert 'reason == &"escaped"' in controller

print("PHASE 4 COMBAT/BOND: PASS | starters=Guard+Speed | wild trio=Attack/Speed/Guard | bond=1+1 paid")
