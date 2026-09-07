extends Node

## Minimal runtime bootstrap for the 15-minute demo foundation.
## Starter seeding remains separate from story, debt, wager, and presentation orchestration.

const STARTER_LOADOUT_SCHEMA: int = 2
const STARTER_CREATURE_SCHEMA: int = 2

var _starter_seeded: bool = false

func _ready() -> void:
    if not SceneRouter.location_changed.is_connected(_on_location_changed):
        SceneRouter.location_changed.connect(_on_location_changed)
    call_deferred("_bootstrap_profile")

func _get_profile() -> GameProfileDefinition:
    return ContentDB.get_active_profile()

func _bootstrap_profile() -> void:
    var profile: GameProfileDefinition = _get_profile()
    if profile == null:
        push_error("DemoBootstrap requires res://data/profiles/active_game_profile.tres")
        return
    var initialized_key: StringName = StringName("profile.%s.initialized" % String(profile.content_id))
    if not bool(GameSession.get_value(initialized_key, false)):
        GameSession.set_value(initialized_key, true)
        GameSession.set_value(&"currency", profile.initial_currency)
        _seed_demo_farm_state(profile)
        call_deferred("_apply_seeded_farm_state_to_live_region", profile)
    _ensure_starter_creatures(profile)
    await get_tree().process_frame
    _seed_player_loadout(profile)
    _claim_pending_rewards()

func _seed_demo_farm_state(profile: GameProfileDefinition) -> void:
    if profile == null or profile.starter_zone_id == &"" or GameSession.has_region_runtime_state(profile.starter_zone_id):
        return
    # Phase 3 opens with one harvest-ready Moonroot. The remaining starter cells are
    # untouched, so the player still performs the complete till → plant → water loop.
    GameSession.set_region_runtime_state(profile.starter_zone_id, {
        "region_id": "region.central_basin",
        "zone_id": String(profile.starter_zone_id),
        "systems": {
            "FarmPlotSystem": {
                "plots": {
                    "0,0": {"tilled": true, "watered": false},
                    "1,0": {
                        "tilled": true,
                        "watered": false,
                        "crop_id": "crop.moonroot",
                        "stage": 3,
                        "watered_growth": 3,
                        "ready": true,
                    },
                },
                "owned_cells": {},
                "last_processed_day": WorldTimeService.get_day(),
            },
        },
    })

func _apply_seeded_farm_state_to_live_region(profile: GameProfileDefinition) -> void:
    if profile == null:
        return
    var region: RegionRoot = SceneRouter.get_current_region_root()
    if region == null:
        region = get_tree().get_first_node_in_group(&"region_root") as RegionRoot
    if region == null or region.get_zone_id() != profile.starter_zone_id:
        return
    var state: Dictionary = GameSession.get_region_runtime_state(profile.starter_zone_id)
    if not state.is_empty():
        region.import_runtime_state(state)

func _ensure_starter_creatures(profile: GameProfileDefinition) -> void:
    if profile == null:
        return
    var seed_key: StringName = StringName("profile.%s.starter_creatures.v%d" % [String(profile.content_id), STARTER_CREATURE_SCHEMA])
    if bool(GameSession.get_value(seed_key, false)):
        return
    var collection: CreatureCollectionModel = CreatureCollectionModel.new()
    var owned_species: Dictionary = {}
    for creature: CreatureInstanceData in collection.get_all_creatures():
        if creature != null:
            owned_species[creature.species_id] = true
    for species_id: StringName in profile.starter_species_ids:
        if species_id == &"" or owned_species.has(species_id):
            continue
        collection.add_captured_creature(species_id, profile.starter_zone_id)
        owned_species[species_id] = true
    GameSession.set_value(seed_key, true)

func _seed_player_loadout(profile: GameProfileDefinition) -> void:
    if profile == null:
        return
    var loadout_key: StringName = StringName("profile.%s.loadout_seeded.v%d" % [String(profile.content_id), STARTER_LOADOUT_SCHEMA])
    if _starter_seeded or bool(GameSession.get_value(loadout_key, false)):
        return
    var player: PlayerActor = get_tree().get_first_node_in_group(&"player") as PlayerActor
    if player == null:
        return
    for resource: Resource in profile.starter_items:
        var entry: StarterItemEntry = resource as StarterItemEntry
        if entry == null or entry.item_id == &"":
            continue
        var current: int = player.inventory_component.get_total_quantity(entry.item_id) + player.hotbar_component.get_total_quantity(entry.item_id)
        if current < entry.amount:
            player.inventory_component.add_item(entry.item_id, entry.amount - current)
    for resource: Resource in profile.starter_items:
        var entry: StarterItemEntry = resource as StarterItemEntry
        if entry != null and entry.hotbar_slot >= 0:
            _move_item_to_hotbar(player, entry.item_id, entry.hotbar_slot)
    player.hotbar_component.select_slot(0)
    _starter_seeded = true
    GameSession.set_value(loadout_key, true)

func _move_item_to_hotbar(player: PlayerActor, item_id: StringName, hotbar_index: int) -> void:
    if player == null or hotbar_index < 0 or hotbar_index >= player.hotbar_component.slot_count:
        return
    if player.hotbar_component.get_item_id(hotbar_index) == item_id:
        return
    if player.hotbar_component.get_item_id(hotbar_index) != &"":
        return
    for inventory_index: int in range(player.inventory_component.get_slot_count()):
        if player.inventory_component.get_item_id(inventory_index) != item_id:
            continue
        player.inventory_component.transfer_slot_to(inventory_index, player.hotbar_component, hotbar_index)
        return

func _on_location_changed(_region_id: StringName, _zone_id: StringName, _spawn_id: StringName) -> void:
    _starter_seeded = false
    var profile: GameProfileDefinition = _get_profile()
    if profile != null:
        call_deferred("_seed_player_loadout", profile)
        call_deferred("_claim_pending_rewards")

func _claim_pending_rewards() -> void:
    var player: PlayerActor = get_tree().get_first_node_in_group(&"player") as PlayerActor
    ContentActionExecutor.claim_pending_rewards(player)

func restart_demo() -> void:
    var profile: GameProfileDefinition = _get_profile()
    if profile == null:
        return
    var old_region: RegionRoot = SceneRouter.get_current_region_root()
    if old_region != null:
        old_region.persist_runtime_state = false
    GameSession.start_new_session(String(profile.content_id))
    WorldStateService.clear_all()
    WorldTimeService.reset_to_default()
    _starter_seeded = false
    SceneRouter.change_scene(profile.start_scene_path, profile.start_spawn_id)
    call_deferred("_bootstrap_profile")
