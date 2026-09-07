#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
TEXT_EXTS = {'.gd', '.tscn', '.tres', '.godot', '.cfg'}
TEMPLATE_ROOT = ROOT / 'data' / 'templates'
ACTIVE_PROFILE = ROOT / 'data' / 'profiles' / 'active_game_profile.tres'
EXPECTED_TEMPLATES = {
    'creature_template.tres', 'evolution_template.tres', 'item_template.tres',
    'crop_template.tres', 'recipe_template.tres', 'npc_template.tres',
    'dialogue_template.tres', 'quest_template.tres', 'discovery_template.tres',
    'shop_template.tres', 'region_template.tres', 'zone_template.tres',
    'habitat_template.tres', 'building_template.tres', 'loot_table_template.tres',
    'gatherable_resource_template.tres',
    'move_template.tres', 'trait_template.tres', 'farm_work_profile_template.tres',
    'interaction_template.tres', 'story_chain_template.tres',
    'world_reaction_template.tres',
}

texts = {}
for p in ROOT.rglob('*'):
    if p.is_file() and '.godot' not in p.parts and p.suffix in TEXT_EXTS:
        texts[p] = p.read_text(encoding='utf-8', errors='ignore')

errors = []
refs = []
incoming_refs = {}
for p, text in texts.items():
    for ref in re.findall(r'res://[^"\'\s\)\]\},]+', text):
        clean = ref.rstrip('.,:;')
        refs.append((p, clean))
        if '%' in clean:
            continue
        target = ROOT / clean.removeprefix('res://')
        if not target.exists():
            errors.append(f'missing ref: {p.relative_to(ROOT)} -> {clean}')
        else:
            incoming_refs[target] = incoming_refs.get(target, 0) + 1

# Registered class names must be unique and reachable by resource path or class usage.
classes = {}
for p, text in texts.items():
    if p.suffix != '.gd':
        continue
    m = re.search(r'^class_name\s+(\w+)', text, re.M)
    if m:
        name = m.group(1)
        if name in classes:
            errors.append(f'duplicate class_name {name}: {classes[name]} and {p.relative_to(ROOT)}')
        classes[name] = p.relative_to(ROOT)

for class_name, rel_path in classes.items():
    source_path = ROOT / rel_path
    direct_ref_count = incoming_refs.get(source_path, 0)
    pattern = re.compile(rf'\b{re.escape(class_name)}\b')
    class_ref_count = 0
    for other_path, other_text in texts.items():
        if other_path == source_path:
            continue
        class_ref_count += len(pattern.findall(other_text))
    if direct_ref_count == 0 and class_ref_count == 0:
        errors.append(f'orphan class_name {class_name}: {rel_path}')

# ContentDB auto-registers every ContentDefinition .tres under data/, excluding templates.
ids = {}
template_ids = {}
for p, text in texts.items():
    if p.suffix != '.tres':
        continue
    for m in re.finditer(r'^content_id\s*=\s*&?"([^"]+)"', text, re.M):
        cid = m.group(1)
        is_template = TEMPLATE_ROOT in p.parents
        target = template_ids if is_template else ids
        if cid in target:
            errors.append(f'duplicate {"template " if is_template else ""}content_id {cid}: {target[cid]} and {p.relative_to(ROOT)}')
        target[cid] = p.relative_to(ROOT)

# The old manual ContentCatalog registry has been removed. ContentDB scans data/ directly.
if (ROOT / 'data' / 'catalogs').exists():
    errors.append('obsolete data/catalogs directory remains; content should auto-register directly')

if not ACTIVE_PROFILE.exists():
    errors.append('designer-modular project is missing data/profiles/active_game_profile.tres')

actual_templates = {p.name for p in TEMPLATE_ROOT.glob('*.tres')} if TEMPLATE_ROOT.exists() else set()
for missing in sorted(EXPECTED_TEMPLATES - actual_templates):
    errors.append(f'missing designer template: data/templates/{missing}')

plugin_cfg = ROOT / 'addons' / 'lung_sa_designer' / 'plugin.cfg'
plugin_gd = ROOT / 'addons' / 'lung_sa_designer' / 'plugin.gd'
if not plugin_cfg.exists() or not plugin_gd.exists():
    errors.append('Lung Sa Designer editor plugin is missing')
else:
    project_text = texts.get(ROOT / 'project.godot', '')
    if 'res://addons/lung_sa_designer/plugin.cfg' not in project_text:
        errors.append('Lung Sa Designer plugin is not enabled in project.godot')

# Guard the generic systems that used to contain slice-specific content IDs.
generic_guard_files = [
    ROOT / 'vertical_slice' / 'demo_bootstrap.gd',
    ROOT / 'systems' / 'story' / 'story_progression_system.gd',
    ROOT / 'ui' / 'quests' / 'quest_tracker_widget.gd',
    ROOT / 'systems' / 'farming' / 'farm_work_ai_system.gd',
    ROOT / 'world' / 'shared' / 'building' / 'building_placement_controller.gd',
    ROOT / 'systems' / 'ecology' / 'world_ecology_reaction_system.gd',
]
content_specific_literals = (
    'creature.mossback', 'creature.rillfin', 'npc.central_basin.',
    'quest.central_basin.', 'world.central_basin.', 'item.tool.field_',
    'item.seed.moonroot', 'story_chain.central_basin.',
)
for p in generic_guard_files:
    text = texts.get(p, '')
    for literal in content_specific_literals:
        if literal in text:
            errors.append(f'content-specific literal {literal!r} remains in generic system {p.relative_to(ROOT)}')



# Lean cleanup guards: these atlas slices were superseded by TileMap/farm visuals.
obsolete_art_resources = [
    ROOT / 'art' / 'sprites' / 'tree.tres',
    ROOT / 'art' / 'sprites' / 'crop_0.tres',
    ROOT / 'art' / 'sprites' / 'crop_1.tres',
    ROOT / 'art' / 'sprites' / 'crop_2.tres',
]
for obsolete in obsolete_art_resources:
    if obsolete.exists():
        errors.append(f'obsolete unreferenced art resource returned: {obsolete.relative_to(ROOT)}')

