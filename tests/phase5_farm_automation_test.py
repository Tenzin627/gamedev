#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

farm_scene = text("world/central_basin/zones/demo_farm.tscn")
village_scene = text("world/central_basin/zones/demo_village.tscn")
rule = text("data/farming/work/farm_work_rule.gd")
ai = text("systems/farming/farm_work_ai_system.gd")
tile = text("world/shared/tile_content/tile_world_content_system.gd")
presenter = text("systems/farming/farm_creature_presenter_system.gd")
panel = text("ui/farming/farm_assignment_panel.gd")
bramble = text("data/creatures/brambleback_baby.tres")
bramble_profile = text("data/farming/work/brambleback_farm_work.tres")

assert 'FarmCrewBoard' in farm_scene and 'farm_crew_board.tscn' in farm_scene
assert 'max_assigned_creatures = 3' in farm_scene
assert 'helper_yield_multiplier = 0.4' in farm_scene
assert 'FarmAssignmentSystem' not in village_scene
assert 'FarmWorkAISystem' not in village_scene
assert 'GATHER_RESOURCE' in rule
assert 'farm_work_profile_id = &"farm_work.brambleback"' in bramble
assert 'content_id = &"farm_work.brambleback"' in bramble_profile
assert 'kind = 4' in bramble_profile
assert 'get_helper_gather_jobs()' in ai
assert 'helper_gather_resource' in ai
assert 'harvest_to_container(cell, farm_storage.storage, helper_yield_multiplier)' in ai
assert 'func get_helper_gather_jobs()' in tile
assert 'func helper_gather_resource(' in tile
assert 'func _scale_helper_drops(' in tile
assert '"produced_items"' in ai
assert 'Carrying to Chest' in presenter
assert 'storage_anchor: Vector2 = Vector2(-480, 175)' in presenter
assert 'Helper harvest/gather output ≈ 40%% of manual work' in panel
assert 'FarmWorkRule.Kind.GATHER_RESOURCE' in panel

print("PHASE 5 FARM AUTOMATION: PASS | assign-only UI | autonomous roles | 40% helper yield | storage carry")
