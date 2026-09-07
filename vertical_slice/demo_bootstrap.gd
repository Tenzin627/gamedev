extends Node

## Canonical clean-save bootstrap for the September 2026 vertical slice.
## Content values live in GameProfileDefinition; this node only applies them to a fresh session.

const FRESH_START_SCHEMA: int = 1

var _starter_seeded: bool = false
var _fresh_state_prepared: bool = false

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

    var fresh_start: bool = GameSession.is_fresh_start_pending()
    if fresh_start and not _fresh_state_prepared:
        _apply_fresh_session_state(profile)
        _fresh_state_prepared = true

    await get_tree().process_frame

    if fresh_start:
        if not _seed_player_loadout(profile):
            call_deferred("_bootstrap_profile")
            return
        _apply_profile_spawn_override(profile)
        GameSession.set_value(&"fresh_start.schema", FRESH_START_SCHEMA)
        GameSession.set_value(&"fresh_start.profile_id", String(profile.content_id))
        GameSession.mark_fresh_start_applied()
        _fresh_state_prepared = false

    _claim_pending_rewards()

func _apply_fresh_session_state(profile: GameProfileDefinition) -> void:
    GameSession.set_value(&"currency", profile.initial_currency)
    GameSession.clear_region_runtime_states()
    WorldStateService.clear_all()
    WorldTimeService.reset_to_default()
    DebtService.initialize_fresh_state(
        profile.initial_debt_total,
        profile.initial_payment_gate_target,
        profile.initial_payment_gate_progress
    )
    WorldStateService.set_flag(&"vs_arrived", true)
    if profile.initial_quest_id != &"":
        if not QuestService.accept_quest(profile.initial_quest_id):
            push_error("DemoBootstrap could not activate initial quest %s" % String(profile.initial_quest_id))

func _seed_player_loadout(profile: GameProfileDefinition) -> bool:
    if profile == null:
        return false
    if _starter_seeded:
        return true
    var player: PlayerActor = get_tree().get_first_node_in_group(&"player") as PlayerActor
    if player == null:
        return false

    player.inventory_component.clear()
    player.hotbar_component.clear_all()

    for resource: Resource in profile.starter_items:
        var entry: StarterItemEntry = resource as StarterItemEntry
        if entry == null or entry.item_id == &"":
            continue
        if player.inventory_component.add_item(entry.item_id, entry.amount) > 0:
            push_error("DemoBootstrap could not fit starter item %s x%d" % [String(entry.item_id), entry.amount])
            return false

    for resource: Resource in profile.starter_items:
        var entry: StarterItemEntry = resource as StarterItemEntry
        if entry != null and entry.hotbar_slot >= 0:
            if not _move_item_to_hotbar(player, entry.item_id, entry.hotbar_slot):
                push_error("DemoBootstrap could not place %s in hotbar slot %d" % [String(entry.item_id), entry.hotbar_slot + 1])
                return false

    player.hotbar_component.select_slot(0)
    _starter_seeded = true
    return true

func _move_item_to_hotbar(player: PlayerActor, item_id: StringName, hotbar_index: int) -> bool:
    if player == null or hotbar_index < 0 or hotbar_index >= player.hotbar_component.slot_count:
        return false
    if player.hotbar_component.get_item_id(hotbar_index) == item_id:
        return true
    if player.hotbar_component.get_item_id(hotbar_index) != &"":
        return false
    for inventory_index: int in range(player.inventory_component.get_slot_count()):
        if player.inventory_component.get_item_id(inventory_index) != item_id:
            continue
        return player.inventory_component.transfer_slot_to(inventory_index, player.hotbar_component, hotbar_index)
    return false

func _apply_profile_spawn_override(profile: GameProfileDefinition) -> void:
    if profile == null or not profile.start_spawn_position_override_enabled:
        return
    var player: PlayerActor = get_tree().get_first_node_in_group(&"player") as PlayerActor
    if player != null:
        player.global_position = profile.start_spawn_position_override
        player.velocity = Vector2.ZERO

func _on_location_changed(_region_id: StringName, zone_id: StringName, spawn_id: StringName) -> void:
    var profile: GameProfileDefinition = _get_profile()
    if profile != null and zone_id == profile.starter_zone_id and spawn_id == profile.start_spawn_id:
        call_deferred("_apply_profile_spawn_override", profile)
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
    _fresh_state_prepared = false
    SceneRouter.change_scene(profile.start_scene_path, profile.start_spawn_id)
    call_deferred("_bootstrap_profile")