# TileMap + visual architecture guards.
required_architecture_files = [
    ROOT / 'world' / 'shared' / 'tile_content' / 'world_content_tileset.tres',
    ROOT / 'world' / 'shared' / 'tile_content' / 'tile_world_content_system.gd',
    ROOT / 'data' / 'gathering' / 'gatherable_resource_definition.gd',
]
for required in required_architecture_files:
    if not required.exists():
        errors.append(f'missing TileMap visual architecture file: {required.relative_to(ROOT)}')

legacy_scene_per_cell_files = [
    ROOT / 'world' / 'shared' / 'exploration' / 'forage_plant_node.gd',
    ROOT / 'world' / 'shared' / 'exploration' / 'forage_plant_node.tscn',
    ROOT / 'world' / 'shared' / 'exploration' / 'gatherable_resource_node.gd',
    ROOT / 'world' / 'shared' / 'exploration' / 'gatherable_tree.tscn',
    ROOT / 'world' / 'shared' / 'exploration' / 'gatherable_dense_rock.tscn',
]
for legacy in legacy_scene_per_cell_files:
    if legacy.exists():
        errors.append(f'legacy scene-per-cell gatherable remains: {legacy.relative_to(ROOT)}')

for pth, text in texts.items():
    if pth.suffix == '.gd' and ('BasinArt.paint' in text or 'BasinArt.item_key' in text):
        errors.append(f'code-driven gameplay art lookup remains in {pth.relative_to(ROOT)}')
    if pth.suffix == '.gd' and 'BasinArt' in text:
        errors.append(f'legacy BasinArt dependency remains in {pth.relative_to(ROOT)}')

region_root_scene = texts.get(ROOT / 'world' / 'shared' / 'region_root.tscn', '')
for layer_name in ('StaticProps', 'Forage', 'ResourceTiles'):
    if f'[node name="{layer_name}" type="TileMapLayer" parent="TileLayers"]' not in region_root_scene:
        errors.append(f'RegionRoot is missing required painted-content layer {layer_name}')
if 'res://world/shared/tile_content/world_content_tileset.tres' not in region_root_scene:
    errors.append('RegionRoot does not use the world content TileSet')
if '[node name="TileWorldContentSystem" type="Node" parent="Systems"]' not in region_root_scene:
    errors.append('RegionRoot is missing TileWorldContentSystem')

world_content_tileset = texts.get(ROOT / 'world' / 'shared' / 'tile_content' / 'world_content_tileset.tres', '')
for data_name in ('content_kind', 'content_id', 'tile_key', 'depleted_tile_key', 'prompt_text', 'interaction_radius', 'interaction_priority'):
    if f'name = "{data_name}"' not in world_content_tileset:
        errors.append(f'World content TileSet is missing custom data layer {data_name}')
for required_id in ('plant.central_basin.wild_herb', 'resource.central_basin.tree', 'resource.central_basin.rock'):
    if required_id not in world_content_tileset:
        errors.append(f'World content TileSet does not directly bind tile custom data to {required_id}')
for legacy_catalog in (
    ROOT / 'world' / 'shared' / 'tile_content' / 'tile_content_catalog.gd',
    ROOT / 'world' / 'shared' / 'tile_content' / 'tile_content_definition.gd',
    ROOT / 'data' / 'tile_content' / 'central_basin_tile_content.tres',
):
    if legacy_catalog.exists():
        errors.append(f'legacy numeric Tile Content Catalog remains: {legacy_catalog.relative_to(ROOT)}')

farm_scene = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_farm.tscn', '')
wilds_scene = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_wilds.tscn', '')
for layer_name in ('StaticProps', 'Forage', 'ResourceTiles'):
    if f'[node name="{layer_name}" parent="TileLayers"]' not in farm_scene:
        errors.append(f'Demo Farm does not author painted tile data for {layer_name}')
for layer_name in ('StaticProps', 'Forage', 'ResourceTiles'):
    if f'[node name="{layer_name}" parent="TileLayers"]' not in wilds_scene:
        errors.append(f'Demo Wilds does not author painted tile data for {layer_name}')

plugin_text = texts.get(ROOT / 'addons' / 'lung_sa_designer' / 'plugin.gd', '')
for legacy_label in ('Gatherable Tree', 'Gatherable Rock', 'Forage Plant'):
    if legacy_label in plugin_text:
        errors.append(f'Designer dock still exposes legacy scene placement: {legacy_label}')
for required_layer in ('Forage', 'ResourceTiles', 'StaticProps'):
    if f'_select_tile_layer.bind(&"{required_layer}")' not in plugin_text:
        errors.append(f'Designer dock cannot select TileMap content layer {required_layer}')
for designer_method in (
    '_make_unique_content_id',
    '_request_duplicate_selected',
    '_show_selected_dependencies',
    '_request_safe_delete_selected',
    '_create_npc_story_bundle',
    '_create_region_story_bundle',
    '_playtest_current_scene',
):
    if f'func {designer_method}(' not in plugin_text:
        errors.append(f'Designer dock is missing low-code workflow method {designer_method}')
if 'EditorUndoRedoManager' not in plugin_text:
    errors.append('Designer world placement does not support editor Undo/Redo')

crop_definition_text = texts.get(ROOT / 'data' / 'farming' / 'crop_definition.gd', '')
if 'farm_stage_source_ids' not in crop_definition_text or 'farm_ready_source_id' not in crop_definition_text:
    errors.append('CropDefinition does not own farm TileMap stage visuals')

item_slot_text = texts.get(ROOT / 'ui' / 'shared' / 'item_slot.gd', '')
if 'definition_for_icon.icon' not in item_slot_text:
    errors.append('Item slot UI is not using explicit ItemDefinition.icon')

