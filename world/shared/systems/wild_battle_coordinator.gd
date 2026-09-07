extends RegionLocalSystem
class_name WildBattleCoordinator

signal wild_battle_requested(species_id: StringName, spawn_token: String)

const BATTLE_SCENE_PATH: String = "res://world/battle/battle_scene.tscn"

var _spawner: RegionEncounterSpawner = null
var _transition_started: bool = false

func _on_region_bound() -> void:
    _spawner = region_root.get_local_system(&"EncounterSpawner") as RegionEncounterSpawner
    if _spawner != null and not _spawner.creature_spawned.is_connected(_on_creature_spawned):
        _spawner.creature_spawned.connect(_on_creature_spawned)
    _connect_existing_creatures()
    call_deferred("_consume_pending_battle_return")

func _exit_tree() -> void:
    if _spawner != null and is_instance_valid(_spawner) and _spawner.creature_spawned.is_connected(_on_creature_spawned):
        _spawner.creature_spawned.disconnect(_on_creature_spawned)

func _connect_existing_creatures() -> void:
    if region_root == null:
        return
    var creatures_container: Node = region_root.get_region_container(&"Creatures")
    if creatures_container == null:
        return
    for child: Node in creatures_container.get_children():
        if child is WildCreatureActor:
            _connect_actor(child as WildCreatureActor)

func _on_creature_spawned(actor: WildCreatureActor, _habitat_instance_id: StringName) -> void:
    _connect_actor(actor)

func _connect_actor(actor: WildCreatureActor) -> void:
    if actor == null:
        return
    if not actor.battle_encounter_requested.is_connected(_on_battle_encounter_requested):
        actor.battle_encounter_requested.connect(_on_battle_encounter_requested)

func _on_battle_encounter_requested(actor: WildCreatureActor, _interactor: Node) -> void:
    if _transition_started or actor == null or not is_instance_valid(actor):
        return
    if not _has_battle_ready_party():
        var hud: CoreHUD = region_root.get_node_or_null(^"CoreHUD") as CoreHUD
        if hud != null:
            hud.show_status_message("Your active party has no creature able to battle.", 2.2)
        return
    var context: BattleEncounterContext = BattleEncounterService.prepare_wild_encounter(actor)
    if context == null or not context.is_valid():
        return
    _transition_started = true
    actor.set_encounter_interaction_enabled(false)
    wild_battle_requested.emit(actor.species_id, actor.spawn_token)
    region_root.persist_current_runtime_state()
    var error: Error = SceneRouter.change_scene(BATTLE_SCENE_PATH, &"battle")
    if error != OK:
        _transition_started = false
        actor.set_encounter_interaction_enabled(true)
        BattleEncounterService.clear_active_encounter()

func _has_battle_ready_party() -> bool:
    var collection: CreatureCollectionModel = CreatureCollectionModel.new()
    for creature: CreatureInstanceData in collection.get_party():
        if creature != null and creature.current_hp > 0:
            return true
    return false

func _consume_pending_battle_return() -> void:
    var pending_variant: Variant = GameSession.get_value(&"pending_battle_return", {})
    if not pending_variant is Dictionary:
        return
    var pending: Dictionary = Dictionary(pending_variant)
    if pending.is_empty():
        return
    GameSession.set_value(&"pending_battle_return", {})
    var token: String = str(pending.get("spawn_token", ""))
    var remove_spawn: bool = bool(pending.get("remove_spawn", false))
    if _spawner != null:
        _spawner.resolve_wild_battle_spawn(token, remove_spawn)