# Ordinary resource collision belongs to the TileSet, not runtime StaticBody generation.
tile_system_text = texts.get(ROOT / 'world' / 'shared' / 'tile_content' / 'tile_world_content_system.gd', '')
if 'StaticBody2D.new()' in tile_system_text:
    errors.append('TileWorldContentSystem still creates movement collision in code; collision belongs in TileSet')
content_tileset_text = texts.get(ROOT / 'world' / 'shared' / 'tile_content' / 'world_content_tileset.tres', '')
if 'TreeSource' in content_tileset_text and 'physics_layer_0/polygon_0/points' not in content_tileset_text:
    errors.append('World content TileSet is missing authored resource collision')

for banned in ('func get_priority(', 'func draw_ellipse(', 'var trait:'):
    for p, text in texts.items():
        if banned in text:
            errors.append(f'banned parser/collision pattern {banned!r} in {p.relative_to(ROOT)}')

# Current lean-checkpoint guards.
required_docs = [
    ROOT / 'docs' / 'ARCHITECTURE.md',
    ROOT / 'docs' / 'DESIGNER_WORKFLOW.md',
    ROOT / 'docs' / 'ART_ASSETS.md',
    ROOT / 'docs' / 'PLAYTEST.md',
    ROOT / 'docs' / 'RELEASE_CHECKLIST.md',
]
for required in required_docs:
    if not required.exists():
        errors.append(f'missing source-of-truth document: {required.relative_to(ROOT)}')

for required in (
    ROOT / 'tests' / 'inventory_transfer_test.gd',
    ROOT / 'tests' / 'inventory_transfer_test.tscn',
):
    if not required.exists():
        errors.append(f'missing inventory transfer regression file: {required.relative_to(ROOT)}')

quest_service_text = texts.get(ROOT / 'systems' / 'quests' / 'quest_service.gd', '')
condition_text = texts.get(ROOT / 'systems' / 'content' / 'content_condition_evaluator.gd', '')
if 'hotbar_slots' in quest_service_text:
    errors.append('QuestService listens for obsolete hotbar_slots state key')
if '_get_saved_container_quantity(&"hotbar"' not in condition_text:
    errors.append('Collection conditions do not include Quick Bar quantities')
if not (ROOT / 'components' / 'inventory' / 'carried_inventory_service.gd').exists():
    errors.append('Shared carried inventory service is missing')
crafting_text = texts.get(ROOT / 'systems' / 'crafting' / 'crafting_service.gd', '')
if 'get_value(&"recipe_unlocks"' in crafting_text or 'set_value(&"recipe_unlocks"' in crafting_text:
    errors.append('CraftingService still uses obsolete recipe_unlocks state key')
for relative_path in (
    'systems/building/building_placement_service.gd',
    'systems/shops/shop_transaction_service.gd',
    'systems/creatures/creature_collection_model.gd',
    'systems/battle/battle_turn_resolver.gd',
):
    if 'CarriedInventoryService' not in texts.get(ROOT / relative_path, ''):
        errors.append(f'{relative_path} does not use the shared carried inventory contract')
save_service_text = texts.get(ROOT / 'core' / 'services' / 'save_service.gd', '')
for required_pattern in ('DirAccess.rename_absolute', '.tmp', '.bak', '_read_save_data'):
    if required_pattern not in save_service_text:
        errors.append(f'SaveService is missing crash-safe save behavior: {required_pattern}')

obsolete_docs = [
    ROOT / 'ART_ASSET_ARCHITECTURE.md',
    ROOT / 'CREATURE_OVERWORLD_ANIMATION.md',
    ROOT / 'DESIGNER_IMPLEMENTATION_AUDIT.md',
    ROOT / 'DESIGNER_WORKFLOW.md',
    ROOT / 'TILEMAP_VISUAL_ARCHITECTURE.md',
    ROOT / 'TILE_CUSTOM_DATA_REFACTOR.md',
    ROOT / 'TILE_CUSTOM_DATA_REFACTOR_CHANGELOG.md',
    ROOT / 'VERTICAL_SLICE.md',
    ROOT / 'docs' / 'DEVELOPMENT_NOTES.md',
    ROOT / 'docs' / 'FARM_DESIGNER_AUTHORING.md',
    ROOT / 'docs' / 'UI_DESIGNER_ARCHITECTURE.md',
]
for obsolete in obsolete_docs:
    if obsolete.exists():
        errors.append(f'superseded checkpoint document returned: {obsolete.relative_to(ROOT)}')

farm_visual_script = texts.get(ROOT / 'world' / 'shared' / 'farming' / 'farm_plot_visual.gd', '')
farm_visual_scene = texts.get(ROOT / 'world' / 'shared' / 'farming' / 'farm_plot_visual.tscn', '')
farm_plot_script = texts.get(ROOT / 'systems' / 'farming' / 'farm_plot_system.gd', '')
for layer_name in ('FarmBuildArea', 'StarterPlots', 'FarmOwnedPlots', 'FarmSoil', 'FarmCrops'):
    if f'[node name="{layer_name}" type="TileMapLayer" parent="."]' not in farm_visual_scene:
        errors.append(f'FarmPlotVisual is missing required layer {layer_name}')
for required_method in ('can_place_farm_plot', 'get_unplaced_plot_allowance', 'get_level_plot_unlock_count'):
    if f'func {required_method}(' not in farm_plot_script:
        errors.append(f'FarmPlotSystem is missing progression placement method {required_method}')
for banned in ('farm_size_cells', 'farm_origin'):
    for p in (
        ROOT / 'world' / 'shared' / 'farming' / 'farm_plot_visual.gd',
        ROOT / 'systems' / 'farming' / 'farm_plot_system.gd',
    ):
        if banned in texts.get(p, ''):
            errors.append(f'code-authored farm geometry returned ({banned}) in {p.relative_to(ROOT)}')
for obsolete in (
    ROOT / 'systems' / 'farming' / 'farm_expansion_system.gd',
    ROOT / 'world' / 'shared' / 'farming' / 'farm_expansion_area.gd',
    ROOT / 'world' / 'shared' / 'farming' / 'farm_expansion_area.tscn',
):
    if obsolete.exists():
        errors.append(f'fixed farm-expansion architecture returned: {obsolete.relative_to(ROOT)}')
for pth, text in texts.items():
    if 'FarmExpansionSystem' in text or 'FarmExpansionArea' in text or 'farm_expansion_requested' in text:
        errors.append(f'stale fixed farm-expansion reference remains in {pth.relative_to(ROOT)}')



# Sanitized Phase 1 guards: legacy content and repository hygiene.
legacy_tokens = (
    'story_chain.central_basin.living_roads',
    'quest.central_basin.quiet_old_bell',
    'quest.central_basin.river_remembers',
    'quest.central_basin.paths_joined',
    'npc.central_basin.sena_riverkeeper',
    'item.tool.trail_axe',
    'item.tool.trail_pickaxe',
    'world/central_basin/interactions/old_path_bell',
)
for path, text in texts.items():
    rel = path.relative_to(ROOT).as_posix()
    if rel.startswith('tests/') or rel.startswith('docs/'):
        continue
    for token in legacy_tokens:
        if token in text:
            errors.append(f'retired Phase 1 content token still referenced in {rel}: {token}')

for p in ROOT.rglob('*'):
    if not p.is_file():
        continue
    name = p.name.lower()
    if name in ('.ds_store', 'thumbs.db') or name.endswith(('.tmp', '.temp', '.bak', '.old', '.orig', '.rej', '~')):
        errors.append(f'repository hygiene artifact committed: {p.relative_to(ROOT)}')
    if p.parent == ROOT / 'data' / 'templates' and p.suffix == '.tres' and p.name != p.name.lower():
        errors.append(f'template filename must be lowercase snake_case: {p.relative_to(ROOT)}')

for p in ROOT.rglob('*.import'):
    source = Path(str(p)[:-7])
    if not source.exists():
        errors.append(f'orphan import sidecar: {p.relative_to(ROOT)}')
for p in ROOT.rglob('*.uid'):
    source = Path(str(p)[:-4])
    if not source.exists():
        errors.append(f'orphan uid sidecar: {p.relative_to(ROOT)}')

# Phase 1 foundation guards: interaction, transitions, single Bond path, and NPC placement.
interactor_text = texts.get(ROOT / 'components' / 'interaction' / 'interactor_component.gd', '')
interactable_text = texts.get(ROOT / 'components' / 'interaction' / 'interactable_component.gd', '')
player_scene_text = texts.get(ROOT / 'actors' / 'player' / 'player_actor.tscn', '')
wild_actor_text = texts.get(ROOT / 'actors' / 'creatures' / 'wild_creature_actor.gd', '')
wild_scene_text = texts.get(ROOT / 'actors' / 'creatures' / 'wild_creature_actor.tscn', '')
overlay_text = texts.get(ROOT / 'ui' / 'transitions' / 'scene_transition_overlay.gd', '')
scene_router_text = texts.get(ROOT / 'core' / 'services' / 'scene_router.gd', '')

for required_pattern in ('front_facing_threshold', '_get_best_candidate(false, true)', 'max_interaction_distance: float = 52.0'):
    if required_pattern not in interactor_text:
        errors.append(f'Phase 1 interaction guard missing: {required_pattern}')
if 'monitorable = enabled' in interactable_text:
    errors.append('Unavailable interactables become undetectable; failure-specific interaction feedback would regress')
if 'radius = 44.0' not in player_scene_text:
    errors.append('Player interaction detector is no longer using the Phase 1 tightened 44 px radius')
if 'EncounterInteractable' not in wild_actor_text or 'EncounterInteractable' not in wild_scene_text:
    errors.append('Wild creature overworld interaction must be EncounterInteractable (battle entry only)')
for obsolete_name in ('CreatureBondCoordinator', 'BondEncounterState', 'BondInteractable'):
    for pth, text in texts.items():
        if obsolete_name in text:
            errors.append(f'obsolete overworld Bond path marker {obsolete_name} remains in {pth.relative_to(ROOT)}')
if '_cancel_title_tween' not in overlay_text or 'begin_blocking()' not in overlay_text:
    errors.append('Scene transition overlay is missing stale-title cancellation')
for required_pattern in ('_resolve_destination_spawn', '_lock_transition_input', 'spawn_fallback_used'):
    if required_pattern not in scene_router_text:
        errors.append(f'SceneRouter Phase 1 reliability behavior missing: {required_pattern}')

for zone_path in sorted((ROOT / 'world' / 'central_basin' / 'zones').glob('*.tscn')):
    zone_text = texts.get(zone_path, '')
    npc_ids = re.findall(r'npc_definition_id\s*=\s*&"([^"]+)"', zone_text)
    duplicates = sorted({npc_id for npc_id in npc_ids if npc_ids.count(npc_id) > 1})
    for npc_id in duplicates:
        errors.append(f'duplicate NPC placement {npc_id} in {zone_path.relative_to(ROOT)}')


# Phase 2 route guards: exactly three demo zones with Village as the hinge.
demo_zone_dir = ROOT / 'world' / 'central_basin' / 'zones'
expected_demo_scenes = {'demo_farm.tscn', 'demo_village.tscn', 'demo_wilds.tscn'}
actual_demo_scenes = {p.name for p in demo_zone_dir.glob('*.tscn')}
if actual_demo_scenes != expected_demo_scenes:
    errors.append(f'Phase 2 zone scene set must be exactly {sorted(expected_demo_scenes)}, got {sorted(actual_demo_scenes)}')

region_text = texts.get(ROOT / 'data' / 'regions' / 'central_basin.tres', '')
for cid in ('zone.central_basin.demo_farm', 'zone.central_basin.demo_village', 'zone.central_basin.demo_wilds'):
    if cid not in region_text:
        errors.append(f'Central Basin region is missing Phase 2 zone {cid}')
for legacy in ('zone.central_basin.west_meadow', 'zone.central_basin.riverbend'):
    for pth, text in texts.items():
        rel = pth.relative_to(ROOT).as_posix()
        if rel.startswith('docs/'):
            continue
        if legacy in text:
            errors.append(f'retired route ID {legacy} remains in {rel}')

farm_scene = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_farm.tscn', '')
village_scene = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_village.tscn', '')
wilds_scene = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_wilds.tscn', '')
if 'destination_zone_id = &"zone.central_basin.demo_village"' not in farm_scene:
    errors.append('Demo Farm must route only to Basin Village')
if 'destination_zone_id = &"zone.central_basin.demo_farm"' not in village_scene or 'destination_zone_id = &"zone.central_basin.demo_wilds"' not in village_scene:
    errors.append('Basin Village must connect Farm and Wilds')
if 'destination_zone_id = &"zone.central_basin.demo_village"' not in wilds_scene:
    errors.append('Demo Wilds must return to Basin Village')
if 'zone.central_basin.demo_wilds' in farm_scene or 'zone.central_basin.demo_farm' in wilds_scene:
    errors.append('Farm and Wilds must not have a direct Phase 2 entrance')
if 'spawning_enabled = false' not in farm_scene:
    errors.append('Demo Farm encounter spawning must remain disabled')
if 'spawning_enabled = false' not in village_scene:
    errors.append('Basin Village encounter spawning must remain disabled')
if 'spawning_enabled = true' not in wilds_scene:
    errors.append('Demo Wilds encounter spawning must remain enabled')
for npc_id in ('npc.central_basin.mei', 'npc.central_basin.ledger_clerk', 'npc.central_basin.shopkeeper', 'npc.central_basin.quest_resident'):
    if npc_id not in village_scene:
        errors.append(f'Basin Village is missing required Phase 2 social anchor {npc_id}')
project_text = texts.get(ROOT / 'project.godot', '')
profile_text = texts.get(ROOT / 'data' / 'profiles' / 'active_game_profile.tres', '')
if 'run/main_scene="res://world/central_basin/zones/demo_farm.tscn"' not in project_text:
    errors.append('Phase 2 project main scene must be Demo Farm')
if 'res://world/central_basin/zones/demo_farm.tscn' not in profile_text or 'zone.central_basin.demo_farm' not in profile_text:
    errors.append('Active profile must start at Demo Farm')


# Phase 3 farm/resource/economy guards.
phase3_required_files = (
    'data/farming/sunpod_crop.tres',
    'data/farming/sunpod_seed.tres',
    'data/items/sunpod.tres',
    'data/items/plant_fiber.tres',
    'data/items/wild_herb.tres',
    'data/plants/wild_basin_herb.tres',
    'data/shops/farm_shipping.tres',
    'docs/PHASE3_ECONOMY.md',
    'tests/phase3_economy_test.py',
)
for relative_path in phase3_required_files:
    if not (ROOT / relative_path).exists():
        errors.append(f'Phase 3 required file missing: {relative_path}')

profile_text = texts.get(ACTIVE_PROFILE, '')
for starter_id in (
    'item.tool.field_hoe', 'item.tool.watering_can', 'item.tool.field_axe', 'item.tool.field_pickaxe',
    'item.seed.moonroot', 'item.seed.sunpod',
):
    if starter_id not in profile_text:
        errors.append(f'Phase 3 active profile missing starter item {starter_id}')
if 'initial_currency = 40' not in profile_text:
    errors.append('Phase 3 active profile must start with 40 currency')

for item_id in ('item.material.basin_wood', 'item.material.plant_fiber', 'item.material.river_stone', 'item.plant.wild_herb'):
    if item_id not in ids:
        errors.append(f'Phase 3 basic resource missing from content IDs: {item_id}')

sunpod_crop = texts.get(ROOT / 'data' / 'farming' / 'sunpod_crop.tres', '')
if 'growth_stages = 2' not in sunpod_crop or 'farm_stage_source_ids = Array[int]([7, 8])' not in sunpod_crop:
    errors.append('Sunpod must remain the one-night Phase 3 showcase crop with authored farm tile sources')

tree_loot = texts.get(ROOT / 'data' / 'gathering' / 'basin_tree_loot.tres', '')
for item_id in ('item.material.basin_wood', 'item.material.plant_fiber'):
    if item_id not in tree_loot:
        errors.append(f'Phase 3 tree loot missing {item_id}')
rock_loot = texts.get(ROOT / 'data' / 'gathering' / 'basin_rock_loot.tres', '')
if 'item.material.river_stone' not in rock_loot:
    errors.append('Phase 3 rock loot must yield River Stone')

farm_scene = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_farm.tscn', '')
village_scene = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_village.tscn', '')
for layer in ('Forage', 'ResourceTiles'):
    block_match = re.search(rf'\[node name="{layer}" parent="TileLayers"\]\n([^\[]*)', village_scene)
    if block_match and 'tile_map_data' in block_match.group(1):
        errors.append(f'Phase 3 Village must not paint tutorial gathering content on {layer}')

for token in ('FarmShippingStand', 'shop.central_basin.farm_shipping', 'start_in_sell_mode = true'):
    if token not in farm_scene:
        errors.append(f'Phase 3 Farm Shipping Stand missing token: {token}')

shop_panel_text = texts.get(ROOT / 'ui' / 'shops' / 'shop_panel.gd', '')
if 'Sell all for %d' not in shop_panel_text or 'EconomyBalanceService.adjusted_sell_price' not in shop_panel_text:
    errors.append('Phase 3 shop selling must expose a correctly priced Sell All action')

bootstrap_text = texts.get(ROOT / 'vertical_slice' / 'demo_bootstrap.gd', '')
for token in ('_seed_demo_farm_state', '"1,0"', '"crop_id": "crop.moonroot"', '"ready": true'):
    if token not in bootstrap_text:
        errors.append(f'Phase 3 bootstrap is missing ready-crop seed behavior: {token}')

farm_cursor_text = texts.get(ROOT / 'presentation' / 'farm_cursor.gd', '')
if 'crop.display_name.to_upper()' not in farm_cursor_text:
    errors.append('Farm cursor is not data-driven for crop display names')
if 'MOONROOT  •  Growth' in farm_cursor_text:
    errors.append('Farm cursor still hardcodes Moonroot growth UI')

project_text = texts.get(ROOT / 'project.godot', '')
# Phase 4 creature/combat/Bond guards. Phase 3 remains a required regression layer.
phase4_required_files = (
    'data/creatures/brambleback_baby.tres',
    'docs/PHASE4_COMBAT_BOND.md',
    'tests/phase4_combat_bond_test.py',
    'tests/phase4_combat_regression.gd',
    'tests/phase4_combat_regression.tscn',
)
for relative_path in phase4_required_files:
    if not (ROOT / relative_path).exists():
        errors.append(f'Phase 4 required file missing: {relative_path}')

for starter_species in ('creature.mossback.baby', 'creature.rillfin.baby'):
    if starter_species not in profile_text:
        errors.append(f'Phase 4 starter party missing {starter_species}')
if 'item.field_poultice' not in profile_text:
    errors.append('Phase 4 active profile must seed Field Poultice')

brambleback_text = texts.get(ROOT / 'data' / 'creatures' / 'brambleback_baby.tres', '')
if 'archetype = "Attack"' not in brambleback_text:
    errors.append('Brambleback must provide the active demo Attack archetype')
riverbank_text = texts.get(ROOT / 'data' / 'habitats' / 'central_basin_riverbank.tres', '')
for species_id in ('creature.mossback.baby', 'creature.rillfin.baby', 'creature.brambleback.baby'):
    if species_id not in riverbank_text:
        errors.append(f'Phase 4 Wilds habitat missing {species_id}')

ruleset_text = texts.get(ROOT / 'data' / 'battle' / 'standard_ruleset.tres', '')
for token in ('party_size = 3', 'active_creatures_per_side = 1', 'switch_cooldown_turns = 1'):
    if token not in ruleset_text:
        errors.append(f'Phase 4 battle ruleset missing {token}')

bond_spell_text = texts.get(ROOT / 'data' / 'spells' / 'bond_spell.tres', '')
for token in ('retry_currency_cost = 25', 'standard_attempts_per_encounter = 1', 'max_paid_retries_per_encounter = 1'):
    if token not in bond_spell_text:
        errors.append(f'Phase 4 Bond contract missing {token}')
bond_service_text = texts.get(ROOT / 'systems' / 'battle' / 'battle_bond_service.gd', '')
if 'model.bond_paid_attempts >= max_paid_retries' not in bond_service_text:
    errors.append('BattleBondService does not enforce the paid retry cap')

battle_hud_text = texts.get(ROOT / 'ui' / 'battle' / 'battle_hud.gd', '')
if '_refresh_matchup_hint' not in battle_hud_text or 'YOUR ADVANTAGE' not in battle_hud_text:
    errors.append('Battle HUD is missing the Phase 4 archetype matchup hint')

if '0.90.0-phase8-ui-dialogue-polish' not in project_text:
    errors.append('Project version is not Phase 8 UI/dialogue checkpoint')



# Phase 5 farm automation guards.
phase5_required = (
    'world/shared/farming/farm_crew_board.gd',
    'world/shared/farming/farm_crew_board.tscn',
    'data/farming/work/brambleback_farm_work.tres',
    'docs/PHASE5_FARM_AUTOMATION.md',
    'tests/phase5_farm_automation_test.py',
    'tests/phase5_farm_automation_regression.gd',
    'tests/phase5_farm_automation_regression.tscn',
)
for relative_path in phase5_required:
    if not (ROOT / relative_path).exists():
        errors.append(f'Phase 5 required file missing: {relative_path}')

farm_scene_phase5 = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_farm.tscn', '')
village_scene_phase5 = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_village.tscn', '')
wilds_scene_phase5 = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_wilds.tscn', '')
for token in ('farm_crew_board.tscn', 'max_assigned_creatures = 3', 'helper_yield_multiplier = 0.4'):
    if token not in farm_scene_phase5:
        errors.append(f'Phase 5 Demo Farm contract missing {token}')
for off_farm_scene, label in ((village_scene_phase5, 'Village'), (wilds_scene_phase5, 'Wilds')):
    for token in ('FarmAssignmentSystem', 'FarmWorkAISystem', 'FarmAssignmentPanel'):
        if token in off_farm_scene:
            errors.append(f'Phase 5 {label} must not own {token}')

bramble_text = texts.get(ROOT / 'data' / 'creatures' / 'brambleback_baby.tres', '')
bramble_profile_text = texts.get(ROOT / 'data' / 'farming' / 'work' / 'brambleback_farm_work.tres', '')
if 'farm_work_profile_id = &"farm_work.brambleback"' not in bramble_text:
    errors.append('Phase 5 Brambleback does not reference its farm work profile')
if 'content_id = &"farm_work.brambleback"' not in bramble_profile_text or 'kind = 4' not in bramble_profile_text:
    errors.append('Phase 5 Brambleback work profile is missing material gathering')

farm_work_rule_text = texts.get(ROOT / 'data' / 'farming' / 'work' / 'farm_work_rule.gd', '')
farm_work_ai_text = texts.get(ROOT / 'systems' / 'farming' / 'farm_work_ai_system.gd', '')
tile_content_phase5 = texts.get(ROOT / 'world' / 'shared' / 'tile_content' / 'tile_world_content_system.gd', '')
for token in ('GATHER_RESOURCE',):
    if token not in farm_work_rule_text:
        errors.append(f'Phase 5 farm work enum missing {token}')
for token in ('helper_yield_multiplier', 'get_helper_gather_jobs()', 'helper_gather_resource', 'harvest_to_container(cell, farm_storage.storage, helper_yield_multiplier)'):
    if token not in farm_work_ai_text:
        errors.append(f'Phase 5 farm work AI contract missing {token}')
for token in ('func get_helper_gather_jobs()', 'func helper_gather_resource(', 'func _scale_helper_drops('):
    if token not in tile_content_phase5:
        errors.append(f'Phase 5 tile helper gathering contract missing {token}')



# Phase 6 story / debt / quest guards.
phase6_required = (
    'systems/progression/debt_service.gd',
    'ui/hud/debt_tracker_widget.gd',
    'ui/hud/debt_tracker_widget.tscn',
    'world/shared/story/debt_payment_desk.gd',
    'world/shared/story/debt_payment_desk.tscn',
    'world/shared/story/village_wager_table.gd',
    'world/shared/story/village_wager_table.tscn',
    'vertical_slice/demo_story_coordinator.gd',
    'data/quests/receipt_that_bites_back.tres',
    'data/quests/lucky_bowl.tres',
    'data/story/first_collection.tres',
    'docs/PHASE6_STORY_DEBT_QUEST.md',
    'tests/phase6_story_debt_test.py',
    'tests/phase6_story_debt_regression.gd',
    'tests/phase6_story_debt_regression.tscn',
)
for relative_path in phase6_required:
    if not (ROOT / relative_path).exists():
        errors.append(f'Phase 6 required file missing: {relative_path}')

project_phase6 = texts.get(ROOT / 'project.godot', '')
for token in (
    'DebtService="*res://systems/progression/debt_service.gd"',
    'DemoStoryCoordinator="*res://vertical_slice/demo_story_coordinator.gd"',
):
    if token not in project_phase6:
        errors.append(f'Phase 6 autoload contract missing {token}')

debt_phase6 = texts.get(ROOT / 'systems' / 'progression' / 'debt_service.gd', '')
for token in ('INITIAL_TOTAL_DEBT: int = 100000', 'FIRST_INSTALLMENT: int = 500', 'func pay_current_due()', 'STATE_FIRST_PAYMENT_COMPLETE'):
    if token not in debt_phase6:
        errors.append(f'Phase 6 debt contract missing {token}')

profile_phase6 = texts.get(ROOT / 'data' / 'profiles' / 'active_game_profile.tres', '')
if 'primary_story_chain_id = &"story_chain.central_basin.first_collection"' not in profile_phase6:
    errors.append('Phase 6 active profile does not point to First Collection story chain')

main_quest_phase6 = texts.get(ROOT / 'data' / 'quests' / 'receipt_that_bites_back.tres', '')
for token in ('reward_currency = 425', 'kind = 0', 'kind = 5', 'kind = 12', 'creature.brambleback.baby'):
    if token not in main_quest_phase6:
        errors.append(f'Phase 6 main quest contract missing {token}')

side_quest_phase6 = texts.get(ROOT / 'data' / 'quests' / 'lucky_bowl.tres', '')
wager_phase6 = texts.get(ROOT / 'world' / 'shared' / 'story' / 'village_wager_table.gd', '')
for token in ('reward_currency = 10', 'demo_wager_played'):
    if token not in side_quest_phase6:
        errors.append(f'Phase 6 wager quest contract missing {token}')
for token in ('STAKE: int = 20', 'WIN_PAYOUT: int = 80', 'WIN_CHANCE: float = 0.55', 'randf() < WIN_CHANCE'):
    if token not in wager_phase6:
        errors.append(f'Phase 6 Lucky Bowl contract missing {token}')

village_phase6 = texts.get(ROOT / 'world' / 'central_basin' / 'zones' / 'demo_village.tscn', '')
for token in ('LedgerPaymentDesk', 'LuckyBowl', 'debt_payment_desk.tscn', 'village_wager_table.tscn'):
    if token not in village_phase6:
        errors.append(f'Phase 6 Village story surface missing {token}')

hud_phase6 = texts.get(ROOT / 'ui' / 'hud' / 'core_hud.tscn', '')
if 'debt_tracker_widget.tscn' not in hud_phase6:
    errors.append('Phase 6 Core HUD is missing debt tracker')

# Phase 6 replaced all temporary Phase 2 resident dialogue content.
for retired_dialogue in (
    ROOT / 'data' / 'dialogue' / 'ledger_clerk_phase2.tres',
    ROOT / 'data' / 'dialogue' / 'mei_foundation.tres',
    ROOT / 'data' / 'dialogue' / 'quest_resident_phase2.tres',
    ROOT / 'data' / 'dialogue' / 'shopkeeper_phase2.tres',
):
    if retired_dialogue.exists():
        errors.append(f'Phase 2 placeholder dialogue returned: {retired_dialogue.relative_to(ROOT)}')


# Phase 7 gambling identity / payoff presentation guards.
phase7_required = (
    'ui/shared/fortune_reveal_panel.gd',
    'ui/shared/fortune_reveal_panel.tscn',
    'docs/PHASE7_GAMBLING_IDENTITY.md',
    'tests/phase7_gambling_identity_test.py',
    'tests/phase7_gambling_identity_regression.gd',
    'tests/phase7_gambling_identity_regression.tscn',
)
for relative_path in phase7_required:
    if not (ROOT / relative_path).exists():
        errors.append(f'Phase 7 required file missing: {relative_path}')

fortune_phase7 = texts.get(ROOT / 'ui' / 'shared' / 'fortune_reveal_panel.gd', '')
for token in ('class_name FortuneRevealPanel', 'open_reveal(', 'COLOR_LEDGER', 'seal_text'):
    if token not in fortune_phase7 and token != 'COLOR_LEDGER':
        errors.append(f'Phase 7 fortune reveal contract missing {token}')
ui_style_phase7 = texts.get(ROOT / 'ui' / 'shared' / 'lung_sa_ui_style.gd', '')
if 'COLOR_LEDGER' not in ui_style_phase7:
    errors.append('Phase 7 UI style is missing Ledger accent')
core_hud_phase7 = texts.get(ROOT / 'ui' / 'hud' / 'core_hud.gd', '')
for token in ('show_fortune_reveal(', '_pending_reward_reveal', 'QUEST SETTLED'):
    if token not in core_hud_phase7:
        errors.append(f'Phase 7 CoreHUD reveal contract missing {token}')
debt_tracker_phase7 = texts.get(ROOT / 'ui' / 'hud' / 'debt_tracker_widget.gd', '')
for token in ('COLLECTION 01', 'FundsBar', 'READY', 'PAID'):
    if token not in debt_tracker_phase7:
        errors.append(f'Phase 7 debt presentation missing {token}')
bond_panel_phase7 = texts.get(ROOT / 'ui' / 'creatures' / 'bond_encounter_panel.gd', '')
for token in ('BOND WAGER', 'TEMPT FATE', 'CHANCE %d%%', 'ONE FREE THROW'):
    if token not in bond_panel_phase7:
        errors.append(f'Phase 7 Bond presentation missing {token}')
wager_phase7 = texts.get(ROOT / 'world' / 'shared' / 'story' / 'village_wager_table.gd', '')
for token in ('ODDS 55%%', 'RESEARCH_STIPEND: int = 10', '+70 NET', '-10 NET', 'show_fortune_reveal'):
    if token not in wager_phase7:
        errors.append(f'Phase 7 wager presentation missing {token}')
story_phase7 = texts.get(ROOT / 'vertical_slice' / 'demo_story_coordinator.gd', '')
for token in ('INHERITANCE DRAW', '+1 FARM  •  +100,000 DEBT', 'FIRST COLLECTION'):
    if token not in story_phase7:
        errors.append(f'Phase 7 story presentation missing {token}')


# Phase 8 unified UI / dialogue guards.
phase8_required = (
    'docs/PHASE8_UI_DIALOGUE_POLISH.md',
    'tests/phase8_ui_dialogue_test.py',
    'tests/phase8_ui_dialogue_regression.gd',
    'tests/phase8_ui_dialogue_regression.tscn',
)
for relative_path in phase8_required:
    if not (ROOT / relative_path).exists():
        errors.append(f'Phase 8 required file missing: {relative_path}')

project_phase8 = texts.get(ROOT / 'project.godot', '')
if 'theme/custom="res://ui/shared/lung_sa_theme.tres"' not in project_phase8:
    errors.append('Phase 8 project does not use the shared global UI theme')
ui_style_phase8 = texts.get(ROOT / 'ui' / 'shared' / 'lung_sa_ui_style.gd', '')
for token in ('PANEL_RADIUS: int = 14', 'BUTTON_RADIUS: int = 10', 'BUTTON_HEIGHT: float = 44.0', 'apply_modal_panel', 'apply_character_frame', 'apply_choice_button'):
    if token not in ui_style_phase8:
        errors.append(f'Phase 8 UI style contract missing {token}')

dialogue_scene_phase8 = texts.get(ROOT / 'ui' / 'dialogue' / 'dialogue_panel.tscn', '')
for token in ('PortraitFrame', 'Portrait', 'Role', 'SpeechPanel', 'ConversationKicker', 'mouse_filter = 0'):
    if token not in dialogue_scene_phase8:
        errors.append(f'Phase 8 dialogue layout missing {token}')
dialogue_script_phase8 = texts.get(ROOT / 'ui' / 'dialogue' / 'dialogue_panel.gd', '')
for token in ('apply_character_frame', 'apply_choice_button', 'portrait: Texture2D = null', 'role: String = "Resident"'):
    if token not in dialogue_script_phase8:
        errors.append(f'Phase 8 dialogue behavior missing {token}')
npc_definition_phase8 = texts.get(ROOT / 'data' / 'npcs' / 'npc_definition.gd', '')
if '@export var portrait_texture: Texture2D' not in npc_definition_phase8:
    errors.append('Phase 8 NPCDefinition is missing designer-authored portrait_texture')
dialogue_coordinator_phase8 = texts.get(ROOT / 'systems' / 'dialogue' / 'dialogue_coordinator.gd', '')
for token in ('npc_definition.portrait_texture', 'npc_definition.world_texture'):
    if token not in dialogue_coordinator_phase8:
        errors.append(f'Phase 8 dialogue portrait fallback missing {token}')

ui_style_exceptions = {
    ROOT / 'ui' / 'battle' / 'battle_backdrop.gd',
    ROOT / 'ui' / 'transitions' / 'scene_transition_overlay.gd',
}
for pth, source in texts.items():
    if pth.suffix != '.gd' or ROOT / 'ui' not in pth.parents or pth in ui_style_exceptions:
        continue
    first_line = source.splitlines()[0] if source else ''
    if 'func _ready' in source and ('extends PanelContainer' in first_line or 'extends Control' in first_line) and 'LungSaUIStyle' not in source:
        errors.append(f'Phase 8 interactive UI does not use shared style: {pth.relative_to(ROOT)}')
for pth, source in texts.items():
    if pth.suffix != '.tscn' or ROOT / 'ui' not in pth.parents or pth.name == 'scene_transition_overlay.tscn':
        continue
    if 'theme_override_colors/font_color = Color' in source:
        errors.append(f'Phase 8 one-off static font color remains in {pth.relative_to(ROOT)}')

if errors:
    print('STATIC AUDIT: FAIL')
    for error in errors:
        print(' -', error)
    sys.exit(1)

print(
    'STATIC AUDIT: PASS | '
    f'files={len(texts)} refs={len(refs)} classes={len(classes)} '
    f'auto_content_ids={len(ids)} templates={len(actual_templates)}'
)
